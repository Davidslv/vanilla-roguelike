require 'spec_helper'

RSpec.describe Vanilla::Systems::InputSystem do
  let(:world) { Vanilla::World.new }
  let(:keyboard) { double('Keyboard') }
  let(:input_system) { described_class.new(world, keyboard) }

  let(:player) do
    player = Vanilla::EntityFactory.create_player(world, 5, 10)
    # Remove the player from world to add it manually for testing
    world.remove_entity(player.id)
    player
  end

  before do
    # Default keyboard behavior - no keys pressed
    allow(keyboard).to receive(:key_pressed?).and_return(false)
  end

  describe '#update' do
    it 'does nothing when there is no player entity' do
      # Don't add player to world

      # This should not raise any errors
      input_system.update(0.1)
    end

    it 'emits movement_requested event when movement key is pressed' do
      # Add player to world
      world.add_entity(player)

      # Mock up arrow key press
      allow(keyboard).to receive(:key_pressed?).with(:up).and_return(true)

      # Create a spy system to catch events
      spy_system = Vanilla::Systems::TestSystem.new(world)
      world.subscribe(:movement_requested, spy_system)

      # Update the input system
      input_system.update(0.1)

      # Process events
      world.update(0.1)

      # Verify movement event was emitted
      expect(spy_system.event_handled).to be true
      expect(spy_system.last_event[:type]).to eq(:movement_requested)
      expect(spy_system.last_event[:data][:entity_id]).to eq(player.id)
      expect(spy_system.last_event[:data][:direction]).to eq(:north)
    end

    it 'emits action_requested event when action key is pressed' do
      # Add player to world
      world.add_entity(player)

      # Mock space key press
      allow(keyboard).to receive(:key_pressed?).with(:space).and_return(true)

      # Create a spy system to catch events
      spy_system = Vanilla::Systems::TestSystem.new(world)
      world.subscribe(:action_requested, spy_system)

      # Update the input system
      input_system.update(0.1)

      # Process events
      world.update(0.1)

      # Verify action event was emitted
      expect(spy_system.event_handled).to be true
      expect(spy_system.last_event[:type]).to eq(:action_requested)
      expect(spy_system.last_event[:data][:entity_id]).to eq(player.id)
      expect(spy_system.last_event[:data][:action_type]).to eq(:primary_action)
    end

    it 'emits inventory_toggle_requested event when inventory key is pressed' do
      # Add player to world
      world.add_entity(player)

      # Mock inventory key press
      allow(keyboard).to receive(:key_pressed?).with(:i).and_return(true)

      # Create a spy system to catch events
      spy_system = Vanilla::Systems::TestSystem.new(world)
      world.subscribe(:inventory_toggle_requested, spy_system)

      # Update the input system
      input_system.update(0.1)

      # Process events
      world.update(0.1)

      # Verify inventory event was emitted
      expect(spy_system.event_handled).to be true
      expect(spy_system.last_event[:type]).to eq(:inventory_toggle_requested)
      expect(spy_system.last_event[:data][:entity_id]).to eq(player.id)
    end

    it 'handles multiple key input types' do
      # Add player to world
      world.add_entity(player)

      # Test WASD keys
      allow(keyboard).to receive(:key_pressed?).with(:w).and_return(true)

      # Create a spy system to catch events
      spy_system = Vanilla::Systems::TestSystem.new(world)
      world.subscribe(:movement_requested, spy_system)

      # Update the input system
      input_system.update(0.1)

      # Process events
      world.update(0.1)

      # Verify north movement was triggered
      expect(spy_system.last_event[:data][:direction]).to eq(:north)
    end
  end
end