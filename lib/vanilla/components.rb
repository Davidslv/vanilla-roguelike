require_relative 'components/component'
require_relative 'components/entity'
require_relative 'components/position_component'
require_relative 'components/movement_component'
require_relative 'components/render_component'
require_relative 'components/tile_component'
require_relative 'components/stairs_component'
require_relative 'components/inventory_component'
require_relative 'components/item_component'
require_relative 'components/key_component'
require_relative 'components/equippable_component'
require_relative 'components/consumable_component'
require_relative 'components/currency_component'
require_relative 'components/durability_component'
require_relative 'components/effect_component'

# Load entity factory and world
require_relative 'entity_factory'
require_relative 'world'

module Vanilla
  module Components
    # This module serves as a namespace for all ECS components
  end
end