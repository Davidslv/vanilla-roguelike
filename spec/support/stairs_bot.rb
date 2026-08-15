# frozen_string_literal: true

require_relative 'headless_game'

# Plays the real game to the stairs, headlessly, one key press at a time
# (Proposal 012, issue #132).
#
# Each turn the bot recomputes its next step from live world state: it roots
# a Dijkstra distance field at the stairs cell -- the same Cell#distances
# machinery MonsterAISystem descends for pursuit, pointed at the stairs
# instead of the player -- and presses the movement key that descends the
# field. When a menu interrupts (Fight/Run on monster contact, the loot menu
# after a kill), it answers '1' (Fight / Pick up). Every action travels
# through HeadlessGame#press, so the bot can do nothing a player could not.
#
# On any failure -- budget exhausted, stall, player death, unreachable
# stairs, or an exception out of the engine -- it raises CertificationFailure
# carrying the seed, the turn count, and the full key script, so the run
# reproduces exactly by replaying those keys against the same seed.
class StairsBot
  MOVEMENT_KEYS = { north: 'k', south: 'j', east: 'l', west: 'h' }.freeze
  MENU_CONFIRM = '1' # Fight in the combat menu, Pick up in the loot menu

  # Consecutive presses with no observable change before declaring a stall.
  # Every real action changes something the fingerprint sees (position,
  # depth, menu state, or the captured-event count), so a run that trips
  # this is wedged, not slow. Ambient events (a pacing monster) can defer
  # the trip; the per-level press budget is the backstop for those shapes.
  STALL_LIMIT = 10

  Result = Struct.new(:seed, :turns, :keys, :depth, keyword_init: true)

  # Carries everything needed to reproduce the failed run: construct a
  # HeadlessGame with the same seed, start it, and press `keys` in order.
  class CertificationFailure < StandardError
    attr_reader :seed, :turns, :keys, :player_position

    def initialize(reason, seed:, turns:, keys:, player_position:)
      @seed = seed
      @turns = turns
      @keys = keys
      @player_position = player_position
      super(<<~MESSAGE)
        #{reason}
        seed #{seed} failed after #{turns} turns (#{keys.size} key presses), player at #{player_position.inspect}
        replay: game = HeadlessGame.new(seed: #{seed}); game.start; "#{keys.join}".each_char { |key| game.press(key) }
      MESSAGE
    end
  end

  attr_reader :keys

  def initialize(game)
    @game = game
    @keys = []
  end

  # Play until the dungeon reaches target_depth (2 = completed level 1 and
  # transitioned). turn_budget bounds the key presses spent per level.
  # @return [Result] on success; raises CertificationFailure otherwise.
  def play(target_depth: 2, turn_budget: 300)
    @keys = []
    @level_presses = 0
    @stalled_presses = 0
    @fingerprint = fingerprint

    until depth >= target_depth
      fail!("turn budget of #{turn_budget} key presses exhausted at depth #{depth}") if @level_presses >= turn_budget

      take_action
      track_progress
    end

    Result.new(seed: @game.seed, turns: @game.turn, keys: @keys, depth: depth)
  rescue CertificationFailure
    raise
  rescue StandardError => e
    fail!("#{e.class}: #{e.message}")
  end

  private

  def take_action
    fail!('player died') unless @game.player

    if @game.selection_mode?
      answer_menu
    else
      step_toward_stairs
    end
  end

  def answer_menu
    fail!("menu offers no '#{MENU_CONFIRM}' option") unless @game.message_system.valid_menu_option?(MENU_CONFIRM)

    press(MENU_CONFIRM)
  end

  def step_toward_stairs
    distances = stairs_distances
    player_cell = @game.grid[*@game.player_position]
    fail!('stairs unreachable from player position') unless distances[player_cell]

    # Unlike MonsterAISystem there is no strict-descent guard: links are
    # bidirectional, so a reachable cell at distance d >= 1 always has a
    # linked neighbour at d - 1, and the budget bounds any degenerate walk.
    next_cell = player_cell.links.select { |cell| distances[cell] }.min_by { |cell| distances[cell] }
    press(MOVEMENT_KEYS.fetch(direction_between(player_cell, next_cell)))
  end

  def press(key)
    @keys << key
    @level_presses += 1
    @game.press(key)
  end

  # The distance field is rooted at the stairs, so descending it walks the
  # shortest path. Links never change within a level, so the field is cached
  # until the maze regenerates (a new grid object).
  def stairs_distances
    grid = @game.grid
    return @stairs_distances if @stairs_distances_grid.equal?(grid)

    stairs = @game.world.find_entity_by_tag(:stairs)
    fail!('no stairs entity on this level') unless stairs

    position = stairs.get_component(:position)
    @stairs_distances_grid = grid
    @stairs_distances = grid[position.row, position.column].distances
  end

  def direction_between(from, to)
    return :north if to.row < from.row
    return :south if to.row > from.row
    return :east if to.column > from.column

    :west
  end

  def depth
    @game.current_level.difficulty
  end

  # A press that changes nothing observable is a stall candidate; STALL_LIMIT
  # of them in a row is a wedged run. A depth change also resets the
  # per-level press budget.
  def track_progress
    current = fingerprint
    if current == @fingerprint
      @stalled_presses += 1
      fail!("no progress after #{STALL_LIMIT} consecutive key presses") if @stalled_presses >= STALL_LIMIT
    else
      @level_presses = 0 if current.first != @fingerprint.first
      @stalled_presses = 0
      @fingerprint = current
    end
  end

  def fingerprint
    [depth, @game.player_position, @game.selection_mode?, @game.events.size]
  end

  def fail!(reason)
    raise CertificationFailure.new(
      reason,
      seed: @game.seed,
      turns: @game.turn,
      keys: @keys.dup,
      player_position: @game.player_position
    )
  end
end
