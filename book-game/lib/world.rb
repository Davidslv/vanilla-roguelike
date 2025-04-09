# lib/world.rb
require 'json'
require_relative "event"
require_relative "keyboard_handler"
require_relative "logger"

class World
  attr_reader :entities, :systems, :event_manager, :width, :height, :current_level

  def initialize(width: 10, height: 5)
    @entities = {}
    @systems = []
    @next_id = 0
    @width = width
    @height = height
    @running = true
    @event_manager = EventManager.new
    @current_level = 1
    @keyboard = KeyboardHandler.new
    Logger.info("World initialized: width=#{width}, height=#{height}")
  end

  def create_entity
    entity = Entity.new(@next_id)
    @entities[@next_id] = entity
    @next_id += 1
    Logger.debug("Entity created: id=#{entity.id}")
    entity
  end

  def add_system(system)
    @systems << system
    Logger.debug("System added: #{system.class.name}")
    self
  end

  def run
    setup_level
    Logger.info("Game started")

    while @running
      # Handle input first
      handle_input

      # Process all systems in order
      @systems.each do |system|
        Logger.debug("Processing system: #{system.class.name}")
        case system
        when Systems::MazeSystem
          system.process(@entities.values)
        when Systems::InputSystem
          system.process(@entities.values)
        when Systems::MovementSystem
          system.process(@entities.values, @width, @height)
          # Check for level completion immediately after movement
          check_level_completion
        when Systems::RenderSystem
          system.process(@entities.values)
        end
      end

      # Clear events after the turn
      @event_manager.clear
    end

    Logger.info("Game ended")
    puts "Goodbye!"
  end

  # Serialization methods
  def serialize
    {
      entities: entities.map { |id, entity| serialize_entity(id, entity) },
      next_entity_id: @next_id,
      width: @width,
      height: @height
    }
  end

  def serialize_entity(id, entity)
    {
      id: id,
      components: entity.components.transform_values do |component|
        serialize_component(component)
      end
    }
  end

  def serialize_component(component)
    # Each component type needs to implement its own serialization
    component.to_h
  end

  def deserialize(data)
    @next_id = data[:next_entity_id]
    @width = data[:width]
    @height = data[:height]

    data[:entities].each do |entity_data|
      id = entity_data[:id]
      entity = Entity.new(id)

      entity_data[:components].each do |component_type, component_data|
        component = deserialize_component(component_type, component_data)
        entity.add_component(component)
      end

      @entities[id] = entity
    end
  end

  def deserialize_component(type, data)
    # Each component type needs to implement its own deserialization
    component_class = type.to_s.classify.constantize
    component_class.from_h(data)
  end

  private

  def setup_level
    # Clear existing entities
    @entities.clear
    @next_id = 0
    Logger.info("Setting up level #{@current_level}")

    # Create player entity
    player = create_entity
    player.add_component(Components::Position.new(1, 1))
    player.add_component(Components::Movement.new)
    player.add_component(Components::Render.new("@"))
    player.add_component(Components::Input.new)
    Logger.debug("Player created at position (1, 1)")

    # Create stairs entity
    stairs = create_entity
    stairs.add_component(Components::Position.new(@width - 2, @height - 2))
    stairs.add_component(Components::Render.new("%"))
    Logger.debug("Stairs created at position (#{@width - 2}, #{@height - 2})")

    # Generate new maze
    maze_system = @systems.find { |s| s.is_a?(Systems::MazeSystem) }
    if maze_system
      Logger.debug("Generating maze")
      maze_system.process(@entities.values)
    else
      Logger.error("MazeSystem not found!")
    end

    puts "Level #{@current_level} - Find the stairs (%)"
  end

  def check_level_completion
    player = @entities.values.find { |e| e.has_component?(Components::Input) }
    stairs = @entities.values.find { |e| e.get_component(Components::Render)&.character == "%" }

    return unless player && stairs

    player_pos = player.get_component(Components::Position)
    stairs_pos = stairs.get_component(Components::Position)

    return unless player_pos.x == stairs_pos.x && player_pos.y == stairs_pos.y

    # Visual feedback for level completion
    system("clear") || system("cls")
    puts "\n\n"
    puts "  🎉 Level #{@current_level} completed! 🎉"
    puts "  Loading level #{@current_level + 1}..."
    puts "\n\n"
    sleep(1) # Brief pause for effect

    Logger.info("Level #{@current_level} completed")
    @current_level += 1
    setup_level
  end

  def handle_input
    # Wait for a single key press
    Logger.debug("Waiting for input")
    input = @keyboard.wait_for_input.downcase
    Logger.debug("Input received: #{input}")

    # Handle the input
    case input
    when 'w', 'a', 's', 'd'
      Logger.debug("Queueing key_pressed event: #{input}")
      @event_manager.queue(Event.new(:key_pressed, { key: input }))
    when 'q'
      Logger.debug("Queueing key_pressed event: #{input}")
      @event_manager.queue(Event.new(:key_pressed, { key: input }))
      @running = false
    else
      Logger.debug("Ignoring input: #{input}")
    end
  end

  def move_player(dx, dy)
    player = @entities.values.find { |e| e.has_component?(Components::Movement) }
    return unless player

    movement = player.get_component(Components::Movement)
    movement.dx = dx
    movement.dy = dy
    Logger.debug("Player movement set: dx=#{dx}, dy=#{dy}")
  end
end

class EventManager
  def initialize
    @queue = []
  end

  def queue(event)
    @queue << event
  end

  def process(&block)
    @queue.dup.each(&block) # Pass events to systems
  end

  def clear
    @queue.clear
  end
end
