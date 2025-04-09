# lib/entity.rb
class Entity
  attr_reader :id, :components

  def initialize(id)
    @id = id
    @components = {}
  end

  def add_component(component)
    @components[component.class] = component
    self
  end

  def get_component(component_class)
    @components[component_class]
  end

  def has_component?(component_class)
    @components.key?(component_class)
  end
end
