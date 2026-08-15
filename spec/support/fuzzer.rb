# frozen_string_literal: true

require_relative 'headless_game'

# Feeds long random key sequences through the headless driver and asserts
# invariants after every single press (Proposal 012, issue #133).
#
# The walk is deterministic: keys are drawn from a private Random instance
# seeded from the game's own seed, never from the global RNG the game pins
# with srand. The game only ever sees key presses, so replaying a recorded
# script through a fresh HeadlessGame reproduces the run exactly — and
# re-running the fuzzer on the same seed regenerates the identical script.
#
# Keys are drawn from the mode the game is actually in: the full mapped
# input set in normal mode (movement, menu toggle, FOV toggle), and the
# live menu options plus the toggle and one ignored key in selection mode.
# Every walk ends by pressing 'q', so the real exit path is exercised once
# per seed without random quits gutting the walk's depth.
#
# On any violation it raises InvariantViolation carrying the seed and the
# full key script, so the failure reproduces by replaying those keys.
class RandomWalkFuzzer
  # Every key InputHandler maps in normal mode, except the exit keys
  # ('q', Ctrl-C): quitting is scripted as the final key instead.
  NORMAL_KEYS = %w[h j k l m f F].freeze

  # Selection-mode alphabet: every option key the menus use — '1'/'2'
  # (fight/run, loot, item actions), digits for item selection, 'i'
  # (inventory), 'b' (back) — plus the toggle and 'x', which no menu maps,
  # to walk the InputSystem branch that discards non-option keys. Keys not
  # valid for the current menu exercise that same ignore branch.
  MENU_KEYS = %w[1 2 3 i b m x].freeze

  MENU_TOGGLE_KEY = 'm'
  EXIT_KEY = 'q'

  # Consecutive presses spent inside selection mode before the fuzzer stops
  # trusting the random walk to leave and drills the exit: MENU_EXIT_BOUND
  # presses of the toggle must return the game to normal mode, or menu mode
  # is not exitable and the run fails. The random walk draws the toggle at
  # roughly 1-in-alphabet, so an exitable menu almost never dwells this long.
  MENU_DWELL_LIMIT = 12
  MENU_EXIT_BOUND = 3

  # Decorrelates the key stream from the game's own srand(seed) stream
  # (both are Mersenne Twisters; an unsalted Random.new(seed) would emit
  # the exact sequence the game consumes).
  KEY_STREAM_SALT = 0xF022

  Result = Struct.new(:seed, :turns, :keys, :quit, keyword_init: true)

  # Carries everything needed to reproduce the failed run: construct a
  # HeadlessGame with the same seed, start it, and press `keys` in order.
  class InvariantViolation < StandardError
    attr_reader :seed, :turns, :keys, :player_position

    def initialize(reason, seed:, turns:, keys:, player_position:)
      @seed = seed
      @turns = turns
      @keys = keys
      @player_position = player_position
      super(<<~MESSAGE)
        #{reason}
        seed #{seed} violated after #{turns} turns (#{keys.size} key presses), player at #{player_position.inspect}
        key script: #{keys.join}
        replay: game = HeadlessGame.new(seed: #{seed}); game.start; "#{keys.join}".each_char { |key| game.press(key) }
      MESSAGE
    end
  end

  attr_reader :keys

  # @param extra_invariants [Hash{String => Proc}] name => ->(game) check,
  #   appended to the built-in invariants; used by the spec to prove the
  #   failure diagnostics without breaking a real invariant.
  def initialize(game, extra_invariants: {})
    @game = game
    @extra_invariants = extra_invariants
    @rng = Random.new(game.seed ^ KEY_STREAM_SALT)
    @keys = []
    @menu_dwell = 0
  end

  # Press `keys` random keys, checking every invariant after each press,
  # then quit through the real exit path. Raises InvariantViolation on the
  # first breach; returns a Result otherwise.
  def walk(keys:)
    keys.times do
      press(next_key)
      check_invariants
      drill_menu_exit if @menu_dwell > MENU_DWELL_LIMIT
    end
    quit_game
    Result.new(seed: @game.seed, turns: @game.turn, keys: @keys, quit: @game.quit?)
  end

  private

  def press(key)
    @keys << key
    @game.press(key)
    @menu_dwell = @game.selection_mode? ? @menu_dwell + 1 : 0
  rescue StandardError => e
    fail!("exception out of the engine: #{e.class}: #{e.message}")
  end

  def next_key
    alphabet = @game.selection_mode? ? MENU_KEYS : NORMAL_KEYS
    alphabet[@rng.rand(alphabet.size)]
  end

  # --- invariants, checked after every press -----------------------------

  def check_invariants
    check_player_cell
    check_player_step
    check_health_bounds
    check_event_stream
    @extra_invariants.each do |name, invariant|
      fail!(name) unless invariant.call(@game)
    end
  end

  # The player, while alive, stands on an in-bounds cell that is linked
  # into the maze. Links are the walkability truth here: a sealed cell (a
  # wall, an uncarved room) has none, so a linked cell is by construction
  # part of the dungeon. The cell's TILE is deliberately not checked — it
  # is an occupancy marker, and legitimately reads as the (non-walkable)
  # monster tile whenever a hunting monster steps onto the player's cell
  # to raise the Fight/Run menu (see MonsterAISystem).
  def check_player_cell
    position = @game.player_position
    return unless position

    grid = @game.grid
    fail!("player at #{position.inspect} is out of bounds") unless grid.in_bounds?(*position)
    fail!("player cell #{position.inspect} has no links") if grid[*position].links.empty?
  end

  # Movement honours the maze: within one level, a press moves the player
  # by at most one cell, and only across a linked edge (the passages
  # MovementSystem is supposed to enforce). A new grid object is a level
  # transition, where the position legitimately jumps to the new spawn.
  # In a perfect maze every cell is linked somewhere, so wall-phasing
  # cannot be caught by looking at the destination cell alone — only the
  # step's edge betrays it.
  def check_player_step
    previous_grid = @stepped_grid
    previous_position = @stepped_position
    @stepped_grid = @game.grid
    @stepped_position = @game.player_position
    return if @stepped_position.nil? || previous_position.nil?
    return unless previous_grid.equal?(@stepped_grid) && previous_position != @stepped_position

    from = @stepped_grid[*previous_position]
    to = @stepped_grid[*@stepped_position]
    return if from.linked?(to)

    fail!("player stepped #{previous_position.inspect} -> #{@stepped_position.inspect} through an unlinked edge")
  end

  # Every entity still in the world holds health within [0, max]. The
  # component clamps the ceiling but not the floor, so a negative value
  # means damage was applied to something that should have died.
  def check_health_bounds
    @game.world.query_entities([:health]).each do |entity|
      health = entity.get_component(:health)
      next if health.current_health.between?(0, health.max_health)

      fail!("#{entity.name} health #{health.current_health} outside [0, #{health.max_health}]")
    end
  end

  # Every captured event is well-formed: a named type (the engine publishes
  # Symbol types from World#emit_event and String types from the direct
  # EventManager publishers) and a hash payload. The failure message never
  # inspects the whole event: its source field can reference the world, and
  # inspecting that object graph effectively hangs the run. Only the events
  # appended since the last press are checked, so the walk stays linear in
  # the total event count.
  def check_event_stream
    events = @game.events
    events[@checked_events.to_i..].each do |event|
      next if named_type?(event.type) && event.data.is_a?(Hash)

      fail!("malformed event: type #{event.type.inspect}, data is a #{event.data.class}")
    end
    @checked_events = events.size
  end

  def named_type?(type)
    (type.is_a?(Symbol) || type.is_a?(String)) && !type.to_s.empty?
  end

  # Menu mode has dwelt past the limit: it must now prove it is exitable
  # within MENU_EXIT_BOUND presses of the toggle. The drill's presses are
  # recorded in the script like any other, so the run still replays.
  def drill_menu_exit
    MENU_EXIT_BOUND.times do
      press(MENU_TOGGLE_KEY)
      break unless @game.selection_mode?
    end
    fail!("menu mode not exitable within #{MENU_EXIT_BOUND} presses of '#{MENU_TOGGLE_KEY}'") if @game.selection_mode?
    @menu_dwell = 0
  end

  # The final key of every walk: 'q' must set the quit flag the real game
  # loop breaks on. 'q' only reaches InputHandler in normal mode, so an
  # open menu is drilled shut first — which is itself the exitability
  # invariant, checked one last time.
  def quit_game
    drill_menu_exit if @game.selection_mode?
    press(EXIT_KEY)
    check_invariants
    fail!("'#{EXIT_KEY}' did not quit the game") unless @game.quit?
  end

  def fail!(reason)
    raise InvariantViolation.new(
      reason,
      seed: @game.seed,
      turns: @game.turn,
      keys: @keys.dup,
      player_position: @game.player_position
    )
  end
end
