# frozen_string_literal: true

require_relative 'system'
require_relative '../messages/message'
require_relative '../messages/message_log'
require_relative '../messages/message_manager'

module Vanilla
  module Systems
    class MessageSystem < System
      MAX_MESSAGES = 100

      # --- Initialization ---
      def initialize(world)
        super
        @message_queue = []
        @logger = Vanilla::Logger.instance
        @manager = Vanilla::Messages::MessageManager.new
        @last_collision_data = nil
        @last_loot_data = nil
        @world.subscribe(:entity_moved, self)
        @world.subscribe(:monster_spawned, self)
        @world.subscribe(:monster_despawned, self)
        @world.subscribe(:entities_collided, self)
        @world.subscribe(:level_transition_requested, self)
        @world.subscribe(:level_transitioned, self)
        @world.subscribe(:item_picked_up, self)
        @world.subscribe(:combat_attack, self)
        @world.subscribe(:combat_damage, self)
        @world.subscribe(:combat_miss, self)
        @world.subscribe(:combat_death, self)
        @world.subscribe(:combat_flee_success, self)
        @world.subscribe(:combat_flee_failed, self)
        @world.subscribe(:loot_dropped, self)
        Vanilla::ServiceRegistry.register(:message_system, self)
      end

      # --- Core Lifecycle Methods ---
      def update(_delta_time)
        @logger.debug("[MessageSystem] update() called, queue size: #{@message_queue.size}")
        process_message_queue
      end

      def render(renderer)
        @manager.render(renderer)
      end

      # --- Interaction/State Methods ---
      def selection_mode?
        @manager.selection_mode
      end

      def toggle_selection_mode
        @manager.toggle_selection_mode
      end

      def valid_menu_option?(key)
        @manager.options.any? { |opt| opt[:key] == key }
      end

      def handle_input(key)
        return unless key.is_a?(String) && key.length == 1

        # Check if we're in selection mode or if there are options available
        if @manager.selection_mode? || !@manager.options.empty?
          option = @manager.options.find { |opt| opt[:key] == key }
          return unless option

          # Handle combat callbacks specially
          case option[:callback]
          when :attack_monster
            handle_attack_monster_callback
            # Don't exit selection mode yet - let combat happen first
            # Selection mode will be exited when combat ends (in handle_combat_death)
            clear_previous_combat_options
            @logger.info("[MessageSystem] Selected attack option, combat will start")
          when :run_away_from_monster
            handle_run_away_callback
            # Run away completes immediately, so exit selection mode
            clear_previous_combat_options
            @manager.toggle_selection_mode if @manager.selection_mode?
            @logger.info("[MessageSystem] Selected run away option, cleared menu")
          when :show_inventory
            handle_inventory_callback
            # Process message queue immediately so inventory appears right away
            process_message_queue
            # Don't exit selection mode - we'll show inventory items
          when :pickup_loot
            handle_pickup_loot_callback
            process_message_queue
          when :ignore_loot
            handle_ignore_loot_callback
            process_message_queue
          when :select_item
            handle_item_selection(option[:item_id])
            # Process message queue immediately so item actions appear right away
            process_message_queue
            # Don't exit selection mode - we'll show item actions
          when :use_item, :drop_item
            handle_item_action_callback(option[:callback], option[:item_id])
            # Process message queue immediately so action result appears right away
            process_message_queue
          else
            @world.queue_command(option[:callback], {})
            # For non-combat options, exit selection mode immediately
            clear_previous_combat_options
            @manager.toggle_selection_mode if @manager.selection_mode?
            @logger.info("[MessageSystem] Selected option #{key}")
          end
        end
      end

      def handle_attack_monster_callback
        return unless @last_collision_data

        player = @world.get_entity(@last_collision_data[:entity_id])
        monster = @world.get_entity(@last_collision_data[:other_entity_id])
        
        # Check if entities still exist (monster might have died)
        unless player && monster
          @logger.warn("[MessageSystem] Cannot attack: player or monster no longer exists. Clearing collision data.")
          @last_collision_data = nil
          return
        end

        # Verify entities are still at the same position (player might have moved)
        player_pos = player.get_component(:position)
        monster_pos = monster.get_component(:position)
        unless player_pos && monster_pos && 
               player_pos.row == monster_pos.row && 
               player_pos.column == monster_pos.column
          @logger.warn("[MessageSystem] Cannot attack: player and monster are no longer at the same position. Clearing collision data.")
          @last_collision_data = nil
          return
        end

        # Create and execute attack command immediately
        attack_command = Vanilla::Commands::AttackCommand.new(player, monster)
        attack_command.execute(@world)
        @logger.info("[MessageSystem] Executed AttackCommand immediately for player #{player.id} -> monster #{monster.id}")
        
        # Process events immediately so combat messages appear
        # Use send to access private method
        @world.send(:process_events) if @world.respond_to?(:process_events, true)
        
        # Update message system to process any queued messages
        update(nil)
      end

      def handle_run_away_callback
        return unless @last_collision_data

        player = @world.get_entity(@last_collision_data[:entity_id])
        monster = @world.get_entity(@last_collision_data[:other_entity_id])

        # Check if entities still exist
        unless player && monster
          @logger.warn("[MessageSystem] Cannot run away: player or monster no longer exists. Clearing collision data.")
          @last_collision_data = nil
          return
        end

        # Create and queue run away command
        run_away_command = Vanilla::Commands::RunAwayCommand.new(player, monster)
        @world.queue_command(run_away_command)
        @logger.info("[MessageSystem] Queued RunAwayCommand for player #{player.id} from monster #{monster.id}")
      end

      # --- Event Handling ---
      def handle_event(event_type, data)
        case event_type
        when :entity_moved
          entity = @world.get_entity(data[:entity_id])
          if entity&.has_tag?(:player)
            add_message("movement.moved", metadata: { x: data[:new_position][:row], y: data[:new_position][:column] }, importance: :low)
          end
        when :monster_spawned
          add_message("monster.spawned", metadata: { type: @world.get_entity(data[:monster_id]).name, x: data[:position][:row], y: data[:position][:column] },
                                         importance: :normal)
        when :monster_despawned
          add_message("monster.died", metadata: { monster: @world.get_entity(data[:monster_id])&.name || "monster" }, importance: :normal)
        when :entities_collided
          @logger.debug("[MessageSystem] Handling entities_collided event: entity_id=#{data[:entity_id]}, other_entity_id=#{data[:other_entity_id]}")
          entity = @world.get_entity(data[:entity_id])
          other = @world.get_entity(data[:other_entity_id])
          @logger.debug("[MessageSystem] Entity: #{entity&.id}, tags: #{entity&.tags&.inspect}, Other: #{other&.id}, tags: #{other&.tags&.inspect}")
          if entity&.has_tag?(:player) && other&.has_tag?(:monster)
            @logger.info("[MessageSystem] Player-monster collision detected, adding combat message")
            # Clear options from previous combat collision messages to prevent duplicates
            clear_previous_combat_options
            # Store collision data for attack/run away commands
            @last_collision_data = data
            enemy_name = other.name || "Monster"
            add_message("combat.collision",
              metadata: { enemy: enemy_name, x: data[:position][:row], y: data[:position][:column] },
              options: [
                { key: '1', content: "Attack #{enemy_name} [1]", callback: :attack_monster },
                { key: '2', content: "Run Away [2]", callback: :run_away_from_monster }
              ],
              importance: :high,
              category: :combat)
            @logger.debug("[MessageSystem] Combat collision message added to queue with 2 options")
            # Process the message queue immediately so message appears right away
            process_message_queue
            # Automatically enter selection mode so player can immediately choose an option
            @manager.toggle_selection_mode unless @manager.selection_mode?
            @logger.debug("[MessageSystem] Auto-enabled selection mode for combat menu")
          elsif entity&.has_tag?(:player) && other&.has_tag?(:stairs)
            add_message("level.stairs_found", importance: :normal)
            process_message_queue
          else
            @logger.debug("[MessageSystem] Collision not handled: entity tags don't match player-monster or player-stairs")
          end
        when :level_transition_requested
          add_message("level.stairs_found", importance: :normal)
        when :level_transitioned
          add_message("level.descended", metadata: { level: data[:difficulty] }, importance: :high)
        when :item_picked_up
          add_message("item.picked_up", metadata: { item: data[:item_name] || "item" }, importance: :normal)
        when :combat_attack
          handle_combat_attack(data)
        when :combat_damage
          handle_combat_damage(data)
        when :combat_miss
          handle_combat_miss(data)
        when :combat_death
          handle_combat_death(data)
        when :combat_flee_success
          handle_flee_success(data)
        when :combat_flee_failed
          handle_flee_failed(data)
        when :loot_dropped
          handle_loot_dropped(data)
        end
      end

      # --- Message Logging Helpers ---
      def log_message(key, options = {})
        @manager.log_translated(key, **options)
      end

      def log_success(key, metadata = {})
        @manager.log_success(key, metadata)
      end

      def log_warning(key, metadata = {})
        @manager.log_warning(key, metadata)
      end

      def log_critical(key, metadata = {})
        @manager.log_critical(key, metadata)
      end

      def get_recent_messages(limit = 10)
        @manager.get_recent_messages(limit)
      end

      def add_message(key, metadata: {}, importance: :normal, options: [], category: :system)
        message = { key: key, metadata: metadata, importance: importance, options: options, category: category, timestamp: Time.now }
        @message_queue << message
        @logger.debug("[MessageSystem] Added message to queue: #{key}, queue size now: #{@message_queue.size}")
        trim_message_queue if @message_queue.size > MAX_MESSAGES
      end

      # Add inventory option to menu if player has inventory and not in combat
      def add_inventory_option_if_available(world)
        return if in_combat_mode?
        
        player = world.get_entity_by_name('Player')
        return unless player&.has_component?(:inventory)
        
        # Clear previous inventory options first
        clear_inventory_options
        
        inventory = player.get_component(:inventory)
        item_count = inventory.items.size
        
        # Check if inventory option already exists
        message_log = @manager.instance_variable_get(:@message_log)
        existing_inventory_msg = message_log.messages.find { |msg| msg.content.to_s == "menu.inventory" }
        
        if existing_inventory_msg
          # Update existing message with current item count
          existing_inventory_msg.options = [
            { key: 'i', content: "Inventory (#{item_count} items) [i]", callback: :show_inventory }
          ]
          @logger.debug("[MessageSystem] Updated existing inventory option with item count: #{item_count}")
        else
          # Add new inventory option
          add_message("menu.inventory",
            options: [
              { key: 'i', content: "Inventory (#{item_count} items) [i]", callback: :show_inventory }
            ],
            importance: :normal,
            category: :system)
          process_message_queue
          @logger.debug("[MessageSystem] Added inventory option to menu")
        end
      end
      
      # Clear all inventory-related options from messages
      def clear_inventory_options
        message_log = @manager.instance_variable_get(:@message_log)
        message_log.messages.each do |msg|
          if msg.content.to_s == "menu.inventory" || msg.content.to_s.start_with?("inventory.")
            msg.options = []
            @logger.debug("[MessageSystem] Cleared options from inventory message: #{msg.content}")
          end
        end
      end
      
      # Check if we're currently in combat mode (combat collision active)
      def in_combat_mode?
        @last_collision_data != nil || 
        @manager.options.any? { |opt| opt[:callback] == :attack_monster || opt[:callback] == :run_away_from_monster }
      end
      
      # Handle inventory callback - show items
      def handle_inventory_callback
        player = @world.get_entity_by_name('Player')
        return unless player&.has_component?(:inventory)
        
        inventory = player.get_component(:inventory)
        
        if inventory.items.empty?
          add_message("inventory.empty", importance: :normal, category: :system)
          process_message_queue
          return
        end
        
        # Clear previous options
        clear_previous_combat_options
        
        # Build item options
        item_options = []
        inventory.items.each_with_index do |item, index|
          item_name = item.name || "Item"
          if item.has_component?(:item)
            item_comp = item.get_component(:item)
            item_name = item_comp.name || item_name
            if item_comp.stackable? && item_comp.stack_size > 1
              item_name += " (x#{item_comp.stack_size})"
            end
          end
          option_key = (index + 1).to_s
          item_options << {
            key: option_key,
            content: "#{option_key}) #{item_name}",
            callback: :select_item,
            item_id: item.id
          }
        end
        
        # Add message with item options
        add_message("inventory.items",
          options: item_options,
          importance: :normal,
          category: :system)
        process_message_queue
        # Process events immediately to ensure messages are displayed
        @world.send(:process_events) if @world.respond_to?(:process_events, true)
        @logger.debug("[MessageSystem] Showing inventory with #{inventory.items.size} items")
      end
      
      # Handle item selection - show actions (use, drop, etc.)
      def handle_item_selection(item_id)
        player = @world.get_entity_by_name('Player')
        return unless player&.has_component?(:inventory)
        
        inventory = player.get_component(:inventory)
        item = inventory.items.find { |i| i.id == item_id }
        return unless item
        
        item_name = item.name || "Item"
        if item.has_component?(:item)
          item_comp = item.get_component(:item)
          item_name = item_comp.name || item_name
        end
        
        # Build action options
        action_options = []
        
        # Use option (if consumable)
        if item.has_component?(:consumable) || item.has_component?(:item)
          action_options << {
            key: '1',
            content: "1) Use #{item_name}",
            callback: :use_item,
            item_id: item.id
          }
        end
        
        # Drop option
        action_options << {
          key: '2',
          content: "2) Drop #{item_name}",
          callback: :drop_item,
          item_id: item.id
        }
        
        # Back option
        action_options << {
          key: 'b',
          content: "b) Back to inventory",
          callback: :show_inventory
        }
        
        # Clear previous options and add item actions
        clear_previous_combat_options
        clear_inventory_options
        add_message("inventory.item_actions",
          metadata: { item: item_name },
          options: action_options,
          importance: :normal,
          category: :system)
        process_message_queue
        # Process events immediately to ensure messages are displayed
        @world.send(:process_events) if @world.respond_to?(:process_events, true)
        @logger.debug("[MessageSystem] Showing actions for item: #{item_name}")
      end
      
      # Handle item action (use, drop)
      def handle_item_action_callback(action, item_id)
        player = @world.get_entity_by_name('Player')
        return unless player&.has_component?(:inventory)
        
        inventory = player.get_component(:inventory)
        item = inventory.items.find { |i| i.id == item_id }
        return unless item
        
        case action
        when :use_item
          handle_use_item(player, item)
        when :drop_item
          handle_drop_item(player, item)
        end
      end
      
      # Use an item
      def handle_use_item(player, item)
        inventory_system = Vanilla::ServiceRegistry.get(:inventory_system)
        if inventory_system
          success = inventory_system.use_item(player, item)
          if success
            add_message("inventory.item_used", metadata: { item: item.name || "item" }, importance: :normal, category: :system)
          else
            add_message("inventory.cannot_use", metadata: { item: item.name || "item" }, importance: :warning, category: :system)
          end
        else
          # Fallback: use ItemUseSystem directly
          item_use_system = @world.systems.find { |s, _| s.is_a?(Vanilla::Systems::ItemUseSystem) }&.first
          if item_use_system
            item_use_system.use_item(player, item)
            add_message("inventory.item_used", metadata: { item: item.name || "item" }, importance: :normal, category: :system)
          end
        end
        process_message_queue
        clear_previous_combat_options
        @manager.toggle_selection_mode if @manager.selection_mode?
      end
      
      # Drop an item
      def handle_drop_item(player, item)
        position = player.get_component(:position)
        return unless position
        
        inventory = player.get_component(:inventory)
        removed_item = inventory.remove(item)
        return unless removed_item
        
        # Place item at player's position (add position component if it doesn't have one)
        unless item.has_component?(:position)
          item.add_component(Vanilla::Components::PositionComponent.new(row: position.row, column: position.column))
        else
          item_pos = item.get_component(:position)
          item_pos.set_position(position.row, position.column)
        end
        
        # Add render component if missing (use GOLD as default item character)
        unless item.has_component?(:render)
          item.add_component(Vanilla::Components::RenderComponent.new(character: Vanilla::Support::TileType::GOLD, color: :yellow))
        end
        
        @world.add_entity(item)
        @world.current_level.add_entity(item)
        @world.current_level.update_grid_with_entity(item)
        
        item_name = item.name || "item"
        if item.has_component?(:item)
          item_comp = item.get_component(:item)
          item_name = item_comp.name || item_name
        end
        
        add_message("inventory.item_dropped", metadata: { item: item_name }, importance: :normal, category: :system)
        process_message_queue
        clear_previous_combat_options
        @manager.toggle_selection_mode if @manager.selection_mode?
      end

      # --- Private Implementation Details ---
      private

      def process_message_queue
        return if @message_queue.empty?

        @logger.debug("[MessageSystem] Processing #{@message_queue.size} messages from queue")
        @message_queue.each do |msg|
          @logger.debug("[MessageSystem] Processing message: #{msg[:key]}, category: #{msg[:category]}")
          @manager.log_translated(msg[:key], importance: msg[:importance], category: msg[:category] || :system, options: msg[:options], **msg[:metadata])
        end
        @message_queue.clear
      end

      def trim_message_queue
        @message_queue.sort_by! { |msg| [msg[:timestamp], importance_value(msg[:importance])] }
        @message_queue = @message_queue.last(MAX_MESSAGES)
      end

      def importance_value(importance)
        { critical: 3, high: 2, normal: 1, low: 0 }[importance] || 0
      end

      def handle_combat_attack(data)
        # Combat attack event is logged, but we wait for damage/miss to show message
        # This is handled in handle_combat_damage or handle_combat_miss
      end

      def handle_combat_miss(data)
        attacker = @world.get_entity(data[:attacker_id])
        target = @world.get_entity(data[:target_id])
        return unless attacker && target

        if attacker&.has_tag?(:player)
          # Player missed
          target_name = target.name || "enemy"
          add_message("combat.player_miss", metadata: { enemy: target_name }, importance: :normal, category: :combat)
          process_message_queue # Process immediately so message appears during combat
        elsif target&.has_tag?(:player)
          # Enemy missed player
          attacker_name = attacker.name || "enemy"
          add_message("combat.enemy_miss", metadata: { enemy: attacker_name }, importance: :normal, category: :combat)
          process_message_queue # Process immediately so message appears during combat
        end
      end

      def handle_combat_damage(data)
        target = @world.get_entity(data[:target_id])
        source = data[:source_id] ? @world.get_entity(data[:source_id]) : nil
        return unless target

        attacker = source || @world.get_entity(data[:attacker_id]) rescue nil
        damage = data[:damage] || 0

        if attacker&.has_tag?(:player)
          # Player attacked something
          target_name = target.name || "enemy"
          add_message("combat.player_hit", metadata: { enemy: target_name, damage: damage }, importance: :normal, category: :combat)
          process_message_queue # Process immediately so message appears during combat
        elsif target&.has_tag?(:player)
          # Player was attacked
          attacker_name = attacker&.name || "enemy"
          add_message("combat.enemy_hit", metadata: { enemy: attacker_name, damage: damage }, importance: :high, category: :combat)
          process_message_queue # Process immediately so message appears during combat
        end
      end

      def handle_combat_death(data)
        # Entity may have been removed from world, so we need to check if it exists
        # or use the data we have
        entity = @world.get_entity(data[:entity_id])
        killer = data[:killer_id] ? @world.get_entity(data[:killer_id]) : nil

        # Get entity name before it's removed, or use a default
        entity_name = entity&.name || data[:entity_name] || "enemy"
        was_player = entity&.has_tag?(:player) || data[:was_player] == true

        # Clear collision data if the dead entity was involved in the last collision
        if @last_collision_data &&
           (@last_collision_data[:entity_id] == data[:entity_id] ||
            @last_collision_data[:other_entity_id] == data[:entity_id])
          @logger.debug("[MessageSystem] Clearing collision data because entity #{data[:entity_id]} died")
          @last_collision_data = nil
          # Clear options from combat collision messages since combat is over
          clear_previous_combat_options
        end

        if killer&.has_tag?(:player)
          # Player killed something
          add_message("combat.player_kill", metadata: { enemy: entity_name }, importance: :high, category: :combat)
          process_message_queue
          # Exit selection mode AFTER message is processed so kill message is visible
          @manager.toggle_selection_mode if @manager.selection_mode?
          @logger.debug("[MessageSystem] Player killed #{entity_name}, message added and selection mode exited")
        elsif was_player
          # Player was killed
          @manager.toggle_selection_mode if @manager.selection_mode?
          killer_name = killer&.name || "enemy"
          add_message("death.player_dies", metadata: { enemy: killer_name }, importance: :critical, category: :combat)
          process_message_queue
        end
      end

      def handle_flee_success(data)
        # Clear collision data and options since player fled
        @last_collision_data = nil
        clear_previous_combat_options
        add_message("combat.flee_success", importance: :normal, category: :combat)
        process_message_queue
      end

      def handle_loot_dropped(data)
        loot = data[:loot]
        return unless loot && (loot[:gold] > 0 || !loot[:items].empty?)

        # Store loot data for pickup
        @last_loot_data = {
          gold: loot[:gold] || 0,
          items: loot[:items] || [],
          position: data[:position]
        }

        # Show loot drop message with options
        add_message("loot.dropped",
          options: [
            { key: '1', content: "Pick up loot [1]", callback: :pickup_loot },
            { key: '2', content: "Leave loot [2]", callback: :ignore_loot }
          ],
          importance: :normal,
          category: :system)
        process_message_queue
        @manager.toggle_selection_mode unless @manager.selection_mode?
        @logger.debug("[MessageSystem] Loot dropped: #{loot[:gold]} gold, #{loot[:items].size} items")
      end

      def handle_pickup_loot_callback
        return unless @last_loot_data

        # Clear loot menu options
        clear_loot_options

        player = @world.get_entity_by_name('Player')
        return unless player

        gold_amount = @last_loot_data[:gold] || 0
        items = @last_loot_data[:items] || []

        # Add gold to player
        if gold_amount > 0
          if player.has_component?(:currency)
            currency = player.get_component(:currency)
            currency.value += gold_amount
          else
            player.add_component(Vanilla::Components::CurrencyComponent.new(gold_amount, :gold))
          end
        end

        # Add items to inventory
        items_added = []
        if !items.empty? && player.has_component?(:inventory)
          inventory = player.get_component(:inventory)
          items.each do |item|
            # Add item to world first if it's not already there
            unless @world.get_entity(item.id)
              @world.add_entity(item)
            end
            if inventory.add(item)
              items_added << item
              @logger.debug("[MessageSystem] Added item #{item.name || item.id} to inventory. Inventory now has #{inventory.items.size} items")
            else
              @logger.warn("[MessageSystem] Failed to add item #{item.name || item.id} to inventory (inventory full?)")
            end
          end
        end

        # Build pickup message
        pickup_parts = []
        pickup_parts << "#{gold_amount} gold" if gold_amount > 0
        items_added.each do |item|
          item_name = item.name || "item"
          if item.has_component?(:item)
            item_comp = item.get_component(:item)
            item_name = item_comp.name || item_name
          end
          pickup_parts << item_name
        end

        if pickup_parts.any?
          add_message("loot.picked_up", metadata: { items: pickup_parts.join(", ") }, importance: :normal, category: :system)
        end

        # Update inventory option count if inventory option exists
        if player.has_component?(:inventory)
          inventory = player.get_component(:inventory)
          message_log = @manager.instance_variable_get(:@message_log)
          existing_inventory_msg = message_log.messages.find { |msg| msg.content.to_s == "menu.inventory" }
          if existing_inventory_msg
            existing_inventory_msg.options = [
              { key: 'i', content: "Inventory (#{inventory.items.size} items) [i]", callback: :show_inventory }
            ]
            @logger.debug("[MessageSystem] Updated inventory option count to #{inventory.items.size} after loot pickup")
          end
        end

        # Clear loot data
        @last_loot_data = nil
        process_message_queue
        @manager.toggle_selection_mode if @manager.selection_mode?
        @logger.info("[MessageSystem] Player picked up loot: #{pickup_parts.join(", ")}")
      end

      def handle_ignore_loot_callback
        return unless @last_loot_data

        # Clear loot menu options
        clear_loot_options

        add_message("loot.ignored", importance: :normal, category: :system)
        @last_loot_data = nil
        process_message_queue
        @manager.toggle_selection_mode if @manager.selection_mode?
        @logger.info("[MessageSystem] Player ignored loot")
      end

      def handle_flee_failed(data)
        monster = @world.get_entity(data[:monster_id])
        monster_name = monster&.name || "monster"
        add_message("combat.flee_failed", metadata: { enemy: monster_name }, importance: :high, category: :combat)
        process_message_queue
      end

      # Clear options from previous combat collision messages to prevent duplicates
      def clear_previous_combat_options
        message_log = @manager.instance_variable_get(:@message_log)
        message_log.messages.each do |msg|
          # Check if this is a combat collision message
          if msg.content.to_s == "combat.collision" || msg.content.to_s.include?("combat.collision")
            msg.options = []
            @logger.debug("[MessageSystem] Cleared options from previous combat collision message")
          end
        end
      end

      # Clear options from loot drop messages
      def clear_loot_options
        message_log = @manager.instance_variable_get(:@message_log)
        message_log.messages.each do |msg|
          if msg.content.to_s == "loot.dropped"
            msg.options = []
            @logger.debug("[MessageSystem] Cleared options from loot drop message")
          end
        end
      end
    end
  end
end
