# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Commands::MoveCommand do
  let(:entity) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.add_component(Vanilla::Components::PositionComponent.new(row: 2, column: 2))
    end
  end
  let(:world) { instance_double('Vanilla::World') }
  let(:movement_system) { instance_double('Vanilla::Systems::MovementSystem') }
  let(:level) { instance_double('Vanilla::Level', difficulty: 1, entities: []) }
  let(:logger) { instance_double('Vanilla::Logger') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(world).to receive(:systems).and_return([[movement_system, 2]])
    allow(world).to receive(:current_level).and_return(level)
    allow(world).to receive(:queue_command)
    allow(movement_system).to receive(:is_a?).with(Vanilla::Systems::MovementSystem).and_return(true)
    allow(movement_system).to receive(:move).and_return(true)
  end

  describe '#initialize' do
    it 'creates command with valid direction' do
      command = described_class.new(entity, :north)
      expect(command.direction).to eq(:north)
      expect(command.entity).to eq(entity)
    end

    it 'raises error for invalid direction' do
      expect {
        described_class.new(entity, :invalid)
      }.to raise_error(described_class::InvalidDirectionError, /Invalid direction/)
    end

    it 'accepts all valid directions' do
      [:north, :south, :east, :west].each do |dir|
        expect { described_class.new(entity, dir) }.not_to raise_error
      end
    end
  end

  describe '#execute' do
    it 'calls movement system to move entity' do
      command = described_class.new(entity, :north)
      expect(movement_system).to receive(:move).with(entity, :north)
      command.execute(world)
    end

    it 'does not execute twice' do
      command = described_class.new(entity, :south)
      command.execute(world)
      expect(movement_system).not_to receive(:move)
      command.execute(world)
    end

    it 'handles missing movement system gracefully' do
      allow(world).to receive(:systems).and_return([])
      command = described_class.new(entity, :east)
      expect { command.execute(world) }.not_to raise_error
    end

    context 'with stairs at target position' do
      let(:stairs) do
        Vanilla::Entities::Entity.new.tap do |e|
          e.add_component(Vanilla::Components::PositionComponent.new(row: 2, column: 3))
          e.add_component(Vanilla::Components::StairsComponent.new)
        end
      end

      before do
        allow(level).to receive(:entities).and_return([stairs])
        position = entity.get_component(:position)
        allow(movement_system).to receive(:move) do
          position.set_position(2, 3)
          true
        end
      end

      it 'queues ChangeLevelCommand when reaching stairs' do
        command = described_class.new(entity, :east)
        expect(world).to receive(:queue_command) do |cmd|
          expect(cmd).to be_a(Vanilla::Commands::ChangeLevelCommand)
        end
        command.execute(world)
      end
    end

    context 'without stairs at target position' do
      it 'does not queue ChangeLevelCommand' do
        command = described_class.new(entity, :west)
        expect(world).not_to receive(:queue_command).with(anything, anything)
        command.execute(world)
      end
    end
  end
end

