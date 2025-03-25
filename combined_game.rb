# Begin /Users/davidslv/projects/vanilla/lib/vanilla/algorithms/abstract_algorithm.rb
# frozen_string_literal: true

module Vanilla
  module Algorithms
    class AbstractAlgorithm
      def self.demodulize
        self.name.split('::').last
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/algorithms/abstract_algorithm.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/algorithms/aldous_broder.rb
# frozen_string_literal: true

module Vanilla
  module Algorithms
    class AldousBroder < AbstractAlgorithm
      def self.on(grid)
        cell = grid.random_cell
        unvisited = grid.size - 1
        while unvisited > 0
          neighbor = cell.neighbors.sample
          if neighbor.links.empty?
            cell.link(cell: neighbor)
            unvisited -= 1
          end
          cell = neighbor
        end

        grid.each_cell do |cell|
          if cell.links.empty?
            cell.tile = Vanilla::Support::TileType::WALL
          end
        end

        grid
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/algorithms/aldous_broder.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/algorithms/binary_tree.rb
# frozen_string_literal: true

# lib/vanilla/algorithms/binary_tree.rb
module Vanilla
  module Algorithms
    class BinaryTree < AbstractAlgorithm
      def self.on(grid)
        grid.each_cell do |cell|
          has_north = !cell.north.nil?
          has_east = !cell.east.nil?
          if has_north && has_east
            cell.link(cell: rand(2) == 0 ? cell.north : cell.east, bidirectional: true)
          elsif has_north
            cell.link(cell: cell.north, bidirectional: true)
          elsif has_east
            cell.link(cell: cell.east, bidirectional: true)
          end
        end

        grid.each_cell do |cell|
          if cell.links.empty?
            cell.tile = Vanilla::Support::TileType::WALL
          end
        end

        grid
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/algorithms/binary_tree.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/algorithms/dijkstra.rb
# frozen_string_literal: true

module Vanilla
  module Algorithms
    class Dijkstra < AbstractAlgorithm
      def self.on(_grid, start:, goal: nil)
        distances = start.distances
        return distances.path_to(goal) if goal

        distances
      end

      def self.shortest_path(_grid, start:, goal:)
        distances = start.distances
        distances.path_to(goal).cells
      end

      # Helper to check if a path exists (for LevelGenerator)
      def self.path_exists?(start, goal)
        distances = start.distances
        !!distances[goal] # Returns true if goal is reachable
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/algorithms/dijkstra.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/algorithms/longest_path.rb
# frozen_string_literal: true

module Vanilla
  module Algorithms
    # Uses Dijkstra's distance to calculate the longest path
    #  the path given doesn't mean it's the only longest path,
    #  but one between the longest possible paths
    #
    #  In the future:
    # We can use this to decide wether the maze has enough complexity,
    # and we can tie it to the characters experience / level
    class LongestPath < AbstractAlgorithm
      def self.on(grid, start:)
        distances = start.distances
        new_start, = distances.max
        new_distances = new_start.distances

        goal, = new_distances.max
        grid.distances = new_distances.path_to(goal)

        grid
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/algorithms/longest_path.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/algorithms/recursive_backtracker.rb
# frozen_string_literal: true

module Vanilla
  module Algorithms
    class RecursiveBacktracker < AbstractAlgorithm
      def self.on(grid)
        stack = []
        stack.push(grid.random_cell)

        while stack.any?
          current = stack.last
          neighbors = current.neighbors.select { |cell| cell.links.empty? }

          if neighbors.empty?
            stack.pop
          else
            neighbor = neighbors.sample
            current.link(cell: neighbor)
            stack.push(neighbor)
          end
        end

        # Set walls only where there are no links to neighbors
        grid.each_cell do |cell|
          cell.tile = Vanilla::Support::TileType::WALL if cell.links.empty?
        end

        grid
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/algorithms/recursive_backtracker.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/algorithms/recursive_division.rb
# frozen_string_literal: true

module Vanilla
  module Algorithms
    class RecursiveDivision < AbstractAlgorithm
      MINIMUM_SIZE = 5
      TOO_SMALL = 1
      HOW_OFTEN = 4

      def self.on(grid)
        new(grid).process
      end

      def initialize(grid)
        @grid = grid
      end

      def process
        @grid.each_cell do |cell|
          cell.neighbors.each { |n| cell.link(cell: n, bidirectional: false) }
        end
        divide(0, 0, @grid.rows, @grid.columns)
        @grid.each_cell { |cell| cell.tile = Vanilla::Support::TileType::WALL if cell.links.empty? }
        @grid
      end

      private

      def divide(row, column, height, width)
        return if height <= TOO_SMALL || width <= TOO_SMALL || (height < MINIMUM_SIZE && width < MINIMUM_SIZE && rand(HOW_OFTEN) == 0)

        if height > width
          divide_horizontally(row, column, height, width)
        else
          divide_vertically(row, column, height, width)
        end
      end

      def divide_horizontally(row, column, height, width)
        divide_south_of = rand(height - 1)
        passage_at = rand(width)
        width.times do |x|
          next if passage_at == x

          cell = @grid[row + divide_south_of, column + x]
          cell.unlink(cell: cell.south)
        end
        divide(row, column, divide_south_of + 1, width)
        divide(row + divide_south_of + 1, column, height - divide_south_of - 1, width)
      end

      def divide_vertically(row, column, height, width)
        divide_east_of = rand(width - 1)
        passage_at = rand(height)
        height.times do |y|
          next if passage_at == y

          cell = @grid[row + y, column + divide_east_of]
          cell.unlink(cell: cell.east)
        end
        divide(row, column, height, divide_east_of + 1)
        divide(row, column + divide_east_of + 1, height, width - divide_east_of - 1)
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/algorithms/recursive_division.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/algorithms.rb
# frozen_string_literal: true

module Vanilla
  module Algorithms
    require_relative 'algorithms/abstract_algorithm'
    require_relative 'algorithms/aldous_broder'
    require_relative 'algorithms/binary_tree'
    require_relative 'algorithms/dijkstra'
    require_relative 'algorithms/longest_path'
    require_relative 'algorithms/recursive_backtracker'
    require_relative 'algorithms/recursive_division'

    #  Available Algorithms for the map
    AVAILABLE = [
      Vanilla::Algorithms::AldousBroder,
      Vanilla::Algorithms::BinaryTree,
      Vanilla::Algorithms::RecursiveDivision,
      Vanilla::Algorithms::RecursiveBacktracker,
    ].freeze
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/algorithms.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/commands/command.rb
# frozen_string_literal: true

module Vanilla
  module Commands
    class Command
      # Flag to track if the command was executed successfully
      attr_reader :executed

      def initialize
        @executed = false
      end

      def execute
        raise NotImplementedError, "#{self.class} must implement #execute"
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/commands/command.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/commands/exit_command.rb
# frozen_string_literal: true

require_relative 'command'

module Vanilla
  module Commands
    class ExitCommand < Command
      def initialize
        super()
        @logger = Vanilla::Logger.instance
      end

      def execute
        @logger.info("Player exiting game")
        exit
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/commands/exit_command.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/commands/move_command.rb
# frozen_string_literal: true

require_relative 'command'

module Vanilla
  module Commands
    # MoveCommand handles entity movement in a specified direction
    # This is a critical command used by the player and NPCs for movement
    class MoveCommand < Command
      attr_reader :entity, :direction, :grid

      # Create a new movement command
      #
      # @param entity [Object] the entity to move (usually player or monster)
      # @param direction [Symbol] the direction to move in (:north, :south, :east, :west)
      # @param grid [Vanilla::MapUtils::Grid] the grid on which to move
      # @param render_system [Vanilla::Systems::RenderSystem] optional render system
      #
      # IMPORTANT: The parameter order is (entity, direction, grid), NOT (entity, grid, direction)
      # Incorrect parameter order will result in a NoMethodError when trying to call to_sym on a Grid object
      def initialize(entity, direction, grid, render_system = nil)
        super()
        @entity = entity
        @direction = direction
        @grid = grid
        @movement_system = Vanilla::Systems::MovementSystem.new(grid)
        @render_system = render_system || Vanilla::Systems::RenderSystemFactory.create
      end

      def execute
        # Store position before movement
        position = @entity.get_component(:position)
        old_row, old_column = position.row, position.column
        logger = Vanilla::Logger.instance
        logger.debug("MoveCommand: Player position before movement: [#{old_row}, #{old_column}]")

        # Execute movement
        success = @movement_system.move(@entity, @direction)
        logger.debug("MoveCommand: Movement successful: #{success}")

        # Update display if movement was successful
        if success
          # Get new position
          new_row, new_column = position.row, position.column
          logger.debug("MoveCommand: Player position after movement: [#{new_row}, #{new_column}]")

          # IMPORTANT: We should NOT modify the grid cells directly
          # This was causing the disappearing entities issue
          # The grid should remain just a representation of walkable spaces and walls

          # Get the game instance
          game = Vanilla::ServiceRegistry.get(:game)

          # Update the grid representation with current entity positions
          # This ensures the grid stays in sync with actual entity positions
          game.level.update_grid_with_entities if game&.level.respond_to?(:update_grid_with_entities)

          # Use the level's all_entities method to get all entities to render
          # This will include the player, stairs, and monsters
          if game && game.level
            entities = game.level.all_entities
          else
            # Fallback if game or level is not available
            entities = []

            # Add the current entity
            entities << @entity

            # Add monsters if available
            monster_system = game&.monster_system
            if monster_system && monster_system.respond_to?(:monsters)
              entities += monster_system.monsters
            end

            # Add stairs if available
            entities << game.level.stairs if game&.level&.stairs
          end

          # Render the scene
          # This will clear the renderer and redraw everything
          @render_system.render(entities, @grid)

          # Set executed flag
          @executed = true
        end

        success
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/commands/move_command.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/commands/no_op_command.rb
# frozen_string_literal: true

module Vanilla
  module Commands
    # A command that does nothing when executed
    # Used when input is handled by other systems (like message selection)
    class NoOpCommand
      attr_reader :reason

      # Initialize a new NoOpCommand
      # @param logger [Logger] Logger instance
      # @param reason [String] Reason why this command is being used
      def initialize(logger = nil, reason = "No operation")
        @logger = logger
        @reason = reason
      end

      # Execute the command - does nothing
      # @return [Boolean] Always returns true
      def execute
        @logger.debug("NoOp command executed: #{@reason}") if @logger
        true
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/commands/no_op_command.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/commands/null_command.rb
# frozen_string_literal: true

require_relative 'command'

module Vanilla
  module Commands
    class NullCommand < Command
      def execute
        # Do nothing
        # NullCommand is not considered a successful execution
        @executed = false
        true
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/commands/null_command.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components/component.rb
# frozen_string_literal: true

module Vanilla
  module Components
    # Base class for all components
    class Component
      # Registry of component types to their implementation classes
      @component_classes = {}

      class << self
        # Get all registered component classes
        # @return [Hash] component type symbols => component classes
        attr_reader :component_classes

        # Register a component subclass
        # @param klass [Class] the component subclass
        def register(klass)
          instance = klass.new rescue return
          type = instance.type rescue return
          @component_classes[type] = klass
        end

        # Get a component class by type
        # @param type [Symbol] the component type
        # @return [Class, nil] the component class, or nil if not found
        def get_class(type)
          @component_classes[type]
        end

        # Create a component from a hash representation
        # @param hash [Hash] serialized component data
        # @return [Component] the deserialized component
        def from_hash(hash)
          type = hash[:type]
          raise ArgumentError, "Component hash must include a type" unless type

          klass = @component_classes[type]
          raise ArgumentError, "Unknown component type: #{type}" unless klass

          klass.from_hash(hash)
        end
      end

      # Initialize the component and check that type is implemented
      def initialize(*)
        type
      end

      # Required method that returns the component type
      # @return [Symbol] the component type
      def type
        raise NotImplementedError, "Component subclasses must implement #type"
      end

      # Convert component to a hash representation
      # @return [Hash] serialized component data
      def to_hash
        # Merge the component type with any data the component provides
        { type: type }
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/components/component.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components/consumable_component.rb
# frozen_string_literal: true

module Vanilla
  module Components
    # Component for items that can be consumed/used and have effects
    class ConsumableComponent < Component
      attr_reader :charges, :effects, :auto_identify

      # Initialize a new consumable component
      # @param charges [Integer] Number of uses before the item is consumed
      # @param effects [Array<Hash>] Effects that occur when used
      # @param auto_identify [Boolean] Whether the item is identified on pickup
      def initialize(charges: 1, effects: [], auto_identify: false)
        super()
        @charges = charges
        @effects = effects
        @auto_identify = auto_identify
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :consumable
      end

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
          charges: @charges,
          effects: @effects,
          auto_identify: @auto_identify
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [ConsumableComponent] The created component
      def self.from_hash(hash)
        new(
          charges: hash[:charges] || 1,
          effects: hash[:effects] || [],
          auto_identify: hash[:auto_identify] || false
        )
      end
    end

    # Register this component with the Component registry
    Component.register(ConsumableComponent)
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/components/consumable_component.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components/currency_component.rb
# frozen_string_literal: true

module Vanilla
  module Components
    # Component for items that represent currency or valuable treasures
    class CurrencyComponent
      attr_reader :currency_type
      attr_accessor :value

      # Initialize a new currency component
      # @param value [Integer] The monetary value of the currency
      # @param currency_type [Symbol] The type of currency (:gold, :silver, etc.)
      def initialize(value, currency_type = :gold)
        @value = value
        @currency_type = currency_type
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :currency
      end

      # Combine with another currency component
      # @param other [CurrencyComponent] Another currency component to combine with
      # @return [Integer] The new value after combining
      def combine(other)
        return @value unless other.is_a?(CurrencyComponent) && other.currency_type == @currency_type

        @value += other.value
      end

      # Split off a portion of the currency
      # @param amount [Integer] The amount to split off
      # @return [Integer, nil] The amount split off, or nil if not enough
      def split(amount)
        return nil if amount > @value

        @value -= amount
        amount
      end

      # Get the display string for the currency
      # @return [String] A formatted string showing value and type
      def display_string
        case @currency_type
        when :gold
          "#{@value} gold coin#{@value > 1 ? 's' : ''}"
        when :silver
          "#{@value} silver coin#{@value > 1 ? 's' : ''}"
        when :copper
          "#{@value} copper coin#{@value > 1 ? 's' : ''}"
        when :gem
          "#{@value} #{@value > 1 ? 'gems' : 'gem'}"
        else
          "#{@value} #{@currency_type}"
        end
      end

      # Get the currency value adjusted by type
      # @return [Integer] The standardized value in gold
      def standard_value
        case @currency_type
        when :copper
          (@value.to_f / 100).ceil  # 100 copper = 1 gold
        when :silver
          (@value.to_f / 10).ceil   # 10 silver = 1 gold
        when :gold
          @value
        when :gem
          @value * 5                # 1 gem = 5 gold
        else
          @value
        end
      end

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
          value: @value,
          currency_type: @currency_type
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [CurrencyComponent] The created component
      def self.from_hash(hash)
        new(
          hash[:value] || 0,
          hash[:currency_type] || :gold
        )
      end
    end

    # Register this component
    Component.register(CurrencyComponent)
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/components/currency_component.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components/durability_component.rb
# frozen_string_literal: true

module Vanilla
  module Components
    # Component for items that have durability and can wear out with use
    class DurabilityComponent
      attr_reader :max_durability
      attr_accessor :current_durability

      # Initialize a new durability component
      # @param max_durability [Integer] The maximum durability value
      # @param current_durability [Integer, nil] The current durability (defaults to max)
      def initialize(max_durability, current_durability = nil)
        @max_durability = max_durability
        @current_durability = current_durability || max_durability
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :durability
      end

      # Reduce durability by a certain amount
      # @param amount [Integer] Amount to reduce by (defaults to 1)
      # @return [Boolean] Whether the item is still usable
      def decrease(amount = 1)
        @current_durability -= amount
        @current_durability = 0 if @current_durability < 0

        # Notify low durability at 20% threshold
        if @current_durability > 0 && @current_durability <= (@max_durability * 0.2) && @current_durability + amount > (@max_durability * 0.2)
          # Just crossed the threshold, notify
          notify_low_durability
        end

        usable?
      end

      # Increase durability (e.g. through repair)
      # @param amount [Integer] Amount to increase by
      # @return [Integer] New durability value
      def repair(amount)
        old_durability = @current_durability
        @current_durability += amount
        @current_durability = @max_durability if @current_durability > @max_durability

        # Calculate actual repair amount
        actual_repair = @current_durability - old_durability

        # Notify if significant repair
        if actual_repair > 0
          notify_repair(actual_repair)
        end

        @current_durability
      end

      # Full repair to maximum durability
      # @return [Integer] New durability value
      def full_repair
        repair(@max_durability - @current_durability)
      end

      # Check if the item is still usable
      # @return [Boolean] Whether the item has any durability left
      def usable?
        @current_durability > 0
      end

      # Get the durability as a percentage
      # @return [Float] Durability percentage (0.0 to 1.0)
      def percentage
        @current_durability.to_f / @max_durability
      end

      # Get a descriptive status of the durability
      # @return [Symbol] Status of the item (:broken, :critical, :poor, :good, :excellent)
      def status
        percent = percentage

        if percent <= 0
          :broken
        elsif percent <= 0.25
          :critical
        elsif percent <= 0.5
          :poor
        elsif percent <= 0.75
          :good
        else
          :excellent
        end
      end

      # Check if the item is in need of repair
      # @return [Boolean] Whether durability is below 50%
      def needs_repair?
        percentage < 0.5
      end

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
          max_durability: @max_durability,
          current_durability: @current_durability
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [DurabilityComponent] The created component
      def self.from_hash(hash)
        new(
          hash[:max_durability] || 0,
          hash[:current_durability]
        )
      end

      private

      # Notify when durability is getting low
      def notify_low_durability
        # Get the item's name if possible
        item_name = "Unknown"
        if (entity = Component.get_entity(self))
          if entity.has_component?(:item)
            item_name = entity.get_component(:item).name
          end
        end

        # Send a message notification
        message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
        if message_system
          message_system.log_message("items.low_durability",
                                     metadata: { item: item_name },
                                     importance: :warning,
                                     category: :item)
        end
      end

      # Notify when item is repaired
      def notify_repair(amount)
        # Get the item's name if possible
        item_name = "Unknown"
        if (entity = Component.get_entity(self))
          if entity.has_component?(:item)
            item_name = entity.get_component(:item).name
          end
        end

        # Send a message notification
        message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
        if message_system
          message_system.log_message("items.repaired",
                                     metadata: { item: item_name, amount: amount },
                                     importance: :success,
                                     category: :item)
        end
      end
    end

    # Register this component
    Component.register(DurabilityComponent)
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/components/durability_component.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components/effect_component.rb
# frozen_string_literal: true

module Vanilla
  module Components
    # Component for managing temporary effects/buffs on entities
    class EffectComponent
      attr_reader :active_effects

      # Initialize a new effect component
      # @param active_effects [Array<Hash>] Initial active effects
      def initialize(active_effects = [])
        @active_effects = active_effects
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :effect
      end

      # Add a new effect to the entity
      # @param effect_type [Symbol] The type of effect (:heal, :buff, etc.)
      # @param effect_value [Integer] The magnitude of the effect
      # @param duration [Integer] How many turns the effect lasts (0 for instant)
      # @param source [String, Symbol] What caused this effect (item name, spell, etc.)
      # @param metadata [Hash] Additional effect data
      # @return [Hash] The added effect
      def add_effect(effect_type, effect_value, duration = 0, source = nil, metadata = {})
        # Create the effect hash
        effect = {
          type: effect_type,
          value: effect_value,
          duration: duration,
          source: source,
          metadata: metadata,
          applied_at: Vanilla.game_turn
        }

        # Add to active effects if it has a duration
        if duration > 0
          @active_effects << effect

          # Notify via message system if available
          message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
          if message_system
            message_system.log_message("effects.applied",
                                       metadata: {
                                         effect_type: effect_type,
                                         value: effect_value,
                                         source: source
                                       },
                                       importance: :normal,
                                       category: :effect)
          end
        end

        effect
      end

      # Remove an effect by its index
      # @param index [Integer] The index of the effect to remove
      # @return [Hash, nil] The removed effect or nil if not found
      def remove_effect(index)
        return nil if index < 0 || index >= @active_effects.size

        removed = @active_effects.delete_at(index)

        # Notify via message system if available
        message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
        if message_system && removed
          message_system.log_message("effects.removed",
                                     metadata: {
                                       effect_type: removed[:type],
                                       source: removed[:source]
                                     },
                                     importance: :normal,
                                     category: :effect)
        end

        removed
      end

      # Remove all effects from a specific source
      # @param source [String, Symbol] The source of effects to remove
      # @return [Array<Hash>] The removed effects
      def remove_effects_by_source(source)
        removed = []

        @active_effects.reject! do |effect|
          if effect[:source] == source
            removed << effect
            true
          else
            false
          end
        end

        # Notify via message system if available
        message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
        if message_system && !removed.empty?
          message_system.log_message("effects.removed_source",
                                     metadata: { source: source, count: removed.size },
                                     importance: :normal,
                                     category: :effect)
        end

        removed
      end

      # Remove all expired effects based on the current turn
      # @return [Array<Hash>] The expired effects that were removed
      def remove_expired_effects
        current_turn = Vanilla.game_turn
        expired = []

        @active_effects.reject! do |effect|
          # Check if the effect has expired
          if effect[:duration] > 0 && effect[:applied_at] + effect[:duration] <= current_turn
            expired << effect
            true
          else
            false
          end
        end

        # Notify via message system if available
        message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
        if message_system && !expired.empty?
          expired.each do |effect|
            message_system.log_message("effects.expired",
                                       metadata: {
                                         effect_type: effect[:type],
                                         source: effect[:source]
                                       },
                                       importance: :normal,
                                       category: :effect)
          end
        end

        expired
      end

      # Get all effects of a specific type
      # @param effect_type [Symbol] The type of effect to look for
      # @return [Array<Hash>] All effects of that type
      def get_effects_by_type(effect_type)
        @active_effects.select { |effect| effect[:type] == effect_type }
      end

      # Check if there are any active effects
      # @return [Boolean] Whether there are any active effects
      def has_active_effects?
        !@active_effects.empty?
      end

      # Get the total modifier for a specific stat from all active effects
      # @param stat [Symbol] The stat to get modifiers for
      # @return [Integer] The sum of all stat modifiers
      def get_stat_modifier(stat)
        @active_effects.sum do |effect|
          if effect[:type] == :buff && effect[:metadata][:stat] == stat
            effect[:value]
          else
            0
          end
        end
      end

      # Update effects (remove expired ones)
      # Called once per game turn
      def update
        remove_expired_effects
      end

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
          active_effects: @active_effects
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [EffectComponent] The created component
      def self.from_hash(hash)
        new(hash[:active_effects] || [])
      end
    end

    # Register this component
    Component.register(EffectComponent)
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/components/effect_component.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components/equippable_component.rb
# frozen_string_literal: true

module Vanilla
  module Components
    # Component for items that can be equipped by entities
    class EquippableComponent < Component
      attr_reader :slot, :stat_modifiers
      attr_accessor :equipped

      # Valid equipment slots
      SLOTS = [:head, :body, :left_hand, :right_hand, :both_hands, :neck, :feet, :ring, :hands]

      # Initialize a new equippable component
      # @param slot [Symbol] The equipment slot this item fits into
      # @param stat_modifiers [Hash] Stats this item modifies when equipped
      # @param equipped [Boolean] Whether the item is currently equipped
      def initialize(slot:, stat_modifiers: {}, equipped: false)
        super()
        @slot = slot
        @stat_modifiers = stat_modifiers
        @equipped = equipped

        validate_slot
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :equippable
      end

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
          slot: @slot,
          stat_modifiers: @stat_modifiers,
          equipped: @equipped
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [EquippableComponent] The created component
      def self.from_hash(hash)
        new(
          slot: hash[:slot] || :misc,
          stat_modifiers: hash[:stat_modifiers] || {},
          equipped: hash[:equipped] || false
        )
      end

      private

      def validate_slot
        raise ArgumentError, "Invalid slot: #{@slot}. Valid slots: #{SLOTS.join(', ')}" unless SLOTS.include?(@slot)
      end
    end

    # Register this component
    Component.register(EquippableComponent)
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/components/equippable_component.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components/input_component.rb
# frozen_string_literal: true

