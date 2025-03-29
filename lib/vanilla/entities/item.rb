# frozen_string_literal: true

module Vanilla
  module Inventory
    # Wrapper class for entities with item components
    # This provides a convenient interface for working with item entities
    class Item < Entities::Entity
      attr_reader :entity

      def initialize(entity)
        super()

        add_component(Components::ItemComponent.new)
      end
    end
  end
end
