# lib/components/movement.rb
module Components
  class Movement
    attr_accessor :dx, :dy

    def initialize(dx = 0, dy = 0)
      @dx = dx  # Delta x (horizontal movement)
      @dy = dy  # Delta y (vertical movement)
    end

    def to_h
      { dx: @dx, dy: @dy }
    end

    def self.from_h(hash)
      new(hash[:dx], hash[:dy])
    end
  end
end