require_relative 'component'

module Vanilla
  module Components
    # Component for storing input state
    # This component stores pending input actions for an entity
    class InputComponent < Component
      attr_accessor :move_direction

      # Initialize a new input component
      def initialize
        super()
        @move_direction = nil
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :input
      end

      # Convert to hash for serialization
      # @return [Hash] Serialized representation
      def to_hash
        {
          move_direction: @move_direction
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] Serialized representation
      # @return [InputComponent] The new component
      def self.from_hash(hash)
        component = new
        component.move_direction = hash[:move_direction]
        component
      end

      # Get the component type
      # @return [Symbol] The component type
      def self.component_type
        :input
      end
    end

    # Register this component
    Component.register(InputComponent)
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/components/input_component.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components/inventory_component.rb
# frozen_string_literal: true

module Vanilla
  module Components
    # Component for managing an entity's inventory of items
    # Used primarily by the player, but can be used by other entities like chests
    class InventoryComponent
      attr_reader :items, :max_size

      # Initialize a new inventory component
      # @param max_size [Integer] The maximum number of items this inventory can hold
      def initialize(max_size: 20)
        @items = []
        @max_size = max_size
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :inventory
      end

      # Check if the inventory is full
      # @return [Boolean] Whether the inventory is at max capacity
      def full?
        @items.size >= @max_size
      end

      # Add an item to the inventory
      # @param item [Entity] The item entity to add
      # @return [Boolean] Whether the item was successfully added
      def add(item)
        return false if full?

        # If the item is stackable, try to stack it with existing items
        if item.has_component?(:item) && item.get_component(:item).stackable?
          existing_item = find_stackable_item(item)
          if existing_item
            existing_item.get_component(:item).increase_stack
            return true
          end
        end

        @items << item
        true
      end

      # Remove an item from the inventory
      # @param item [Entity] The item entity to remove
      # @return [Entity, nil] The removed item, or nil if not found
      def remove(item)
        index = @items.find_index(item)
        return nil unless index

        # If stackable with more than 1 in stack, reduce stack size instead of removing
        if item.has_component?(:item) && item.get_component(:item).stackable? &&
           item.get_component(:item).stack_size > 1
          item.get_component(:item).decrease_stack
          return item
        end

        @items.delete_at(index)
      end

      # Check if the inventory contains an item of a specific type
      # @param item_type [Symbol] The type of item to check for
      # @return [Boolean] Whether an item of the specified type exists
      def has?(item_type)
        @items.any? do |item|
          item.has_component?(:item) && item.get_component(:item).item_type == item_type
        end
      end

      # Count the number of items of a specific type
      # @param item_type [Symbol] The type of item to count
      # @return [Integer] The number of items of that type (including stack sizes)
      def count(item_type)
        @items.sum do |item|
          if item.has_component?(:item) && item.get_component(:item).item_type == item_type
            item.get_component(:item).stack_size
          else
            0
          end
        end
      end

      # Find an item by its ID
      # @param id [String] The unique ID of the item to find
      # @return [Entity, nil] The found item, or nil if not found
      def find_by_id(id)
        @items.find { |item| item.id == id }
      end

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
          max_size: @max_size,
          items: @items.map(&:to_hash)
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [InventoryComponent] The created component
      def self.from_hash(hash)
        component = new(max_size: hash[:max_size])

        # Items will be handled separately by the entity that owns this component
        component
      end

      private

      # Find a stackable item of the same type
      # @param item [Entity] The item to find a stack for
      # @return [Entity, nil] A matching item that can be stacked with, or nil
      def find_stackable_item(item)
        return nil unless item.has_component?(:item)

        item_component = item.get_component(:item)
        item_type = item_component.item_type

        @items.find do |inv_item|
          inv_item.has_component?(:item) &&
            inv_item.get_component(:item).item_type == item_type &&
            inv_item.get_component(:item).stackable?
        end
      end
    end

    # Register this component
    Component.register(InventoryComponent)
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/components/inventory_component.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components/item_component.rb
# frozen_string_literal: true

module Vanilla
  module Components
    # Component for items that can be picked up, used, and stored in inventory
    class ItemComponent < Component
      attr_reader :name, :description, :item_type, :weight, :value
      attr_accessor :stack_size

      # Initialize a new item component
      # @param name [String] The display name of the item
      # @param description [String] The item description
      # @param item_type [Symbol] The type of item (:weapon, :armor, :potion, etc.)
      # @param weight [Integer] The weight of the item
      # @param value [Integer] The value of the item in currency
      # @param stackable [Boolean] Whether the item can be stacked
      # @param stack_size [Integer] The current stack size for stackable items
      def initialize(name:,
                     description: "",
                     item_type: :misc,
                     weight: 1,
                     value: 0,
                     stackable: false,
                     stack_size: 1)
        super()
        @name = name
        @description = description
        @item_type = item_type
        @weight = weight
        @value = value
        @stackable = stackable
        @stack_size = stack_size
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :item
      end

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
          name: @name,
          description: @description,
          item_type: @item_type,
          weight: @weight,
          value: @value,
          stackable: @stackable,
          stack_size: @stack_size
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [ItemComponent] The created component
      def self.from_hash(hash)
        new(
          name: hash[:name] || "Unknown Item",
          description: hash[:description] || "",
          item_type: hash[:item_type] || :misc,
          weight: hash[:weight] || 1,
          value: hash[:value] || 0,
          stackable: hash[:stackable] || false,
          stack_size: hash[:stack_size] || 1
        )
      end
    end

    # Register this component
    Component.register(ItemComponent)
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/components/item_component.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components/key_component.rb
# frozen_string_literal: true

module Vanilla
  module Components
    # Component for items that can unlock doors, chests, or other locked objects
    class KeyComponent
      attr_reader :key_id, :lock_type, :one_time_use

      # Initialize a new key component
      # @param key_id [String] Unique identifier for the key matched to the lock
      # @param lock_type [Symbol] Type of lock this key opens (:door, :chest, :gate, etc.)
      # @param one_time_use [Boolean] Whether the key is consumed after use
      def initialize(key_id, lock_type = :door, one_time_use = true)
        @key_id = key_id
        @lock_type = lock_type
        @one_time_use = one_time_use
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :key
      end

      # Check if this key matches a specific lock
      # @param lock_id [String] The ID of the lock to check
      # @param lock_type [Symbol] The type of the lock to check
      # @return [Boolean] Whether this key can open that lock
      def matches?(lock_id, lock_type = nil)
        # Match by ID and optionally by type
        matches_id = (@key_id == lock_id)
        matches_type = (lock_type.nil? || @lock_type == lock_type)

        matches_id && matches_type
      end

      # Use the key to unlock something
      # @param lock_id [String] The ID of the lock to open
      # @param lock_type [Symbol] The type of lock to open
      # @return [Boolean] Whether the unlock was successful
      def unlock(lock_id, lock_type = nil)
        return false unless matches?(lock_id, lock_type)

        # Notify via message system if available
        message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
        if message_system
          message_system.log_message("items.key.unlock",
                                     metadata: { lock_type: lock_type || @lock_type },
                                     importance: :success,
                                     category: :item)
        end

        # Return whether the key should be consumed
        @one_time_use
      end

      # Get descriptive text for the key
      # @return [String] Description of what this key unlocks
      def description
        consumed_text = @one_time_use ? " (consumed on use)" : ""
        "Opens a #{@lock_type}#{consumed_text}"
      end

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
          key_id: @key_id,
          lock_type: @lock_type,
          one_time_use: @one_time_use
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [KeyComponent] The created component
      def self.from_hash(hash)
        new(
          hash[:key_id] || "generic_key",
          hash[:lock_type] || :door,
          hash[:one_time_use].nil? ? true : hash[:one_time_use]
        )
      end
    end

    # Register this component
    Component.register(KeyComponent)
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/components/key_component.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components/movement_component.rb
# frozen_string_literal: true

module Vanilla
  module Components
    class MovementComponent < Component
      attr_reader :speed, :active

      def initialize(active: true, speed: 1)
        super()
        @active = active
        @speed = speed
      end

      def type
        :movement
      end

      def active?
        !!@active
      end

      def to_hash
        { type: type, active: @active, speed: @speed }
      end

      def self.from_hash(hash)
        active = hash.key?(:active) ? hash[:active] : true
        speed  = hash.key?(:speed) ? hash[:speed] : 1
        new(active: active, speed: speed)
      end
    end

    Component.register(MovementComponent)
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/components/movement_component.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components/position_component.rb
# frozen_string_literal: true

module Vanilla
  module Components
    class PositionComponent < Component
      attr_reader :row, :column

      def initialize(row:, column:)
        super()
        @row = row
        @column = column
      end

      def type
        :position
      end

      # FIX: Movement mechanic is depending on this.
      def set_position(row, column)
        @row = row
        @column = column
      end

      def to_hash
        { type: type, row: @row, column: @column }
      end

      def self.from_hash(hash)
        new(row: hash[:row], column: hash[:column])
      end
    end

    Component.register(PositionComponent)
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/components/position_component.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components/render_component.rb
# frozen_string_literal: true

module Vanilla
  module Components
    # RenderComponent stores visual representation data for entities.
    # It defines how an entity appears in the rendering system, including
    # its character, color, and rendering layer (z-index).
    class RenderComponent < Component
      attr_reader :character, :color, :layer, :entity_type

      # Initialize a new render component
      # @param character [String] The character to display
      # @param color [Symbol, nil] The color to use, or nil for default
      # @param layer [Integer] The rendering layer (z-index)
      # @param entity_type [String, nil] The entity type, defaults to character
      # @raise [ArgumentError] If the character is invalid
      def initialize(character:, color: nil, layer: 0, entity_type: nil)
        unless Vanilla::Support::TileType.valid?(character)
          raise ArgumentError, "Invalid character type: #{character}"
        end

        @character = character
        @color = color
        @layer = layer
        @entity_type = entity_type || character # Default entity_type to character if not provided
        super()
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :render
      end

      # Convert to hash for serialization
      # @return [Hash] Serialized component data as hash
      def to_hash
        {
          character: @character,
          color: @color,
          layer: @layer,
          entity_type: @entity_type
        }
      end

      # Create a component from serialized data
      # @param hash [Hash] Serialized component data
      # @return [RenderComponent] The deserialized component
      def self.from_hash(hash)
        new(
          character: hash[:character],
          color: hash[:color],
          layer: hash[:layer] || 0,
          entity_type: hash[:entity_type]
        )
      end
    end

    # Register component within the module definition
    Component.register(RenderComponent)
  end
end

# Note on component registration approach:
#
# We register the RenderComponent twice - once inside the module definition,
# and again here outside of it. This dual registration approach ensures the
# component is reliably available in the Component registry for several reasons:
#
# 1. Redundancy for reliability: The first registration happens inside the module
#    definition, but occasionally Ruby load order issues might prevent proper registration.
#    This second call ensures the component gets registered regardless.
#
# 2. Testing compatibility: During testing, components sometimes aren't properly
#    registered when accessed from test files, causing registration tests to fail.
#    The second registration makes the component consistently available for tests.
#
# 3. Explicit over implicit: Explicitly registering outside the class/module definition
#    makes it clear this component should be available in the component registry.
#
# This defensive programming technique helps avoid subtle bugs that could occur
# if the component wasn't properly registered in all execution contexts.
#
Vanilla::Components::Component.register(Vanilla::Components::RenderComponent)
# End /Users/davidslv/projects/vanilla/lib/vanilla/components/render_component.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components/stairs_component.rb
# frozen_string_literal: true

module Vanilla
  module Components
    # Component for tracking whether an entity has found stairs
    class StairsComponent < Component
      # @return [Boolean] whether stairs have been found
      attr_accessor :found_stairs

      alias found_stairs? found_stairs

      # Initialize a new stairs component
      # @param found_stairs [Boolean] whether stairs have been found
      def initialize(found_stairs: false)
        super()
        @found_stairs = found_stairs
      end

      # @return [Symbol] the component type
      def type
        :stairs
      end

      # @return [Hash] serialized component data
      def to_hash
        {
          type: type,
          found_stairs: @found_stairs
        }
      end

      # Create a stairs component from a hash
      # @param hash [Hash] serialized component data
      # @return [StairsComponent] deserialized component
      def self.from_hash(hash)
        new(found_stairs: hash[:found_stairs])
      end
    end

    # Register this component type
    Component.register(StairsComponent)
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/components/stairs_component.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/components.rb
# frozen_string_literal: true

module Vanilla
  # Components module contains all the component types
  # used in the entity-component-system architecture.
  #
  # Components are primarily data containers to be used
  # with entities.
  module Components
    # Load the component system
    require_relative 'components/component'

    # Load specific components
    require_relative 'components/position_component'
    require_relative 'components/stairs_component'
    require_relative 'components/movement_component'
    require_relative 'components/render_component'
    require_relative 'components/inventory_component'
    require_relative 'components/item_component'
    require_relative 'components/consumable_component'
    require_relative 'components/effect_component'
    require_relative 'components/equippable_component'
    require_relative 'components/key_component'
    require_relative 'components/durability_component'
    require_relative 'components/currency_component'
    require_relative 'components/input_component'
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/components.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/display_handler.rb
# frozen_string_literal: true

module Vanilla
  class DisplayHandler
    attr_reader :keyboard_handler

    def initialize
      @keyboard_handler = Vanilla::KeyboardHandler.new
    end

    def cleanup
      @keyboard_handler.cleanup
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/display_handler.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/entities/entity.rb
# frozen_string_literal: true

require 'securerandom'

module Vanilla
  module Entities
    # An entity is a container for components
    class Entity
      # @return [String] unique identifier for this entity
      attr_reader :id

      # @return [Array<Component>] all components attached to this entity
      attr_reader :components

      # @return [String] name of the entity (for display purposes)
      attr_accessor :name

      # Initialize a new entity
      # @param id [String, nil] optional ID for the entity, will be auto-generated if nil
      def initialize(id: nil)
        @id = id || SecureRandom.uuid
        @components = []
        @component_map = {}
        @tags = Set.new
        @name = "Entity_#{@id[0..7]}"
      end

      # Add a component to the entity
      # @param component [Component] the component to add
      # @return [Entity] self, for method chaining
      def add_component(component)
        # Ensure the component has a type method
        unless component.respond_to?(:type)
          raise ArgumentError, "Component must respond to #type"
        end

        type = component.type

        # Check for duplicate component types
        if @component_map.key?(type)
          raise ArgumentError, "Entity already has a component of type #{type}"
        end

        @components << component
        @component_map[type] = component

        self
      end

      # Remove a component from the entity
      # @param type [Symbol] the type of component to remove
      # @return [Component, nil] the removed component, or nil if not found
      def remove_component(type)
        component = @component_map[type]
        return nil unless component

        @components.delete(component)
        @component_map.delete(type)

        component
      end

      # Check if the entity has a component of the given type
      # @param type [Symbol] the type to check for
      # @return [Boolean] true if the entity has a component of the given type
      def has_component?(type)
        @component_map.key?(type)
      end

      # Get a component of the given type
      # @param type [Symbol] the type to get
      # @return [Component, nil] the component, or nil if not found
      def get_component(type)
        @component_map[type]
      end

      # Add a tag to the entity
      # @param tag [Symbol, String] the tag to add
      # @return [Entity] self, for method chaining
      def add_tag(tag)
        @tags.add(tag.to_sym)
        self
      end

      # Remove a tag from the entity
      # @param tag [Symbol, String] the tag to remove
      # @return [Entity] self, for method chaining
      def remove_tag(tag)
        @tags.delete(tag.to_sym)
        self
      end

      # Check if the entity has a tag
      # @param tag [Symbol, String] the tag to check for
      # @return [Boolean] true if the entity has the tag
      def has_tag?(tag)
        @tags.include?(tag.to_sym)
      end

      # Get all tags on the entity
      # @return [Array<Symbol>] the tags
      def tags
        @tags.to_a
      end

      # Convert to hash for serialization
      # @return [Hash] serialized representation
      def to_hash
        {
          id: @id,
          name: @name,
          tags: @tags.to_a,
          components: @components.map(&:to_hash)
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] serialized representation
      # @return [Entity] the new entity
      def self.from_hash(hash)
        entity = new(id: hash[:id])
        entity.name = hash[:name] if hash[:name]

        # Add tags
        hash[:tags]&.each do |tag|
          entity.add_tag(tag)
        end

        # Add components
        hash[:components]&.each do |component_hash|
          component_type = component_hash[:type]
          component_class = Vanilla::Components::Component.get_class(component_type)

          if component_class
            component = component_class.from_hash(component_hash)
            entity.add_component(component)
          end
        end

        entity
      end

      # Method missing to provide component accessors
      # @deprecated Use #get_component instead
      def method_missing(method, *args, &block)
        # Log a warning about using method_missing
        Vanilla::Logger.instance.warn("Entity#method_missing called for #{method}. Consider accessing the component directly instead. Entity: #{id}")

        # Check for component accessor methods (e.g., position, render, etc.)
        component_type = method.to_sym
        return get_component(component_type) if has_component?(component_type)

        # Check for component predicate methods (e.g., position?, render?, etc.)
        if method.to_s.end_with?('?')
          component_type = method.to_s.chomp('?').to_sym
          return has_component?(component_type)
        end

        super
      end

      # Allow respond_to? to work with method_missing
      # @deprecated Use #has_component? instead
      def respond_to_missing?(method, include_private = false)
        # Log a warning about using respond_to_missing?
        Vanilla::Logger.instance.warn("Entity#respond_to_missing? called for #{method}. Consider checking component types directly. Entity: #{id}")

        component_type = method.to_sym
        return true if has_component?(component_type)

        if method.to_s.end_with?('?')
          component_type = method.to_s.chomp('?').to_sym
          return true if @component_map.key?(component_type)
        end

        super
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/entities/entity.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/entities/monster.rb
# frozen_string_literal: true

require_relative '../components'

module Vanilla
  module Entities
    # The Monster entity represents an enemy in the game.
    #
    # This entity uses the ECS architecture by combining various components:
    # * PositionComponent - For tracking position in the grid
    # * MovementComponent - For movement capabilities
    # * RenderComponent - For visual representation and rendering
    #
    # Monsters can move around the map and interact with the player.
    class Monster < Entities::Entity
      # @return [String] the monster's type
      attr_accessor :monster_type

      # @return [Integer] the monster's health points
      attr_accessor :health

      # @return [Integer] the damage the monster inflicts
      attr_accessor :damage

      # Initialize a new monster entity
      # @param monster_type [String] the type of monster
      # @param row [Integer] the starting row position
      # @param column [Integer] the starting column position
      # @param health [Integer] the monster's health points
      # @param damage [Integer] the damage the monster inflicts
      def initialize(monster_type: 'goblin', row:, column:, health: 10, damage: 2)
        super()

        @monster_type = monster_type
        @health = health
        @damage = damage

        # Add required components
        add_component(Components::PositionComponent.new(row: row, column: column))
        add_component(Components::MovementComponent.new)

        # Add RenderComponent for visual representation
        add_component(Components::RenderComponent.new(
                        character: Support::TileType::MONSTER,
                        entity_type: @monster_type,
                        layer: 5 # Monsters are below player
                      ))
      end

      # Check if the monster is alive
      # @return [Boolean] true if the monster is alive, false otherwise
      def alive?
        @health > 0
      end

      # Take damage from an attack
      # @param amount [Integer] the amount of damage to take
      # @return [Integer] the remaining health
      def take_damage(amount)
        @health -= amount
        @health = 0 if @health < 0
        @health
      end

      # Attack a target entity
      # @param target [Entity] the entity to attack
      # @return [Integer] the amount of damage dealt
      def attack(target)
        if target.respond_to?(:take_damage)
          target.take_damage(@damage)
          @damage
        else
          0
        end
      end

      # Convert the monster entity to a hash representation
      # @return [Hash] serialized monster data
      def to_hash
        super.merge(
          monster_type: @monster_type,
          health: @health,
          damage: @damage
        )
      end

      # Create a monster entity from a hash representation
      # @param hash [Hash] serialized monster data
      # @return [Monster] the deserialized monster entity
      def self.from_hash(hash)
        # First, extract position information from components to initialize the monster
        position = extract_position_from_components(hash[:components])

        # Create a new monster with the position information
        monster = new(
          monster_type: hash[:monster_type],
          row: position[:row],
          column: position[:column],
          health: hash[:health],
          damage: hash[:damage]
        )

        # Set entity ID to match original
        monster.instance_variable_set(:@id, hash[:id])

        monster
      end

      # For backward compatibility - get the tile character
      def tile
        render_component = get_component(:render)
        render_component&.character || Support::TileType::MONSTER
      end

      # Extract position information from serialized components
      # @param components [Array<Hash>] serialized components
      # @return [Hash] position information with :row and :column keys
      def self.extract_position_from_components(components)
        position_component = components.find { |c| c[:type] == :position }

        if position_component && position_component[:data]
          { row: position_component[:data][:row], column: position_component[:data][:column] }
        else
          { row: 0, column: 0 } # Default if not found
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/entities/monster.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/entities/player.rb
# frozen_string_literal: true

require_relative '../components'

module Vanilla
  module Entities
    # The Player entity represents the player character in the game.
    #
    # This entity uses the ECS architecture by combining various components:
    # * PositionComponent - For tracking position in the grid
    # * MovementComponent - For movement capabilities
    # * StairsComponent - For tracking stairs discovery
    # * RenderComponent - For visual representation and rendering
    #
    # The entity maintains backward compatibility with the old Unit-based system
    # by delegating methods to the appropriate components.
    class Player < Entities::Entity
      # @return [String] the player's name
      attr_accessor :name

      # @return [Integer] the player's current level
      attr_accessor :level

      # @return [Integer] the player's current experience points
      attr_accessor :experience

      # @return [Array] the player's inventory
      attr_accessor :inventory

      # Initialize a new player entity
      # @param name [String] the player's name
      # @param row [Integer] the starting row position
      # @param column [Integer] the starting column position
      def initialize(name: 'player', row:, column:)
        super()

        @name = name
        @level = 1
        @experience = 0
        @inventory = []

        # Add required components
        add_component(Components::PositionComponent.new(row: row, column: column))
        add_component(Components::MovementComponent.new)
        add_component(Components::StairsComponent.new)
        add_component(Components::RenderComponent.new(
                        character: Support::TileType::PLAYER,
                        entity_type: Support::TileType::PLAYER,
                        layer: 10 # Player is usually drawn on top
                      ))
      end

      # Convert the player entity to a hash representation
      # @return [Hash] serialized player data
      def to_hash
        super.merge(
          name: @name,
          level: @level,
          experience: @experience,
          inventory: @inventory
        )
      end

      # Create a player entity from a hash representation
      # @param hash [Hash] serialized player data
      # @return [Player] the deserialized player entity
      def self.from_hash(hash)
        # First, extract position information from components to initialize the player
        position = extract_position_from_components(hash[:components])

        # Create a new player with the position information
        new(
          name: hash[:name],
          row: position[:row],
          column: position[:column]
        )
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/entities/player.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/entities/stairs.rb
# frozen_string_literal: true

require_relative '../components'

module Vanilla
  module Entities
    # The Stairs entity represents a staircase to the next level.
    #
    # This entity uses the ECS architecture by combining:
    # * PositionComponent - For tracking position in the grid
    # * RenderComponent - For visual rendering in the system
    class Stairs < Entities::Entity
      # Initialize a new stairs entity
      # @param row [Integer] the row position
      # @param column [Integer] the column position
      def initialize(row:, column:)
        super()

        # Add required components
        add_component(Components::PositionComponent.new(row: row, column: column))

        # Add RenderComponent
        add_component(Components::RenderComponent.new(
                        character: Support::TileType::STAIRS,
                        layer: 2 # Above floor, below monsters
                      ))
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/entities/stairs.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/entities.rb
# frozen_string_literal: true

require_relative 'entities/entity'
require_relative 'entities/player'
require_relative 'entities/monster'
require_relative 'entities/stairs'
# End /Users/davidslv/projects/vanilla/lib/vanilla/entities.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/entity_factory.rb
# frozen_string_literal: true

