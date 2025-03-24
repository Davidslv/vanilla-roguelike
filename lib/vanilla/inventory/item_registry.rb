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
