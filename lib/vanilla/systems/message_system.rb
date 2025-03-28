# lib/vanilla/systems/message_system.rb
# frozen_string_literal: true

require_relative 'system'
require_relative '../messages/message'
require_relative '../messages/message_log'
require_relative '../messages/message_manager'

module Vanilla
  module Systems
    class MessageSystem < System
      MAX_MESSAGES = 100

      def initialize(world)
        super
        @message_queue = []

        @logger = Vanilla::Logger.instance
        @manager = Vanilla::Messages::MessageManager.new

        @world.subscribe(:entity_moved, self)
        @world.subscribe(:monster_spawned, self)
        @world.subscribe(:monster_despawned, self)
        @world.subscribe(:entities_collided, self)
        @world.subscribe(:level_transition_requested, self)
        @world.subscribe(:level_transitioned, self)
        @world.subscribe(:item_picked_up, self)
        Vanilla::ServiceRegistry.register(:message_system, self)
      end

      def update(_delta_time)
        process_message_queue
      end

      def render(renderer)
        @manager.render(renderer)
      end

      def selection_mode?
        @manager.selection_mode
      end

      def toggle_selection_mode
        @manager.toggle_selection_mode
      end

      def handle_input(key)
        if key == 'm'
          toggle_selection_mode
          @logger.info("[MessageSystem] Toggled menu mode to #{@manager.selection_mode ? 'ON' : 'OFF'}")
          return true
        end

        if @manager.selection_mode
          if key == 'q'
            toggle_selection_mode
            @logger.info("[MessageSystem] Quit menu mode")
            return true
          elsif key.is_a?(String) && key.length == 1
            option = @manager.options.find { |opt| opt[:key] == key }
            if option
              @world.queue_command(option[:callback], {})
              toggle_selection_mode
              @logger.info("[MessageSystem] Selected option #{key}, exiting menu mode")
              return true
            end
          end
          # Ignore other keys in menu mode, wait for valid input
          return true
        end

        @manager.handle_input(key)
      end

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
          entity = @world.get_entity(data[:entity_id])
          other = @world.get_entity(data[:other_entity_id])
          if entity&.has_tag?(:player) && other&.has_tag?(:monster)
            add_message("combat.collision", metadata: { x: data[:position][:row], y: data[:position][:column] },
                                            options: [{ key: '1', content: "Attack Monster [M]", callback: :attack_monster }], importance: :high)
          elsif entity&.has_tag?(:player) && other&.has_tag?(:stairs)
            add_message("level.stairs_found", importance: :normal)
          end
        when :level_transition_requested
          add_message("level.stairs_found", importance: :normal)
        when :level_transitioned
          add_message("level.descended", metadata: { level: data[:difficulty] }, importance: :high)
        when :item_picked_up
          add_message("item.picked_up", metadata: { item: data[:item_name] || "item" }, importance: :normal)
        end
      end

      def add_message(key, metadata: {}, importance: :normal, options: [])
        message = { key: key, metadata: metadata, importance: importance, options: options, timestamp: Time.now }
        @message_queue << message
        trim_message_queue if @message_queue.size > MAX_MESSAGES
      end

      private

      def process_message_queue
        @message_queue.each do |msg|
          @manager.log_translated(msg[:key], importance: msg[:importance], category: :system, options: msg[:options], metadata: msg[:metadata])
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
    end
  end
end
