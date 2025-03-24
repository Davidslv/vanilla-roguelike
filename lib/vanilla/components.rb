# frozen_string_literal: true

module Vanilla
  # Components module contains all the component types
  # used in the entity-component-system architecture.
  #
  # Components are primarily data containers to be used
  # with entities.
  module Components
    # Load the component system
    require_relative 'components/component'

    # Load specific components
    require_relative 'components/position_component'
    require_relative 'components/stairs_component'
    require_relative 'components/movement_component'
    require_relative 'components/render_component'
    require_relative 'components/inventory_component'
    require_relative 'components/item_component'
    require_relative 'components/consumable_component'
    require_relative 'components/effect_component'
    require_relative 'components/equippable_component'
    require_relative 'components/key_component'
    require_relative 'components/durability_component'
    require_relative 'components/currency_component'
    require_relative 'components/input_component'
  end
end
