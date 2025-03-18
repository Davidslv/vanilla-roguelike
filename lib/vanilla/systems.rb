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
  end
end

# Require all system files
require_relative 'systems/movement_system'