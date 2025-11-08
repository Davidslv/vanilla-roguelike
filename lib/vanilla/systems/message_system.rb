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
        Vanilla::ServiceRegistry.register(:message_system, self)
      end

      # --- Core Lifecycle Methods ---
      def update(_delta_time)
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
        return unless @manager.selection_mode && key.is_a?(String) && key.length == 1

        option = @manager.options.find { |opt| opt[:key] == key }
        return unless option

        # Handle attack_monster callback specially
        if option[:callback] == :attack_monster
          handle_attack_monster_callback
        else
          @world.queue_command(option[:callback], {})
        end
        @logger.info("[MessageSystem] Selected option #{key}")
      end

      def handle_attack_monster_callback
        return unless @last_collision_data

        player = @world.get_entity(@last_collision_data[:entity_id])
        monster = @world.get_entity(@last_collision_data[:other_entity_id])
        return unless player && monster

        # Create and queue attack command
        attack_command = Vanilla::Commands::AttackCommand.new(player, monster)
        @world.queue_command(attack_command)
        @logger.info("[MessageSystem] Queued AttackCommand for player #{player.id} -> monster #{monster.id}")
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
            # Store collision data for attack command
            @last_collision_data = data
            add_message("combat.collision", metadata: { x: data[:position][:row], y: data[:position][:column] },
                                            options: [{ key: '1', content: "Attack Monster [1]", callback: :attack_monster }], importance: :high, category: :combat)
            @logger.debug("[MessageSystem] Combat collision message added to queue")
          elsif entity&.has_tag?(:player) && other&.has_tag?(:stairs)
            add_message("level.stairs_found", importance: :normal)
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
        trim_message_queue if @message_queue.size > MAX_MESSAGES
      end

      # --- Private Implementation Details ---
      private

      def process_message_queue
        return if @message_queue.empty?
        
        @logger.debug("[MessageSystem] Processing #{@message_queue.size} messages from queue")
        @message_queue.each do |msg|
          @logger.debug("[MessageSystem] Processing message: #{msg[:key]}, category: #{msg[:category]}")
          @manager.log_translated(msg[:key], importance: msg[:importance], category: msg[:category] || :system, options: msg[:options], metadata: msg[:metadata])
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
        elsif target&.has_tag?(:player)
          # Enemy missed player
          attacker_name = attacker.name || "enemy"
          add_message("combat.enemy_miss", metadata: { enemy: attacker_name }, importance: :normal, category: :combat)
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
        elsif target&.has_tag?(:player)
          # Player was attacked
          attacker_name = attacker&.name || "enemy"
          add_message("combat.enemy_hit", metadata: { enemy: attacker_name, damage: damage }, importance: :high, category: :combat)
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

        if killer&.has_tag?(:player)
          # Player killed something
          add_message("combat.player_kill", metadata: { enemy: entity_name }, importance: :high, category: :combat)
        elsif was_player
          # Player was killed
          killer_name = killer&.name || "enemy"
          add_message("death.player_dies", metadata: { enemy: killer_name }, importance: :critical, category: :combat)
        end
      end
    end
  end
end
