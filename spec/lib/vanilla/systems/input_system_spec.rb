require 'spec_helper'

RSpec.describe Vanilla::Systems::InputSystem do
  let(:world) { instance_double("Vanilla::World", keyboard: keyboard) }
  let(:keyboard) { instance_double("Vanilla::KeyboardHandler") }
  let(:player) { instance_double("Vanilla::Components::Entity", id: 'player-1') }
  let(:input_component) { instance_double("Vanilla::Components::InputComponent") }
  let(:system) { Vanilla::Systems::InputSystem.new(world) }

  before do
    allow(world).to receive(:find_entity_by_tag).with(:player).and_return(player)
    allow(player).to receive(:has_component?).with(:input).and_return(true)
    allow(player).to receive(:get_component).with(:input).and_return(input_component)
    allow(input_component).to receive(:set_move_direction)
    allow(input_component).to receive(:set_action_triggered)
    allow(world).to receive(:emit_event)
  end

  describe '#initialize' do
    it 'initializes with the world reference' do
      expect(system.world).to eq(world)
    end
  end

  describe '#update' do
    context 'when no player entity is found' do
      before do
        allow(world).to receive(:find_entity_by_tag).with(:player).and_return(nil)
      end

      it 'does nothing' do
        system.update(0.1)
        expect(world).not_to have_received(:emit_event)
      end
    end

    context 'when player has no input component' do
      before do
        allow(player).to receive(:has_component?).with(:input).and_return(false)
      end

      it 'does nothing' do
        system.update(0.1)
        expect(world).not_to have_received(:emit_event)
      end
    end

    context 'when processing movement input' do
      it 'sets north direction when up key is pressed' do
        allow(keyboard).to receive(:key_pressed?).with(:up).and_return(true)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_UP).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:down).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_DOWN).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:left).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_LEFT).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:right).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_RIGHT).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:k).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:j).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:h).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:l).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:space).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:i).and_return(false)

        system.update(0.1)

        expect(input_component).to have_received(:set_move_direction).with(:north)
      end

      it 'sets south direction when down key is pressed' do
        allow(keyboard).to receive(:key_pressed?).with(:up).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_UP).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:down).and_return(true)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_DOWN).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:left).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_LEFT).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:right).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_RIGHT).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:k).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:j).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:h).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:l).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:space).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:i).and_return(false)

        system.update(0.1)

        expect(input_component).to have_received(:set_move_direction).with(:south)
      end

      it 'sets west direction when left key is pressed' do
        allow(keyboard).to receive(:key_pressed?).with(:up).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_UP).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:down).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_DOWN).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:left).and_return(true)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_LEFT).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:right).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_RIGHT).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:k).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:j).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:h).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:l).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:space).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:i).and_return(false)

        system.update(0.1)

        expect(input_component).to have_received(:set_move_direction).with(:west)
      end

      it 'sets east direction when right key is pressed' do
        allow(keyboard).to receive(:key_pressed?).with(:up).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_UP).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:down).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_DOWN).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:left).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_LEFT).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:right).and_return(true)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_RIGHT).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:k).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:j).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:h).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:l).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:space).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:i).and_return(false)

        system.update(0.1)

        expect(input_component).to have_received(:set_move_direction).with(:east)
      end

      it 'sets nil direction when no movement keys are pressed' do
        allow(keyboard).to receive(:key_pressed?).with(:up).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_UP).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:down).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_DOWN).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:left).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_LEFT).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:right).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:KEY_RIGHT).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:k).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:j).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:h).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:l).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:space).and_return(false)
        allow(keyboard).to receive(:key_pressed?).with(:i).and_return(false)

        system.update(0.1)

        expect(input_component).to have_received(:set_move_direction).with(nil)
      end
    end

    context 'when processing action input' do
      before do
        # Setup default behavior for all keys
        allow(keyboard).to receive(:key_pressed?).with(any_args).and_return(false)
      end

      it 'sets action triggered when space is pressed' do
        allow(keyboard).to receive(:key_pressed?).with(:space).and_return(true)

        system.update(0.1)

        expect(input_component).to have_received(:set_action_triggered).with(true)
      end

      it 'sets action not triggered when space is not pressed' do
        allow(keyboard).to receive(:key_pressed?).with(:space).and_return(false)

        system.update(0.1)

        expect(input_component).to have_received(:set_action_triggered).with(false)
      end
    end

    context 'when processing inventory toggle' do
      before do
        # Setup default behavior for all keys
        allow(keyboard).to receive(:key_pressed?).with(any_args).and_return(false)
      end

      it 'emits inventory_toggled event when i is pressed' do
        allow(keyboard).to receive(:key_pressed?).with(:i).and_return(true)

        system.update(0.1)

        expect(world).to have_received(:emit_event).with(
          :inventory_toggled,
          { entity_id: player.id }
        )
      end

      it 'does not emit inventory_toggled event when i is not pressed' do
        allow(keyboard).to receive(:key_pressed?).with(:i).and_return(false)

        system.update(0.1)

        expect(world).not_to have_received(:emit_event).with(:inventory_toggled, any_args)
      end
    end

    it 'emits input_processed event after processing input' do
      # Setup default behavior for all keys
      allow(keyboard).to receive(:key_pressed?).with(any_args).and_return(false)

      system.update(0.1)

      expect(world).to have_received(:emit_event).with(
        :input_processed,
        { entity_id: player.id }
      )
    end
  end
end