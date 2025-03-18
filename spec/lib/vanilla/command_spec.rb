require 'spec_helper'

RSpec.describe Vanilla::Command do
  let(:grid) { instance_double('Vanilla::MapUtils::Grid') }
  let(:logger) { instance_double('Vanilla::Logger') }
  let(:input_handler) { instance_double('Vanilla::InputHandler') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:debug)
    allow(Vanilla::InputHandler).to receive(:new).and_return(input_handler)
  end

  describe '.process' do
    context 'with an entity' do
      let(:entity) do
        entity = Vanilla::Components::Entity.new
        entity.add_component(Vanilla::Components::PositionComponent.new(row: 1, column: 1))
        entity
      end

      it 'creates a new command and processes it' do
        expect(input_handler).to receive(:handle_input).with('k', entity, grid)

        described_class.process(key: 'k', grid: grid, unit: entity)
      end
    end

    context 'with arrow keys' do
      let(:entity) do
        entity = Vanilla::Components::Entity.new
        entity.add_component(Vanilla::Components::PositionComponent.new(row: 1, column: 1))
        entity
      end

      it 'handles arrow keys' do
        expect(input_handler).to receive(:handle_input).with(:KEY_UP, entity, grid)

        described_class.process(key: :KEY_UP, grid: grid, unit: entity)
      end
    end
  end
end