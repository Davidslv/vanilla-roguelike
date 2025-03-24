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
        if entity = Component.get_entity(self)
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
        if entity = Component.get_entity(self)
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
