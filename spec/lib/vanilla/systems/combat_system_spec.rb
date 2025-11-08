# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Systems::CombatSystem do
  let(:world) { instance_double('Vanilla::World') }
  let(:system) { described_class.new(world) }
  let(:logger) { instance_double('Vanilla::Logger') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
  end

  describe '#initialize' do
    it 'initializes with a world reference' do
      expect(system.world).to eq(world)
    end
  end

  describe '#calculate_damage' do
    let(:attacker_combat) { Vanilla::Components::CombatComponent.new(attack_power: 10, defense: 2) }
    let(:defender_combat) { Vanilla::Components::CombatComponent.new(attack_power: 5, defense: 3) }

    it 'calculates damage based on attack_power and defense' do
      damage = system.calculate_damage(attacker_combat, defender_combat)
      expect(damage).to eq(7) # 10 attack - 3 defense = 7
    end

    it 'applies minimum damage of 1' do
      weak_attacker = Vanilla::Components::CombatComponent.new(attack_power: 2, defense: 5)
      strong_defender = Vanilla::Components::CombatComponent.new(attack_power: 10, defense: 10)
      damage = system.calculate_damage(weak_attacker, strong_defender)
      expect(damage).to eq(1) # Minimum damage
    end

    it 'handles zero defense' do
      no_defense = Vanilla::Components::CombatComponent.new(attack_power: 5, defense: 0)
      damage = system.calculate_damage(attacker_combat, no_defense)
      expect(damage).to eq(10) # Full attack power
    end

    it 'handles defense greater than attack' do
      strong_defense = Vanilla::Components::CombatComponent.new(attack_power: 5, defense: 15)
      damage = system.calculate_damage(attacker_combat, strong_defense)
      expect(damage).to eq(1) # Minimum damage
    end
  end

  describe '#apply_damage' do
    let(:target) { Vanilla::Entities::Entity.new }
    let(:health_component) { Vanilla::Components::HealthComponent.new(max_health: 100, current_health: 50) }

    before do
      target.add_component(health_component)
      allow(world).to receive(:get_entity).and_return(target)
      allow(world).to receive(:emit_event)
    end

    it 'reduces target health by damage amount' do
      system.apply_damage(target, 10)
      expect(health_component.current_health).to eq(40)
    end

    it 'does not reduce health below 0' do
      system.apply_damage(target, 100)
      expect(health_component.current_health).to eq(0)
    end

    it 'emits combat_damage event' do
      expect(world).to receive(:emit_event).with(:combat_damage, hash_including(
        target_id: target.id,
        damage: 10
      ))
      system.apply_damage(target, 10)
    end

    it 'includes source_id in event if provided' do
      attacker = Vanilla::Entities::Entity.new
      expect(world).to receive(:emit_event).with(:combat_damage, hash_including(
        target_id: target.id,
        damage: 10,
        source_id: attacker.id
      ))
      system.apply_damage(target, 10, attacker)
    end
  end

  describe '#check_death' do
    let(:entity) { Vanilla::Entities::Entity.new }
    let(:health_component) { Vanilla::Components::HealthComponent.new(max_health: 100, current_health: 0) }

    before do
      entity.add_component(health_component)
      allow(world).to receive(:get_entity).and_return(entity)
      allow(world).to receive(:emit_event)
      allow(world).to receive(:remove_entity)
    end

    it 'detects when entity health reaches 0' do
      expect(system.check_death(entity)).to be true
    end

    it 'returns false when entity has health remaining' do
      health_component.current_health = 10
      expect(system.check_death(entity)).to be false
    end

    it 'returns false when entity has no health component' do
      entity_without_health = Vanilla::Entities::Entity.new
      expect(system.check_death(entity_without_health)).to be false
    end

    it 'emits combat_death event when entity dies' do
      killer = Vanilla::Entities::Entity.new
      expect(world).to receive(:emit_event).with(:combat_death, hash_including(
        entity_id: entity.id,
        killer_id: killer.id
      ))
      system.check_death(entity, killer)
    end

    it 'removes entity from world when it dies' do
      expect(world).to receive(:remove_entity).with(entity.id)
      system.check_death(entity)
    end
  end

  describe 'integration' do
    let(:attacker) { Vanilla::Entities::Entity.new }
    let(:target) { Vanilla::Entities::Entity.new }
    let(:attacker_combat) { Vanilla::Components::CombatComponent.new(attack_power: 10, defense: 2) }
    let(:target_combat) { Vanilla::Components::CombatComponent.new(attack_power: 5, defense: 3) }
    let(:target_health) { Vanilla::Components::HealthComponent.new(max_health: 50, current_health: 50) }

    before do
      attacker.add_component(attacker_combat)
      target.add_component(target_combat)
      target.add_component(target_health)
      allow(world).to receive(:get_entity).and_return(target)
      allow(world).to receive(:emit_event)
      allow(world).to receive(:remove_entity)
    end

    it 'handles full attack sequence' do
      # Stub rand to guarantee hit (rand < accuracy when accuracy is 0.8)
      allow(system).to receive(:rand).and_return(0.5) # 0.5 < 0.8, so hit
      expect(world).to receive(:emit_event).with(:combat_attack, anything)
      expect(world).to receive(:emit_event).with(:combat_damage, anything)
      system.process_attack(attacker, target)
      expect(target_health.current_health).to be < 50
    end

    it 'handles player killing monster' do
      target_health.current_health = 5
      allow(system).to receive(:rand).and_return(0.5) # Guarantee hit
      expect(world).to receive(:emit_event).with(:combat_attack, anything)
      expect(world).to receive(:emit_event).with(:combat_damage, anything)
      expect(world).to receive(:emit_event).with(:combat_death, anything)
      expect(world).to receive(:remove_entity).with(target.id)
      system.process_attack(attacker, target)
    end

    it 'handles miss based on accuracy' do
      # Set attacker accuracy to 0 to guarantee miss
      attacker_combat.instance_variable_set(:@accuracy, 0.0)
      allow(system).to receive(:rand).and_return(0.5) # Random > 0.0, so miss

      expect(world).to receive(:emit_event).with(:combat_attack, anything)
      expect(world).not_to receive(:emit_event).with(:combat_damage, anything)
      system.process_attack(attacker, target)
      expect(target_health.current_health).to eq(50) # No damage
    end
  end
end

