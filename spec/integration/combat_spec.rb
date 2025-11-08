# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Combat Integration', type: :integration do
  let(:world) { Vanilla::World.new }
  let(:event_manager) { Vanilla::Events::EventManager.new(store_config: { file: false }) }
  let(:message_system) { Vanilla::Systems::MessageSystem.new(world) }

  let(:player) do
    Vanilla::EntityFactory.create_player(5, 5).tap do |p|
      # EntityFactory now creates CombatComponent, so we just update it for testing
      combat = p.get_component(:combat)
      combat.instance_variable_set(:@accuracy, 1.0) # 100% accuracy for testing
    end
  end

  let(:monster) do
    Vanilla::EntityFactory.create_monster('goblin', 5, 6, 20, 5)
    # EntityFactory now creates CombatComponent with attack_power: 5, defense: 1, accuracy: 0.7
  end

  before do
    Vanilla::ServiceRegistry.register(:event_manager, event_manager)
    Vanilla::ServiceRegistry.register(:message_system, message_system)
    world.add_entity(player)
    world.add_entity(monster)

    # Add required systems
    world.add_system(Vanilla::Systems::CombatSystem.new(world), 3)
    world.add_system(Vanilla::Systems::CollisionSystem.new(world), 3)
    world.add_system(message_system, 5)
  end

  after do
    Vanilla::ServiceRegistry.clear
  end

  describe 'player attacking monster on collision' do
    it 'player can attack monster when they collide' do
      # Move player into monster position
      player_position = player.get_component(:position)
      player_position.set_position(5, 6) # Same position as monster

      # Trigger collision
      world.emit_event(:entity_moved, {
        entity_id: player.id,
        old_position: { row: 5, column: 5 },
        new_position: { row: 5, column: 6 }
      })

      # Process collision
      collision_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::CollisionSystem) }&.first
      collision_system&.handle_event(:entity_moved, {
        entity_id: player.id,
        new_position: { row: 5, column: 6 }
      })

      # Verify collision event was emitted
      world.update(nil) # Process events

      # Now execute attack command
      attack_command = Vanilla::Commands::AttackCommand.new(player, monster)
      attack_command.execute(world)

      # Verify monster took damage
      monster_health = monster.get_component(:health)
      expect(monster_health.current_health).to be < 20
    end
  end

  describe 'combat integration with collision system' do
    it 'collision system can detect player-monster collision' do
      # Move player into monster position
      player_position = player.get_component(:position)
      monster_position = monster.get_component(:position)
      player_position.set_position(monster_position.row, monster_position.column)

      # Get collision system
      collision_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::CollisionSystem) }&.first
      expect(collision_system).not_to be_nil

      # Trigger entity_moved event which CollisionSystem handles
      world.emit_event(:entity_moved, {
        entity_id: player.id,
        old_position: { row: 5, column: 5 },
        new_position: { row: monster_position.row, column: monster_position.column }
      })

      # CollisionSystem should detect the collision
      collision_system.handle_event(:entity_moved, {
        entity_id: player.id,
        new_position: { row: monster_position.row, column: monster_position.column }
      })

      # Verify entities_collided event was emitted
      collision_events = []
      subscriber = double("CollisionSubscriber")
      allow(subscriber).to receive(:handle_event) do |event_type, data|
        collision_events << { type: event_type, data: data } if event_type == :entities_collided
      end

      world.subscribe(:entities_collided, subscriber)
      world.update(nil)

      # Should have collision event
      expect(collision_events).not_to be_empty
      expect(collision_events.first[:data][:entity_id]).to eq(player.id)
      expect(collision_events.first[:data][:other_entity_id]).to eq(monster.id)
    end
  end

  describe 'message system integration' do
    it 'shows combat messages when player attacks monster' do
      # Stub rand to guarantee hit
      allow_any_instance_of(Vanilla::Systems::CombatSystem).to receive(:rand).and_return(0.5)

      attack_command = Vanilla::Commands::AttackCommand.new(player, monster)
      attack_command.execute(world)
      
      # Process events first, then update systems (which processes message queue)
      world.update(nil) # This processes events and updates systems including MessageSystem
      message_system.update(nil) # Ensure message queue is processed

      # Check that combat message was added
      messages = message_system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
      combat_messages = messages.select { |m| m.category == :combat }
      expect(combat_messages).not_to be_empty
    end

    it 'shows kill message when monster dies' do
      monster_health = monster.get_component(:health)
      monster_health.current_health = 5

      # Stub rand to guarantee hit
      allow_any_instance_of(Vanilla::Systems::CombatSystem).to receive(:rand).and_return(0.5)

      attack_command = Vanilla::Commands::AttackCommand.new(player, monster)
      attack_command.execute(world)
      world.update(nil) # Process events and update systems
      message_system.update(nil) # Ensure message queue is processed

      # Check for kill message
      messages = message_system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
      kill_messages = messages.select { |m| m.content == "combat.player_kill" || (m.respond_to?(:key) && m.key == "combat.player_kill") }
      expect(kill_messages).not_to be_empty
    end

    it 'shows miss message when attack misses' do
      # Set player accuracy to 0 to guarantee miss
      player_combat = player.get_component(:combat)
      player_combat.instance_variable_set(:@accuracy, 0.0)

      # Stub rand to return value > 0 (miss)
      allow_any_instance_of(Vanilla::Systems::CombatSystem).to receive(:rand).and_return(0.5)

      attack_command = Vanilla::Commands::AttackCommand.new(player, monster)
      attack_command.execute(world)
      world.update(nil) # Process events and update systems
      message_system.update(nil) # Ensure message queue is processed

      # Check for miss message
      messages = message_system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
      miss_messages = messages.select { |m| m.content == "combat.player_miss" || (m.respond_to?(:key) && m.key == "combat.player_miss") }
      expect(miss_messages).not_to be_empty
    end
  end

  describe 'monster dies after taking enough damage' do
    it 'removes monster from world when health reaches 0' do
      # Set monster health to low value
      monster_health = monster.get_component(:health)
      monster_health.current_health = 5

      # Execute attack that will kill monster
      attack_command = Vanilla::Commands::AttackCommand.new(player, monster)
      attack_command.execute(world)

      # Process events to handle death
      world.update(nil)

      # Verify monster is removed
      expect(world.get_entity(monster.id)).to be_nil
    end

    it 'emits combat_death event when monster dies' do
      monster_health = monster.get_component(:health)
      monster_health.current_health = 5

      # Subscribe to World's event system
      death_events = []
      subscriber = double("DeathSubscriber")
      allow(subscriber).to receive(:handle_event) do |event_type, data|
        death_events << { type: event_type, data: data } if event_type == :combat_death
      end

      world.subscribe(:combat_death, subscriber)

      attack_command = Vanilla::Commands::AttackCommand.new(player, monster)
      attack_command.execute(world)
      world.update(nil)

      expect(death_events).not_to be_empty
      expect(death_events.first[:data][:entity_id]).to eq(monster.id)
    end
  end

  describe 'player can continue attacking same monster' do
    it 'allows multiple attacks on the same monster' do
      initial_health = monster.get_component(:health).current_health

      # First attack
      attack1 = Vanilla::Commands::AttackCommand.new(player, monster)
      attack1.execute(world)
      health_after_first = monster.get_component(:health).current_health
      expect(health_after_first).to be < initial_health

      # Second attack
      attack2 = Vanilla::Commands::AttackCommand.new(player, monster)
      attack2.execute(world)
      health_after_second = monster.get_component(:health).current_health
      expect(health_after_second).to be < health_after_first
    end
  end

  describe 'combat damage calculation' do
    it 'calculates damage correctly based on attack_power and defense' do
      initial_health = monster.get_component(:health).current_health
      player_combat = player.get_component(:combat)
      monster_combat = monster.get_component(:combat)

      expected_damage = [player_combat.attack_power - monster_combat.defense, 1].max

      attack_command = Vanilla::Commands::AttackCommand.new(player, monster)
      attack_command.execute(world)

      final_health = monster.get_component(:health).current_health
      actual_damage = initial_health - final_health

      expect(actual_damage).to eq(expected_damage)
    end

    it 'applies minimum damage of 1 even when defense is high' do
      # Create monster with very high defense
      strong_monster = Vanilla::EntityFactory.create_monster('tank', 10, 10, 50, 1).tap do |m|
        # EntityFactory creates CombatComponent, so we update it
        combat = m.get_component(:combat)
        combat.instance_variable_set(:@defense, 100) # Very high defense
      end
      world.add_entity(strong_monster)

      initial_health = strong_monster.get_component(:health).current_health

      attack_command = Vanilla::Commands::AttackCommand.new(player, strong_monster)
      attack_command.execute(world)

      final_health = strong_monster.get_component(:health).current_health
      damage = initial_health - final_health

      expect(damage).to eq(1) # Minimum damage
    end
  end

  describe 'accuracy affects hit chance' do
    it 'can miss attacks based on accuracy' do
      # Set player accuracy to 0 to guarantee miss
      player_combat = player.get_component(:combat)
      player_combat.instance_variable_set(:@accuracy, 0.0)

      initial_health = monster.get_component(:health).current_health

      # Stub rand to return value > 0 (miss)
      allow_any_instance_of(Vanilla::Systems::CombatSystem).to receive(:rand).and_return(0.5)

      attack_command = Vanilla::Commands::AttackCommand.new(player, monster)
      attack_command.execute(world)

      final_health = monster.get_component(:health).current_health
      expect(final_health).to eq(initial_health) # No damage on miss
    end

    it 'hits when accuracy check passes' do
      player_combat = player.get_component(:combat)
      player_combat.instance_variable_set(:@accuracy, 1.0) # 100% accuracy

      initial_health = monster.get_component(:health).current_health

      # Stub rand to return value < 1.0 (hit)
      allow_any_instance_of(Vanilla::Systems::CombatSystem).to receive(:rand).and_return(0.5)

      attack_command = Vanilla::Commands::AttackCommand.new(player, monster)
      attack_command.execute(world)

      final_health = monster.get_component(:health).current_health
      expect(final_health).to be < initial_health # Damage applied on hit
    end
  end

  describe 'combat events are emitted' do
    it 'emits combat_attack event when attack is initiated' do
      attack_events = []
      subscriber = double("AttackSubscriber")
      allow(subscriber).to receive(:handle_event) do |event_type, data|
        attack_events << { type: event_type, data: data } if event_type == :combat_attack
      end

      world.subscribe(:combat_attack, subscriber)

      attack_command = Vanilla::Commands::AttackCommand.new(player, monster)
      attack_command.execute(world)
      world.update(nil)

      expect(attack_events).not_to be_empty
      expect(attack_events.first[:data][:attacker_id]).to eq(player.id)
      expect(attack_events.first[:data][:target_id]).to eq(monster.id)
    end

    it 'emits combat_damage event when damage is dealt' do
      damage_events = []
      subscriber = double("DamageSubscriber")
      allow(subscriber).to receive(:handle_event) do |event_type, data|
        damage_events << { type: event_type, data: data } if event_type == :combat_damage
      end

      world.subscribe(:combat_damage, subscriber)

      # Stub rand to guarantee hit
      allow_any_instance_of(Vanilla::Systems::CombatSystem).to receive(:rand).and_return(0.5)

      attack_command = Vanilla::Commands::AttackCommand.new(player, monster)
      attack_command.execute(world)
      world.update(nil)

      expect(damage_events).not_to be_empty
      expect(damage_events.first[:data][:target_id]).to eq(monster.id)
      expect(damage_events.first[:data][:damage]).to be > 0
      expect(damage_events.first[:data][:source_id]).to eq(player.id)
    end
  end
end

