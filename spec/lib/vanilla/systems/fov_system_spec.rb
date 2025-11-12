# frozen_string_literal: true

require "spec_helper"
require "vanilla/systems/fov_system"
require "vanilla/world"
require "vanilla/entities/entity"
require "vanilla/components/visibility_component"
require "vanilla/components/position_component"
require "vanilla/components/dev_mode_component"
require "vanilla/map_utils/grid"

RSpec.describe Vanilla::Systems::FOVSystem do
  let(:world) { instance_double(Vanilla::World) }
  let(:grid) { instance_double(Vanilla::MapUtils::Grid, rows: 20, columns: 20) }
  let(:fov_system) { described_class.new(world, grid) }

  describe "#update" do
    it "processes entities with visibility and position components" do
      entity = Vanilla::Entities::Entity.new
      entity.add_component(Vanilla::Components::VisibilityComponent.new)
      entity.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 5))

      allow(world).to receive(:query_entities).with([:visibility, :position]).and_return([entity])
      allow(grid).to receive(:blocks_vision?).and_return(false)
      allow(grid).to receive(:in_bounds?).and_return(true)

      fov_system.update(0.016)

      visibility = entity.get_component(:visibility)
      expect(visibility.visible_tiles).not_to be_empty
    end

    it "skips entities without visibility component" do
      allow(world).to receive(:query_entities).with([:visibility, :position]).and_return([])

      expect { fov_system.update(0.016) }.not_to raise_error
    end

    it "skips FOV calculation when dev mode enabled" do
      entity = Vanilla::Entities::Entity.new
      entity.add_component(Vanilla::Components::VisibilityComponent.new)
      entity.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 5))
      entity.add_component(Vanilla::Components::DevModeComponent.new(fov_disabled: true))

      allow(world).to receive(:query_entities).with([:visibility, :position]).and_return([entity])

      fov_system.update(0.016)

      visibility = entity.get_component(:visibility)
      expect(visibility.visible_tiles).to be_empty
    end
  end

  describe "#calculate_fov" do
    let(:entity) { Vanilla::Entities::Entity.new }
    let(:visibility) { Vanilla::Components::VisibilityComponent.new(vision_radius: 5) }
    let(:position) { Vanilla::Components::PositionComponent.new(row: 10, column: 10) }

    before do
      entity.add_component(visibility)
      entity.add_component(position)
    end

    context "in empty room (no walls)" do
      before do
        allow(grid).to receive(:blocks_vision?).and_return(false)
        allow(grid).to receive(:in_bounds?).and_return(true)
      end

      it "makes all tiles within radius visible" do
        fov_system.calculate_fov(entity)

        # Check tiles at various distances in the cardinal directions
        expect(visibility.tile_visible?(11, 10)).to be true  # 1 south
        expect(visibility.tile_visible?(10, 11)).to be true  # 1 east
      end

      it "respects vision_radius limit" do
        fov_system.calculate_fov(entity)

        # Tile at distance 6 should not be visible (radius is 5)
        expect(visibility.tile_visible?(16, 10)).to be false
      end

      it "includes player position in visible tiles" do
        fov_system.calculate_fov(entity)

        expect(visibility.tile_visible?(10, 10)).to be true
      end
    end

    context "with walls blocking vision" do
      before do
        # Stub in_bounds to return true for test coordinates
        allow(grid).to receive(:in_bounds?) do |row, col|
          row >= 0 && row < 20 && col >= 0 && col < 20
        end

        # Wall at (10, 12) blocks vision
        allow(grid).to receive(:blocks_vision?) do |row, col|
          row == 10 && col == 12
        end
      end

      it "blocks vision behind walls" do
        fov_system.calculate_fov(entity)

        # Tile directly behind wall should not be visible
        expect(visibility.tile_visible?(10, 13)).to be false
      end

      it "does not make tiles behind walls visible" do
        fov_system.calculate_fov(entity)

        # Tiles further behind wall should also not be visible
        expect(visibility.tile_visible?(10, 14)).to be false
        expect(visibility.tile_visible?(10, 15)).to be false
      end
    end
  end

  describe "#update_explored_tiles" do
    let(:entity) { Vanilla::Entities::Entity.new }
    let(:visibility) { Vanilla::Components::VisibilityComponent.new }

    before do
      entity.add_component(visibility)
    end

    it "adds newly visible tiles to explored set" do
      visibility.add_visible_tile(5, 10)
      visibility.add_visible_tile(6, 11)

      fov_system.send(:update_explored_tiles, entity)

      expect(visibility.tile_explored?(5, 10)).to be true
      expect(visibility.tile_explored?(6, 11)).to be true
    end

    it "retains previously explored tiles" do
      visibility.explored_tiles.add([1, 2])
      visibility.add_visible_tile(5, 10)

      fov_system.send(:update_explored_tiles, entity)

      expect(visibility.tile_explored?(1, 2)).to be true
      expect(visibility.tile_explored?(5, 10)).to be true
    end

    it "does not remove tiles from explored set" do
      visibility.explored_tiles.add([1, 2])
      visibility.explored_tiles.add([3, 4])

      fov_system.send(:update_explored_tiles, entity)

      expect(visibility.tile_explored?(1, 2)).to be true
      expect(visibility.tile_explored?(3, 4)).to be true
    end
  end

  describe "#dev_mode_active?" do
    let(:entity) { Vanilla::Entities::Entity.new }

    it "returns true when entity has dev_mode component with fov_disabled" do
      entity.add_component(Vanilla::Components::DevModeComponent.new(fov_disabled: true))

      expect(fov_system.send(:dev_mode_active?, entity)).to be true
    end

    it "returns false when entity has no dev_mode component" do
      expect(fov_system.send(:dev_mode_active?, entity)).to be false
    end

    it "returns false when dev_mode.fov_disabled is false" do
      entity.add_component(Vanilla::Components::DevModeComponent.new(fov_disabled: false))

      expect(fov_system.send(:dev_mode_active?, entity)).to be false
    end
  end

  describe "helper methods" do
    describe "#in_bounds?" do
      it "delegates to grid" do
        expect(grid).to receive(:in_bounds?).with(5, 10).and_return(true)
        expect(fov_system.send(:in_bounds?, 5, 10)).to be true
      end
    end

    describe "#blocks_vision?" do
      it "delegates to grid" do
        expect(grid).to receive(:blocks_vision?).with(5, 10).and_return(false)
        expect(fov_system.send(:blocks_vision?, 5, 10)).to be false
      end
    end
  end
end
