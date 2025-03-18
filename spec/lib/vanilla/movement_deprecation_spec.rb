require 'spec_helper'

RSpec.describe Vanilla::Movement do
  let(:grid) { instance_double('Vanilla::MapUtils::Grid') }
  let(:cell) { instance_double('Vanilla::MapUtils::Cell') }
  let(:west_cell) { instance_double('Vanilla::MapUtils::Cell') }
  let(:east_cell) { instance_double('Vanilla::MapUtils::Cell') }
  let(:north_cell) { instance_double('Vanilla::MapUtils::Cell') }
  let(:south_cell) { instance_double('Vanilla::MapUtils::Cell') }
  let(:unit) do
    instance_double('Vanilla::Unit',
      row: 5,
      column: 10,
      coordinates: [5, 10],
      tile: '@',
      found_stairs: false
    )
  end
  let(:logger) { instance_double('Vanilla::Logger') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:warn)

    allow(grid).to receive(:[]).with(5, 10).and_return(cell)
    allow(cell).to receive(:west).and_return(west_cell)
    allow(cell).to receive(:east).and_return(east_cell)
    allow(cell).to receive(:north).and_return(north_cell)
    allow(cell).to receive(:south).and_return(south_cell)

    allow(west_cell).to receive(:row).and_return(5)
    allow(west_cell).to receive(:column).and_return(9)
    allow(west_cell).to receive(:stairs?).and_return(false)
    allow(west_cell).to receive(:tile=)

    allow(east_cell).to receive(:row).and_return(5)
    allow(east_cell).to receive(:column).and_return(11)
    allow(east_cell).to receive(:stairs?).and_return(false)
    allow(east_cell).to receive(:tile=)

    allow(north_cell).to receive(:row).and_return(4)
    allow(north_cell).to receive(:column).and_return(10)
    allow(north_cell).to receive(:stairs?).and_return(false)
    allow(north_cell).to receive(:tile=)

    allow(south_cell).to receive(:row).and_return(6)
    allow(south_cell).to receive(:column).and_return(10)
    allow(south_cell).to receive(:stairs?).and_return(false)
    allow(south_cell).to receive(:tile=)

    allow(cell).to receive(:linked?).with(west_cell).and_return(true)
    allow(cell).to receive(:linked?).with(east_cell).and_return(true)
    allow(cell).to receive(:linked?).with(north_cell).and_return(true)
    allow(cell).to receive(:linked?).with(south_cell).and_return(true)

    allow(cell).to receive(:tile=)
    allow(unit).to receive(:row=)
    allow(unit).to receive(:column=)
    allow(unit).to receive(:found_stairs=)
  end

  context 'when using legacy movement methods' do
    it 'logs deprecation warning for legacy_move' do
      expect(logger).to receive(:warn).with("DEPRECATED: Legacy movement system is deprecated. Please migrate to the ECS pattern.")
      expect(logger).to receive(:warn).with("DEPRECATED: Method legacy_move is deprecated. Please use Vanilla::Systems::MovementSystem.")

      described_class.move(grid: grid, unit: unit, direction: :left)
    end

    it 'logs deprecation warning for move_left' do
      expect(logger).to receive(:warn).with("DEPRECATED: Method move_left is deprecated. Please use Vanilla::Systems::MovementSystem.")

      described_class.move_left(cell, unit)
    end

    it 'logs deprecation warning for move_right' do
      expect(logger).to receive(:warn).with("DEPRECATED: Method move_right is deprecated. Please use Vanilla::Systems::MovementSystem.")

      described_class.move_right(cell, unit)
    end

    it 'logs deprecation warning for move_up' do
      expect(logger).to receive(:warn).with("DEPRECATED: Method move_up is deprecated. Please use Vanilla::Systems::MovementSystem.")

      described_class.move_up(cell, unit)
    end

    it 'logs deprecation warning for move_down' do
      expect(logger).to receive(:warn).with("DEPRECATED: Method move_down is deprecated. Please use Vanilla::Systems::MovementSystem.")

      described_class.move_down(cell, unit)
    end
  end

  context 'with an entity that has required components' do
    let(:entity) { instance_double('Vanilla::Components::Entity') }
    let(:movement_system) { instance_double('Vanilla::Systems::MovementSystem') }

    before do
      allow(entity).to receive(:respond_to?).with(:has_component?).and_return(true)
      allow(entity).to receive(:has_component?).with(:position).and_return(true)
      allow(entity).to receive(:has_component?).with(:movement).and_return(true)

      allow(Vanilla::Systems::MovementSystem).to receive(:new).with(grid).and_return(movement_system)
      allow(movement_system).to receive(:move)
    end

    it 'uses the movement system without deprecation warning' do
      expect(logger).not_to receive(:warn).with(/DEPRECATED/)
      expect(movement_system).to receive(:move).with(entity, :left)

      described_class.move(grid: grid, unit: entity, direction: :left)
    end
  end
end