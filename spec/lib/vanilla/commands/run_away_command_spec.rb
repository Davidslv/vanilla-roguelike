# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Commands::RunAwayCommand do
  let(:world) { instance_double('Vanilla::World') }
  let(:player) { Vanilla::Entities::Entity.new.tap { |e| e.name = "Player"; e.add_tag(:player) } }
  let(:monster) { Vanilla::Entities::Entity.new.tap { |e| e.name = "Goblin"; e.add_tag(:monster) } }
  let(:logger) { instance_double('Vanilla::Logger') }
  let(:combat_system) { instance_double('Vanilla::Systems::CombatSystem') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:warn)
    allow(world).to receive(:emit_event)
    allow(world).to receive(:systems).and_return([[combat_system, 3]])
    allow(combat_system).to receive(:is_a?).with(Vanilla::Systems::CombatSystem).and_return(true)
    allow(combat_system).to receive(:process_attack)
  end

  describe '#initialize' do
    it 'sets player and monster' do
      command = described_class.new(player, monster)
      expect(command.player).to eq(player)
      expect(command.monster).to eq(monster)
    end
  end

  describe '#execute' do
    let(:command) { described_class.new(player, monster) }

    context 'when flee succeeds' do
      it 'moves player away and emits flee success event' do
        # Stub calculate_flee_chance to return high chance, and rand to succeed
        allow(command).to receive(:calculate_flee_chance).and_return(0.50) # 50% chance
        allow(command).to receive(:rand).and_return(0.10) # rand < 0.50, so succeeds

        expect(world).to receive(:emit_event).with(:combat_flee_success, hash_including(
          player_id: player.id,
          monster_id: monster.id
        ))

        expect(world).not_to receive(:emit_event).with(:combat_flee_failed, anything)
        expect(combat_system).not_to receive(:process_attack)

        command.execute(world)
        expect(command.instance_variable_get(:@executed)).to be true
      end
    end

    context 'when flee fails' do
      it 'monster attacks player and emits flee failed event' do
        # Stub calculate_flee_chance to return low chance, and rand to fail
        allow(command).to receive(:calculate_flee_chance).and_return(0.10) # 10% chance
        allow(command).to receive(:rand).and_return(0.50) # rand > 0.10, so fails

        expect(world).to receive(:emit_event).with(:combat_flee_failed, hash_including(
          player_id: player.id,
          monster_id: monster.id
        ))

        expect(combat_system).to receive(:process_attack).with(monster, player)

        command.execute(world)
        expect(command.instance_variable_get(:@executed)).to be true
      end
    end

    context 'flee chance calculation' do
      it 'calculates flee chance between 1-30%' do
        # Test multiple times to ensure range
        chances = 100.times.map do
          cmd = described_class.new(player, monster)
          cmd.send(:calculate_flee_chance)
        end

        chances.each do |chance|
          expect(chance).to be >= 0.01
          expect(chance).to be <= 0.30
        end
      end
    end

    context 'when player or monster is nil' do
      it 'handles nil player gracefully' do
        command = described_class.new(nil, monster)
        expect { command.execute(world) }.not_to raise_error
        expect(command.instance_variable_get(:@executed)).to be true
        expect(world).not_to receive(:emit_event)
      end

      it 'handles nil monster gracefully' do
        command = described_class.new(player, nil)
        expect { command.execute(world) }.not_to raise_error
        expect(command.instance_variable_get(:@executed)).to be true
        expect(world).not_to receive(:emit_event)
      end
    end

    it 'does not execute twice' do
      allow(command).to receive(:calculate_flee_chance).and_return(0.50)
      allow(command).to receive(:rand).and_return(0.10)
      allow(world).to receive(:emit_event)

      command.execute(world)
      expect(command.instance_variable_get(:@executed)).to be true

      # Second execution should not emit events
      expect(world).not_to receive(:emit_event)
      command.execute(world)
    end
  end
end

