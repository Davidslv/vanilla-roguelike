# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Systems::CombatSystem do
  let(:world) { instance_double('Vanilla::World') }
  let(:system) { described_class.new(world) }
  let(:logger) { instance_double('Vanilla::Logger') }
  let(:player) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.name = "Player"
      e.add_tag(:player)
      e.add_component(Vanilla::Components::HealthComponent.new(max_health: 100))
      e.add_component(Vanilla::Components::CombatComponent.new(attack_power: 10, defense: 2, accuracy: 1.0))
    end
  end
  let(:monster) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.name = "Goblin"
      e.add_tag(:monster)
      e.add_component(Vanilla::Components::HealthComponent.new(max_health: 20))
      e.add_component(Vanilla::Components::CombatComponent.new(attack_power: 5, defense: 1, accuracy: 0.8))
    end
  end

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:warn)
    allow(world).to receive(:emit_event)
    allow(world).to receive(:remove_entity)
    allow(world).to receive(:get_entity).and_return(nil)
  end

  describe 'turn-based combat' do
    before do
      allow(world).to receive(:get_entity).with(player.id).and_return(player)
      allow(world).to receive(:get_entity).with(monster.id).and_return(monster)
    end

    it 'player attacks first in turn-based combat' do
      # Set monster health high so combat continues for a few rounds
      monster.get_component(:health).current_health = 50

      # Stub rand to guarantee hits
      allow(system).to receive(:rand).and_return(0.5)

      # Track turn order
      turn_order = []
      original_player_turn = system.method(:player_turn)
      original_monster_turn = system.method(:monster_turn)

      allow(system).to receive(:player_turn) do
        turn_order << :player
        original_player_turn.call
      end

      allow(system).to receive(:monster_turn) do
        turn_order << :monster
        original_monster_turn.call
      end

      # Limit to 2 rounds
      call_count = 0
      allow(system).to receive(:combat_active?) do
        call_count += 1
        call_count <= 2
      end

      system.process_turn_based_combat(player, monster)

      # Player should attack first
      expect(turn_order.first).to eq(:player)
    end

    it 'monster counter-attacks after player' do
      # Set monster health high so combat continues
      monster.get_component(:health).current_health = 50
      player.get_component(:health).current_health = 100

      # Stub rand to guarantee hits
      allow(system).to receive(:rand).and_return(0.5)

      # Track turn order
      turn_order = []
      original_player_turn = system.method(:player_turn)
      original_monster_turn = system.method(:monster_turn)

      allow(system).to receive(:player_turn) do
        turn_order << :player
        original_player_turn.call
      end

      allow(system).to receive(:monster_turn) do
        turn_order << :monster
        original_monster_turn.call
      end

      # Ensure combat stays active for at least 2 turns
      combat_check_count = 0
      allow(system).to receive(:combat_active?) do
        combat_check_count += 1
        # Return true for first 3 checks (before player turn, after player turn, before monster turn)
        # This ensures both player and monster get a turn
        combat_check_count <= 3
      end

      system.process_turn_based_combat(player, monster)

      # Player should attack first, then monster
      expect(turn_order[0]).to eq(:player)
      expect(turn_order[1]).to eq(:monster)
    end

    it 'continues combat until one dies' do
      # Set monster health so it dies after a few hits
      monster.get_component(:health).current_health = 15

      # Stub rand to guarantee hits
      allow(system).to receive(:rand).and_return(0.5)

      # Track number of turns
      turn_count = 0
      original_player_turn = system.method(:player_turn)
      original_monster_turn = system.method(:monster_turn)

      allow(system).to receive(:player_turn) do
        turn_count += 1
        original_player_turn.call
      end

      allow(system).to receive(:monster_turn) do
        turn_count += 1
        original_monster_turn.call
      end

      system.process_turn_based_combat(player, monster)

      # Should have at least one turn
      expect(turn_count).to be >= 1
    end

    it 'clears combat state when combat ends' do
      # Set monster health low so it dies quickly
      monster.get_component(:health).current_health = 5

      # Stub rand to guarantee hits
      allow(system).to receive(:rand).and_return(0.5)

      system.process_turn_based_combat(player, monster)

      # Combat state should be cleared
      expect(system.instance_variable_get(:@active_combat)).to be_nil
    end

    it 'stops combat if player dies' do
      # Set player health low
      player.get_component(:health).current_health = 3

      # Stub rand to guarantee hits
      allow(system).to receive(:rand).and_return(0.5)

      system.process_turn_based_combat(player, monster)

      # Combat should have ended
      expect(system.instance_variable_get(:@active_combat)).to be_nil
    end

    it 'stops combat if monster dies' do
      # Set monster health low
      monster.get_component(:health).current_health = 5

      # Stub rand to guarantee hits
      allow(system).to receive(:rand).and_return(0.5)

      system.process_turn_based_combat(player, monster)

      # Combat should have ended
      expect(system.instance_variable_get(:@active_combat)).to be_nil
    end
  end
end

