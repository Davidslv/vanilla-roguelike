# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Commands::ChangeLevelCommand do
  let(:player) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.name = "Player"
      e.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 5))
    end
  end
  let(:world) { instance_double('Vanilla::World') }
  let(:maze_system) { instance_double('Vanilla::Systems::MazeSystem') }
  let(:level) { instance_double('Vanilla::Level', add_entity: nil) }
  let(:logger) { instance_double('Vanilla::Logger') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:warn)
    allow(world).to receive(:systems).and_return([[maze_system, 0]])
    allow(world).to receive(:current_level).and_return(level)
    allow(world).to receive(:level_changed=)
    allow(world).to receive(:level_changed).and_return(false)
    allow(world).to receive(:emit_event)
    allow(maze_system).to receive(:is_a?).with(Vanilla::Systems::MazeSystem).and_return(true)
    allow(maze_system).to receive(:difficulty=)
    allow(maze_system).to receive(:update)
  end

  describe '#initialize' do
    it 'creates command with difficulty and player' do
      command = described_class.new(2, player)
      expect(command.instance_variable_get(:@difficulty)).to eq(2)
      expect(command.instance_variable_get(:@player)).to eq(player)
    end
  end

  describe '#execute' do
    it 'updates maze system difficulty' do
      command = described_class.new(3, player)
      expect(maze_system).to receive(:difficulty=).with(3)
      command.execute(world)
    end

    it 'sets world level_changed flag' do
      command = described_class.new(2, player)
      expect(world).to receive(:level_changed=).with(true)
      command.execute(world)
    end

    it 'calls maze system update to regenerate level' do
      command = described_class.new(2, player)
      expect(maze_system).to receive(:update).with(nil)
      command.execute(world)
    end

    it 'resets player position to 0, 0' do
      command = described_class.new(2, player)
      position = player.get_component(:position)
      command.execute(world)
      expect(position.row).to eq(0)
      expect(position.column).to eq(0)
    end

    it 'adds player to new level' do
      command = described_class.new(2, player)
      allow(level).to receive(:add_entity).with(player)
      command.execute(world)
      expect(level).to have_received(:add_entity).with(player)
    end

    it 'emits level_transitioned event' do
      command = described_class.new(2, player)
      expect(world).to receive(:emit_event).with(:level_transitioned, hash_including(
        difficulty: 2,
        player_id: player.id
      ))
      command.execute(world)
    end

    it 'resets level_changed flag after transition' do
      command = described_class.new(2, player)
      expect(world).to receive(:level_changed=).with(false)
      command.execute(world)
    end

    it 'does not execute twice' do
      command = described_class.new(2, player)
      command.execute(world)
      expect(maze_system).not_to receive(:update)
      command.execute(world)
    end

    it 'handles missing maze system gracefully' do
      allow(world).to receive(:systems).and_return([])
      command = described_class.new(2, player)
      expect { command.execute(world) }.not_to raise_error
    end

    it 'handles nil player gracefully' do
      command = described_class.new(2, nil)
      expect { command.execute(world) }.not_to raise_error
    end
  end
end

