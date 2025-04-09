# lib/components/position.rb
module Components
  class Position
    attr_accessor :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    # Serialize to a hash for JSON or debugging
    def to_h
      { x: @x, y: @y }
    end

    # Deserialize from a hash
    def self.from_h(hash)
      new(hash[:x], hash[:y])
    end
  end
end
