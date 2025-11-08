# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Systems::MessageSystem do
  let(:world) { instance_double('Vanilla::World') }
  let(:system) { described_class.new(world) }
  let(:logger) { instance_double('Vanilla::Logger') }
  let(:player) { Vanilla::Entities::Entity.new.tap { |e| e.name = "Player"; e.add_tag(:player) } }
  let(:monster) { Vanilla::Entities::Entity.new.tap { |e| e.name = "Goblin"; e.add_tag(:monster) } }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:warn)
    allow(world).to receive(:subscribe)
    allow(world).to receive(:queue_command)
    allow(world).to receive(:get_entity).and_return(nil)
    allow(Vanilla::ServiceRegistry).to receive(:register)
  end

  describe 'combat event handling' do
    before do
      allow(world).to receive(:get_entity).with(player.id).and_return(player)
      allow(world).to receive(:get_entity).with(monster.id).and_return(monster)
    end

    describe '#handle_combat_damage' do
      it 'shows player hit message when player attacks' do
        system.handle_event(:combat_damage, {
          target_id: monster.id,
          source_id: player.id,
          damage: 10
        })

        system.update(nil) # Process message queue

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        combat_messages = messages.select { |m| m.category == :combat }
        expect(combat_messages).not_to be_empty
        expect(combat_messages.first.content).to eq("combat.player_hit")
      end

      it 'shows enemy hit message when player is attacked' do
        system.handle_event(:combat_damage, {
          target_id: player.id,
          source_id: monster.id,
          damage: 5
        })

        system.update(nil) # Process message queue

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        combat_messages = messages.select { |m| m.category == :combat }
        expect(combat_messages).not_to be_empty
        expect(combat_messages.first.content).to eq("combat.enemy_hit")
      end
    end

    describe '#handle_combat_miss' do
      it 'shows player miss message when player misses' do
        system.handle_event(:combat_miss, {
          attacker_id: player.id,
          target_id: monster.id
        })

        system.update(nil) # Process message queue

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        combat_messages = messages.select { |m| m.category == :combat }
        expect(combat_messages).not_to be_empty
        expect(combat_messages.first.content).to eq("combat.player_miss")
      end

      it 'shows enemy miss message when enemy misses player' do
        system.handle_event(:combat_miss, {
          attacker_id: monster.id,
          target_id: player.id
        })

        system.update(nil) # Process message queue

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        combat_messages = messages.select { |m| m.category == :combat }
        expect(combat_messages).not_to be_empty
        expect(combat_messages.first.content).to eq("combat.enemy_miss")
      end
    end

    describe '#handle_combat_death' do
      it 'shows player kill message when player kills monster' do
        system.handle_event(:combat_death, {
          entity_id: monster.id,
          killer_id: player.id
        })

        system.update(nil) # Process message queue

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        combat_messages = messages.select { |m| m.category == :combat }
        expect(combat_messages).not_to be_empty
        expect(combat_messages.first.content).to eq("combat.player_kill")
      end

      it 'shows player death message when player is killed' do
        system.handle_event(:combat_death, {
          entity_id: player.id,
          killer_id: monster.id
        })

        system.update(nil) # Process message queue

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        combat_messages = messages.select { |m| m.category == :combat }
        expect(combat_messages).not_to be_empty
        expect(combat_messages.first.content).to eq("death.player_dies")
      end
    end
  end

  describe '#handle_attack_monster_callback' do
    before do
      allow(world).to receive(:get_entity).with(player.id).and_return(player)
      allow(world).to receive(:get_entity).with(monster.id).and_return(monster)
      system.instance_variable_set(:@last_collision_data, {
        entity_id: player.id,
        other_entity_id: monster.id,
        position: { row: 5, column: 6 }
      })
    end

    it 'creates and queues AttackCommand when callback is triggered' do
      expect(world).to receive(:queue_command) do |command|
        expect(command).to be_a(Vanilla::Commands::AttackCommand)
        expect(command.attacker).to eq(player)
        expect(command.target).to eq(monster)
      end

      system.handle_attack_monster_callback
    end

    it 'handles missing collision data gracefully' do
      system.instance_variable_set(:@last_collision_data, nil)
      expect { system.handle_attack_monster_callback }.not_to raise_error
    end

    it 'handles missing entities gracefully' do
      allow(world).to receive(:get_entity).and_return(nil)
      expect { system.handle_attack_monster_callback }.not_to raise_error
    end
  end

  describe 'collision message with attack option' do
    before do
      allow(world).to receive(:get_entity).with(player.id).and_return(player)
      allow(world).to receive(:get_entity).with(monster.id).and_return(monster)
    end

    it 'shows attack option when player collides with monster' do
      system.handle_event(:entities_collided, {
        entity_id: player.id,
        other_entity_id: monster.id,
        position: { row: 5, column: 6 }
      })

      system.update(nil) # Process message queue

      messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
      collision_messages = messages.select { |m| m.content == "combat.collision" || m.key == "combat.collision" }
      expect(collision_messages).not_to be_empty

      message = collision_messages.first
      expect(message.options).not_to be_empty
      expect(message.options.first[:key]).to eq('1')
      expect(message.options.first[:callback]).to eq(:attack_monster)
    end
  end
end

