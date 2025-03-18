require 'spec_helper'

RSpec.describe Vanilla::Command do
  let(:grid) { instance_double('Vanilla::MapUtils::Grid') }
  let(:logger) { instance_double('Vanilla::Logger') }
  let(:draw) { Vanilla::Draw }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:warn)
    allow(draw).to receive(:movement)
  end

  describe '.process' do
    context 'with a legacy-compatible entity' do
      let(:unit) do
        entity = Vanilla::Components::Entity.new
        entity.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 5))
        entity.add_component(Vanilla::Components::TileComponent.new(tile: '@'))
        entity
      end

      before do
        allow(unit).to receive(:respond_to?).with(any_args()).and_return(false)
        allow(logger).to receive(:warn)
      end

      it 'processes up movement' do
        expect(draw).to receive(:movement).with(grid: grid, unit: unit, direction: :up)
        expect(logger).to receive(:info).with("Player attempting to move UP")
        expect(logger).to receive(:warn).with("DEPRECATED: Using legacy Unit object in Command. Please use Entity with components.")
        described_class.process(key: 'k', grid: grid, unit: unit)
      end

      it 'processes down movement' do
        expect(draw).to receive(:movement).with(grid: grid, unit: unit, direction: :down)
        expect(logger).to receive(:info).with("Player attempting to move DOWN")
        expect(logger).to receive(:warn).with("DEPRECATED: Using legacy Unit object in Command. Please use Entity with components.")
        described_class.process(key: 'j', grid: grid, unit: unit)
      end

      it 'processes right movement' do
        expect(draw).to receive(:movement).with(grid: grid, unit: unit, direction: :right)
        expect(logger).to receive(:info).with("Player attempting to move RIGHT")
        expect(logger).to receive(:warn).with("DEPRECATED: Using legacy Unit object in Command. Please use Entity with components.")
        described_class.process(key: 'l', grid: grid, unit: unit)
      end

      it 'processes left movement' do
        expect(draw).to receive(:movement).with(grid: grid, unit: unit, direction: :left)
        expect(logger).to receive(:info).with("Player attempting to move LEFT")
        expect(logger).to receive(:warn).with("DEPRECATED: Using legacy Unit object in Command. Please use Entity with components.")
        described_class.process(key: 'h', grid: grid, unit: unit)
      end

      it 'exits on q' do
        expect(logger).to receive(:info).with("Player exiting game")
        expect(Kernel).to receive(:exit)
        described_class.process(key: 'q', grid: grid, unit: unit)
      end

      it 'logs unknown keys' do
        expect(logger).to receive(:debug).with('Unknown key pressed: "x"')
        expect(logger).to receive(:warn).with("DEPRECATED: Using legacy Unit object in Command. Please use Entity with components.")
        described_class.process(key: 'x', grid: grid, unit: unit)
      end
    end

    context 'with an entity' do
      let(:player) { Vanilla::Entities::Player.new(row: 5, column: 5) }

      it 'processes up movement' do
        expect(logger).to receive(:info).with("Player attempting to move UP")
        expect(Vanilla::Draw).to receive(:movement).with(grid: grid, unit: player, direction: :up)

        described_class.process(key: 'k', grid: grid, unit: player)
      end

      it 'processes down movement' do
        expect(logger).to receive(:info).with("Player attempting to move DOWN")
        expect(Vanilla::Draw).to receive(:movement).with(grid: grid, unit: player, direction: :down)

        described_class.process(key: 'j', grid: grid, unit: player)
      end

      it 'processes right movement' do
        expect(logger).to receive(:info).with("Player attempting to move RIGHT")
        expect(Vanilla::Draw).to receive(:movement).with(grid: grid, unit: player, direction: :right)

        described_class.process(key: 'l', grid: grid, unit: player)
      end

      it 'processes left movement' do
        expect(logger).to receive(:info).with("Player attempting to move LEFT")
        expect(Vanilla::Draw).to receive(:movement).with(grid: grid, unit: player, direction: :left)

        described_class.process(key: 'h', grid: grid, unit: player)
      end

      it 'exits on q' do
        expect(logger).to receive(:info).with("Player exiting game")
        expect { described_class.process(key: 'q', grid: grid, unit: player) }.to raise_error(SystemExit)
      end

      it 'logs unknown keys' do
        expect(logger).to receive(:debug).with("Unknown key pressed: \"x\"")
        described_class.process(key: 'x', grid: grid, unit: player)
      end
    end
  end
end