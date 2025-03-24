module Vanilla
  # Systems module contains the logic for processing entities and components
  # in the Entity-Component-System architecture.
  #
  # Unlike components, which are primarily data containers, systems contain
  # the logic for processing entities with specific component combinations.
  # This separation of data (components) and logic (systems) is a key feature
  # of the ECS pattern.
  #
  # Each system typically operates on entities that have a specific set of
  # components, applying transformations, calculations, or other processing
  # to those entities.
  module Systems
    # Load base system class first
    require_relative 'systems/system'

    # Load other system classes
    require_relative 'systems/input_system'
    require_relative 'systems/movement_system'
    require_relative 'systems/collision_system'
    require_relative 'systems/message_system'
    require_relative 'systems/monster_system'
    require_relative 'systems/render_system'
    require_relative 'systems/render_system_factory'
  end
end
