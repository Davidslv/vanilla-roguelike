# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Commands::AttackCommand do
  let(:world) { instance_double('Vanilla::World') }
  let(:attacker) { Vanilla::Entities::Entity.new }
  let(:target) { Vanilla::Entities::Entity.new }
  let(:combat_system) { instance_double('Vanilla::Systems::CombatSystem') }
  let(:logger) { instance_double('Vanilla::Logger') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:warn)
  end

  describe '#initialize' do
    it 'sets attacker and target' do
      command = described_class.new(attacker, target)
      expect(command.attacker).to eq(attacker)
      expect(command.target).to eq(target)
    end
  end

  describe '#execute' do
    let(:command) { described_class.new(attacker, target) }

    context 'when CombatSystem exists' do
      before do
        allow(world).to receive(:systems).and_return([[combat_system, 3]])
        allow(combat_system).to receive(:is_a?).with(Vanilla::Systems::CombatSystem).and_return(true)
      end

      it 'calls CombatSystem to process attack' do
        expect(combat_system).to receive(:process_attack).with(attacker, target)
        command.execute(world)
      end

      it 'marks command as executed' do
        allow(combat_system).to receive(:process_attack)
        command.execute(world)
        expect(command.executed).to be true
      end

      it 'does not execute twice' do
        allow(combat_system).to receive(:process_attack)
        command.execute(world)
        expect(combat_system).not_to receive(:process_attack)
        command.execute(world)
      end
    end

    context 'when CombatSystem does not exist' do
      before do
        allow(world).to receive(:systems).and_return([])
      end

      it 'logs an error and does not execute' do
        expect(logger).to receive(:error).with(/No CombatSystem found/)
        expect { command.execute(world) }.not_to raise_error
      end
    end

    context 'when attacker is invalid' do
      it 'handles nil attacker gracefully' do
        command = described_class.new(nil, target)
        allow(world).to receive(:systems).and_return([[combat_system, 3]])
        allow(combat_system).to receive(:is_a?).with(Vanilla::Systems::CombatSystem).and_return(true)
        allow(combat_system).to receive(:process_attack).and_return(false)
        expect { command.execute(world) }.not_to raise_error
      end
    end

    context 'when target is invalid' do
      it 'handles nil target gracefully' do
        command = described_class.new(attacker, nil)
        allow(world).to receive(:systems).and_return([[combat_system, 3]])
        allow(combat_system).to receive(:is_a?).with(Vanilla::Systems::CombatSystem).and_return(true)
        allow(combat_system).to receive(:process_attack).and_return(false)
        expect { command.execute(world) }.not_to raise_error
      end
    end

    context 'when attacker lacks CombatComponent' do
      it 'handles missing component gracefully' do
        allow(world).to receive(:systems).and_return([[combat_system, 3]])
        allow(combat_system).to receive(:is_a?).with(Vanilla::Systems::CombatSystem).and_return(true)
        allow(combat_system).to receive(:process_attack).and_return(false)
        expect { command.execute(world) }.not_to raise_error
      end
    end
  end
end

