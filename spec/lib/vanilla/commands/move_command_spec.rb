require 'spec_helper'

RSpec.describe Vanilla::Commands::MoveCommand do
  let(:grid) { instance_double('Vanilla::MapUtils::Grid') }
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
  end

  describe '#execute' do
    context 'when movement is successful' do
      it 'calls movement system and updates display' do
        command = described_class.new(entity, :up, grid)

        expect(movement_system).to receive(:move).with(entity, :up).and_return(true)
        expect(Vanilla::Draw).to receive(:player).with(grid: grid, unit: entity)
        expect(Vanilla::Draw).to receive(:map).with(grid)

        result = command.execute
        expect(result).to be true
      end
    end

    context 'when movement fails' do
      it 'does not update display' do
        command = described_class.new(entity, :up, grid)

        expect(movement_system).to receive(:move).with(entity, :up).and_return(false)
        expect(Vanilla::Draw).not_to receive(:player)
        expect(Vanilla::Draw).not_to receive(:map)

        result = command.execute
        expect(result).to be false
      end
    end
  end
end