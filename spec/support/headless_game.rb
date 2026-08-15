# frozen_string_literal: true

# Drives the real game headlessly for integration specs (Proposal 012).
#
# HeadlessGame builds the world exactly the way Vanilla::Game#setup_world does,
# with two deliberate differences:
#
# - InputSystem is constructed but NOT registered in the world: its update
#   blocks on a terminal read. Keys are instead scripted through the same
#   InputSystem instance (see #press), so every key still travels the real
#   dispatch path (menu toggling, menu options, movement commands).
# - RenderSystem is omitted entirely: no terminal is attached.
#
# The event store runs with file storage disabled so spec runs never write to
# event_logs/. Every event published through the EventManager is captured in
# memory and exposed via #events for assertions.
class HeadlessGame
  # Stands in for Vanilla::KeyboardHandler: returns pre-scripted keys instead
  # of reading the terminal. Raises if the game asks for a key the spec never
  # pressed, so a runaway loop fails loudly instead of hanging.
  class ScriptedKeyboard
    def initialize
      @keys = []
    end

    def push(key)
      @keys << key
    end

    def wait_for_input
      raise 'ScriptedKeyboard has no key queued; press one via HeadlessGame#press' if @keys.empty?

      @keys.shift
    end

    def cleanup; end
  end

  # Prepended onto the EventManager's singleton class so every published
  # event is recorded without altering the real publish path.
  module EventCapture
    def captured_events
      @captured_events ||= []
    end

    def publish(event)
      captured_events << event
      super
    end
  end

  attr_reader :world, :turn, :event_manager, :message_system, :seed

  def initialize(seed: Random.new_seed, difficulty: 1)
    @seed = seed
    @difficulty = difficulty
    @turn = 0
    # Reseeding here (and in MazeSystem/start, mirroring the real game) pins
    # the global RNG; remember what it was so cleanup can restore it and the
    # rest of the suite doesn't inherit this game's rand stream.
    @previous_seed = srand(@seed)
    setup_world
  end

  # Mirrors Vanilla::Game#start minus rendering and the blocking loop.
  def start
    srand(@seed)
    @maze_system.update(nil)
    @fov_system.update(nil)
  end

  # Feed one key press through the real input dispatch, then run one pass of
  # the game loop. Mirrors both branches of Vanilla::Game#game_loop, with one
  # deliberate simplification: one key per press. In the real game InputSystem
  # sits inside world.update, so the menu branch's trailing world.update
  # blocks for (and consumes) a SECOND key before commands drain, and the
  # normal branch reads its key between MazeSystem and MovementSystem rather
  # than before the frame. Neither difference reorders command or event
  # processing within a frame; the smoke specs pin the observable behaviour.
  def press(key)
    @keyboard.push(key)
    # Branch as the real loop does: on selection mode BEFORE the key is
    # dispatched (dispatching a menu key can toggle selection mode off).
    in_menu = selection_mode?
    @input_system.update(nil)
    if in_menu
      @world.send(:process_events)
      @message_system.update(nil)
      @world.update(nil)
    else
      @world.update(nil)
      @turn += 1
    end
  end

  # --- State readers for assertions ---

  def player
    @world.find_entity_by_tag(:player)
  end

  # @return [Array(Integer, Integer), nil] [row, column], or nil if no player
  def player_position
    position = player&.get_component(:position)
    position && [position.row, position.column]
  end

  def current_level
    @world.current_level
  end

  def grid
    @world.grid
  end

  def selection_mode?
    @message_system.selection_mode?
  end

  def quit?
    @world.quit?
  end

  # Captured events, optionally filtered by type. Always a copy, so callers
  # cannot corrupt the capture buffer.
  # @return [Array<Vanilla::Events::Event>]
  def events(type = nil)
    all = @event_manager.captured_events
    type ? all.select { |event| event.type == type } : all.dup
  end

  def recent_messages(limit = 10)
    @message_system.get_recent_messages(limit)
  end

  # Process any events still queued in the world (e.g. monster_spawned from
  # maze generation, which the real game only drains on its first frame).
  # Call before mutating world state in a spec's arrange step, so handlers
  # never observe entities the spec has already removed.
  def flush_pending_events
    @world.send(:process_events)
  end

  # Undo this instance's global side effects so consecutive specs do not
  # leak state: unregister exactly the services setup_world placed, and
  # restore the global RNG seed captured at construction.
  def cleanup
    Vanilla::ServiceRegistry.unregister(:game)
    Vanilla::ServiceRegistry.unregister(:event_manager)
    Vanilla::ServiceRegistry.unregister(:message_system)
    srand(@previous_seed)
  end

  private

  # Mirrors Vanilla::Game#setup_world, minus InputSystem (blocking terminal
  # read) and RenderSystem (terminal output). Priorities match the real game.
  def setup_world
    @world = Vanilla::World.new
    @keyboard = ScriptedKeyboard.new
    @world.display.instance_variable_set(:@keyboard_handler, @keyboard)

    @event_manager = Vanilla::Events::EventManager.new(store_config: { file: false })
    @event_manager.singleton_class.prepend(EventCapture)
    Vanilla::ServiceRegistry.register(:event_manager, @event_manager)
    # The real game registers itself as :game; Vanilla.game_turn reads it for
    # message turn-stamps and effect expiry. The harness answers #turn too.
    Vanilla::ServiceRegistry.register(:game, self)

    @player = Vanilla::EntityFactory.create_player(0, 0)
    @world.add_entity(@player)

    @maze_system = Vanilla::Systems::MazeSystem.new(@world, difficulty: @difficulty, seed: @seed)
    @world.add_system(@maze_system, 0)
    @input_system = Vanilla::Systems::InputSystem.new(@world)
    @world.add_system(Vanilla::Systems::MovementSystem.new(@world), 2)
    @fov_system = Vanilla::Systems::FOVSystem.new(@world)
    @world.add_system(@fov_system, 2.5)
    @world.add_system(Vanilla::Systems::MonsterAISystem.new(@world), 2.6)
    @world.add_system(Vanilla::Systems::CombatSystem.new(@world), 3)
    @world.add_system(Vanilla::Systems::CollisionSystem.new(@world), 3)
    @world.add_system(Vanilla::Systems::LootSystem.new(@world), 3)
    @world.add_system(Vanilla::Systems::MonsterSystem.new(@world, player: @player), 4)
    @message_system = Vanilla::Systems::MessageSystem.new(@world)
    @world.add_system(@message_system, 5)
    Vanilla::ServiceRegistry.register(:message_system, @message_system)
  end
end
