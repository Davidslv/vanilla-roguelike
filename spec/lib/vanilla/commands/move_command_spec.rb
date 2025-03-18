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

  before do
    allow(Vanilla::Systems::MovementSystem).to receive(:new).with(grid).and_return(movement_system)
    allow(Vanilla::Draw).to receive(:player)
    allow(Vanilla::Draw).to receive(:map)
    allow(grid).to receive(:[]).with(5, 5).and_return(cell)
    allow(cell).to receive(:tile=)
  end

  describe '#execute' do
    context 'when movement is successful' do
      it 'clears old position and updates display' do
        command = described_class.new(entity, :up, grid)
        position_component = entity.get_component(:position)

        # Mock the movement to change position
        expect(movement_system).to receive(:move).with(entity, :up) do
          position_component.row = 4  # Simulate movement up
          true  # Return success
        end

        # Expect old position to be cleared
        expect(grid).to receive(:[]).with(5, 5).and_return(cell)
        expect(cell).to receive(:tile=).with(Vanilla::Support::TileType::EMPTY)

        # Expect display update
        expect(Vanilla::Draw).to receive(:player).with(grid: grid, unit: entity)
        expect(Vanilla::Draw).to receive(:map).with(grid)

        result = command.execute
        expect(result).to be true
      end
    end

    context 'when movement fails' do
      it 'does not update display or clear position' do
        command = described_class.new(entity, :up, grid)

        expect(movement_system).to receive(:move).with(entity, :up).and_return(false)
        expect(Vanilla::Draw).not_to receive(:player)
        expect(Vanilla::Draw).not_to receive(:map)
        expect(cell).not_to receive(:tile=)

        result = command.execute
        expect(result).to be false
      end
    end

    context 'when entity does not change position' do
      it 'does not clear the old position' do
        command = described_class.new(entity, :up, grid)

        # Mock the movement to not change position
        expect(movement_system).to receive(:move).with(entity, :up) do
          # Position stays the same
          true  # Return success anyway
        end

        # Should not try to clear the position
        expect(cell).not_to receive(:tile=)

        # Still update display
        expect(Vanilla::Draw).to receive(:player).with(grid: grid, unit: entity)
        expect(Vanilla::Draw).to receive(:map).with(grid)

        result = command.execute
        expect(result).to be true
      end
    end
  end
end