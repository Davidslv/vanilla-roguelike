# lib/vanilla/components/health_component.rb
module Vanilla
  module Components
    class HealthComponent < Component
      attr_reader :max_health, :current_health

      def initialize(max_health:, current_health: nil)
        @max_health = max_health
        @current_health = current_health || max_health
      end

      def type
        :health
      end

      def to_hash
        { max_health: @max_health, current_health: @current_health }
      end

      def self.from_hash(hash)
        new(max_health: hash[:max_health], current_health: hash[:current_health])
      end
    end
    Component.register(HealthComponent)
  end
end