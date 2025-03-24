# frozen_string_literal: true
module Vanilla
  module Components
    class MovementComponent < Component
      attr_reader :speed

      def initialize(active: true, speed: 1)
        super()
        @active = active
        @speed = speed
      end

      def type
        :movement
      end

      def active?
        @active
      end

      def to_hash
        { type: type, active: @active, speed: @speed }
      end

      def self.from_hash(hash)
        new(active: hash[:active], speed: hash[:speed])
      end
    end

    Component.register(MovementComponent)
  end
end