module Vanilla
  class EntityFactory
    def self.create_player(row, column)
      player = Vanilla::Entities::Entity.new
      player.name = "Player"
      player.add_tag(:player)
      player.add_component(Vanilla::Components::PositionComponent.new(row: row, column: column))
      player.add_component(Vanilla::Components::RenderComponent.new(character: Vanilla::Support::TileType::PLAYER, color: :white))
      player.add_component(Vanilla::Components::InputComponent.new)
      player.add_component(Vanilla::Components::MovementComponent.new(active: true))
      player
    end

    def self.create_stairs(row, column)
      stairs = Vanilla::Entities::Entity.new
      stairs.name = "Stairs"
      stairs.add_tag(:stairs)
      stairs.add_component(Vanilla::Components::PositionComponent.new(row: row, column: column))
      stairs.add_component(Vanilla::Components::RenderComponent.new(character: Vanilla::Support::TileType::STAIRS, color: :white))
      stairs
    end

    def self.create_monster(type, row, column, health, damage)
      monster = Vanilla::Entities::Entity.new
      monster.name = type.capitalize
      monster.add_tag(:monster)
      monster.add_component(Vanilla::Components::PositionComponent.new(row: row, column: column))
      monster.add_component(Vanilla::Components::RenderComponent.new(character: Vanilla::Support::TileType::MONSTER, color: :white))
      # Placeholder for health/damage; add HealthComponent later if needed
      monster.instance_variable_set(:@health, health)
      monster.instance_variable_set(:@damage, damage)
      monster.define_singleton_method(:alive?) { @health > 0 }
      monster
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/entity_factory.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/events/event.rb
# frozen_string_literal: true

require 'json'
require 'time'
require 'securerandom'

module Vanilla
  module Events
    # Base class for all events in the system
    class Event
      attr_reader :id, :timestamp, :source, :type, :data

      # Initialize a new event
      # @param type [String] The event type identifier
      # @param source [Object] The source/originator of the event
      # @param data [Hash] Additional event data
      # @param id [String, nil] Optional event ID, generated if not provided
      # @param timestamp [Time, nil] Optional timestamp, current time if not provided
      def initialize(type, source = nil, data = {}, id = nil, timestamp = nil)
        @id = id || SecureRandom.uuid
        @type = type
        @source = source
        @data = data
        @timestamp = timestamp.is_a?(String) ? Time.parse(timestamp) : (timestamp || Time.now.utc)
      end

      # String representation of the event
      # @return [String] Human-readable event string
      def to_s
        "[#{@timestamp}] #{@type}: #{@data.inspect}"
      end

      # Hash representation of the event
      # @return [Hash] Event data as a hash
      def to_h
        {
          id: @id,
          type: @type,
          source: @source.to_s,
          timestamp: @timestamp.iso8601(3),
          data: safe_serialize(@data)
        }
      end

      # JSON representation of the event
      # @return [String] Event data as a JSON string
      def to_json(*_args)
        to_h.to_json
      end

      # Create an event from its JSON representation
      # @param json [String] JSON representation of an event
      # @return [Event] Reconstructed event
      def self.from_json(json)
        data = JSON.parse(json, symbolize_names: true)

        new(
          data[:type],
          data[:source],
          data[:data] || {},
          data[:id],
          data[:timestamp]
        )
      end

      private

      # Safely serialize data by handling non-serializable objects
      # @param value [Object] The value to serialize
      # @return [Object] A serializable version of the value
      def safe_serialize(value)
        case value
        when Hash
          value.each_with_object({}) do |(k, v), h|
            h[k] = safe_serialize(v)
          end
        when Array
          value.map { |v| safe_serialize(v) }
        when Numeric, String, true, false, nil
          value
        else
          # For complex objects, convert to string representation
          value.to_s
        end
      rescue
        # If any error occurs during serialization, return a safe fallback
        "#<#{value.class} - non-serializable>"
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/events/event.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/events/event_manager.rb
# frozen_string_literal: true

module Vanilla
  module Events
    # Central event management class that handles event publication and subscription
    class EventManager
      # Initialize a new event manager
      # @param logger [Logger] Logger instance for event logging
      # @param store_config [Hash] Configuration for event storage
      #   file: [Boolean] Whether to use file-based storage (default: true)
      #   file_directory: [String] Directory for event files (default: "event_logs")
      def initialize(logger, store_config = { file: true })
        @subscribers = Hash.new { |h, k| h[k] = [] }
        @logger = logger

        # Set up file storage if configured
        if store_config[:file]
          require_relative 'storage/file_event_store'
          directory = store_config[:file_directory] || "event_logs"
          @event_store = Storage::FileEventStore.new(directory)
          @logger.info("Event system initialized with file storage in #{directory}")
        else
          @logger.info("Event system initialized without persistent storage")
        end
      end

      # Subscribe to events of a specific type
      # @param event_type [String] The event type to subscribe to
      # @param subscriber [Object] The subscriber that will handle the events
      # @return [void]
      def subscribe(event_type, subscriber)
        @subscribers[event_type] << subscriber
        @logger.debug("Subscribed #{subscriber.class} to #{event_type}")
      end

      # Unsubscribe from events of a specific type
      # @param event_type [String] The event type to unsubscribe from
      # @param subscriber [Object] The subscriber to remove
      # @return [void]
      def unsubscribe(event_type, subscriber)
        @subscribers[event_type].delete(subscriber)
        @logger.debug("Unsubscribed #{subscriber.class} from #{event_type}")
      end

      # Publish an event to all subscribers
      # @param event [Vanilla::Events::Event] The event to publish
      # @return [void]
      def publish(event)
        @logger.debug("Publishing event: #{event}")

        # Store the event if storage is configured
        @event_store&.store(event)

        # Deliver to subscribers
        @subscribers[event.type].each do |subscriber|
          begin
            subscriber.handle_event(event)
          rescue => e
            @logger.error("Error in subscriber #{subscriber.class} handling #{event.type}: #{e.message}")
            @logger.error(e.backtrace.join("\n"))
          end
        end
      end

      # Create and publish an event in one step
      # @param type [String] The event type
      # @param source [Object] The source of the event
      # @param data [Hash] Additional event data
      # @return [Event] The published event
      def publish_event(type, source = nil, data = {})
        event = Event.new(type, source, data)
        publish(event)
        event
      end

      # Query for events based on options
      # @param options [Hash] Query options
      # @return [Array<Vanilla::Events::Event>] Matching events
      def query_events(options = {})
        @event_store&.query(options) || []
      end

      # Get the current session ID
      # @return [String, nil] The current session ID, or nil if no event store
      def current_session
        @event_store&.current_session
      end

      # Close the event store
      # @return [void]
      def close
        @event_store&.close
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/events/event_manager.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/events/event_subscriber.rb
# frozen_string_literal: true

module Vanilla
  module Events
    # Interface for components that respond to events
    # Classes including this module must implement the handle_event method
    module EventSubscriber
      # Handle an event that this subscriber is interested in
      # @param event [Vanilla::Events::Event] The event to handle
      # @return [void]
      def handle_event(event)
        raise NotImplementedError, "#{self.class} must implement handle_event(event)"
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/events/event_subscriber.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/events/event_visualization.rb
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'
require_relative 'storage/event_store'
require_relative 'storage/file_event_store'

