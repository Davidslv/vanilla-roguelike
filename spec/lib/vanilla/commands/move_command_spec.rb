# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Commands::MoveCommand do
  let(:grid) { instance_double('Vanilla::MapUtils::Grid') }
  let(:cell) { instance_double('Vanilla::MapUtils::Cell') }
  let(:entity) do
    entity = Vanilla::Components::Entity.new
    entity.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 5))
    entity.add_component(Vanilla::Components::TileComponent.new(tile: '@'))
    entity
  end
  let(:movement_system) { instance_double('Vanilla::Systems::MovementSystem') }
  let(:render_system) { instance_double('Vanilla::Systems::RenderSystem') }

  before do
    allow(Vanilla::Systems::MovementSystem).to receive(:new).with(grid).and_return(movement_system)
    allow(grid).to receive(:[]).with(5, 5).and_return(cell)
    allow(cell).to receive(:tile=)

    # Handle respond_to? calls with any arguments
    allow(entity).to receive(:respond_to?).and_return(false)
    allow(entity).to receive(:respond_to?).with(:all_entities, any_args).and_return(false)

    # Handle grid respond_to?
    allow(grid).to receive(:respond_to?).and_return(false)
    allow(grid).to receive(:respond_to?).with(:monster_system, any_args).and_return(false)
  end

  describe '#execute' do
    context 'when movement is successful' do
      it 'clears old position and updates display' do
        command = described_class.new(entity, :up, grid, render_system)
        position_component = entity.get_component(:position)

        # Mock ServiceRegistry for game access
        game = double('Game')
        level = double('Level')
        allow(Vanilla::ServiceRegistry).to receive(:get).with(:game).and_return(game)
        allow(game).to receive(:level).and_return(level)
        allow(level).to receive(:update_grid_with_entities)
        allow(level).to receive(:all_entities).and_return([entity])

        # Mock the movement to change position
        expect(movement_system).to receive(:move).with(entity, :up) do
          position_component.row = 4 # Simulate movement up
          true # Return success
        end

        # Expect level's grid update to be called
        expect(level).to receive(:update_grid_with_entities)

        # Expect render system to be called
        expect(render_system).to receive(:render).with([entity], grid)

        result = command.execute
        expect(result).to be true
      end
    end

    context 'when movement fails' do
      it 'does not update display or clear position' do
        command = described_class.new(entity, :up, grid, render_system)

        expect(movement_system).to receive(:move).with(entity, :up).and_return(false)
        expect(render_system).not_to receive(:render)
        expect(cell).not_to receive(:tile=)

        result = command.execute
        expect(result).to be false
      end
    end

    context 'when entity does not change position' do
      it 'does not clear the old position' do
        command = described_class.new(entity, :up, grid, render_system)

        # Mock the movement to not change position
        expect(movement_system).to receive(:move).with(entity, :up) do
          # Position stays the same
          true # Return success anyway
        end

        # Should not try to clear the position
        expect(cell).not_to receive(:tile=)

        # Still update display
        expect(render_system).to receive(:render).with([entity], grid)

        result = command.execute
        expect(result).to be true
      end
    end

    context 'when entity has all_entities method' do
      let(:level_entity) do
        entity = Vanilla::Components::Entity.new
        entity.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 5))
        entity.add_component(Vanilla::Components::TileComponent.new(tile: '@'))
        entity
      end
      let(:entities_collection) { [level_entity] }

      before do
        # More carefully set up respond_to? expectations
        allow(level_entity).to receive(:respond_to?).and_return(false)
        allow(level_entity).to receive(:respond_to?).with(:all_entities, any_args).and_return(true)
        allow(level_entity).to receive(:all_entities).and_return(entities_collection)
      end

      it 'uses the collection for rendering' do
        command = described_class.new(level_entity, :up, grid, render_system)

        # Mock the movement
        expect(movement_system).to receive(:move).with(level_entity, :up).and_return(true)

        # Expect render system to be called with collection
        expect(render_system).to receive(:render).with(entities_collection, grid)

        command.execute
      end
    end
  end
end
