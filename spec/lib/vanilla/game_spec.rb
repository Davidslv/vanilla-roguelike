# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Game do
  let(:game) { Vanilla::Game.new }

  describe '#initialize' do
    it 'initializes with default options' do
      expect(game.world).to be_a(Vanilla::World)
      expect(game.running).to be false
    end

    it 'registers the game in the service registry' do
      expect(Vanilla::ServiceRegistry.get(:game)).to eq(game)
    end

    it 'initializes systems in the world' do
      # Ensure the world has systems registered
      expect(game.world.systems).not_to be_empty
    end

    it 'creates an initial level' do
      expect(game.world.current_level).not_to be_nil
    end

    it 'creates a player entity' do
      player = game.player
      expect(player).not_to be_nil
      expect(player.has_tag?(:player)).to be true
    end
  end

  describe '#player' do
    it 'returns the player entity' do
      player = game.player
      expect(player).not_to be_nil
      expect(player.has_tag?(:player)).to be true
      expect(player.has_component?(:position)).to be true
      expect(player.has_component?(:input)).to be true
    end
  end

  describe '#level' do
    it 'returns the current level' do
      level = game.level
      expect(level).not_to be_nil
      expect(level).to eq(game.world.current_level)
    end
  end

  describe '#next_level' do
    it 'increases the difficulty' do
      initial_difficulty = game.instance_variable_get(:@difficulty)
      game.next_level
      expect(game.instance_variable_get(:@difficulty)).to eq(initial_difficulty + 1)
    end

    it 'queues a level change command' do
      expect(game.world).to receive(:queue_command).with(
        :change_level,
        hash_including(
          difficulty: anything,
          player_id: anything
        )
      )
      game.next_level
    end
  end

  describe '#exit_game' do
    it 'sets running to false' do
      game.instance_variable_set(:@running, true)
      game.exit_game
      expect(game.running).to be false
    end
  end
end