module Vanilla
  module Events
    # A utility class for visualizing event logs
    class EventVisualization
      def initialize(event_store)
        @event_store = event_store
      end

      # Generates HTML timeline visualization for a session
      # @param session_id [String] the session ID to visualize
      # @param output_file [String] the HTML file path to write
      # @return [String] the path to the generated HTML file
      def generate_timeline(session_id = nil, output_file = nil)
        session_id ||= latest_session_id
        output_file ||= "event_timeline_#{session_id}.html"

        events = @event_store.load_session(session_id)
        return nil if events.empty?

        html = generate_html(events, session_id)

        FileUtils.mkdir_p('event_visualizations')
        output_path = File.join('event_visualizations', output_file)
        File.write(output_path, html)

        output_path
      end

      # Find the most recent session ID
      # @return [String] the latest session ID
      def latest_session_id
        Dir.glob(File.join(@event_store.storage_path, '*.jsonl'))
           .map { |f| File.basename(f, '.jsonl').gsub(/^events_/, '') }
           .sort
           .last
      end

      private

      # Generate HTML visualization
      # @param events [Array<Event>] the events to visualize
      # @param session_id [String] the session ID
      # @return [String] HTML content
      def generate_html(events, session_id)
        return "<html><body><h1>No events found</h1></body></html>" if events.empty?

        # Group events by type
        event_types = events.map(&:type).uniq.sort
        events_by_type = {}
        event_types.each do |type|
          events_by_type[type] = events.select { |e| e.type == type }
        end

        # Find time boundaries
        start_time = events.first.timestamp
        end_time = events.last.timestamp
        duration = end_time - start_time

        # Generate the HTML
        html = <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>Event Timeline - #{session_id}</title>
            <style>
              body { font-family: Arial, sans-serif; margin: 20px; }
              h1 { color: #333; }
              .timeline { position: relative; margin: 20px 0; border-left: 2px solid #ccc; padding-left: 20px; }
              .event-group { margin-bottom: 30px; }
              .event-type { font-weight: bold; margin-bottom: 10px; }
              .event { position: relative; margin-bottom: 5px; cursor: pointer; }
              .event-marker {
                position: absolute;
                width: 10px;
                height: 10px;
                border-radius: 50%;
                background-color: #3498db;
                left: -25px;
                top: 5px;
              }
              .event-time { color: #666; font-size: 0.8em; margin-right: 10px; display: inline-block; width: 80px; }
              .event-details { display: none; padding: 10px; background-color: #f5f5f5; margin: 5px 0; border-radius: 4px; }
              .event.active .event-details { display: block; }
              .event.active .event-marker { background-color: #e74c3c; }
              .timestamp { color: #666; font-size: 0.8em; }
              .filter-controls { margin-bottom: 20px; }
              .event-count { font-size: 0.8em; color: #666; margin-left: 10px; }
              .timeline-header { display: flex; justify-content: space-between; align-items: center; }
              .position-marker {
                position: absolute;
                left: calc(var(--position-percent) * 100%);
                width: 2px;
                height: 100%;
                background-color: rgba(255, 0, 0, 0.5);
                z-index: 1;
              }
            </style>
          </head>
          <body>
            <h1>Event Timeline - #{session_id}</h1>
            <div class="timestamp">
              Start: #{start_time.strftime('%Y-%m-%d %H:%M:%S.%L')}<br>
              End: #{end_time.strftime('%Y-%m-%d %H:%M:%S.%L')}<br>
              Duration: #{duration.round(2)} seconds
            </div>

            <div class="filter-controls">
              <input type="text" id="search" placeholder="Filter events..." style="width: 250px; padding: 5px;">
              <button id="expandAll">Expand All</button>
              <button id="collapseAll">Collapse All</button>
              <div style="margin-top: 10px;">
                <label>Show event types:</label>
                <div id="eventTypeFilters">
                  <!-- Event type checkboxes will be inserted here -->
                </div>
              </div>
            </div>

            <div class="timeline">
              <!-- Timeline content will be inserted here -->
            </div>

            <script>
              // Event data
              const events = #{events.map { |e| # {' '}
                               {
                                 id: e.id,
                                 type: e.type,
                                 source: e.source.to_s,
                                 timestamp: e.timestamp,
                                 time_offset: (e.timestamp - start_time).round(3),
                                 position_percent: duration > 0 ? (e.timestamp - start_time) / duration : 0,
                                 data: e.data || {}
                               }
                             }.to_json};

              const eventTypes = #{event_types.to_json};
              const duration = #{duration};

              // Setup event type filters
              const filtersContainer = document.getElementById('eventTypeFilters');
              eventTypes.forEach(type => {
                const count = events.filter(e => e.type === type).length;
                const div = document.createElement('div');
                div.innerHTML = `
                  <label>
                    <input type="checkbox" class="event-type-filter" data-type="${type}" checked>
                    ${type} <span class="event-count">(${count})</span>
                  </label>
                `;
                filtersContainer.appendChild(div);
              });

              // Render timeline
              function renderTimeline() {
                const timeline = document.querySelector('.timeline');
                timeline.innerHTML = '';

                // Add position marker
                const marker = document.createElement('div');
                marker.className = 'position-marker';
                marker.style.setProperty('--position-percent', 0);
                timeline.appendChild(marker);

                // Group events by type and render
                const visibleTypes = Array.from(
                  document.querySelectorAll('.event-type-filter:checked')
                ).map(cb => cb.dataset.type);

                const searchTerm = document.getElementById('search').value.toLowerCase();

                eventTypes.forEach(type => {
                  if (!visibleTypes.includes(type)) return;

                  const typeEvents = events.filter(e => e.type === type && (
                    searchTerm === '' ||
                    type.toLowerCase().includes(searchTerm) ||
                    JSON.stringify(e.data).toLowerCase().includes(searchTerm)
                  ));

                  if (typeEvents.length === 0) return;

                  const eventGroup = document.createElement('div');
                  eventGroup.className = 'event-group';

                  const eventTypeHeader = document.createElement('div');
                  eventTypeHeader.className = 'event-type';
                  eventTypeHeader.innerHTML = `${type} <span class="event-count">(${typeEvents.length})</span>`;
                  eventGroup.appendChild(eventTypeHeader);

                  typeEvents.forEach(event => {
                    const eventEl = document.createElement('div');
                    eventEl.className = 'event';
                    eventEl.dataset.id = event.id;
                    eventEl.dataset.position = event.position_percent;

                    const marker = document.createElement('div');
                    marker.className = 'event-marker';
                    marker.style.left = `calc(-25px + ${event.position_percent * 100}% * 0.8)`;
                    eventEl.appendChild(marker);

                    const eventContent = document.createElement('div');
                    eventContent.innerHTML = `
                      <span class="event-time">+${event.time_offset}s</span>
                      <span>${event.source}</span>
                    `;
                    eventEl.appendChild(eventContent);

                    const eventDetails = document.createElement('div');
                    eventDetails.className = 'event-details';
                    eventDetails.innerHTML = `
                      <div><strong>ID:</strong> ${event.id}</div>
                      <div><strong>Type:</strong> ${event.type}</div>
                      <div><strong>Source:</strong> ${event.source}</div>
                      <div><strong>Timestamp:</strong> ${event.timestamp}</div>
                      <div><strong>Data:</strong> <pre>${JSON.stringify(event.data, null, 2)}</pre></div>
                    `;
                    eventEl.appendChild(eventDetails);

                    eventEl.addEventListener('click', () => {
                      eventEl.classList.toggle('active');
                      marker.style.setProperty('--position-percent', event.position_percent);
                    });

                    eventEl.addEventListener('mouseenter', () => {
                      marker.style.setProperty('--position-percent', event.position_percent);
                    });

                    eventGroup.appendChild(eventEl);
                  });

                  timeline.appendChild(eventGroup);
                });
              }

              // Event listeners for filters
              document.querySelectorAll('.event-type-filter').forEach(checkbox => {
                checkbox.addEventListener('change', renderTimeline);
              });

              document.getElementById('search').addEventListener('input', renderTimeline);

              document.getElementById('expandAll').addEventListener('click', () => {
                document.querySelectorAll('.event').forEach(el => {
                  el.classList.add('active');
                });
              });

              document.getElementById('collapseAll').addEventListener('click', () => {
                document.querySelectorAll('.event').forEach(el => {
                  el.classList.remove('active');
                });
              });

              // Initial render
              renderTimeline();
            </script>
          </body>
          </html>
        HTML

        html
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/events/event_visualization.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/events/storage/event_store.rb
# frozen_string_literal: true

module Vanilla
  module Events
    module Storage
      # Interface for event storage implementations
      # All concrete event store classes should implement these methods
      class EventStore
        # Store an event
        # @param event [Vanilla::Events::Event] The event to store
        # @return [void]
        def store(event)
          raise NotImplementedError, "#{self.class} must implement store(event)"
        end

        # Query for events based on options
        # @param options [Hash] Query options (type, time range, limit, etc.)
        # @return [Array<Vanilla::Events::Event>] Matching events
        def query(options = {})
          raise NotImplementedError, "#{self.class} must implement query(options)"
        end

        # Load all events from a session
        # @param session_id [String, nil] Session ID to load, or current session if nil
        # @return [Array<Vanilla::Events::Event>] Events from the session
        def load_session(session_id = nil)
          raise NotImplementedError, "#{self.class} must implement load_session(session_id)"
        end

        # List available sessions
        # @return [Array<String>] List of session IDs
        def list_sessions
          raise NotImplementedError, "#{self.class} must implement list_sessions"
        end

        # Close the event store and release resources
        # @return [void]
        def close
          # Optional method, default implementation does nothing
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/events/storage/event_store.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/events/storage/file_event_store.rb
# frozen_string_literal: true

require 'fileutils'
require 'json'

module Vanilla
  module Events
    module Storage
      # Implementation of event storage using files on disk
      # Events are stored in JSONL (JSON Lines) format, one event per line
      class FileEventStore < EventStore
        attr_reader :current_session, :storage_path

        # Initialize a new file-based event store
        # @param directory [String] The directory to store event files in
        # @param session_id [String, nil] Optional session ID, defaults to timestamp
        def initialize(directory = "event_logs", session_id = nil)
          require 'fileutils'

          @directory = directory
          @storage_path = directory
          FileUtils.mkdir_p(@directory) unless Dir.exist?(@directory)
          @current_session = session_id || Time.now.strftime("%Y%m%d_%H%M%S")
          @current_file = nil
        end

        # Store an event to disk
        # @param event [Vanilla::Events::Event] The event to store
        # @return [void]
        def store(event)
          ensure_file_open

          # Write event as JSON line
          @current_file.puts(event.to_json)
          @current_file.flush # Ensure data is written immediately
        end

        # Query for events based on options
        # This implementation loads the session and filters in memory
        # For more advanced querying needs, consider using a database
        # @param options [Hash] Query options
        # @return [Array<Vanilla::Events::Event>] Matching events
        def query(options = {})
          session_id = options[:session_id] || @current_session
          events = load_session(session_id)

          # Filter by type
          if options[:type]
            events = events.select { |e| e.type == options[:type] }
          end

          # Filter by time range
          if options[:start_time] && options[:end_time]
            events = events.select do |e|
              e.timestamp >= options[:start_time] && e.timestamp <= options[:end_time]
            end
          end

          # Limit results
          if options[:limit]
            events = events.last(options[:limit])
          end

          events
        end

        # Load all events from a session
        # @param session_id [String, nil] Session ID to load, or current session if nil
        # @return [Array<Vanilla::Events::Event>] Events from the session
        def load_session(session_id = nil)
          session_id ||= @current_session
          events = []

          # First try without the events_ prefix (for backward compatibility)
          filename = File.join(@directory, "#{session_id}.jsonl")

          # If not found, try with the events_ prefix
          unless File.exist?(filename)
            filename = File.join(@directory, "events_#{session_id}.jsonl")
          end

          return [] unless File.exist?(filename)

          File.open(filename, "r") do |file|
            file.each_line do |line|
              next if line.strip.empty?

              events << Event.from_json(line)
            end
          end

          events
        end

        # List available sessions
        # @return [Array<String>] List of session IDs
        def list_sessions
          Dir.glob(File.join(@directory, "events_*.jsonl")).map do |file|
            File.basename(file).gsub(/^events_/, "").gsub(/\.jsonl$/, "")
          end
        end

        # Close the file handle
        # @return [void]
        def close
          @current_file&.close
          @current_file = nil
        end

        private

        # Ensure the file is open for writing
        # @return [void]
        def ensure_file_open
          return if @current_file && !@current_file.closed?

          filename = File.join(@directory, "events_#{@current_session}.jsonl")
          @current_file = File.open(filename, "a")
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/events/storage/file_event_store.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/events/types.rb
# frozen_string_literal: true

module Vanilla
  module Events
    # Constants for all event types used in the system
    module Types
      # Entity events - related to entity lifecycle and state changes
      ENTITY_CREATED = "entity_created"
      ENTITY_DESTROYED = "entity_destroyed"
      ENTITY_MOVED = "entity_moved"
      ENTITY_COLLISION = "entity_collision"
      ENTITY_STATE_CHANGED = "entity_state_changed"

      # Game state events - related to overall game state
      GAME_STARTED = "game_started"
      GAME_ENDED = "game_ended"
      LEVEL_CHANGED = "level_changed"
      TURN_STARTED = "turn_started"
      TURN_ENDED = "turn_ended"

      # Input events - related to user input
      KEY_PRESSED = "key_pressed"
      COMMAND_ISSUED = "command_issued"

      # Command-specific events
      MOVE_COMMAND_ISSUED = "move_command_issued"
      EXIT_COMMAND_ISSUED = "exit_command_issued"

      # Movement-related events
      MOVEMENT_INTENT = "movement_intent" # Intent to move
      MOVEMENT_SUCCEEDED = "movement_succeeded" # Movement was successful
      MOVEMENT_BLOCKED = "movement_blocked" # Movement was blocked

      # Combat events
      COMBAT_ATTACK = "combat_attack"
      COMBAT_DAMAGE = "combat_damage"
      COMBAT_DEATH = "combat_death"

      # Item events
      ITEM_PICKED_UP = "item_picked_up"
      ITEM_DROPPED = "item_dropped"
      ITEM_USED = "item_used"

      # Monster events
      MONSTER_SPAWNED = "monster_spawned"
      MONSTER_DESPAWNED = "monster_despawned"
      MONSTER_DETECTED_PLAYER = "monster_detected_player"

      # Debug events
      DEBUG_COMMAND = "debug_command"
      DEBUG_STATE_DUMP = "debug_state_dump"
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/events/types.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/events.rb
# frozen_string_literal: true

# Event system for Vanilla game
# This file requires all components of the event system

require_relative 'events/event'
require_relative 'events/types'
require_relative 'events/event_subscriber'
require_relative 'events/storage/event_store'
require_relative 'events/storage/file_event_store'
require_relative 'events/event_manager'
# End /Users/davidslv/projects/vanilla/lib/vanilla/events.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/game.rb
# frozen_string_literal: true

# lib/vanilla/game.rb
module Vanilla
  class Game
    attr_reader :turn, :world, :level

    def initialize(options = {})
      @difficulty = options[:difficulty] || 1
      @seed = options[:seed] || Random.new_seed
      @logger = Vanilla::Logger.instance
      @turn = 0
      setup_world
      Vanilla::ServiceRegistry.register(:game, self)
    end

    def start
      @logger.info("Starting game with seed: #{@seed}, difficulty: #{@difficulty}")
      srand(@seed)
      render
      game_loop
    end

    def cleanup
      @logger.info("Game cleanup")
      @display&.cleanup
      Vanilla::ServiceRegistry.unregister(:game)
    end

    private

    def setup_world
      @world = Vanilla::World.new
      @display = @world.display
      @level = LevelGenerator.new.generate(@difficulty, @seed)
      @world.set_level(@level)

      @player = Vanilla::EntityFactory.create_player(0, 0)
      @world.add_entity(@player)
      @level.add_entity(@player)

      @monster_system = Vanilla::Systems::MonsterSystem.new(@world, player: @player, logger: @logger)
      @monster_system.spawn_monsters(@difficulty)

      # Note: InputSystem must have the highest priority (zero)
      @world.add_system(Vanilla::Systems::InputSystem.new(@world), 0)
      @world.add_system(Vanilla::Systems::MovementSystem.new(@world), 1)
      @world.add_system(Vanilla::Systems::RenderSystem.new(@world, @difficulty, @seed), 2)
      @world.add_system(@monster_system, 3)

      Vanilla::ServiceRegistry.register(:message_system, Vanilla::Systems::MessageSystem.new(@world))
    end

    def game_loop
      @turn = 0
      loop do
        @world.update(nil)  # Input, Movement, Commands (level change), Render
        render              # Shows new level immediately
        @turn += 1
        break if @world.quit?
      end
    end

    def render
      @world.systems.find { |s, _| s.is_a?(Vanilla::Systems::RenderSystem) }[0].update(nil)
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/game.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/input_handler.rb
# frozen_string_literal: true

require_relative 'commands/move_command'
require_relative 'commands/exit_command'
require_relative 'commands/null_command'
require_relative 'commands/no_op_command'

module Vanilla
  class InputHandler
    # Initialize a new input handler
    # @param logger [Logger] Logger instance
    # @param event_manager [Vanilla::Events::EventManager, nil] Optional event manager
    # @param render_system [Vanilla::Systems::RenderSystem, nil] Optional render system
    def initialize(logger = Vanilla::Logger.instance, event_manager = nil, render_system = nil)
      @logger = logger
      @event_manager = event_manager
      @render_system = render_system || Vanilla::Systems::RenderSystemFactory.create
    end

    # Handle a key press from the user
    # @param key [String, Symbol] The key that was pressed
    # @param entity [Vanilla::Entity] The entity to control (typically the player)
    # @param grid [Vanilla::MapUtils::Grid] The current game grid
    # @return [Vanilla::Commands::Command] The command that was executed
    def handle_input(key, entity, grid)
      # Log the key press
      @logger.info("Player pressed key: #{key}")

      # Publish key press event if event manager is available
      if @event_manager
        @event_manager.publish_event(
          Vanilla::Events::Types::KEY_PRESSED,
          self,
          { key: key, entity_id: entity.id }
        )
      end

      # Create and execute the command
      command = create_command(key, entity, grid)

      # Publish command issued event if event manager is available
      if @event_manager && command.class != Commands::NullCommand
        command_type = command.class.name.split('::').last.gsub('Command', '').downcase
        event_type = "#{command_type}_command_issued"

        @event_manager.publish_event(
          event_type,
          command,
          { entity_id: entity.id }
        )
      end

      # Execute the command and return it
      command.execute
      command
    end

    private

    # Create a command based on the key that was pressed
    # @param key [String, Symbol] The key that was pressed
    # @param entity [Vanilla::Entity] The entity to control
    # @param grid [Vanilla::MapUtils::Grid] The current game grid
    # @return [Vanilla::Commands::Command] The command to execute
    def create_command(key, entity, grid)
      case key
      when "k", "K", :KEY_UP
        @logger.info("Player attempting to move UP")
        Commands::MoveCommand.new(entity, :up, grid, @render_system)
      when "j", "J", :KEY_DOWN
        @logger.info("Player attempting to move DOWN")
        Commands::MoveCommand.new(entity, :down, grid, @render_system)
      when "l", "L", :KEY_RIGHT
        @logger.info("Player attempting to move RIGHT")
        Commands::MoveCommand.new(entity, :right, grid, @render_system)
      when "h", "H", :KEY_LEFT
        @logger.info("Player attempting to move LEFT")
        Commands::MoveCommand.new(entity, :left, grid, @render_system)
      when "\C-c", "q"
        Commands::ExitCommand.new
      else
        @logger.debug("Unknown key pressed: #{key.inspect}")
        Commands::NullCommand.new
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/input_handler.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/inventory/item.rb
# frozen_string_literal: true

module Vanilla
  module Inventory
    # Wrapper class for entities with item components
    # This provides a convenient interface for working with item entities
    class Item
      attr_reader :entity

      # Initialize a new item wrapper
      # @param entity [Entity] The entity to wrap
      def initialize(entity)
        @entity = entity

        # Ensure the entity has an item component
        unless entity.has_component?(:item)
          raise ArgumentError, "Entity must have an item component"
        end
      end

      # Get the item component
      # @return [ItemComponent] The item component
      def item_component
        @entity.get_component(:item)
      end

      # Get the item name
      # @return [String] The item name
      def name
        item_component.name
      end

      # Get the item description
      # @return [String] The item description
      def description
        item_component.description
      end

      # Check if the item is stackable
      # @return [Boolean] Whether the item can be stacked
      def stackable?
        item_component.stackable?
      end

      # Get the item type
      # @return [Symbol] The item type
      def type
        item_component.item_type
      end

      # Get the item weight
      # @return [Integer] The item weight
      def weight
        item_component.weight
      end

      # Get the item value
      # @return [Integer] The item value
      def value
        item_component.value
      end

      # Get the stack size
      # @return [Integer] The stack size
      def stack_size
        item_component.stack_size
      end

      # Check if the item is equippable
      # @return [Boolean] Whether the item can be equipped
      def equippable?
        @entity.has_component?(:equippable)
      end

      # Get the equippable component if it exists
      # @return [EquippableComponent, nil] The equippable component or nil
      def equippable_component
        @entity.get_component(:equippable) if equippable?
      end

      # Check if the item is consumable
      # @return [Boolean] Whether the item can be consumed
      def consumable?
        @entity.has_component?(:consumable)
      end

      # Get the consumable component if it exists
      # @return [ConsumableComponent, nil] The consumable component or nil
      def consumable_component
        @entity.get_component(:consumable) if consumable?
      end

      # Use the item on a target entity
      # @param target [Entity] The entity to use the item on
      # @return [Boolean] Whether the item was successfully used
      def use(target)
        if consumable?
          consumable_component.consume(target)
        elsif equippable?
          if equippable_component.equipped?
            equippable_component.unequip(target)
          else
            equippable_component.equip(target)
          end
        else
          item_component.use(target)
        end
      end

      # Convert to a string for debugging
      # @return [String] A string representation
      def to_s
        if equippable? && equippable_component.equipped?
          "[E] #{name} (#{type})"
        else
          "#{name} (#{type})"
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/inventory/item.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/inventory/item_factory.rb
# frozen_string_literal: true

module Vanilla
  module Inventory
    # Factory for creating different types of items
    class ItemFactory
      # Create a new item factory
      # @param logger [Logger] The logger instance
      def initialize(logger)
        @logger = logger
      end

      # Create a basic item
      # @param name [String] The name of the item
      # @param options [Hash] Additional item options
      # @return [Entity] The created item entity
      def create_item(name, options = {})
        item = Vanilla::Entities::Entity.new

        # Add a render component - without validation
        # We're creating a special version since item characters don't need to be valid TileTypes
        character = options[:character] || '?'

        # Create a custom render component class
        render_component = Class.new(Vanilla::Components::Component) do
          attr_reader :character, :color, :layer, :entity_type, :tile

          def initialize(character, color, layer, entity_type)
            super()
            @character = character
            @color = color
            @layer = layer
            @entity_type = entity_type
            @tile = character # For compatibility
          end

          def type
            :render
          end
        end.new(
          character,
          options[:color] || nil,
          options[:layer] || 5,
          options[:entity_type] || 'item'
        )

        # Add the render component to the item
        item.add_component(render_component)

        # Add an item component
        item.add_component(
          Vanilla::Components::ItemComponent.new(
            name: name,
            description: options[:description] || "",
            item_type: options[:item_type] || :misc,
            weight: options[:weight] || 1,
            value: options[:value] || 0,
            stackable: options[:stackable] || false
          )
        )

        # Add any additional components
        if options[:components]
          options[:components].each do |component|
            item.add_component(component)
          end
        end

        item
      end

      # Create a weapon item
      # @param name [String] The name of the weapon
      # @param damage [Integer] The damage value of the weapon
      # @param options [Hash] Additional weapon options
      # @return [Entity] The created weapon entity
      def create_weapon(name, damage, options = {})
        # Set default character for weapons
        options[:character] ||= ')'
        options[:item_type] = :weapon

        # Create the equippable component
        equippable = Vanilla::Components::EquippableComponent.new(
          slot: options[:slot] || :right_hand,
          stat_modifiers: { attack: damage }
        )

        # Add to the components list
        options[:components] ||= []
        options[:components] << equippable

        create_item(name, options)
      end

      # Create an armor item
      # @param name [String] The name of the armor
      # @param defense [Integer] The defense value of the armor
      # @param options [Hash] Additional armor options
      # @return [Entity] The created armor entity
      def create_armor(name, defense, options = {})
        # Set default character for armor
        options[:character] ||= '['
        options[:item_type] = :armor

        # Determine the slot based on armor type if not specified
        options[:slot] ||= determine_armor_slot(name)

        # Create the equippable component
        equippable = Vanilla::Components::EquippableComponent.new(
          slot: options[:slot],
          stat_modifiers: { defense: defense }
        )

        # Add to the components list
        options[:components] ||= []
        options[:components] << equippable

        create_item(name, options)
      end

      # Create a potion item
      # @param name [String] The name of the potion
      # @param effect_type [Symbol] The type of effect (:heal, :buff, etc.)
      # @param effect_amount [Integer] The amount/strength of the effect
      # @param options [Hash] Additional potion options
      # @return [Entity] The created potion entity
      def create_potion(name, effect_type, effect_amount, options = {})
        # Set default character for potions
        options[:character] ||= '!'
        options[:item_type] = :potion
        options[:stackable] = true unless options.key?(:stackable)

        # Create the effect based on type
        effect = { type: effect_type, amount: effect_amount }
        effect[:duration] = options[:duration] if options[:duration]
        effect[:stat] = options[:stat] if options[:stat]

        # Create the consumable component
        consumable = Vanilla::Components::ConsumableComponent.new(
          charges: options[:charges] || 1,
          effects: [effect],
          auto_identify: options[:auto_identify] || false
        )

        # Add to the components list
        options[:components] ||= []
        options[:components] << consumable

        create_item(name, options)
      end

      # Create a scroll item
      # @param name [String] The name of the scroll
      # @param effect_type [Symbol] The type of effect
      # @param effect_amount [Integer] The amount/strength of the effect
      # @param options [Hash] Additional scroll options
      # @return [Entity] The created scroll entity
      def create_scroll(name, effect_type, effect_amount, options = {})
        # Set default character for scrolls
        options[:character] ||= '?'
        options[:item_type] = :scroll

        # Create the effect based on type
        effect = { type: effect_type, amount: effect_amount }
        effect[:duration] = options[:duration] if options[:duration]
        effect[:stat] = options[:stat] if options[:stat]

        # Create the consumable component
        consumable = Vanilla::Components::ConsumableComponent.new(
          charges: options[:charges] || 1,
          effects: [effect],
          auto_identify: options[:auto_identify] || false
        )

        # Add to the components list
        options[:components] ||= []
        options[:components] << consumable

        create_item(name, options)
      end

      private

      # Determine the appropriate equipment slot based on armor name
      # @param name [String] The name of the armor
      # @return [Symbol] The equipment slot to use
      def determine_armor_slot(name)
        name = name.downcase

        if name.include?('helm') || name.include?('hat') || name.include?('crown')
          :head
        elsif name.include?('boot') || name.include?('shoe') || name.include?('greave')
          :feet
        elsif name.include?('glove') || name.include?('gauntlet') || name.include?('bracer')
          :hands
        elsif name.include?('amulet') || name.include?('necklace') || name.include?('pendant')
          :neck
        elsif name.include?('ring')
          :ring
        else
          # Default to body armor
          :body
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/inventory/item_factory.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/inventory/item_registry.rb
# frozen_string_literal: true

module Vanilla
  module Inventory
    # Registry for item definitions that can be used to create items consistently
    class ItemRegistry
      # Initialize a new item registry
      # @param logger [Logger] The logger instance
      def initialize(logger)
        @logger = logger
        @item_templates = {}
        @item_factory = ItemFactory.new(logger)

        # Load default items
        load_default_templates
      end

      # Register a new item template
      # @param key [Symbol] The unique key for this item template
      # @param data [Hash] The item template data
      # @return [Symbol] The key that was registered
      def register_template(key, data)
        @item_templates[key] = data
        key
      end

      # Get an item template by key
      # @param key [Symbol] The key for the item template
      # @return [Hash, nil] The item template data or nil if not found
      def get_template(key)
        @item_templates[key]
      end

      # Create an item from a template
      # @param key [Symbol] The key for the item template
      # @param overrides [Hash] Optional property overrides
      # @return [Entity, nil] The created item entity or nil if the template doesn't exist
      def create_item(key, overrides = {})
        template = get_template(key)
        return nil unless template

        # Deep clone to avoid modifying the template
        item_data = Marshal.load(Marshal.dump(template))

        # Apply overrides
        overrides.each do |property, value|
          item_data[property] = value
        end

        # Get item type and use the appropriate factory method
        item_type = item_data[:item_type] || :misc

        case item_type
        when :weapon
          create_weapon_from_data(item_data)
        when :armor
          create_armor_from_data(item_data)
        when :potion
          create_potion_from_data(item_data)
        when :scroll
          create_scroll_from_data(item_data)
        when :key
          create_key_from_data(item_data)
        when :currency
          create_currency_from_data(item_data)
        else
          create_misc_from_data(item_data)
        end
      end

      # List all available item template keys
      # @return [Array<Symbol>] Array of available template keys
      def available_templates
        @item_templates.keys
      end

      # Get a random item template key of a specific type
      # @param item_type [Symbol] The type of item to get (:weapon, :armor, etc.)
      # @return [Symbol, nil] A random template key or nil if none found
      def random_template_key(item_type = nil)
        templates = if item_type
                      @item_templates.select { |_, data| data[:item_type] == item_type }
                    else
                      @item_templates
                    end

        return nil if templates.empty?

        templates.keys.sample
      end

      # Create a random item of a specific type
      # @param item_type [Symbol] The type of item to create
      # @param difficulty [Integer] Optional difficulty level to scale the item
      # @return [Entity, nil] A random item or nil if no templates found
      def create_random_item(item_type = nil, difficulty = 1)
        key = random_template_key(item_type)
        return nil unless key

        # Scale certain properties based on difficulty
        overrides = {}

        # For weapons, scale damage
        if item_type == :weapon
          template = get_template(key)
          if template[:damage]
            overrides[:damage] = template[:damage] + (difficulty - 1) * 2
          end
        end

        # For potions, scale effect amount
        if item_type == :potion
          template = get_template(key)
          if template[:effect_amount]
            overrides[:effect_amount] = template[:effect_amount] + (difficulty - 1) * 5
          end
        end

        create_item(key, overrides)
      end

      private

      # Create a weapon from template data
      def create_weapon_from_data(data)
        @item_factory.create_weapon(
          data[:name],
          data[:damage] || 1,
          {
            description: data[:description],
            slot: data[:slot] || :right_hand,
            character: data[:character] || ')',
            color: data[:color] || :white,
            weight: data[:weight] || 2
          }
        )
      end

      # Create armor from template data
      def create_armor_from_data(data)
        @item_factory.create_armor(
          data[:name],
          data[:defense] || 1,
          {
            description: data[:description],
            slot: data[:slot] || :body,
            character: data[:character] || '[',
            color: data[:color] || :blue,
            weight: data[:weight] || 3
          }
        )
      end

      # Create a potion from template data
      def create_potion_from_data(data)
        @item_factory.create_potion(
          data[:name],
          data[:effect_type] || :heal,
          data[:effect_amount] || 10,
          {
            description: data[:description],
            character: data[:character] || '!',
            color: data[:color] || :red,
            charges: data[:charges] || 1,
            duration: data[:duration],
            stat: data[:stat],
            weight: data[:weight] || 1
          }
        )
      end

      # Create a scroll from template data
      def create_scroll_from_data(data)
        @item_factory.create_scroll(
          data[:name],
          data[:effect_type] || :buff,
          data[:effect_amount] || 5,
          {
            description: data[:description],
            character: data[:character] || '?',
            color: data[:color] || :yellow,
            charges: data[:charges] || 1,
            duration: data[:duration],
            stat: data[:stat],
            weight: data[:weight] || 0.5
          }
        )
      end

      # Create a key from template data
      def create_key_from_data(data)
        # Create basic item first
        key = @item_factory.create_item(
          data[:name],
          {
            description: data[:description] || "A key that opens something",
            character: data[:character] || '⚿',
            color: data[:color] || :cyan,
            item_type: :key,
            weight: data[:weight] || 0.5
          }
        )

        # Add key component
        key.add_component(Vanilla::Components::KeyComponent.new(
                            data[:key_id] || SecureRandom.uuid,
                            data[:lock_type] || :door,
                            data[:one_time_use].nil? ? true : data[:one_time_use]
                          ))

        key
      end

      # Create currency from template data
      def create_currency_from_data(data)
        # Create basic item first
        currency = @item_factory.create_item(
          data[:name],
          {
            description: data[:description] || "Currency that can be used for trading",
            character: data[:character] || '$',
            color: data[:color] || :yellow,
            item_type: :currency,
            stackable: true,
            weight: data[:weight] || 0.01
          }
        )

        # Add currency component
        currency.add_component(Vanilla::Components::CurrencyComponent.new(
                                 data[:value] || 1,
                                 data[:currency_type] || :gold
                               ))

        currency
      end

      # Create a misc item from template data
      def create_misc_from_data(data)
        @item_factory.create_item(
          data[:name],
          {
            description: data[:description],
            item_type: data[:item_type] || :misc,
            character: data[:character] || '&',
            color: data[:color] || :white,
            stackable: data[:stackable] || false,
            weight: data[:weight] || 1
          }
        )
      end

      # Load default item templates
      def load_default_templates
        # Weapons
        register_template(:short_sword, {
                            name: "Short Sword",
                            description: "A simple but effective weapon.",
                            item_type: :weapon,
                            damage: 5,
                            slot: :right_hand,
                            character: '/',
                            color: :white,
                            weight: 3
                          })

        register_template(:dagger, {
                            name: "Dagger",
                            description: "A small, quick blade.",
                            item_type: :weapon,
                            damage: 3,
                            slot: :right_hand,
                            character: '†',
                            color: :cyan,
                            weight: 1
                          })

        # Armors
        register_template(:leather_armor, {
                            name: "Leather Armor",
                            description: "Basic protection made of hardened leather.",
                            item_type: :armor,
                            defense: 2,
                            slot: :body,
                            character: '[',
                            color: :brown,
                            weight: 5
                          })

        register_template(:helmet, {
                            name: "Helmet",
                            description: "A metal helmet that protects your head.",
                            item_type: :armor,
                            defense: 1,
                            slot: :head,
                            character: '^',
                            color: :gray,
                            weight: 2
                          })

        # Potions
        register_template(:healing_potion, {
                            name: "Healing Potion",
                            description: "A small vial of red liquid that restores health.",
                            item_type: :potion,
                            effect_type: :heal,
                            effect_amount: 15,
                            character: '!',
                            color: :red,
                            weight: 1
                          })

        register_template(:strength_potion, {
                            name: "Strength Potion",
                            description: "A potion that temporarily boosts your strength.",
                            item_type: :potion,
                            effect_type: :buff,
                            effect_amount: 3,
                            stat: :strength,
                            duration: 10,
                            character: '!',
                            color: :green,
                            weight: 1
                          })

        # Scrolls
        register_template(:scroll_of_identify, {
                            name: "Scroll of Identify",
                            description: "Reveals the true nature of an item.",
                            item_type: :scroll,
                            effect_type: :identify,
                            effect_amount: 1,
                            character: '?',
                            color: :yellow,
                            weight: 0.5
                          })

        # Keys
        register_template(:rusty_key, {
                            name: "Rusty Key",
                            description: "An old, rusty key. It might unlock something.",
                            item_type: :key,
                            key_id: "dungeon_1",
                            lock_type: :door,
                            one_time_use: true,
                            character: 'k',
                            color: :brown,
                            weight: 0.5
                          })

        # Currency
        register_template(:gold_coins, {
                            name: "Gold Coins",
                            description: "Standard currency for trade.",
                            item_type: :currency,
                            value: 10,
                            currency_type: :gold,
                            character: '$',
                            color: :yellow,
                            weight: 0.01
                          })

        # Misc items
        register_template(:mysterious_artifact, {
                            name: "Mysterious Artifact",
                            description: "A strange object of unknown purpose.",
                            item_type: :misc,
                            character: '*',
                            color: :magenta,
                            weight: 1
                          })
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/inventory/item_registry.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/inventory.rb
# frozen_string_literal: true

# Main entry point for the inventory system
# This file requires all individual inventory system components

module Vanilla
  # Load component definitions
  require_relative 'components/inventory_component'
  require_relative 'components/item_component'
  require_relative 'components/equippable_component'
  require_relative 'components/consumable_component'
  require_relative 'components/effect_component'
  require_relative 'components/durability_component'
  require_relative 'components/key_component'
  require_relative 'components/currency_component'

  # Load inventory subsystem files
  require_relative 'inventory/item'
  require_relative 'inventory/item_factory'
  require_relative 'inventory/item_registry'

  # Load systems
  require_relative 'systems/inventory_system'
  require_relative 'systems/item_interaction_system'
  require_relative 'systems/inventory_render_system'

  # Main Inventory module
  module Inventory
    # This facade class provides a simplified interface for the inventory subsystem
    class InventorySystemFacade
      attr_reader :inventory_system, :render_system, :item_interaction_system, :item_factory, :item_registry, :inventory_render_system

      def initialize(logger, render_system)
        @logger = logger
        @render_system = render_system
        @inventory_system = Vanilla::Systems::InventorySystem.new(logger)
        @item_interaction_system = Vanilla::Systems::ItemInteractionSystem.new(@inventory_system)
        @item_factory = Vanilla::Inventory::ItemFactory.new(logger)
        @item_registry = Vanilla::Inventory::ItemRegistry.new(logger)
        @inventory_render_system = Vanilla::Systems::InventoryRenderSystem.new(render_system, logger)
        @inventory_visible = false

        # Register this facade with the service registry
        Vanilla::ServiceRegistry.register(:inventory_system, self)
      end

      # Add an item to an entity's inventory
      # @param entity [Entity] The entity to add the item to
      # @param item [Entity] The item to add
      # @return [Boolean] Whether the item was successfully added
      def add_item_to_entity(entity, item)
        @inventory_system.add_item(entity, item)
      end

      # Remove an item from an entity's inventory
      # @param entity [Entity] The entity to remove the item from
      # @param item [Entity] The item to remove
      # @return [Boolean] Whether the item was successfully removed
      def remove_item_from_entity(entity, item)
        @inventory_system.remove_item(entity, item)
      end

      # Use an item from an entity's inventory
      # @param entity [Entity] The entity using the item
      # @param item [Entity] The item to use
      # @return [Boolean] Whether the item was successfully used
      def use_item(entity, item)
        @inventory_system.use_item(entity, item)
      end

      # Equip an item from an entity's inventory
      # @param entity [Entity] The entity equipping the item
      # @param item [Entity] The item to equip
      # @return [Boolean] Whether the item was successfully equipped
      def equip_item(entity, item)
        @inventory_system.equip_item(entity, item)
      end

      # Unequip an item from an entity
      # @param entity [Entity] The entity unequipping the item
      # @param item [Entity] The item to unequip
      # @return [Boolean] Whether the item was successfully unequipped
      def unequip_item(entity, item)
        @inventory_system.unequip_item(entity, item)
      end

      # Drop an item from an entity's inventory to the ground
      # @param entity [Entity] The entity dropping the item
      # @param item [Entity] The item to drop
      # @return [Boolean] Whether the item was successfully dropped
      def drop_item(entity, item, level)
        @inventory_system.drop_item(entity, item, level)
      end

      # Check for items at the entity's current position
      # @param entity [Entity] The entity to check for items at its position
      # @param level [Level] The current game level
      # @return [Boolean] Whether any items were picked up
      def check_for_items_at_position(entity, level)
        return false unless entity.has_component?(:position)

        position = entity.get_component(:position)
        @item_interaction_system.process_items_at_location(entity, level, position.row, position.column)
      end

      # Display the inventory UI for an entity
      # @param entity [Entity] The entity whose inventory to display
      def display_inventory(entity)
        @inventory_visible = true
        @inventory_render_system.render_inventory(entity)
      end

      # Hide the inventory UI
      def hide_inventory
        @inventory_visible = false
      end

      # Check if inventory UI is currently visible
      # @return [Boolean] Whether the inventory UI is visible
      def inventory_visible?
        @inventory_visible
      end

      # Toggle inventory view visibility
      # @param entity [Entity] The entity whose inventory to toggle
      # @return [Boolean] The new visibility state
      def toggle_inventory_view(entity)
        @inventory_visible = !@inventory_visible

        if @inventory_visible
          display_inventory(entity)
        end

        @inventory_visible
      end

      # Handle input when inventory is visible
      # @param key [String, Symbol] The input key
      # @param entity [Entity] The entity whose inventory is displayed
      # @return [Boolean] Whether the input was handled
      def handle_inventory_input(key, entity)
        return false unless @inventory_visible

        case key
        when "\e", :escape # ESC key
          hide_inventory
          return true
        when /[a-z]/
          # Letter selection
          index = key.ord - 'a'.ord
          return @inventory_render_system.select_item(entity, index)
        end

        false
      end

      # Cleanup and release resources
      def cleanup
        Vanilla::ServiceRegistry.unregister(:inventory_system)
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/inventory.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/keyboard_handler.rb
# frozen_string_literal: true

require 'io/console'
module Vanilla
  class KeyboardHandler
    def wait_for_input
      $stdin.raw { $stdin.getc }
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/keyboard_handler.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/level.rb
# frozen_string_literal: true

# lib/vanilla/level.rb
module Vanilla
  class Level
    attr_reader :grid, :difficulty, :entities, :stairs, :algorithm, :entrance_row, :entrance_column

    def initialize(rows:, columns:, difficulty:)
      @grid = Vanilla::MapUtils::Grid.new(rows, columns)
      @difficulty = difficulty
      @entities = []
      @entrance_row = 0
      @entrance_column = 0
      @logger = Vanilla::Logger.instance
    end

    def generate(algorithm)
      @algorithm = algorithm
      algorithm.on(@grid)
      self
    end

    def place_stairs(row, column)
      cell = @grid[row, column]
      @logger.debug("Placing stairs at: [#{row}, #{column}]")
      cell.tile = Vanilla::Support::TileType::STAIRS
      @stairs = Vanilla::EntityFactory.create_stairs(row, column)
      add_entity(@stairs)
    end

    def add_entity(entity)
      @entities << entity
      update_grid_with_entity(entity)
    end

    def remove_entity(entity)
      @entities.delete(entity)
    end

    def all_entities
      @entities
    end

    def update_grid_with_entity(entity)
      position = entity.get_component(:position)
      return unless position

      cell = @grid[position.row, position.column]
      return unless cell

      render = entity.get_component(:render)
      if render && render.character
        # Only update if cell isn’t already occupied by a higher-priority entity (e.g., player over stairs)
        if cell.tile == Vanilla::Support::TileType::EMPTY || entity.has_tag?(:player)
          cell.tile = render.character
          @logger.debug("Updated grid with entity at: [#{position.row}, #{position.column}] to tile: #{cell.tile}")
        end
      end
    end

    def update_grid_with_entities
      @grid.each_cell do |cell|
        cell.tile = cell.links.empty? ? Vanilla::Support::TileType::WALL : Vanilla::Support::TileType::EMPTY
      end
      # Process stairs first, then other entities, then player last
      @entities.sort_by { |e| e.has_tag?(:player) ? 1 : e.has_tag?(:stairs) ? 0 : 2 }.each { |e| update_grid_with_entity(e) }
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/level.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/level_generator.rb
# frozen_string_literal: true

# lib/vanilla/level_generator.rb
module Vanilla
  class LevelGenerator
    def generate(difficulty, seed = Random.new_seed, algorithm = nil)
      $seed = seed
      srand($seed)
      @logger = Vanilla::Logger.instance
      @logger.debug("Starting level generation with difficulty: #{difficulty}, seed: #{$seed}")

      begin
        level = Level.new(rows: 10, columns: 10, difficulty: difficulty)
        @algorithm = algorithm || Vanilla::Algorithms::AVAILABLE.sample(random: Random.new($seed))
        @logger.debug("Selected algorithm: #{@algorithm.demodulize}")
        level.generate(@algorithm)

        player_cell = level.grid[0, 0]
        @logger.debug("Player cell set to: [#{player_cell.row}, #{player_cell.column}]")

        distances = player_cell.distances
        @logger.debug("Distances from player: #{distances.cells.count} reachable cells")
        new_start = distances.max&.first || level.grid.random_cell
        @logger.debug("New start cell: [#{new_start.row}, #{new_start.column}]")

        new_distances = new_start.distances
        @logger.debug("Distances from new start: #{new_distances.cells.count} reachable cells")
        stairs_cell = new_distances.max&.first || level.grid.random_cell
        @logger.debug("Stairs cell selected: [#{stairs_cell.row}, #{stairs_cell.column}]")

        # Avoid placing stairs at player’s start
        if stairs_cell == player_cell
          max_attempts = level.grid.rows * level.grid.columns # Total cells
          attempts = 0
          stairs_cell = level.grid.random_cell

          while stairs_cell == player_cell && attempts < max_attempts
            stairs_cell = level.grid.random_cell
            attempts += 1
          end

          stairs_cell = level.grid[1, 0] if stairs_cell == player_cell # Fallback to a nearby cell
          @logger.debug("Stairs cell reselected to avoid player: [#{stairs_cell.row}, #{stairs_cell.column}]")
        end

        ensure_path(level.grid, player_cell, stairs_cell)

        player_cell.tile = Vanilla::Support::TileType::PLAYER
        @logger.debug("Player tile set at: [#{player_cell.row}, #{player_cell.column}]")
        stairs_cell.tile = Vanilla::Support::TileType::STAIRS
        @logger.debug("Stairs tile set at: [#{stairs_cell.row}, #{stairs_cell.column}]")
        level.place_stairs(stairs_cell.row, stairs_cell.column)
        @logger.debug("Stairs placed at: [#{stairs_cell.row}, #{stairs_cell.column}]")

        level
      rescue StandardError => e
        @logger.error("Error generating level: #{e.message}\n#{e.backtrace.join("\n")}")
        raise
      end
    end

    private

    def ensure_path(grid, start_cell, goal_cell)
      @logger.debug("Ensuring path from [#{start_cell.row}, #{start_cell.column}] to [#{goal_cell.row}, #{goal_cell.column}]")
      current = start_cell
      until current == goal_cell
        next_cell = [current.north, current.south, current.east, current.west].compact.min_by do |cell|
          (cell.row - goal_cell.row).abs + (cell.column - goal_cell.column).abs
        end
        if next_cell
          current.link(cell: next_cell, bidirectional: true)
          next_cell.tile = Vanilla::Support::TileType::EMPTY unless next_cell == goal_cell
          @logger.debug("Linked to [#{next_cell.row}, #{next_cell.column}]")
          current = next_cell
        else
          @logger.warn("No valid next cell found; using random fallback")
          goal_cell = grid.random_cell while goal_cell == start_cell
          current = start_cell # Restart pathing
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/level_generator.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/logger.rb
# frozen_string_literal: true

# module Vanilla
#   class Logger
#     def self.instance
#       @instance ||= ::Logger.new(STDOUT).tap { |l| l.level = ::Logger::DEBUG }
#     end
#   end
# end

require 'fileutils'
require 'singleton'

module Vanilla
  class Logger
    include Singleton

    LOG_LEVELS = {
      debug: 0,
      info: 1,
      warn: 2,
      error: 3,
      fatal: 4
    }.freeze

    attr_accessor :level

    def initialize
      @level = ENV['VANILLA_LOG_LEVEL']&.downcase&.to_sym || :info
      @log_env = ENV['VANILLA_LOG_DIR'] || 'development'

      @log_dir = File.join(Dir.pwd, 'logs', @log_env)
      FileUtils.mkdir_p(@log_dir) unless Dir.exist?(@log_dir)

      @log_file = File.join(@log_dir, "vanilla_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log")
      @file = File.open(@log_file, 'w')

      # Write header
      @file.puts "=== Vanilla Game Log Started at #{Time.now} ==="
      @file.flush
    end

    def debug(message)
      log(:debug, message)
    end

    def info(message)
      log(:info, message)
    end

    def warn(message)
      log(:warn, message)
    end

    def error(message)
      log(:error, message)
    end

    def fatal(message)
      log(:fatal, message)
    end

    def close
      return unless @file

      @file.puts "=== Vanilla Game Log Ended at #{Time.now} ==="
      @file.close
      @file = nil
    end

    private

    def log(level, message)
      timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S.%L')
      formatted_message = "[#{timestamp}] [#{level.to_s.upcase}] #{message}"

      @file.puts(formatted_message)
      @file.flush
    end
  end
end

# Ensure logs are closed properly when the program exits
at_exit { Vanilla::Logger.instance.close }
# End /Users/davidslv/projects/vanilla/lib/vanilla/logger.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/map.rb
# frozen_string_literal: true

module Vanilla
  class Map
    def initialize(rows: 10, columns: 10, algorithm:, seed: nil)
      @logger = Vanilla::Logger.instance

      $seed = seed || rand(999_999_999_999_999)
      @logger.info("Map initialized with seed: #{$seed}")
      srand($seed)

      @rows, @columns, @algorithm = rows, columns, algorithm
      @logger.debug("Map parameters set: rows=#{rows}, columns=#{columns}, algorithm=#{algorithm}")
    end

    def self.create(rows:, columns:, algorithm: Vanilla::Algorithms::BinaryTree, seed:)
      Vanilla::Logger.instance.info("Creating map with algorithm: #{algorithm}")
      new(rows: rows, columns: columns, algorithm: algorithm, seed: seed).create
    end

    def create
      @logger.debug("Creating grid with rows=#{@rows}, columns=#{@columns}")
      grid = Vanilla::MapUtils::Grid.new(rows: @rows, columns: @columns)

      @logger.debug("Applying algorithm: #{@algorithm}")
      @algorithm.on(grid)

      dead_ends_count = grid.dead_ends.count
      @logger.debug("Map created with #{dead_ends_count} dead ends")

      # Store the algorithm used to create this grid
      grid.instance_variable_set(:@algorithm, @algorithm)

      # Add a method to access the algorithm
      grid.define_singleton_method(:algorithm) { @algorithm }

      grid
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/map.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/map_utils/cell.rb
# frozen_string_literal: true

require_relative 'cell_type_factory'

module Vanilla
  module MapUtils
    # Represents a single cell in a maze or grid-based map
    # It has a position in the grid and can be linked to other cells.
    # Cells can be linked to other cells to form a path or maze.
    # Cells can also have various properties, such as whether they are a dead end, or contain a player or stairs.
    #
    # @example
    #  cell = Vanilla::MapUtils::Cell.new(row: 0, column: 0)
    #  cell.north = Vanilla::MapUtils::Cell.new(row: 0, column: 0)
    #  cell.north.link(cell: cell)
    #
    # The `link` method is used to link this cell to another cell.
    # The `unlink` method is used to unlink this cell from another cell.
    # The `links` method returns an array of all cells linked to this cell.
    # The `linked?` method checks if this cell is linked to another cell.
    # The `neighbors` method returns an array of all neighboring cells (north, south, east, west).
    # The `distances` method calculates the distance from the current cell to all other cells in the map.
    # The `dead_end?` method checks if this cell is a dead end.
    # The `player?` method checks if this cell contains the player.
    # The `stairs?` method checks if this cell contains stairs.
    class Cell
      attr_reader :row, :column, :cell_type
      attr_accessor :north, :south, :east, :west
      attr_accessor :dead_end

      # Initialize a new cell with its position in the grid
      # @param row [Integer] The row position of the cell
      # @param column [Integer] The column position of the cell
      # @param type_factory [CellTypeFactory] Factory for cell types
      def initialize(row:, column:, type_factory: nil)
        @row, @column = row, column
        @links = {}

        # Use the provided factory or create a default one
        @type_factory = type_factory || CellTypeFactory.new
        @cell_type = @type_factory.get_cell_type(:empty)
      end

      # Get the position of the cell as an array
      # @return [Array<Integer>] An array containing the row and column
      def position
        [row, column]
      end

      # Link this cell to another cell
      # @param cell [Cell] The cell to link to
      # @param bidirectional [Boolean] Whether to create a bidirectional link
      # @return [Cell] Returns self for method chaining
      def link(cell:, bidirectional: true)
        raise ArgumentError, "Cannot link a cell to itself" if cell == self

        @links[cell] = true
        cell.link(cell: self, bidirectional: false) if bidirectional
        self
      end

      # Unlink this cell from another cell
      # @param cell [Cell] The cell to unlink from
      # @param bidirectional [Boolean] Whether to remove the link in both directions
      def unlink(cell:, bidirectional: true)
        @links.delete(cell)
        cell.unlink(cell: self, bidirectional: false) if bidirectional

        self
      end

      # Get all cells linked to this cell
      # @return [Array<Cell>] An array of linked cells
      def links
        @links.keys
      end

      # Check if this cell is linked to another cell
      # @param cell [Cell] The cell to check for a link
      # @return [Boolean] True if linked, false otherwise
      def linked?(cell)
        @links.key?(cell)
      end

      # Check if this cell is a dead end
      # @return [Boolean] True if it's a dead end, false otherwise
      def dead_end?
        !!dead_end
      end

      # Check if this cell contains the player
      # @return [Boolean] True if it contains the player, false otherwise
      def player?
        @cell_type.player?
      end

      # Check if this cell contains stairs
      # @return [Boolean] True if it contains stairs, false otherwise
      def stairs?
        @cell_type.stairs?
      end

      # Get all neighboring cells (north, south, east, west)
      # @return [Array<Cell>] An array of neighboring cells
      def neighbors
        [north, south, east, west].compact
      end

      # Set the cell type from a tile character
      # @param tile_character [String] The character to set
      def tile=(tile_character)
        @cell_type = @type_factory.get_by_character(tile_character)
      end

      # Get the tile character for this cell
      # @return [String] The tile character
      def tile
        @cell_type.tile_character
      end

      # Calculate distances from this cell to all other cells in the maze
      # @return [DistanceBetweenCells] A DistanceBetweenCells object containing distances
      def distances
        distances = Vanilla::MapUtils::DistanceBetweenCells.new(self)
        frontier = [self]

        while frontier.any?
          new_frontier = []

          frontier.each do |cell|
            cell.links.each do |linked|
              next if distances[linked]

              distances[linked] = distances[cell] + 1
              new_frontier << linked
            end
          end

          frontier = new_frontier
        end

        distances
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/map_utils/cell.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/map_utils/cell_type.rb
# frozen_string_literal: true

module Vanilla
  module MapUtils
    # CellType implements the Flyweight pattern for cell types
    # It stores the intrinsic (shared) state of cells, such as
    # the tile character and properties like walkability
    class CellType
      attr_reader :key, :tile_character, :properties

      # Initialize a new cell type
      # @param key [Symbol] The key identifier for this cell type
      # @param tile_character [String] The character used to render this cell type
      # @param properties [Hash] Additional properties for this cell type
      def initialize(key, tile_character, properties = {})
        @key = key
        @tile_character = tile_character
        @properties = properties.freeze
      end

      # Check if this cell type is walkable
      # @return [Boolean] True if walkable, false otherwise
      def walkable?
        @properties.fetch(:walkable, true)
      end

      # Check if this cell type represents stairs
      # @return [Boolean] True if stairs, false otherwise
      def stairs?
        @properties.fetch(:stairs, false)
      end

      # Check if this cell type represents a player
      # @return [Boolean] True if player, false otherwise
      def player?
        @properties.fetch(:player, false)
      end

      # Get the character to render for this cell type
      # @return [String] The tile character
      def to_s
        @tile_character
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/map_utils/cell_type.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/map_utils/cell_type_factory.rb
# frozen_string_literal: true

require_relative 'cell_type'

module Vanilla
  module MapUtils
    # CellTypeFactory implements the Flyweight pattern factory
    # It creates and manages CellType instances, ensuring that
    # identical types are reused rather than duplicated
    class CellTypeFactory
      # Initialize a new factory and setup standard types
      def initialize
        @types = {}
        setup_standard_types
      end

      # Get a cell type by its key identifier
      # @param key [Symbol] The key for the cell type
      # @return [CellType] The requested cell type
      # @raise [ArgumentError] If the key is unknown
      def get_cell_type(key)
        @types[key] or raise ArgumentError, "Unknown cell type: #{key}"
      end

      # Get a cell type by its tile character
      # @param tile_character [String] The tile character
      # @return [CellType] The cell type for this character, or the empty type if not found
      def get_by_character(tile_character)
        # Find the type with matching tile character or default to empty
        @types.values.find { |t| t.tile_character == tile_character } || @types[:empty]
      end

      # Register a new cell type
      # @param key [Symbol] The identifier for this type
      # @param tile_character [String] The character used to render this type
      # @param properties [Hash] Additional properties for this type
      # @return [CellType] The newly created cell type
      def register(key, tile_character, properties = {})
        @types[key] = CellType.new(key, tile_character, properties)
      end

      private

      # Setup the standard cell types used in the game
      def setup_standard_types
        register(:empty, Vanilla::Support::TileType::EMPTY, walkable: true)
        register(:wall, Vanilla::Support::TileType::WALL, walkable: false)
        register(:player, Vanilla::Support::TileType::PLAYER, walkable: true, player: true)
        register(:stairs, Vanilla::Support::TileType::STAIRS, walkable: true, stairs: true)
        register(:door, Vanilla::Support::TileType::DOOR, walkable: true)
        register(:floor, Vanilla::Support::TileType::FLOOR, walkable: true)
        register(:monster, Vanilla::Support::TileType::MONSTER, walkable: false)
        register(:vertical_wall, Vanilla::Support::TileType::VERTICAL_WALL, walkable: false)
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/map_utils/cell_type_factory.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/map_utils/distance_between_cells.rb
# frozen_string_literal: true

module Vanilla
  module MapUtils
    # We will use this class to record the distance of each cell from the starting point (@root)
    # so the initialize constructor simply sets up the hash so that the distance of the root from itself is 0.
    class DistanceBetweenCells
      def initialize(root)
        @root = root
        @cells = {}
        @cells[@root] = 0
      end

      #  We also add an array accessor method, [](cell),
      #  so that we can query the distance of a given cell from the root
      def [](cell)
        @cells[cell]
      end

      #  And a corresponding setter, to record the distance of a given cell.
      def []=(cell, distance)
        @cells[cell] = distance
      end

      # to get a list of all of the cells that are present.
      def cells
        @cells.keys
      end

      def path_to(goal)
        current = goal

        breadcrumbs = DistanceBetweenCells.new(@root)
        breadcrumbs[current] = @cells[current]

        until current == @root
          current.links.each do |neighbor|
            if @cells[neighbor] < @cells[current]
              breadcrumbs[neighbor] = @cells[neighbor]
              current = neighbor

              break
            end
          end
        end

        breadcrumbs
      end

      def max
        max_distance = 0
        max_cell = @root

        @cells.each do |cell, distance|
          if distance > max_distance
            max_cell = cell
            max_distance = distance
          end
        end

        [max_cell, max_distance]
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/map_utils/distance_between_cells.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/map_utils/grid.rb
# frozen_string_literal: true

module Vanilla
  module MapUtils
    class Grid
      attr_reader :rows, :columns

      def initialize(rows, columns)
        @rows = rows
        @columns = columns
        @grid = Array.new(rows * columns) { |i| Cell.new(self, i / columns, i % columns) }
        # Set neighbors for each cell
        each_cell do |cell|
          row, col = cell.row, cell.column
          cell.north = self[row - 1, col] if row > 0
          cell.south = self[row + 1, col] if row < @rows - 1
          cell.east  = self[row, col + 1] if col < @columns - 1
          cell.west  = self[row, col - 1] if col > 0
        end
      end

      def [](row, col)
        return nil unless row.is_a?(Integer) && col.is_a?(Integer)
        return nil unless row.between?(0, @rows - 1) && col.between?(0, @columns - 1)

        @grid[row * @columns + col]
      end

      def each_cell
        @grid.each { |cell| yield cell }
      end

      def random_cell
        @grid.sample
      end

      def size
        @rows * @columns
      end
    end

    class Cell
      attr_reader :row, :column, :grid
      attr_accessor :north, :south, :east, :west, :tile

      def initialize(grid, row, column)
        @grid = grid
        @row = row
        @column = column
        @links = {}
        @tile = Vanilla::Support::TileType::EMPTY # Default to walkable
      end

      def link(cell:, bidirectional: true)
        @links[cell] = true
        cell.links[self] = true if bidirectional && cell
      end

      def unlink(cell:, bidirectional: true)
        @links.delete(cell)
        cell.links.delete(self) if bidirectional && cell
      end

      def linked?(cell)
        @links.key?(cell)
      end

      def links
        @links
      end

      def neighbors
        [north, south, east, west].compact
      end

      def distances
        Distances.new(self)
      end
    end

    class Distances
      def initialize(root)
        @root = root
        @cells = { root => 0 }
      end

      def [](cell)
        @cells[cell]
      end

      def path_to(_goal)
        self # Placeholder
      end

      def cells
        @cells.keys
      end

      def max
        max_distance = 0
        max_cell = @root
        @cells.each { |cell, distance| max_cell, max_distance = cell, distance if distance > max_distance }
        [max_cell, max_distance]
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/map_utils/grid.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/map_utils.rb
# frozen_string_literal: true

module Vanilla
  module MapUtils
    require_relative 'map_utils/distance_between_cells'
    require_relative 'map_utils/cell'
    require_relative 'map_utils/grid'
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/map_utils.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/message_system.rb
# frozen_string_literal: true

# Main entry point for the message system
# This file requires all individual message system components

require_relative 'messages/message'
require_relative 'messages/message_log'
require_relative 'messages/message_panel'
require_relative 'messages/message_manager'

module Vanilla
  module Messages
    # This module contains the message system for the game
    # The message system is responsible for displaying messages to the player
    # and providing a way to browse through message history.

    # MessageSystem serves as a facade for the message subsystem
    # TODO: Separete Concerns: MessageSystem and MessageSystemFacade?
    # This follows the Facade pattern to provide a simplified interface
    class MessageSystem
      attr_reader :manager

      def initialize(logger, render_system)
        @logger = logger
        @manager = MessageManager.new(logger, render_system)

        # Register this system in the service registry
        Vanilla::ServiceRegistry.register(:message_system, self)
      end

      # Set up the message panel with the given dimensions
      def setup_panel(x, y, width, height)
        @manager.setup_panel(x, y, width, height)
      end

      # Render the message panel
      def render(render_system)
        @manager.render(render_system)
      end

      # Log a message with the given translation key
      def log_message(key, options = {})
        @manager.log_translated(key, **options)
      end

      # Log a success message
      def log_success(key, metadata = {})
        @manager.log_success(key, metadata)
      end

      # Log a warning message
      def log_warning(key, metadata = {})
        @manager.log_warning(key, metadata)
      end

      # Log a critical message
      def log_critical(key, metadata = {})
        @manager.log_critical(key, metadata)
      end

      # Get recent messages
      def get_recent_messages(limit = 10)
        @manager.get_recent_messages(limit)
      end

      # Handle user input
      def handle_input(key)
        @manager.handle_input(key)
      end

      # Toggle selection mode
      def toggle_selection_mode
        @manager.toggle_selection_mode
      end

      # Check if in selection mode
      def selection_mode?
        @manager.selection_mode
      end

      # Get the service instance - implementing Service Locator
      def self.instance
        Vanilla::ServiceRegistry.get(:message_system)
      end

      # Clean up resources - called when the game ends
      def cleanup
        Vanilla::ServiceRegistry.unregister(:message_system)
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/message_system.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/messages/message.rb
# frozen_string_literal: true

module Vanilla
  module Messages
    # Message represents a single message in the game's message log.
    # It supports translation through I18n, selectable options, and shortcut keys.
    class Message
      attr_reader :content, :category, :importance, :turn, :timestamp, :metadata
      attr_accessor :selectable, :selection_callback, :shortcut_key

      # Initialize a new message
      # @param content [String, Symbol] The message text or translation key
      # @param category [Symbol] Category of the message (e.g., :combat, :item, :system)
      # @param importance [Symbol] Importance level affecting display (:normal, :warning, :critical, :success)
      # @param turn [Integer, nil] Game turn when the message was created (defaults to current turn)
      # @param metadata [Hash] Additional data for translation interpolation or message context
      # @param selectable [Boolean] Whether the message is selectable for interaction
      # @param shortcut_key [String, nil] Single-key shortcut for direct selection (optional)
      # @param turn_provider [Proc] Optional proc that provides the current turn number
      # @yield [Message] Called when the message is selected, if selectable
      def initialize(content, category: :system, importance: :normal,
                     turn: nil, metadata: {}, selectable: false,
                     shortcut_key: nil, turn_provider: -> { Vanilla.game_turn rescue 0 },
                     &selection_callback)
        @content = content
        @category = category
        @importance = importance
        @turn = turn || turn_provider.call
        @timestamp = Time.now
        @metadata = metadata
        @selectable = selectable
        @shortcut_key = shortcut_key
        @selection_callback = selection_callback if block_given?
      end

      # Check if the message is selectable
      # @return [Boolean] true if the message is selectable
      def selectable?
        @selectable
      end

      # Activate the message's selection callback if it's selectable
      # @return [Object] The result of the callback, or nil if not selectable
      def select
        @selection_callback&.call(self) if @selectable
      end

      # Check if the message has a shortcut key
      # @return [Boolean] true if the message has a shortcut key
      def has_shortcut?
        !@shortcut_key.nil?
      end

      # Get the translated text of the message
      # If the text is a symbol, it will be translated using I18n
      # @return [String] The translated text
      def translated_text
        return @content unless @content.is_a?(Symbol) || @content.is_a?(String) && @content.include?('.')

        # Handle translation with interpolation values from metadata
        key = @content.is_a?(Symbol) ? @content.to_s : @content
        I18n.t(key, default: key, **@metadata)
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/messages/message.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/messages/message_log.rb
# frozen_string_literal: true

module Vanilla
  module Messages
    class MessageLog
      attr_reader :messages, :history_size

      DEFAULT_CATEGORIES = [:system, :combat, :movement, :item, :story, :debug]

      def initialize(logger, history_size: 120)
        @logger = logger
        @messages = []
        @history_size = history_size
        @formatters = {}
        @current_selection_index = nil
        @observers = []

        # Initialize default formatters
        register_default_formatters
      end

      # Observer pattern methods
      def add_observer(observer)
        @observers << observer unless @observers.include?(observer)
      end

      def remove_observer(observer)
        @observers.delete(observer)
      end

      def notify_observers
        @observers.each { |observer| observer.update }
      end

      # Get the current game turn instead of directly accessing the global
      def current_game_turn
        Vanilla.game_turn rescue 0
      end

      # Add a message using a translation key
      def add(key, options = {}, _turn_provider = method(:current_game_turn))
        # Extract category and importance from options
        category = options.delete(:category) || :system
        importance = options.delete(:importance) || :normal

        # Create a new Message object with the content
        message = Message.new(
          key,
          category: category,
          importance: importance,
          metadata: options
        )

        add_message(message)
        message
      end

      # Add a pre-constructed message object
      def add_message(message)
        return unless message.is_a?(Message)

        # Add to message list
        @messages.unshift(message)

        # Trim history if needed
        @messages.pop if @messages.size > @history_size

        # Notify observers that a message was added
        notify_observers

        message
      end

      # Get messages by category
      def get_by_category(category, limit = 10)
        @messages.select { |m| m.category == category }.take(limit)
      end

      # Get messages by importance level
      def get_by_importance(importance, limit = 10)
        @messages.select { |m| m.importance == importance }.take(limit)
      end

      # Get recent messages
      def get_recent(limit = 10)
        @messages.take(limit)
      end

      # Get selectable messages
      def get_selectable_messages
        @messages.select { |m| m.respond_to?(:selectable?) && m.selectable? }
      end

      # Register a formatter for a specific category
      def register_formatter(name, formatter)
        @formatters[name] = formatter
      end

      # Clear all messages
      def clear
        @messages.clear
        notify_observers
      end

      private

      def register_default_formatters
        # Register formatters for different message types
        register_formatter(:combat, ->(message) {
          # Format combat messages (highlighting damage numbers, etc)
          message
        })

        # Add more formatters as needed
      end

      def apply_formatters(message)
        if message.is_a?(Message)
          formatter = @formatters[message.category]
          return message unless formatter

          formatter.call(message)
        else
          message
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/messages/message_log.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/messages/message_manager.rb
# frozen_string_literal: true

module Vanilla
  module Messages
    class MessageManager
      attr_reader :selection_mode

      def initialize(logger, render_system)
        @logger = logger
        @render_system = render_system
        @message_log = MessageLog.new(logger)
        @panel = nil
        @selection_mode = false
        @selection_index = 0
      end

      # Log a message with the translation key
      def log_message(key, options = {})
        @message_log.add(key, options)
      end

      # Add method to log translated messages
      def log_translated(key, importance: :normal, category: :system, **options)
        # Extract metadata if it's nested
        metadata = options.delete(:metadata) || options

        # Create a new message with the content and translation key
        message = Message.new(
          key,
          category: category,
          importance: importance,
          metadata: metadata
        )

        @message_log.add_message(message)
        message
      end

      # Add a message directly
      def add_message(content, options = {})
        message = Message.new(
          content,
          category: options[:category] || :system,
          importance: options[:importance] || :normal,
          metadata: options[:metadata] || {}
        )

        @message_log.add_message(message)
        message
      end

      # Toggle message selection mode on/off
      # @return [Boolean] The new selection mode state
      def toggle_selection_mode
        @selection_mode = !@selection_mode
        @logger.info("Message selection mode: #{@selection_mode ? 'ON' : 'OFF'}")

        # Reset selection index when toggling
        @selection_index = 0 if @selection_mode

        @selection_mode
      end

      # Handle user input for message selection and interaction
      # @param key [Symbol, String] The key pressed by the user
      # @return [Boolean] Whether the input was handled
      def handle_input(key)
        # Never intercept 'q' keys for quitting
        return false if key == 'q' || key == 'Q'

        # Handle shortcut keys for messages with shortcuts
        if !@selection_mode && key.is_a?(String) && key.length == 1
          # First try from get_recent_messages for test compatibility
          selectable_messages = get_recent_messages

          # Find a message with matching shortcut key
          message_with_shortcut = selectable_messages.find do |m|
            m.selectable? && m.has_shortcut? && m.shortcut_key == key
          end

          if message_with_shortcut
            message_with_shortcut.select
            return true
          end
        end

        # Handle navigation in selection mode
        if @selection_mode
          case key
          when :KEY_UP, :KEY_LEFT, 'k', 'h'
            navigate_selection(-1)
            return true
          when :KEY_DOWN, :KEY_RIGHT, 'j', 'l'
            navigate_selection(1)
            return true
          when :enter, "\r", ' '
            return select_current_message
          when :escape, "\e"
            toggle_selection_mode
            return true
          end
        end

        # If we got here, input wasn't handled
        false
      end

      # Get the currently selected message
      def currently_selected_message
        selectable_messages = @message_log.get_selectable_messages
        return nil if selectable_messages.empty?

        # Ensure index is within bounds
        @selection_index = @selection_index.clamp(0, selectable_messages.size - 1)
        selectable_messages[@selection_index]
      end

      # Select the currently highlighted message
      def select_current_message
        return false unless @selection_mode

        message = currently_selected_message
        return false unless message

        message.select
        true
      end

      # Set up the message panel with the specified dimensions
      def setup_panel(x, y, width, height)
        @panel = MessagePanel.new(x, y, width, height, @message_log)
      end

      # Render the message panel
      def render(render_system)
        if $DEBUG
          puts "DEBUG: Rendering message panel, selection mode: #{@selection_mode}"
        end

        return unless @panel

        @panel.render(render_system, @selection_mode)
      end

      # Get recent messages from the log
      def get_recent_messages(limit = 10)
        @message_log.get_recent(limit)
      end

      # Get messages by category
      def get_messages_by_category(category, limit = 10)
        @message_log.get_by_category(category, limit)
      end

      # Clear all messages
      def clear_messages
        @message_log.clear
      end

      #
      # Convenience methods for different message types
      #

      # Log a combat message
      def log_combat(key, metadata = {}, importance = :normal)
        log_translated(key,
                       category: :combat,
                       importance: importance,
                       metadata: metadata)
      end

      # Log a movement message
      def log_movement(key, metadata = {})
        log_translated(key,
                       category: :movement,
                       importance: :normal,
                       metadata: metadata)
      end

      # Log an item-related message
      def log_item(key, metadata = {}, importance = :info)
        log_translated(key,
                       category: :item,
                       importance: importance,
                       metadata: metadata)
      end

      # Log an exploration message
      def log_exploration(key, metadata = {}, importance = :info)
        log_translated(key,
                       category: :exploration,
                       importance: importance,
                       metadata: metadata)
      end

      # Log a warning message
      def log_warning(key, metadata = {})
        log_translated(key,
                       category: :system,
                       importance: :warning,
                       metadata: metadata)
      end

      # Log a critical message
      def log_critical(key, metadata = {})
        log_translated(key,
                       category: :system,
                       importance: :critical,
                       metadata: metadata)
      end

      # Log a success message
      def log_success(key, metadata = {})
        log_translated(key,
                       category: :system,
                       importance: :success,
                       metadata: metadata)
      end

      private

      # Navigate through selectable messages
      def navigate_selection(direction)
        selectable_messages = @message_log.get_selectable_messages
        return if selectable_messages.empty?

        @selection_index = (@selection_index + direction) % selectable_messages.size
        @logger.debug("Selection index: #{@selection_index} (#{selectable_messages.size} selectable)")
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/messages/message_manager.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/messages/message_panel.rb
# frozen_string_literal: true

module Vanilla
  module Messages
    # Panel for displaying messages beneath the map
    class MessagePanel
      attr_reader :x, :y, :width, :height, :message_log

      # Initialize a new message panel
      # @param x [Integer] X coordinate (column) for top-left corner
      # @param y [Integer] Y coordinate (row) for top-left corner
      # @param width [Integer] Width of the panel
      # @param height [Integer] Height of the panel (number of visible messages)
      # @param message_log [MessageLog] The message log to display
      def initialize(x, y, width, height, message_log)
        @x = x
        @y = y
        @width = width
        @height = height
        @message_log = message_log
        @scroll_offset = 0

        # Register as an observer of the message log
        @message_log.add_observer(self) if @message_log.respond_to?(:add_observer)
      end

      # Called when the message log is updated
      # Implements Observer pattern
      def update
        # Nothing needed here - panel will get updated on next render
      end

      # Clean up resources
      def cleanup
        @message_log.remove_observer(self) if @message_log.respond_to?(:remove_observer)
      end

      # Render the message panel
      # @param renderer [Vanilla::Renderers::Renderer] The renderer to use
      # @param selection_mode [Boolean] Whether the game is in message selection mode
      def render(renderer, _selection_mode = false)
        return unless renderer.respond_to?(:draw_character)

        # Debug output with concise message
        if $DEBUG
          msg_types = @message_log.messages.take(5).map(&:category).tally
          puts "DEBUG: Drawing message panel with #{@message_log.messages.size} msgs (#{msg_types})"
        end

        # Draw a separator line above the message panel
        draw_separator_line(renderer)

        # Get messages to display with scroll offset
        messages = @message_log.get_recent(@height + @scroll_offset)

        # Add a default message if no messages exist
        if messages.nil? || messages.empty?
          default_msg = "Welcome to Vanilla! Use movement keys to navigate."
          default_msg.each_char.with_index do |char, i|
            renderer.draw_character(@y + 1, @x + i, char)
          end
          return
        end

        visible_messages = messages[@scroll_offset, @height] || []

        # Force visibility with a marker
        renderer.draw_character(@y, @x, "#")

        # Draw messages directly using draw_character
        visible_messages.each_with_index do |message, idx|
          y_pos = @y + idx + 1

          # Handle both Message objects and hash-based messages
          if message.is_a?(Message)
            render_message_object(renderer, message, y_pos)
          else
            render_hash_message(renderer, message, y_pos)
          end
        end

        # Draw message count indicator
        draw_message_count(renderer, visible_messages.size)
      end

      # Scroll the panel up
      # @return [Integer] The new scroll offset
      def scroll_up
        # Increment offset to show older messages
        max_scroll = [@message_log.messages.size - @height, 0].max
        @scroll_offset = [(@scroll_offset + 1), max_scroll].min
      end

      # Scroll the panel down
      # @return [Integer] The new scroll offset
      def scroll_down
        # Decrement offset to show newer messages
        @scroll_offset = [(@scroll_offset - 1), 0].max
      end

      private

      # Render a Message object
      # @param renderer [Vanilla::Renderers::Renderer] The renderer to use
      # @param message [Message] The message object to render
      # @param y_pos [Integer] The y position to render at
      def render_message_object(renderer, message, y_pos)
        # If the message is selectable, add an indicator
        x_offset = 0

        if message.selectable?
          # Determine if this message is selected
          is_selected = false
          if @message_log.current_selection_index
            selectable_messages = @message_log.get_selectable_messages
            is_selected = selectable_messages[@message_log.current_selection_index] == message
          end

          # Show selection indicator (* or >)
          indicator = is_selected ? ">" : "*"
          renderer.draw_character(y_pos, @x, indicator, :cyan)
          x_offset += 1

          # If it has a shortcut key, show it
          if message.has_shortcut?
            shortcut_text = "#{message.shortcut_key})"
            shortcut_text.each_char.with_index do |char, char_idx|
              renderer.draw_character(y_pos, @x + x_offset + char_idx, char, :cyan)
            end
            x_offset += shortcut_text.length
          end

          # Add a space after indicators
          x_offset += 1
        end

        # Draw message text
        text = format_message_object(message, @width - x_offset)
        color = get_color_for_message(message)

        text.each_char.with_index do |char, char_idx|
          renderer.draw_character(y_pos, @x + char_idx + x_offset, char, color)
        end
      end

      # Render a hash-based message
      # @param renderer [Vanilla::Renderers::Renderer] The renderer to use
      # @param message [Hash] The message hash to render
      # @param y_pos [Integer] The y position to render at
      def render_hash_message(renderer, message, y_pos)
        # Get formatted message text with prefix
        text = format_hash_message(message, @width)

        # Get color based on importance and category
        color = get_color_for_hash_message(message)

        # Draw each character
        text.each_char.with_index do |char, char_idx|
          renderer.draw_character(y_pos, @x + char_idx, char, color)
        end
      end

      # Get color for a hash-based message
      # @param message [Hash] The message hash
      # @return [Symbol] Color to use
      def get_color_for_hash_message(message)
        # First check importance
        importance = message[:importance] || :normal
        category = message[:category] || :system

        case importance
        when :critical, :danger
          :red
        when :warning
          :yellow
        when :success
          :green
        else
          # Then check category
          case category
          when :combat
            :red
          when :item
            :green
          when :movement
            :cyan
          when :exploration
            :blue
          else
            :white
          end
        end
      end

      # Format a Message object for display, handling truncation
      # @param message [Message] The message to format
      # @param max_width [Integer] Maximum width for the message text
      # @return [String] The formatted message text
      def format_message_object(message, max_width)
        text = message.translated_text.to_s

        # Add a prefix based on message category/importance
        prefix = case message.importance
                 when :critical then "!! "
                 when :warning then "* "
                 when :success then "+ "
                 else "> "
                 end

        # Add prefix and ensure message fits in panel
        prefixed_text = prefix + text

        # Truncate to fit panel width
        prefixed_text.length > max_width ? prefixed_text[0...(max_width - 3)] + "..." : prefixed_text
      end

      # Format a hash-based message
      # @param message [Hash] The message to format
      # @param max_width [Integer] Maximum width for the message text
      # @return [String] The formatted message text
      def format_hash_message(message, max_width)
        text = message[:text].to_s

        # Add a prefix based on message category/importance
        prefix = case message[:importance]
                 when :critical, :danger then "!! "
                 when :warning then "* "
                 when :success then "+ "
                 else "> "
                 end

        # Add prefix and ensure message fits in panel
        prefixed_text = prefix + text

        # Truncate to fit panel width
        prefixed_text.length > max_width ? prefixed_text[0...(max_width - 3)] + "..." : prefixed_text
      end

      # Draw a separator line at the top of the message panel
      # @param renderer [Vanilla::Renderers::Renderer] The renderer to use
      def draw_separator_line(renderer)
        # Draw a clearly visible separator using special characters
        renderer.draw_character(@y, @x, "+")

        # Draw a very visible line with alternating characters
        width.times do |i|
          char = (i % 2 == 0) ? "=" : "-"
          renderer.draw_character(@y, @x + i + 1, char)
        end

        renderer.draw_character(@y, @x + width + 1, "+")
      end

      # Draw a message count indicator
      # @param renderer [Vanilla::Renderers::Renderer] The renderer to use
      # @param visible_count [Integer] The number of visible messages
      def draw_message_count(renderer, visible_count)
        # Make count more obvious with brackets and stars
        count_text = "**[#{visible_count}/#{@message_log.messages.size}]**"
        count_text.each_char.with_index do |char, i|
          renderer.draw_character(@y, @x + width - count_text.length + i, char)
        end
      end

      # Get appropriate color for a message based on category and importance
      # @param message [Message] The message to color
      # @return [Symbol] The color symbol to use
      def get_color_for_message(message)
        # First check importance for critical/warning messages
        case message.importance
        when :critical, :danger
          :red
        when :warning
          :yellow
        when :success
          :green
        else
          # Then check category for normal importance messages
          case message.category
          when :combat
            :red
          when :item
            :green
          when :movement
            :cyan
          when :exploration
            :blue
          else
            :white
          end
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/messages/message_panel.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/renderers/renderer.rb
# frozen_string_literal: true

module Vanilla
  module Renderers
    class Renderer
      def clear
        raise NotImplementedError, "Renderers must implement #clear"
      end

      def clear_screen
        raise NotImplementedError, "Renderers must implement #clear_screen"
      end

      def draw_grid(grid)
        raise NotImplementedError, "Renderers must implement #draw_grid"
      end

      def draw_character(row, column, character, color = nil)
        raise NotImplementedError, "Renderers must implement #draw_character"
      end

      def present
        raise NotImplementedError, "Renderers must implement #present"
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/renderers/renderer.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/renderers/terminal_renderer.rb
# frozen_string_literal: true

# lib/vanilla/renderers/terminal_renderer.rb
module Vanilla
  module Renderers
    class TerminalRenderer
      def clear
        system("clear")
      end

      def draw_grid(grid, algorithm)
        output = [
          "Vanilla Roguelike - Difficulty: 1 - Seed: #{$seed}",
          "Rows: #{grid.rows} | Columns: #{grid.columns} | Algorithm: #{algorithm}",
          "\n"
        ]

        # Add top border
        top_border = "+"
        grid.columns.times { top_border += "---+"; }
        output << top_border

        grid.rows.times do |row|
          row_cells = "|"
          row_walls = "+"
          grid.columns.times do |col|
            cell = grid[row, col]
            row_cells += " #{cell.tile || '.'} "
            row_cells += (col == grid.columns - 1) ? "|" : (cell.linked?(cell.east) ? " " : "|")
            row_walls += cell.linked?(cell.south) ? "   +" : "---+"
          end
          output << row_cells
          output << row_walls
        end

        print output.join("\n") + "\n"
      end

      def draw_title_screen(difficulty, seed)
        # Moved to draw_grid
      end

      def present
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/renderers/terminal_renderer.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/renderers.rb
# frozen_string_literal: true

module Vanilla
  # The Renderers module provides interfaces and implementations for different
  # rendering approaches in the Vanilla game.
  #
  # This module uses Ruby's `autoload` instead of `require_relative` for lazy loading:
  # - Files are only loaded when their corresponding constants are first accessed
  # - This improves startup performance by deferring loading until needed
  # - Helps avoid circular dependencies by delaying actual loading
  # - Reduces memory usage by not loading renderers that aren't used
  # - Makes it easier to extend with new renderers in the future
  #
  # The `File.expand_path` with `__dir__` ensures paths are resolved correctly
  # regardless of the current working directory when the code is executed.
  module Renderers
    # Load rendering-related code
    autoload :Renderer, File.expand_path('renderers/renderer', __dir__)
    autoload :TerminalRenderer, File.expand_path('renderers/terminal_renderer', __dir__)
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/renderers.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/support/tile_type.rb
# frozen_string_literal: true

module Vanilla
  module Support
    class TileType
      VALUES = [
        EMPTY   = ' '.freeze,
        WALL    = '#'.freeze,
        DOOR    = '/'.freeze,
        FLOOR   = '.'.freeze,
        PLAYER  = '@'.freeze,
        MONSTER = 'M'.freeze,
        STAIRS  = '%'.freeze,
        VERTICAL_WALL = '|'.freeze,
        GOLD = '$'.freeze
      ].freeze

      def self.values
        VALUES
      end

      # Check if the provided tile is a valid tile type
      # @param tile [String] The tile character to check
      # @return [Boolean] true if the tile is valid, false otherwise
      def self.valid?(tile)
        VALUES.include?(tile)
      end

      def self.walkable?(tile)
        return false unless valid?(tile)

        # FIX: Treat MONSTER as walkable tile
        # Temporary workaround: Treat MONSTER as walkable until a combat system is implemented.
        # This ensures players can navigate mazes when the only path to stairs crosses a monster.
        [MONSTER, EMPTY, FLOOR, DOOR, STAIRS, GOLD].include?(tile)
      end

      # Check if the tile is a wall type (blocks movement)
      # @param tile [String] The tile character to check
      # @return [Boolean] true if the tile is a wall type, false otherwise
      def self.wall?(tile)
        return false unless valid?(tile)

        [WALL, VERTICAL_WALL].include?(tile)
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/support/tile_type.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/systems/collision_system.rb
# frozen_string_literal: true

require_relative 'system'

module Vanilla
  module Systems
    # System that handles collision detection and response
    class CollisionSystem < System
      # Initialize the collision system
      # @param world [World] The world this system belongs to
      def initialize(world)
        super
        @logger = Vanilla::Logger.instance
        @world.subscribe(:entity_moved, self)
      end

      # Update method called once per frame
      # @param delta_time [Float] Time since last update
      def update(delta_time)
        # Most collision logic is handled via events
        # Any continuous collision detection would go here
      end

      # Handle events from the world
      # @param event_type [Symbol] The type of event
      # @param data [Hash] The event data
      def handle_event(event_type, data)
        return unless event_type == :entity_moved

        entity_id = data[:entity_id]
        entity = @world.get_entity(entity_id)
        return unless entity

        # Get position from data or entity
        if data[:new_position]
          row = data[:new_position][:row]
          column = data[:new_position][:column]
        elsif entity.has_component?(:position)
          position = entity.get_component(:position)
          row = position.row
          column = position.column
        else
          return
        end

        # Find entities at the same position
        entities_at_position = find_entities_at_position(row, column)
        entities_at_position.each do |other_entity|
          next if other_entity.id == entity_id

          # Emit collision event
          emit_event(:entities_collided, {
                       entity_id: entity_id,
                       other_entity_id: other_entity.id,
                       position: { row: row, column: column }
                     })

          handle_specific_collisions(entity, other_entity)
        end
      end

      private

      # Find all entities at a specific position
      # @param row [Integer] The row position
      # @param column [Integer] The column position
      # @return [Array<Entity>] Entities at the specified position
      def find_entities_at_position(row, column)
        entities_with(:position).select do |entity|
          pos = entity.get_component(:position)
          pos.row == row && pos.column == column
        end
      end

      # Handle specific collision types
      # @param entity [Entity] The first entity
      # @param other_entity [Entity] The second entity
      def handle_specific_collisions(entity, other_entity)
        # Handle player-stairs collision
        if (entity.has_tag?(:player) && other_entity.has_tag?(:stairs)) ||
           (entity.has_tag?(:stairs) && other_entity.has_tag?(:player))
          player = entity.has_tag?(:player) ? entity : other_entity
          emit_event(:level_transition_requested, { player_id: player.id })
        end

        # Handle player-item collision for pickup
        if (entity.has_tag?(:player) && other_entity.has_tag?(:item)) ||
           (entity.has_tag?(:item) && other_entity.has_tag?(:player))
          player = entity.has_tag?(:player) ? entity : other_entity
          item = entity.has_tag?(:item) ? entity : other_entity

          if player.has_component?(:inventory) && item.has_component?(:item)
            item_name = item.get_component(:item).name

            emit_event(:item_picked_up, {
                         player_id: player.id,
                         item_id: item.id,
                         item_name: item_name
                       })

            # Queue command to add item to inventory and remove from world
            @world.queue_command(:add_to_inventory, {
                                   player_id: player.id,
                                   item_id: item.id
                                 })

            @world.queue_command(:remove_entity, {
                                   entity_id: item.id
                                 })
          end
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/systems/collision_system.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/systems/input_system.rb
# frozen_string_literal: true

require_relative 'system'

module Vanilla
  module Systems
    class InputSystem < System
      def initialize(world)
        super(world)
        @logger = Vanilla::Logger.instance
        @quit = false
      end

      def update(_unused)
        entities_with(:input).each do |entity|
          process_input(entity)
        end
      end

      def quit?
        @logger.debug("<InputSystem>: Quit? #{@quit}")

        @quit
      end

      private

      def process_input(entity)
        return unless entity.has_tag?(:player)

        game = Vanilla::ServiceRegistry.get(:game)
        return unless game

        input = game.instance_variable_get(:@display).keyboard_handler.wait_for_input
        @logger.debug("InputSystem: Received input #{input.inspect}")

        case input
        when "q", "\u0003" # 'q' or Ctrl+C
          @quit = true
        else
          key_to_direction = {
            "h" => :west,
            "j" => :south,
            "k" => :north,
            "l" => :east
          }
          direction = key_to_direction[input]

          if direction
            @logger.debug("InputSystem: Setting direction #{direction} for entity #{entity.id}")

            entity.get_component(:input).move_direction = direction
          end
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/systems/input_system.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/systems/inventory_render_system.rb
# frozen_string_literal: true

module Vanilla
  module Systems
    # System for rendering inventory UI and handling inventory display
    class InventoryRenderSystem
      # Initialize a new inventory render system
      # @param renderer [Vanilla::Renderers::Renderer] The renderer to use
      # @param logger [Logger] The logger instance
      def initialize(renderer, logger)
        @renderer = renderer
        @logger = logger
        @message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
        @currently_selected_item_index = 0
        @item_action_mode = false
      end

      # Render the inventory UI for an entity
      # @param entity [Entity] The entity whose inventory to display
      # @param x [Integer] The x position to render at (defaults to centered)
      # @param y [Integer] The y position to render at (defaults to centered)
      # @param width [Integer] The width of the inventory panel
      # @param height [Integer] The height of the inventory panel
      # @return [Boolean] Whether the inventory was rendered
      def render_inventory(entity, x = nil, y = nil, width = 30, height = 20)
        return false unless entity && entity.has_component?(:inventory)

        inventory = entity.get_component(:inventory)

        # Default to center if not specified
        terminal_width = @renderer.terminal_width rescue 80
        terminal_height = @renderer.terminal_height rescue 24

        x ||= (terminal_width - width) / 2
        y ||= (terminal_height - height) / 2

        # Draw inventory panel border
        draw_panel_border(x, y, width, height, "Inventory")

        # Draw inventory contents
        inventory.items.each_with_index do |item, index|
          # Skip if we've gone past the displayable area
          break if index > height - 4

          # Determine if this item is currently selected
          is_selected = (index == @currently_selected_item_index)

          # Get display text for the item
          display_string = get_item_display_string(item, index)

          # Determine color based on item type and selection state
          color = get_item_color(item, is_selected)

          # Draw the item text
          draw_text(x + 2, y + 2 + index, display_string, color)
        end

        # Draw equipment section if appropriate
        render_equipment_section(entity, x, y + height - 10, width - 2, 8) if height > 12

        # Draw key instructions at the bottom
        instructions = "[ESC] Close  [a-z] Select  [Enter] Use  [d] Drop  [e] Equip/Unequip"
        draw_text(x + 1, y + height - 1, instructions.ljust(width - 2), :cyan)

        true
      end

      # Render the equipment section showing equipped items
      # @param entity [Entity] The entity whose equipment to display
      # @param x [Integer] The x position to render at
      # @param y [Integer] The y position to render at
      # @param width [Integer] The width of the equipment section
      # @param height [Integer] The height of the equipment section
      def render_equipment_section(entity, x, y, width, height)
        draw_panel_border(x, y, width, height, "Equipment")

        # Display equipped items for each slot
        row = 0

        # Get all equipped items
        equipped_items = entity.get_component(:inventory).items.select do |item|
          item.has_component?(:equippable) && item.get_component(:equippable).equipped?
        end

        # Display equipment by slot
        Vanilla::Components::EquippableComponent::SLOTS.each do |slot|
          break if row >= height - 2

          # Find item for this slot
          item = equipped_items.find do |i|
            i.has_component?(:equippable) && i.get_component(:equippable).slot == slot
          end

          # Display the slot and item (or empty)
          slot_name = slot.to_s.capitalize.gsub('_', ' ')
          item_text = item ? item.get_component(:item).name : "-"

          slot_text = "#{slot_name}: #{item_text}"
          color = item ? :green : :gray

          draw_text(x + 2, y + 2 + row, slot_text.ljust(width - 4), color)
          row += 1
        end
      end

      # Process item selection
      # @param entity [Entity] The entity whose inventory is being displayed
      # @param index [Integer] The index of the selected item
      # @return [Boolean] Whether an item was successfully selected
      def select_item(entity, index)
        return false unless entity && entity.has_component?(:inventory)

        inventory = entity.get_component(:inventory)
        return false if index < 0 || index >= inventory.items.size

        # Set the currently selected item
        @currently_selected_item_index = index
        @item_action_mode = true

        # Get the selected item
        selected_item = inventory.items[index]

        # Show item details or action menu
        show_item_actions(entity, selected_item)

        true
      end

      # Show actions available for a selected item
      # @param entity [Entity] The entity whose inventory contains the item
      # @param item [Entity] The item to show actions for
      def show_item_actions(entity, item)
        return unless item && entity

        # Get item name and type
        item_name = item.get_component(:item).name

        # Use the message system to display options
        options = {}

        # Always offer examine option
        options["Examine #{item_name}"] = -> { show_item_details(item) }

        # Add use option for consumables
        if item.has_component?(:consumable)
          inventory_system = Vanilla::ServiceRegistry.get(:inventory_system)
          options["Use #{item_name}"] = -> {
            inventory_system.use_item(entity, item)
            @item_action_mode = false
          }
        end

        # Add equip/unequip option for equippable items
        if item.has_component?(:equippable)
          inventory_system = Vanilla::ServiceRegistry.get(:inventory_system)

          if item.get_component(:equippable).equipped?
            options["Unequip #{item_name}"] = -> {
              inventory_system.unequip_item(entity, item)
              @item_action_mode = false
            }
          else
            options["Equip #{item_name}"] = -> {
              inventory_system.equip_item(entity, item)
              @item_action_mode = false
            }
          end
        end

        # Add drop option
        options["Drop #{item_name}"] = -> {
          inventory_system = Vanilla::ServiceRegistry.get(:inventory_system)
          level = Vanilla::ServiceRegistry.get(:current_level)
          inventory_system.drop_item(entity, item, level)
          @item_action_mode = false
        }

        # Log options using the message system
        @message_system.log_options(options) if @message_system
      end

      # Handle input for inventory actions
      # @param key [String, Symbol] The key pressed
      # @param entity [Entity] The entity whose inventory is displayed
      # @return [Boolean] Whether the input was handled
      def handle_input(key, entity)
        return false unless entity && entity.has_component?(:inventory)

        inventory = entity.get_component(:inventory)

        if @item_action_mode
          # In item action mode, handle action selection
          case key
          when :escape, "\e"
            @item_action_mode = false
            return true
          when :KEY_UP, 'k'
            @currently_selected_item_index = [@currently_selected_item_index - 1, 0].max
            # Reshow options for newly selected item
            if @currently_selected_item_index < inventory.items.size
              show_item_actions(entity, inventory.items[@currently_selected_item_index])
            end
            return true
          when :KEY_DOWN, 'j'
            @currently_selected_item_index = [@currently_selected_item_index + 1, inventory.items.size - 1].min
            # Reshow options for newly selected item
            if @currently_selected_item_index < inventory.items.size
              show_item_actions(entity, inventory.items[@currently_selected_item_index])
            end
            return true
          end
        else
          # In inventory navigation mode
          case key
          when :escape, "\e"
            # Close inventory
            return true
          when :KEY_UP, 'k'
            @currently_selected_item_index = [@currently_selected_item_index - 1, 0].max
            return true
          when :KEY_DOWN, 'j'
            @currently_selected_item_index = [@currently_selected_item_index + 1, inventory.items.size - 1].min
            return true
          when "\r", :enter
            # Select the current item
            if @currently_selected_item_index < inventory.items.size
              select_item(entity, @currently_selected_item_index)
            end
            return true
          when /[a-z]/
            # Handle letter selection
            index = key.ord - 'a'.ord
            if index >= 0 && index < inventory.items.size
              select_item(entity, index)
              return true
            end
          end
        end

        false
      end

      private

      # Draw text at the specified position with the given color
      # @param x [Integer] The x position
      # @param y [Integer] The y position
      # @param text [String] The text to draw
      # @param color [Symbol] The color to use
      def draw_text(x, y, text, color = :white)
        text.each_char.with_index do |char, index|
          @renderer.draw_character(y, x + index, char, color)
        end
      end

      # Draw a panel border with a title
      # @param x [Integer] The x position of the top-left corner
      # @param y [Integer] The y position of the top-left corner
      # @param width [Integer] The width of the panel
      # @param height [Integer] The height of the panel
      # @param title [String, nil] Optional title to display
      def draw_panel_border(x, y, width, height, title = nil)
        # Draw top and bottom borders
        draw_text(x, y, "+" + "-" * (width - 2) + "+", :white)
        draw_text(x, y + height - 1, "+" + "-" * (width - 2) + "+", :white)

        # Draw side borders
        (height - 2).times do |i|
          draw_text(x, y + i + 1, "|", :white)
          draw_text(x + width - 1, y + i + 1, "|", :white)
        end

        # Draw title if provided
        if title
          # Center the title
          title_x = x + [(width - title.length) / 2, 1].max
          draw_text(title_x, y, " #{title} ", :yellow)
        end
      end

      # Get a color for an item based on its type and selection state
      # @param item [Entity] The item to get the color for
      # @param selected [Boolean] Whether the item is selected
      # @return [Symbol] The color to use
      def get_item_color(item, selected)
        return :cyan if selected

        if item.has_component?(:item)
          item_component = item.get_component(:item)
          case item_component.item_type
          when :weapon
            :red
          when :armor
            :blue
          when :potion
            :green
          when :scroll
            :yellow
          when :key
            :magenta
          when :currency
            :yellow
          else
            :white
          end
        else
          :white
        end
      end

      # Get display string for an item
      # @param item [Entity] The item to get the display string for
      # @param index [Integer] The item's index in the inventory
      # @return [String] The formatted display string
      def get_item_display_string(item, index)
        return "Unknown item" unless item.has_component?(:item)

        item_component = item.get_component(:item)

        # Letter index for selection
        letter = ('a'.ord + index).chr

        # Basic display with letter prefix
        display = "#{letter}) #{item_component.display_string}"

        # Add equipped indicator if applicable
        if item.has_component?(:equippable) && item.get_component(:equippable).equipped?
          display += " [E]"
        end

        display
      end

      # Show detailed information about an item
      # @param item [Entity] The item to show details for
      def show_item_details(item)
        return unless item && item.has_component?(:item)

        item_component = item.get_component(:item)

        # Build the details message
        details = "#{item_component.name}: #{item_component.description}"

        # Add equipment stats if applicable
        if item.has_component?(:equippable)
          equippable = item.get_component(:equippable)
          details += "\nSlot: #{equippable.slot.to_s.capitalize}"

          if equippable.stat_modifiers.any?
            stats = equippable.stat_modifiers.map { |stat, val| "#{stat}: #{val > 0 ? '+' : ''}#{val}" }.join(", ")
            details += "\nStats: #{stats}"
          end
        end

        # Add consumable info if applicable
        if item.has_component?(:consumable)
          consumable = item.get_component(:consumable)
          details += "\nCharges: #{consumable.charges}"

          if consumable.effects.any?
            effects = consumable.effects.map do |effect|
              case effect[:type]
              when :heal
                "Heal +#{effect[:amount]}"
              when :damage
                "Damage #{effect[:amount]}"
              when :buff
                "#{effect[:stat].to_s.capitalize} +#{effect[:amount]} (#{effect[:duration]} turns)"
              else
                effect[:type].to_s.capitalize
              end
            end.join(", ")

            details += "\nEffects: #{effects}"
          end
        end

        # Display the details using the message system
        @message_system.log_message(details, category: :item, importance: :info) if @message_system
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/systems/inventory_render_system.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/systems/inventory_system.rb
# frozen_string_literal: true

module Vanilla
  module Systems
    # System for managing entity inventories and item interactions
    class InventorySystem
      # Create a new inventory system
      # @param logger [Logger] The logger instance
      def initialize(logger)
        @logger = logger
        @message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
      end

      # Add an item to an entity's inventory
      # @param entity [Entity] The entity to add the item to
      # @param item [Entity] The item to add
      # @return [Boolean] Whether the item was successfully added
      def add_item(entity, item)
        return false unless entity && item
        return false unless entity.has_component?(:inventory)

        inventory = entity.get_component(:inventory)
        result = inventory.add(item)

        if result
          log_message("items.add", { item: item_name(item) })
        else
          log_message("items.inventory_full", {}, importance: :warning)
        end

        result
      end

      # Remove an item from an entity's inventory
      # @param entity [Entity] The entity to remove the item from
      # @param item [Entity] The item to remove
      # @return [Entity, nil] The removed item, or nil if not found
      def remove_item(entity, item)
        return nil unless entity && item
        return nil unless entity.has_component?(:inventory)

        inventory = entity.get_component(:inventory)
        result = inventory.remove(item)

        if result
          log_message("items.remove", { item: item_name(item) })
        end

        result
      end

      # Use an item from an entity's inventory
      # @param entity [Entity] The entity using the item
      # @param item [Entity] The item to use
      # @return [Boolean] Whether the item was successfully used
      def use_item(entity, item)
        return false unless entity && item
        return false unless entity.has_component?(:inventory)
        return false unless entity.get_component(:inventory).items.include?(item)

        # Handle different item use cases
        result = if item.has_component?(:consumable)
                   use_consumable(entity, item)
                 elsif item.has_component?(:equippable)
                   toggle_equip(entity, item)
                 else
                   # Default generic use behavior
                   log_message("items.use", { item: item_name(item) })
                   true
                 end

        result
      end

      # Equip an item
      # @param entity [Entity] The entity equipping the item
      # @param item [Entity] The item to equip
      # @return [Boolean] Whether the item was successfully equipped
      def equip_item(entity, item)
        return false unless entity && item
        return false unless entity.has_component?(:inventory)
        return false unless entity.get_component(:inventory).items.include?(item)
        return false unless item.has_component?(:equippable)

        equippable = item.get_component(:equippable)

        # Check if already equipped
        return false if equippable.equipped?

        # Try to equip the item
        result = equippable.equip(entity)

        if result
          log_message("items.equip", { item: item_name(item) })
        else
          log_message("items.cannot_equip", { item: item_name(item) }, importance: :warning)
        end

        result
      end

      # Unequip an item
      # @param entity [Entity] The entity unequipping the item
      # @param item [Entity] The item to unequip
      # @return [Boolean] Whether the item was successfully unequipped
      def unequip_item(entity, item)
        return false unless entity && item
        return false unless entity.has_component?(:inventory)
        return false unless entity.get_component(:inventory).items.include?(item)
        return false unless item.has_component?(:equippable)

        equippable = item.get_component(:equippable)

        # Check if actually equipped
        return false unless equippable.equipped?

        # Try to unequip the item
        result = equippable.unequip(entity)

        if result
          log_message("items.unequip", { item: item_name(item) })
        end

        result
      end

      # Drop an item from an entity's inventory onto the current level
      # @param entity [Entity] The entity dropping the item
      # @param item [Entity] The item to drop
      # @param level [Level] The current game level
      # @return [Boolean] Whether the item was successfully dropped
      def drop_item(entity, item, level)
        return false unless entity && item && level
        return false unless entity.has_component?(:inventory)
        return false unless entity.has_component?(:position)

        # First try to unequip if it's equipped
        if item.has_component?(:equippable) && item.get_component(:equippable).equipped?
          unequip_item(entity, item)
        end

        # Remove from inventory
        removed_item = remove_item(entity, item)
        return false unless removed_item

        # Position the item at the entity's location on the level
        if removed_item.has_component?(:position)
          pos = entity.get_component(:position)
          removed_item.get_component(:position).move_to(pos.row, pos.column)
        else
          # Add a position component if it doesn't have one
          pos = entity.get_component(:position)
          removed_item.add_component(
            Vanilla::Components::PositionComponent.new(row: pos.row, column: pos.column)
          )
        end

        # Add the item to the level's entities
        level.add_entity(removed_item)

        log_message("items.drop", { item: item_name(item) })
        true
      end

      private

      # Get the name of an item
      # @param item [Entity] The item entity
      # @return [String] The name of the item
      def item_name(item)
        return "unknown item" unless item && item.has_component?(:item)

        item.get_component(:item).name
      end

      # Use a consumable item
      # @param entity [Entity] The entity using the item
      # @param item [Entity] The consumable item
      # @return [Boolean] Whether the item was successfully used
      def use_consumable(entity, item)
        consumable = item.get_component(:consumable)
        result = consumable.consume(entity)

        if result
          log_message("items.consume", { item: item_name(item) })

          # Remove the item if it's out of charges
          unless consumable.has_charges?
            remove_item(entity, item)
          end
        else
          log_message("items.cannot_use", { item: item_name(item) }, importance: :warning)
        end

        result
      end

      # Toggle equipment state of an item
      # @param entity [Entity] The entity toggling equipment
      # @param item [Entity] The equippable item
      # @return [Boolean] Whether the toggle was successful
      def toggle_equip(entity, item)
        equippable = item.get_component(:equippable)

        if equippable.equipped?
          unequip_item(entity, item)
        else
          equip_item(entity, item)
        end
      end

      # Log a message through the message system
      # @param key [String, Symbol] The message key to log
      # @param metadata [Hash] Additional metadata for the message
      # @param options [Hash] Additional options like importance
      def log_message(key, metadata = {}, options = {})
        return unless @message_system

        importance = options[:importance] || :normal
        category = options[:category] || :item

        @message_system.log_message(key, {
                                      category: category,
                                      importance: importance,
                                      metadata: metadata
                                    })
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/systems/inventory_system.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/systems/item_interaction_system.rb
# frozen_string_literal: true

module Vanilla
  module Systems
    # System for handling interactions between entities and items in the game world
    class ItemInteractionSystem
      # Create a new item interaction system
      # @param inventory_system [InventorySystem] The inventory system to use
      def initialize(inventory_system)
        @inventory_system = inventory_system
        @message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
      end

      # Process available items at a cell when an entity moves there
      # @param entity [Entity] The entity that moved
      # @param level [Level] The current game level
      # @param row [Integer] The row coordinate
      # @param column [Integer] The column coordinate
      # @return [Boolean] Whether any items were found
      def process_items_at_location(entity, level, row, column)
        return false unless entity && level

        # Find all item entities at this position
        items = find_items_at_position(level, row, column)
        return false if items.empty?

        # Log a message about finding items
        if @message_system
          if items.size == 1
            item = items.first
            item_name = item.has_component?(:item) ? item.get_component(:item).name : "unknown item"
            @message_system.log_message("items.found.single",
                                        { item: item_name },
                                        importance: :normal,
                                        category: :item)
          else
            @message_system.log_message("items.found.multiple",
                                        { count: items.size },
                                        importance: :normal,
                                        category: :item)
          end
        end

        # Auto-pickup implementation could go here
        # For now, just return true to indicate items were found
        true
      end

      # Pickup a specific item at the entity's location
      # @param entity [Entity] The entity picking up the item
      # @param level [Level] The current game level
      # @param item [Entity] The specific item to pick up
      # @return [Boolean] Whether the item was successfully picked up
      def pickup_item(entity, level, item)
        return false unless entity && level && item
        return false unless entity.has_component?(:position)
        return false unless entity.has_component?(:inventory)
        return false unless item.has_component?(:position)

        # Check if the entity is at the same position as the item
        entity_pos = entity.get_component(:position)
        item_pos = item.get_component(:position)

        unless entity_pos.row == item_pos.row && entity_pos.column == item_pos.column
          if @message_system
            @message_system.log_message("items.not_here",
                                        importance: :warning,
                                        category: :item)
          end
          return false
        end

        # Add the item to the entity's inventory
        result = @inventory_system.add_item(entity, item)

        if result
          # Remove the item from the level
          level.remove_entity(item)
        end

        result
      end

      # Pick up all items at the entity's location
      # @param entity [Entity] The entity picking up items
      # @param level [Level] The current game level
      # @return [Integer] The number of items successfully picked up
      def pickup_all_items(entity, level)
        return 0 unless entity && level
        return 0 unless entity.has_component?(:position)

        entity_pos = entity.get_component(:position)
        items = find_items_at_position(level, entity_pos.row, entity_pos.column)

        # Try to pick up each item
        picked_up_count = 0

        items.each do |item|
          if pickup_item(entity, level, item)
            picked_up_count += 1
          end
        end

        # Log a summary message
        if picked_up_count > 0 && @message_system
          if picked_up_count == 1
            @message_system.log_message("items.picked_up.single",
                                        importance: :normal,
                                        category: :item)
          else
            @message_system.log_message("items.picked_up.multiple",
                                        category: :item,
                                        importance: :normal)
          end
        elsif picked_up_count == 0 && items.any? && @message_system
          @message_system.log_message("items.inventory_full",
                                      importance: :warning,
                                      category: :item)
        end

        picked_up_count
      end

      private

      # Find all item entities at a specific position
      # @param level [Level] The current game level
      # @param row [Integer] The row coordinate
      # @param column [Integer] The column coordinate
      # @return [Array<Entity>] The items found at that position
      def find_items_at_position(level, row, column)
        # Get all entities from the level that:
        # 1. Have a position component at the specified row and column
        # 2. Have an item component
        level.all_entities.select do |entity|
          entity.has_component?(:position) &&
            entity.has_component?(:item) &&
            entity.get_component(:position).row == row &&
            entity.get_component(:position).column == column
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/systems/item_interaction_system.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/systems/message_system.rb
# frozen_string_literal: true

require_relative 'system'

module Vanilla
  module Systems
    # System for managing and displaying game messages
    class MessageSystem < System
      MAX_MESSAGES = 100

      # Initialize the message system
      # @param world [World] The world this system belongs to
      def initialize(world)
        super
        @message_queue = []

        # Subscribe to relevant events
        @world.subscribe(:entity_moved, self)
        @world.subscribe(:entities_collided, self)
        @world.subscribe(:level_transition_requested, self)
        @world.subscribe(:level_transitioned, self)
        @world.subscribe(:item_picked_up, self)
        @world.subscribe(:damage_dealt, self)
        @world.subscribe(:entity_died, self)
      end

      # Update method called once per frame
      # @param delta_time [Float] Time since last update
      def update(_delta_time)
        # Process any queued messages
        process_message_queue
      end

      # Handle events from the world
      # @param event_type [Symbol] The type of event
      # @param data [Hash] The event data
      def handle_event(event_type, data)
        case event_type
        when :entity_moved
          entity = @world.get_entity(data[:entity_id])
          if entity&.has_tag?(:player)
            add_message("movement.player_moved", importance: :low)
          end

        when :entities_collided
          # Handle collision messages based on entity types
          entity = @world.get_entity(data[:entity_id])
          other = @world.get_entity(data[:other_entity_id])

          # Player collisions
          if entity&.has_tag?(:player) && other&.has_tag?(:item)
            add_message("collision.player_item", importance: :normal)
          elsif entity&.has_tag?(:player) && other&.has_tag?(:monster)
            add_message("collision.player_monster", importance: :high)
          elsif entity&.has_tag?(:player) && other&.has_tag?(:stairs)
            add_message("collision.player_stairs", importance: :normal)
          end

        when :level_transition_requested
          add_message("level.stairs_found", importance: :normal)

        when :level_transitioned
          difficulty = data[:difficulty]
          add_message("level.descended", { level: difficulty }, importance: :high)

        when :item_picked_up
          item_name = data[:item_name] || "item"
          add_message("item.picked_up", { item: item_name }, importance: :normal)

        when :damage_dealt
          attacker = @world.get_entity(data[:attacker_id])
          target = @world.get_entity(data[:target_id])
          damage = data[:damage]

          if attacker&.has_tag?(:player)
            add_message("combat.player_hit", { target: target&.name || "enemy", damage: damage }, importance: :normal)
          elsif target&.has_tag?(:player)
            add_message("combat.player_damaged", { attacker: attacker&.name || "enemy", damage: damage }, importance: :high)
          end

        when :entity_died
          entity = @world.get_entity(data[:entity_id])
          @world.get_entity(data[:killer_id])

          if entity&.has_tag?(:monster)
            add_message("combat.monster_died", { monster: entity.name || "monster" }, importance: :normal)
          elsif entity&.has_tag?(:player)
            add_message("combat.player_died", importance: :critical)
          end
        end
      end

      # Add a message to the queue
      # @param key [String] The message key/text
      # @param metadata [Hash] Additional message data
      # @param importance [Symbol] Message importance (:low, :normal, :high, :critical)
      def add_message(key, metadata = {}, importance: :normal)
        message = {
          key: key,
          metadata: metadata,
          importance: importance,
          timestamp: Time.now
        }

        @message_queue << message
        trim_message_queue if @message_queue.size > MAX_MESSAGES
      end

      private

      # Process and display messages in the queue
      def process_message_queue
        # Implementation depends on the display system
        # This would typically render messages to a message log area
      end

      # Keep message queue at a reasonable size
      def trim_message_queue
        # Keep the most recent messages, prioritizing by importance
        @message_queue.sort_by! { |msg| [msg[:timestamp], importance_value(msg[:importance])] }
        @message_queue = @message_queue.last(MAX_MESSAGES)
      end

      # Convert importance symbol to numeric value for sorting
      # @param importance [Symbol] The importance level
      # @return [Integer] Numeric importance value
      def importance_value(importance)
        case importance
        when :critical then 3
        when :high then 2
        when :normal then 1
        when :low then 0
        else 0
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/systems/message_system.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/systems/monster_system.rb
# frozen_string_literal: true

require_relative '../entities'

module Vanilla
  module Systems
    class MonsterSystem < System
      MAX_MONSTERS = {
        1 => 2,
        2 => 4,
        3 => 6,
        4 => 8
      }.freeze

      def initialize(world, player:, logger: nil)
        super(world)
        @player = player
        @monsters = []
        @logger = logger || Vanilla::Logger.instance
        @rng = Random.new
      end

      attr_reader :monsters

      def spawn_monsters(level)
        @monsters.clear
        count = determine_monster_count(level)
        @logger.info("Spawning #{count} monsters at level #{level}")
        count.times { spawn_monster(level) }
      end

      def update(_delta_time = nil)
        @monsters.reject! { |m| !m.alive? }
      end

      def monster_at(row, column)
        @monsters.find do |monster|
          position = monster.get_component(:position)
          position.row == row && position.column == column
        end
      end

      def player_collision?
        player_pos = @player.get_component(:position)
        monster_at(player_pos.row, player_pos.column) != nil
      end

      private

      def determine_monster_count(level)
        max = MAX_MONSTERS[level] || MAX_MONSTERS.values.last
        @rng.rand((max / 2.0).ceil..max)
      end

      def spawn_monster(level)
        grid = @world.current_level.grid
        cell = find_spawn_location(grid)
        return nil unless cell

        health = 10 + (level * 2)
        damage = 1 + (level / 2)

        monster_types = {
          'goblin' => 0.4,
          'orc' => 0.3,
          'troll' => 0.2,
          'ogre' => 0.1
        }

        monster_type = select_weighted_monster_type(monster_types)

        case monster_type
        when 'orc'
          health += 5
          damage += 1
        when 'troll'
          health += 10
          damage += 2
        when 'ogre'
          health += 15
          damage += 3
        end

        monster = Vanilla::EntityFactory.create_monster(monster_type, cell.row, cell.column, health, damage)
        cell.tile = Vanilla::Support::TileType::MONSTER
        @monsters << monster
        @world.current_level.add_entity(monster) # Sync with level entities
        @logger.info("Spawned #{monster_type} at [#{cell.row}, #{cell.column}] with #{health} HP and #{damage} damage")
        monster
      end

      def find_spawn_location(grid)
        walkable_cells = []
        grid.each_cell do |cell|
          next unless cell.tile == Vanilla::Support::TileType::EMPTY

          player_pos = @player.get_component(:position)
          distance = (cell.row - player_pos.row).abs + (cell.column - player_pos.column).abs
          next if distance < 5

          has_nearby_monster = @monsters.any? do |m|
            m_pos = m.get_component(:position)
            nearby_distance = (cell.row - m_pos.row).abs + (cell.column - m_pos.column).abs
            nearby_distance < 3
          end
          next if has_nearby_monster

          walkable_cells << cell
        end
        walkable_cells.empty? ? nil : walkable_cells.sample(random: @rng)
      end

      def select_weighted_monster_type(types)
        total = types.values.sum
        roll = @rng.rand(total)
        running_total = 0
        types.each do |type, probability|
          running_total += probability
          return type if roll <= running_total
        end
        types.keys.first
      end

      def valid_move?(row, column)
        grid = @world.current_level.grid
        cell = grid[row, column]
        return false unless cell
        return false unless Vanilla::Support::TileType.walkable?(cell.tile)

        @monsters.none? do |other|
          other_pos = other.get_component(:position)
          other_pos.row == row && other_pos.column == column
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/systems/monster_system.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/systems/movement_system.rb
# frozen_string_literal: true

# lib/vanilla/systems/movement_system.rb
require_relative 'system'

module Vanilla
  module Systems
    class MovementSystem < System
      def initialize(world_or_grid)
        super(world_or_grid)
        @logger = Vanilla::Logger.instance
      end

      def update(_delta_time)
        movable_entities = entities_with(:position, :movement, :input, :render)
        @logger.debug("Found #{movable_entities.size} movable entities")
        movable_entities.each { |entity| process_entity_movement(entity) }
      end

      def process_entity_movement(entity)
        input = entity.get_component(:input)
        direction = input.move_direction
        @logger.debug("Entity #{entity.id} direction: #{direction}")
        return unless direction

        success = move(entity, direction)
        @logger.debug("Movement success: #{success}")
        input.move_direction = nil if success
      end

      def move(entity, direction)
        @logger.debug("Starting move for entity #{entity.id}")

        position = entity.get_component(:position)
        @logger.debug("Position: [#{position.row}, #{position.column}]")

        render = entity.get_component(:render)
        @logger.debug("Render: to_hash #{render.to_hash}")

        movement = entity.get_component(:movement)
        @logger.debug("Movement active: #{movement.active?}")
        return false unless movement&.active?

        @logger.debug("Movement direction: #{direction}")

        grid = @world.current_level.grid
        @logger.debug("Grid rows: #{grid.rows}, columns: #{grid.columns}")
        return false unless grid

        current_cell = grid[position.row, position.column]
        @logger.debug("Current cell: #{current_cell ? "[#{current_cell.row}, #{current_cell.column}] Tile: #{current_cell.tile}" : 'nil'}")
        return false unless current_cell

        target_cell = get_target_cell(current_cell, direction)
        @logger.debug("Target cell: #{target_cell ? "[#{target_cell.row}, #{target_cell.column}] Tile: #{target_cell.tile}" : 'nil'}")
        return false unless target_cell && can_move_to?(current_cell, target_cell, direction)

        old_position = { row: position.row, column: position.column }
        position.set_position(target_cell.row, target_cell.column)

        handle_special_cell_attributes(entity, target_cell)
        log_movement(entity, direction, old_position, { row: position.row, column: position.column })

        emit_event(
          :entity_moved,
          {
            entity_id: entity.id,
            old_position: old_position,
            new_position: { row: position.row, column: position.column },
            direction: direction
          }
        )

        grid[old_position[:row], old_position[:column]].tile = Vanilla::Support::TileType::EMPTY
        grid[position.row, position.column].tile = render.character

        true
      rescue StandardError => e
        @logger.error("Error in move: #{e.message}\n#{e.backtrace.join("\n")}")
        false
      end

      private

      def can_process?(entity)
        result = entity.has_component?(:position) && entity.has_component?(:movement) && entity.has_component?(:render)
        @logger.debug("Can process entity #{entity.id}? #{result}")
        result
      end

      def get_target_cell(cell, direction)
        case direction
        when :north then cell.north
        when :south then cell.south
        when :east then cell.east
        when :west then cell.west
        else nil
        end
      end

      def can_move_to?(current_cell, target_cell, _direction)
        linked = current_cell.linked?(target_cell)
        walkable = Vanilla::Support::TileType.walkable?(target_cell.tile)
        @logger.debug("Can move to [#{target_cell.row}, #{target_cell.column}]? Linked: #{linked}, Walkable: #{walkable}")
        linked && walkable
      end

      def handle_special_cell_attributes(entity, target_cell)
        @logger.debug("Checking cell: [#{target_cell.row}, #{target_cell.column}]")
        if target_cell.tile == Vanilla::Support::TileType::STAIRS
          @logger.info("Stairs at [#{target_cell.row}, #{target_cell.column}] reached by entity #{entity.id}")
          emit_event(:stairs_found, { entity_id: entity.id })
          queue_command(:change_level, { difficulty: @world.current_level.difficulty + 1, player_id: entity.id })
        end
      end

      def log_movement(_entity, direction, old_position, new_position)
        @logger.info("Entity moved #{direction} from [#{old_position[:row]}, #{old_position[:column]}] to [#{new_position[:row]}, #{new_position[:column]}]")
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/systems/movement_system.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/systems/render_system.rb
# frozen_string_literal: true

module Vanilla
  module Systems
    class RenderSystem < System
      def initialize(world, difficulty, seed)
        super(world)
        @renderer = Vanilla::Renderers::TerminalRenderer.new
        @difficulty = difficulty
        @seed = seed
        @logger = Vanilla::Logger.instance
      end

      def update(_delta_time)
        @renderer.clear
        @renderer.draw_title_screen(@difficulty, @seed)
        render_grid
        render_messages
        @renderer.present
      end

      private

      def render_grid
        grid = @world.current_level&.grid
        @renderer.draw_grid(grid, @world.current_level&.algorithm&.demodulize || "Unknown")
      end

      def render_messages
        message_system = Vanilla::ServiceRegistry.get(:message_system)
        game = Vanilla::ServiceRegistry.get(:game)
        turn = game&.turn || 0
        print "\n=== MESSAGES ===\n"
        if message_system
          print "Turn #{turn}: Player moved.\n"
        else
          print "No messages yet. Play the game to see messages here.\n"
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/systems/render_system.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/systems/render_system_factory.rb
# frozen_string_literal: true

module Vanilla
  module Systems
    # Factory for creating render systems
    # @deprecated - Use RenderSystem.new(world) directly
    class RenderSystemFactory
      # Create a new render system
      # @param world [World] The world to use (optional for compatibility)
      # @return [RenderSystem] A new render system
      def self.create(world = nil)
        if world
          # New ECS-style initialization
          RenderSystem.new(world)
        else
          # Legacy initialization - provide a warning
          warn "[DEPRECATED] RenderSystemFactory.create() without world parameter is deprecated."
          warn "Use RenderSystem.new(world) instead."

          renderer = Vanilla::Renderers::TerminalRenderer.new
          legacy_render_system = Class.new(RenderSystem) do
            # Override initialize to maintain compatibility
            def initialize(renderer)
              @renderer = renderer
              @logger = Vanilla::Logger.instance
            end

            # Legacy render method
            def render(entities, grid)
              # Simulate what update would do, but with external entities/grid
              @renderer.clear
              @renderer.draw_grid(grid)

              drawable_entities = entities.select do |entity|
                entity.has_component?(:position) && entity.has_component?(:render)
              end

              drawable_entities.sort_by! { |e| e.get_component(:render).layer || 0 }

              drawable_entities.each do |entity|
                render_component = entity.get_component(:render)
                position = entity.get_component(:position)

                @renderer.draw_character(
                  position.row,
                  position.column,
                  render_component.respond_to?(:char) ? render_component.char : render_component.character,
                  render_component.color
                )
              end

              @renderer.present
            end
          end

          legacy_render_system.new(renderer)
        end
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/systems/render_system_factory.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/systems/system.rb
# frozen_string_literal: true

module Vanilla
  module Systems
    # Base class for all systems in the ECS architecture.
    # Systems contain the behavior and logic of the game.
    class System
      attr_reader :world

      # Initialize a new system
      # @param world [World] The world this system belongs to
      def initialize(world)
        @world = world
      end

      # Update method called once per frame
      # @param delta_time [Float] Time since last update
      def update(delta_time)
        # Override in subclasses
      end

      # Handle an event from the world
      # @param event_type [Symbol] The type of event
      # @param data [Hash] The event data
      def handle_event(event_type, data)
        # Override in subclasses
      end

      # Helper method to find entities with specific components
      # @param component_types [Array<Symbol>] Component types to query for
      # @return [Array<Entity>] Entities with all the specified component types
      def entities_with(*component_types)
        @world.query_entities(component_types)
      end

      # Helper method to emit an event
      # @param event_type [Symbol] The type of event
      # @param data [Hash] The event data
      def emit_event(event_type, data = {})
        @world.emit_event(event_type, data)
      end

      # Helper method to queue a command
      # @param command_type [Symbol] The type of command
      # @param params [Hash] The command parameters
      def queue_command(command_type, params = {})
        @world.queue_command(command_type, params)
      end
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/systems/system.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/systems.rb
# frozen_string_literal: true

module Vanilla
  # Systems module contains the logic for processing entities and components
  # in the Entity-Component-System architecture.
  #
  # Unlike components, which are primarily data containers, systems contain
  # the logic for processing entities with specific component combinations.
  # This separation of data (components) and logic (systems) is a key feature
  # of the ECS pattern.
  #
  # Each system typically operates on entities that have a specific set of
  # components, applying transformations, calculations, or other processing
  # to those entities.
  module Systems
    # Load base system class first
    require_relative 'systems/system'

    # Load other system classes
    require_relative 'systems/input_system'
    require_relative 'systems/movement_system'
    require_relative 'systems/collision_system'
    require_relative 'systems/message_system'
    require_relative 'systems/monster_system'
    require_relative 'systems/render_system'
    require_relative 'systems/render_system_factory'
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/systems.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla/world.rb
# frozen_string_literal: true

module Vanilla
  # The World class is the central container for all entities and systems.
  # It manages entities, systems, events, and commands.
  #
  # World acts as a coordinator, not a decision-maker.
  #  It runs systems in order (update loop) and provides access to entities/components.

  class World
    attr_reader :entities, :systems, :display, :current_level

    # Initialize a new world
    def initialize
      @entities = {}
      @systems = []

      @display = DisplayHandler.new
      @logger = Vanilla::Logger.instance

      @current_level = nil
      @level_changed = false

      @event_subscribers = Hash.new { |h, k| h[k] = [] }
      @event_queue = Queue.new
      @command_queue = Queue.new
    end

    # Works by delegating it to InputSystem
    def quit?
      input_system, _priority = @systems.find { |system, _priority| system.is_a?(Vanilla::Systems::InputSystem) }

      input_system&.quit? || false
    end

    # Check if the level changed this frame (resets after checking)
    def level_changed?
      changed = @level_changed
      @level_changed = false # Reset after querying
      changed
    end

    # Add an entity to the world
    # @param entity [Entity] The entity to add
    # @return [Entity] The added entity
    def add_entity(entity)
      @entities[entity.id] = entity
      entity
    end

    # Remove an entity from the world
    # @param entity_id [String] The ID of the entity to remove
    # @return [Entity, nil] The removed entity or nil if not found
    def remove_entity(entity_id)
      @entities.delete(entity_id)
    end

    # Get an entity by ID
    # @param entity_id [String] The ID of the entity to find
    # @return [Entity, nil] The entity or nil if not found
    def get_entity(entity_id)
      @entities[entity_id]
    end

    # Find the first entity with a specific tag
    # @param tag [Symbol, String] The tag to find
    # @return [Entity, nil] The first entity with the tag or nil if none found
    def find_entity_by_tag(tag)
      @entities.values.find { |e| e.has_tag?(tag) }
    end

    # Query entities with specific component types
    # @param component_types [Array<Symbol>] The component types to find
    # @return [Array<Entity>] Entities with all specified component types
    def query_entities(component_types)
      return @entities.values if component_types.empty?

      @entities.values.select do |entity|
        component_types.all? { |type| entity.has_component?(type) }
      end
    end

    # Add a system to the world with a priority
    # @param system [System] The system to add
    # @param priority [Integer] The priority for update order (lower numbers run first)
    # @return [System] The added system
    def add_system(system, priority = 0)
      @systems << [system, priority]

      @systems.sort_by! { |_system, system_priority| system_priority }

      system
    end

    # Update all systems and process events and commands
    # @param delta_time [Float] The time since the last update
    def update(_unused)
      # Update all systems
      @systems.each do |system, _| # rubocop:disable Style/HashEachMethods
        system.update(nil)
      end

      # IMPORTANT:
      # Commands are processed before events to ensure any events triggered by commands
      # are handled in the same update cycle

      # Process queued commands
      process_commands

      # Process events after systems have updated
      process_events
    end

    # Queue a command to be processed
    # @param command_type [Symbol] The type of command
    # @param params [Hash] The command parameters
    def queue_command(command_type, params = {})
      @command_queue << [command_type, params]
    end

    # Emit an event to be processed
    # @param event_type [Symbol] The type of event
    # @param data [Hash] The event data
    def emit_event(event_type, data = {})
      @event_queue << [event_type, data]
    end

    # Subscribe a system to an event
    # @param event_type [Symbol] The type of event
    # @param subscriber [Object] The object that will handle the event
    def subscribe(event_type, subscriber)
      @event_subscribers[event_type] << subscriber
    end

    # Unsubscribe a system from an event
    # @param event_type [Symbol] The type of event
    # @param subscriber [Object] The object to unsubscribe
    def unsubscribe(event_type, subscriber)
      @event_subscribers[event_type].delete(subscriber)
    end

    # Set the current level
    # @param level [Level] The level to set
    def set_level(level)
      @current_level = level
    end

    # Get the grid from the current level
    # @return [Grid, nil] The grid or nil if no level is set
    def grid
      @current_level&.grid
    end

    private

    # Process all queued events
    def process_events
      until @event_queue.empty?
        event_type, data = @event_queue.pop
        @event_subscribers[event_type].each do |subscriber|
          subscriber.handle_event(event_type, data)
        end
      end
    end

    # Process all queued commands
    def process_commands
      until @command_queue.empty?
        command_type, params = @command_queue.pop
        handle_command(command_type, params)
      end
    end

    # Handle a specific command
    # @param command_type [Symbol] The type of command
    # @param params [Hash] The command parameters
    def handle_command(command_type, params)
      case command_type
      when :change_level
        change_level(params[:difficulty], params[:player_id])
      when :add_entity
        add_entity(params[:entity])
      when :remove_entity
        remove_entity(params[:entity_id])
      when :add_to_inventory
        add_to_inventory(params[:player_id], params[:item_id])
        # Other command handlers...
      end
    end

    # TODO: Consider refactoring it into smaller methods to improve maintainability.
    # Setting the flag (@level_changed) after level transition ensures the rendering system knows when to refresh the display, which is essential for the game loop.
    # The change_level method is quite long and handles multiple responsibilities.
    def change_level(difficulty, player_id)
      level_generator = LevelGenerator.new
      new_level = level_generator.generate(difficulty)
      player = get_entity(player_id)
      if player
        position = player.get_component(:position)
        entrance_row = new_level.respond_to?(:entrance_row) ? new_level.entrance_row : 0
        entrance_column = new_level.respond_to?(:entrance_column) ? new_level.entrance_column : 0
        position.set_position(entrance_row, entrance_column)
        new_level.add_entity(player) # Ensure player is added to new level's entities
      end
      set_level(new_level)

      # Spawn monsters for the new level
      monster_system = systems.find { |sys, _| sys.is_a?(Vanilla::Systems::MonsterSystem) }&.first
      monster_system&.spawn_monsters(difficulty)

      emit_event(:level_transitioned, { difficulty: difficulty, player_id: player_id })

      # Flag to inform world that there's a new level to be rendered
      @level_changed = true
    end

    # Add an item to a player's inventory
    # @param player_id [String] The ID of the player entity
    # @param item_id [String] The ID of the item entity
    def add_to_inventory(player_id, item_id)
      player = get_entity(player_id)
      item = get_entity(item_id)

      return unless player && item
      return unless player.has_component?(:inventory) && item.has_component?(:item)

      inventory = player.get_component(:inventory)
      inventory.add_item(item)
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla/world.rb

# Begin /Users/davidslv/projects/vanilla/lib/vanilla.rb
# frozen_string_literal: true

STDOUT.sync = true

require 'pry'
require 'logger'
require 'securerandom'
require 'i18n'

module Vanilla
  # New ECS Framework
  require_relative 'vanilla/world'
  require_relative 'vanilla/keyboard_handler'
  require_relative 'vanilla/display_handler'
  require_relative 'vanilla/entity_factory'
  require_relative 'vanilla/level_generator'
  require_relative 'vanilla/game'

  # Systems
  require_relative 'vanilla/systems'

  # game
  require_relative 'vanilla/input_handler'
  require_relative 'vanilla/logger'
  require_relative 'vanilla/level'

  # map
  require_relative 'vanilla/map_utils'
  require_relative 'vanilla/map'

  # renderers
  require_relative 'vanilla/renderers'

  # algorithms
  require_relative 'vanilla/algorithms'

  # support
  require_relative 'vanilla/support/tile_type'

  # components (entity component system)
  require_relative 'vanilla/components'

  # entities
  require_relative 'vanilla/entities'

  # event system
  require_relative 'vanilla/events'

  # message system
  require_relative 'vanilla/message_system'

  # inventory system
  require_relative 'vanilla/inventory'

  # Setup I18n if it hasn't been set up already (like in tests)
  if I18n.load_path.empty?
    I18n.load_path += Dir[File.expand_path('../config/locales/*.yml', __dir__)]
    I18n.default_locale = :en
  end

  # Have a seed for the random number generator
  # This is used to generate the same map for the same seed
  # This is useful for testing
  $seed = nil

  # Service registry to replace global variables
  # Implementation of Service Locator pattern
  class ServiceRegistry
    @@services = {}

    def self.register(key, service)
      @@services[key] = service
    end

    def self.get(key)
      @@services[key]
    end

    def self.unregister(key)
      @@services.delete(key)
    end

    def self.clear
      @@services.clear
    end
  end

  # Get the current game turn
  # @return [Integer] The current game turn or 0 if the game is not running
  def self.game_turn
    game = ServiceRegistry.get(:game)
    game&.turn || 0
  end

  # Get the current event manager
  # @return [EventManager] The current event manager or nil if not available
  def self.event_manager
    game = ServiceRegistry.get(:game)
    game&.instance_variable_get(:@event_manager)
  end

  # Game class implements the core game loop pattern and orchestrates the game's
  # main components. It manages the game lifecycle from initialization to cleanup.
  #
  # The Game Loop pattern provides a way to:
  # 1. Process player input
  # 2. Update game state
  # 3. Render the updated state
  # 4. Repeat until the game ends
  #
  # This implementation uses a turn-based approach appropriate for roguelike games,
  # where updates happen in discrete steps rather than in real-time.

  class Scheduler
    def initialize
      @entities = []
    end

    def register(entity)
      @entities << entity
    end

    def unregister(entity)
      @entities.delete(entity)
    end

    def update
      @entities.each { |entity| entity.update }
    end
  end

  # Entry point for starting the game
  # Creates a new Game instance and manages its lifecycle
  # @return [void]
  def self.run
    # Skip game initialization in test mode
    return if ENV['VANILLA_TEST_MODE'] == 'true'

    game = Game.new
    begin
      game.start
    ensure
      game.cleanup
    end
  end
end
# End /Users/davidslv/projects/vanilla/lib/vanilla.rb

# Begin /Users/davidslv/projects/vanilla/bin/play.rb
#!/usr/bin/env ruby
# frozen_string_literal: true

# Add lib directory to load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'vanilla'
require 'vanilla/game'

# Parse command line arguments

require 'optparse'

# Parse command line arguments
options = {
  seed: Random.new_seed,
  difficulty: 1
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} [options]"

  opts.on("--seed=SEED", Integer, "Set random seed") do |seed|
    options[:seed] = seed
  end

  opts.on("--difficulty=LEVEL", Integer, "Set difficulty level (1-5)") do |level|
    if level.between?(1, 5)
      options[:difficulty] = level
    else
      puts "Difficulty must be between 1 and 5, defaulting to 1"
      options[:difficulty] = 1
    end
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

# Create and start the game with ECS architecture
game = Vanilla::Game.new(options)
game.start
# End /Users/davidslv/projects/vanilla/bin/play.rb

