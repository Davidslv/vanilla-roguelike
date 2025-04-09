# lib/components/render.rb
module Components
  class Render
    attr_accessor :character, :color

    def initialize(character, color = nil)
      @character = character  # e.g., "@", "#", etc.
      @color = color          # Placeholder for future color support (e.g., :red)
    end

    def to_h
      { character: @character, color: @color }
    end

    def self.from_h(hash)
      new(hash[:character], hash[:color])
    end
  end
end
