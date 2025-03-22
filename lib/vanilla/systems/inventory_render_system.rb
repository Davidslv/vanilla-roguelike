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