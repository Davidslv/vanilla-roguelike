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

  describe 'enhanced combat menu' do
    before do
      allow(world).to receive(:get_entity).with(player.id).and_return(player)
      allow(world).to receive(:get_entity).with(monster.id).and_return(monster)
    end

    it 'shows menu with attack and run away options on collision' do
      system.handle_event(:entities_collided, {
        entity_id: player.id,
        other_entity_id: monster.id,
        position: { row: 5, column: 6 }
      })

      system.update(nil) # Process message queue

      messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
      collision_messages = messages.select { |m| m.content == "combat.collision" || (m.respond_to?(:key) && m.key == "combat.collision") }
      expect(collision_messages).not_to be_empty

      message = collision_messages.first
      expect(message.options).not_to be_empty
      expect(message.options.size).to eq(2)

      # Check option 1 (Attack)
      attack_option = message.options.find { |opt| opt[:key] == '1' }
      expect(attack_option).not_to be_nil
      expect(attack_option[:callback]).to eq(:attack_monster)
      expect(attack_option[:content]).to include("Attack")

      # Check option 2 (Run Away)
      run_away_option = message.options.find { |opt| opt[:key] == '2' }
      expect(run_away_option).not_to be_nil
      expect(run_away_option[:callback]).to eq(:run_away_from_monster)
      expect(run_away_option[:content]).to include("Run Away")
    end

    it 'option 1 triggers attack command' do
      system.instance_variable_set(:@last_collision_data, {
        entity_id: player.id,
        other_entity_id: monster.id,
        position: { row: 5, column: 6 }
      })

      # Set up positions
      player.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 6)) unless player.get_component(:position)
      monster.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 6)) unless monster.get_component(:position)

      # Add options to message log so handle_input can find them
      allow(system.instance_variable_get(:@manager)).to receive(:options).and_return([
        { key: '1', content: "Attack Goblin [1]", callback: :attack_monster },
        { key: '2', content: "Run Away [2]", callback: :run_away_from_monster }
      ])

      expect(world).to receive(:queue_command) do |command|
        expect(command).to be_a(Vanilla::Commands::AttackCommand)
      end

      # Simulate selecting option 1
      system.handle_input('1')
    end

    it 'option 2 triggers run away command' do
      system.instance_variable_set(:@last_collision_data, {
        entity_id: player.id,
        other_entity_id: monster.id,
        position: { row: 5, column: 6 }
      })

      # Set up positions
      player.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 6)) unless player.get_component(:position)
      monster.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 6)) unless monster.get_component(:position)

      # Add options to message log so handle_input can find them
      allow(system.instance_variable_get(:@manager)).to receive(:options).and_return([
        { key: '1', content: "Attack Goblin [1]", callback: :attack_monster },
        { key: '2', content: "Run Away [2]", callback: :run_away_from_monster }
      ])

      expect(world).to receive(:queue_command) do |command|
        expect(command).to be_a(Vanilla::Commands::RunAwayCommand)
      end

      # Simulate selecting option 2
      system.handle_input('2')
    end

    it 'menu options are properly formatted with enemy name' do
      monster.name = "Troll"

      system.handle_event(:entities_collided, {
        entity_id: player.id,
        other_entity_id: monster.id,
        position: { row: 5, column: 6 }
      })

      system.update(nil) # Process message queue

      messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
      collision_messages = messages.select { |m| m.content == "combat.collision" || (m.respond_to?(:key) && m.key == "combat.collision") }
      message = collision_messages.first

      attack_option = message.options.find { |opt| opt[:key] == '1' }
      expect(attack_option[:content]).to include("Troll")
    end
  end
end

