module Vanilla
  module Components
    # Load the component system
    require_relative 'components/component'
    require_relative 'components/entity'

    # Load specific components
    require_relative 'components/position_component'
    require_relative 'components/tile_component'
    require_relative 'components/stairs_component'
    require_relative 'components/movement_component'
  end
end