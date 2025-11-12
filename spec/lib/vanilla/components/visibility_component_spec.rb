# frozen_string_literal: true

require "spec_helper"
require "vanilla/components/visibility_component"

RSpec.describe Vanilla::Components::VisibilityComponent do
  describe "#initialize" do
    it "sets vision_radius to 8 by default" do
      component = described_class.new
      expect(component.vision_radius).to eq(8)
    end

    it "initializes visible_tiles as empty Set" do
      component = described_class.new
      expect(component.visible_tiles).to be_a(Set)
      expect(component.visible_tiles).to be_empty
    end

    it "initializes explored_tiles as empty Set" do
      component = described_class.new
      expect(component.explored_tiles).to be_a(Set)
      expect(component.explored_tiles).to be_empty
    end

    it "sets blocks_vision to false by default" do
      component = described_class.new
      expect(component.blocks_vision).to be false
    end

    it "allows custom vision_radius" do
      component = described_class.new(vision_radius: 12)
      expect(component.vision_radius).to eq(12)
    end

    it "allows custom blocks_vision" do
      component = described_class.new(blocks_vision: true)
      expect(component.blocks_vision).to be true
    end
  end

  describe "#type" do
    it "returns :visibility" do
      component = described_class.new
      expect(component.type).to eq(:visibility)
    end
  end

  describe "#add_visible_tile" do
    it "adds tile to visible_tiles Set" do
      component = described_class.new
      component.add_visible_tile(5, 10)

      expect(component.visible_tiles).to include([5, 10])
    end

    it "prevents duplicate tiles" do
      component = described_class.new
      component.add_visible_tile(5, 10)
      component.add_visible_tile(5, 10)

      expect(component.visible_tiles.size).to eq(1)
    end
  end

  describe "#clear_visible_tiles" do
    it "clears visible_tiles Set" do
      component = described_class.new
      component.add_visible_tile(5, 10)
      component.add_visible_tile(6, 11)

      component.clear_visible_tiles

      expect(component.visible_tiles).to be_empty
    end
  end

  describe "#tile_visible?" do
    it "returns true if tile in visible_tiles" do
      component = described_class.new
      component.add_visible_tile(5, 10)

      expect(component.tile_visible?(5, 10)).to be true
    end

    it "returns false if tile not in visible_tiles" do
      component = described_class.new

      expect(component.tile_visible?(5, 10)).to be false
    end
  end

  describe "#tile_explored?" do
    it "returns true if tile in explored_tiles" do
      component = described_class.new
      component.explored_tiles.add([5, 10])

      expect(component.tile_explored?(5, 10)).to be true
    end

    it "returns false if tile not in explored_tiles" do
      component = described_class.new

      expect(component.tile_explored?(5, 10)).to be false
    end
  end

  describe "#to_hash" do
    it "serializes component data" do
      component = described_class.new(vision_radius: 10, blocks_vision: true)
      component.add_visible_tile(5, 10)
      component.add_visible_tile(6, 11)
      component.explored_tiles.add([1, 2])

      hash = component.to_hash

      expect(hash[:vision_radius]).to eq(10)
      expect(hash[:blocks_vision]).to be true
      expect(hash[:visible_tiles]).to be_a(Array)
      expect(hash[:explored_tiles]).to be_a(Array)
    end

    it "converts Sets to Arrays for serialization" do
      component = described_class.new
      component.add_visible_tile(5, 10)
      component.explored_tiles.add([1, 2])

      hash = component.to_hash

      expect(hash[:visible_tiles]).to contain_exactly([5, 10])
      expect(hash[:explored_tiles]).to contain_exactly([1, 2])
    end
  end

  describe ".from_hash" do
    it "deserializes component data" do
      hash = {
        vision_radius: 12,
        blocks_vision: true,
        visible_tiles: [[5, 10], [6, 11]],
        explored_tiles: [[1, 2], [3, 4]]
      }

      component = described_class.from_hash(hash)

      expect(component.vision_radius).to eq(12)
      expect(component.blocks_vision).to be true
      expect(component.visible_tiles).to be_a(Set)
      expect(component.explored_tiles).to be_a(Set)
    end

    it "converts Arrays back to Sets" do
      hash = {
        vision_radius: 8,
        blocks_vision: false,
        visible_tiles: [[5, 10], [6, 11]],
        explored_tiles: [[1, 2]]
      }

      component = described_class.from_hash(hash)

      expect(component.visible_tiles).to contain_exactly([5, 10], [6, 11])
      expect(component.explored_tiles).to contain_exactly([1, 2])
    end
  end
end
