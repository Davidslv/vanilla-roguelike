require 'spec_helper'

RSpec.describe Vanilla::Command do
  let(:grid) { instance_double('Vanilla::MapUtils::Grid') }
  let(:logger) { instance_double('Vanilla::Logger') }
  let(:draw) { Vanilla::Draw }
  let(:input_handler) { instance_double('Vanilla::InputHandler') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:warn)
    allow(Vanilla::InputHandler).to receive(:new).and_return(input_handler)
    allow(input_handler).to receive(:handle_input)
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
      end

      it 'delegates to input handler and issues deprecation warning' do
        expect(logger).to receive(:warn).with("DEPRECATED: Using legacy Unit object in Command. Please use Entity with components.")
        expect(input_handler).to receive(:handle_input).with('k', unit, grid)

        described_class.process(key: 'k', grid: grid, unit: unit)
      end
    end

    context 'with an entity' do
      let(:entity) do
        entity = Vanilla::Components::Entity.new
        entity.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 5))
        entity.add_component(Vanilla::Components::TileComponent.new(tile: '@'))
        entity
      end

      it 'delegates to input handler without warning' do
        expect(logger).not_to receive(:warn)
        expect(input_handler).to receive(:handle_input).with('k', entity, grid)

        described_class.process(key: 'k', grid: grid, unit: entity)
      end
    end
  end
end