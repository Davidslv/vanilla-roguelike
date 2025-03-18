require 'spec_helper'

RSpec.describe Vanilla::Movement do
  let(:grid) { instance_double('Vanilla::MapUtils::Grid') }
  let(:logger) { instance_double('Vanilla::Logger', info: nil, debug: nil) }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
  end

  describe '.move' do
    context 'with an ECS entity' do
      let(:entity) { Vanilla::Components::Entity.new }
      let(:position_component) { Vanilla::Components::PositionComponent.new(row: 5, column: 5) }
      let(:movement_component) { Vanilla::Components::MovementComponent.new }
      let(:movement_system) { instance_double('Vanilla::Systems::MovementSystem') }

      before do
        entity.add_component(position_component)
        entity.add_component(movement_component)

        allow(Vanilla::Systems::MovementSystem).to receive(:new).with(grid).and_return(movement_system)
        allow(movement_system).to receive(:move)
      end

      it 'uses MovementSystem for entities with required components' do
        described_class.move(grid: grid, unit: entity, direction: :north)

        expect(Vanilla::Systems::MovementSystem).to have_received(:new).with(grid)
        expect(movement_system).to have_received(:move).with(entity, :north)
      end
    end

    context 'with a legacy unit object' do
      let(:unit) { double('Unit', coordinates: [5, 5], row: 5, column: 5) }
      let(:cell) { instance_double('Vanilla::MapUtils::Cell') }
      let(:north_cell) { instance_double('Vanilla::MapUtils::Cell', row: 4, column: 5, stairs?: false) }

      before do
        allow(grid).to receive(:[]).with(5, 5).and_return(cell)
        allow(cell).to receive(:north).and_return(north_cell)
        allow(cell).to receive(:linked?).with(north_cell).and_return(true)
        allow(cell).to receive(:tile=)
        allow(north_cell).to receive(:tile=)
        allow(unit).to receive(:found_stairs=)
        allow(unit).to receive(:found_stairs).and_return(false)
        allow(unit).to receive(:tile)
        allow(unit).to receive(:row=)
        allow(unit).to receive(:column=)
      end

      it 'uses legacy movement for non-entity objects' do
        described_class.move(grid: grid, unit: unit, direction: :up)

        expect(unit).to have_received(:row=).with(4)
        expect(unit).to have_received(:column=).with(5)
      end

      it 'checks if the path is linked before moving' do
        allow(cell).to receive(:linked?).with(north_cell).and_return(false)

        described_class.move(grid: grid, unit: unit, direction: :up)

        expect(unit).not_to have_received(:row=)
        expect(unit).not_to have_received(:column=)
      end

      it 'updates found_stairs when moving to a cell with stairs' do
        allow(north_cell).to receive(:stairs?).and_return(true)

        described_class.move(grid: grid, unit: unit, direction: :up)

        expect(unit).to have_received(:found_stairs=).with(true)
      end
    end
  end
end