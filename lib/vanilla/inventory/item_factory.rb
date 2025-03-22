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
        item = Vanilla::Components::Entity.new

        # Add a render component
        item.add_component(
          Vanilla::Components::RenderComponent.new(
            options[:character] || '?',
            options[:color] || nil,
            options[:layer] || 5,
            options[:entity_type] || 'item'
          )
        )

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