# lib/event.rb
class Event
  attr_reader :type, :data

  def initialize(type, data = {})
    @type = type     # e.g., :key_pressed, :entity_moved
    @data = data     # Additional info, like { key: "w" } or { entity_id: 1 }
  end
end
