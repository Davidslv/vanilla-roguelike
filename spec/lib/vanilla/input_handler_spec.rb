# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::InputHandler do
  let(:world) { instance_double('Vanilla::World') }
  let(:logger) { instance_double('Vanilla::Logger') }
  let(:event_manager) { instance_double('Vanilla::Events::EventManager') }
  let(:player) { instance_double('Vanilla::Entity', id: 'player-id', name: 'Player') }

  # Command doubles
  let(:move_command) { instance_double('Vanilla::Commands::MoveCommand') }
  let(:exit_command) { instance_double('Vanilla::Commands::ExitCommand') }
  let(:null_command) { instance_double('Vanilla::Commands::NullCommand') }
  let(:toggle_menu_command) { instance_double('Vanilla::Commands::ToggleMenuModeCommand') }

  before do
    # Mock Logger
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:debug)

    # Mock ServiceRegistry
    allow(Vanilla::ServiceRegistry).to receive(:get).with(:event_manager).and_return(event_manager)

    # Mock EventManager
    allow(event_manager).to receive(:publish_event)

    # Mock World
    allow(world).to receive(:get_entity_by_name).with('Player').and_return(player)
    allow(world).to receive(:queue_command)

    # Mock command creation
    allow(Vanilla::Commands::MoveCommand).to receive(:new).and_return(move_command)
    allow(Vanilla::Commands::ExitCommand).to receive(:new).and_return(exit_command)
    allow(Vanilla::Commands::NullCommand).to receive(:new).and_return(null_command)
    allow(Vanilla::Commands::ToggleMenuModeCommand).to receive(:new).and_return(toggle_menu_command)
  end

  describe '#initialize' do
    it 'initializes with a world parameter and retrieves event_manager from ServiceRegistry' do
      expect(Vanilla::ServiceRegistry).to receive(:get).with(:event_manager).and_return(event_manager)
      input_handler = described_class.new(world)
      expect(input_handler.instance_variable_get(:@world)).to eq(world)
      expect(input_handler.instance_variable_get(:@event_manager)).to eq(event_manager)
    end
  end

  describe '#handle_input' do
    subject(:input_handler) { described_class.new(world) }

    context 'when the player entity is not found' do
      before do
        allow(world).to receive(:get_entity_by_name).with('Player').and_return(nil)
      end

      it 'logs an error and returns nil' do
        expect(logger).to receive(:error).with('[InputHandler] No player entity found')
        expect(input_handler.handle_input('k')).to be_nil
      end
    end

    context 'with valid player entity' do
      it 'publishes a key press event' do
        expect(event_manager).to receive(:publish_event).with(
          Vanilla::Events::Types::KEY_PRESSED,
          input_handler,
          { key: 'k', entity_id: 'player-id' }
        )
        input_handler.handle_input('k')
      end

      context 'with movement keys' do
        it 'creates a MoveCommand with :north direction for "k" key' do
          expect(Vanilla::Commands::MoveCommand).to receive(:new).with(player, :north).and_return(move_command)
          expect(world).to receive(:queue_command).with(move_command)
          expect(logger).to receive(:info).with('[InputHandler] User attempting to move NORTH')
          input_handler.handle_input('k')
        end

        it 'creates a MoveCommand with :south direction for "j" key' do
          expect(Vanilla::Commands::MoveCommand).to receive(:new).with(player, :south).and_return(move_command)
          expect(world).to receive(:queue_command).with(move_command)
          input_handler.handle_input('j')
        end

        it 'creates a MoveCommand with :east direction for "l" key' do
          expect(Vanilla::Commands::MoveCommand).to receive(:new).with(player, :east).and_return(move_command)
          expect(world).to receive(:queue_command).with(move_command)
          expect(logger).to receive(:info).with('[InputHandler] User attempting to move EAST')
          input_handler.handle_input('l')
        end

        it 'creates a MoveCommand with :west direction for "h" key' do
          expect(Vanilla::Commands::MoveCommand).to receive(:new).with(player, :west).and_return(move_command)
          expect(world).to receive(:queue_command).with(move_command)
          input_handler.handle_input('h')
        end
      end

      context 'with menu toggle key' do
        it 'creates a ToggleMenuModeCommand for "m" key' do
          expect(Vanilla::Commands::ToggleMenuModeCommand).to receive(:new).and_return(toggle_menu_command)
          expect(world).to receive(:queue_command).with(toggle_menu_command)
          expect(logger).to receive(:info).with('[InputHandler] User attempting to toggle message menu')
          input_handler.handle_input('m')
        end
      end

      context 'with exit keys' do
        it 'creates an ExitCommand for "q" key' do
          expect(Vanilla::Commands::ExitCommand).to receive(:new).and_return(exit_command)
          expect(world).to receive(:queue_command).with(exit_command)
          expect(logger).to receive(:info).with('[InputHandler] User attempting to exit game')
          input_handler.handle_input('q')
        end

        it 'creates an ExitCommand for Ctrl+C key' do
          expect(Vanilla::Commands::ExitCommand).to receive(:new).and_return(exit_command)
          expect(world).to receive(:queue_command).with(exit_command)
          expect(logger).to receive(:info).with('[InputHandler] User attempting to exit game')
          input_handler.handle_input("\C-c")
        end

        it 'creates an ExitCommand for unicode representation of Ctrl+C' do
          expect(Vanilla::Commands::ExitCommand).to receive(:new).and_return(exit_command)
          expect(world).to receive(:queue_command).with(exit_command)
          expect(logger).to receive(:info).with('[InputHandler] User attempting to exit game')
          input_handler.handle_input("\u0003")
        end
      end

      context 'with unknown key' do
        it 'creates a NullCommand for unknown key' do
          expect(Vanilla::Commands::NullCommand).to receive(:new).and_return(null_command)
          expect(world).to receive(:queue_command).with(null_command)
          expect(logger).to receive(:debug).with('[InputHandler] Unknown key pressed: "x"')
          input_handler.handle_input('x')
        end
      end

      it 'publishes a command issued event' do
        expect(event_manager).to receive(:publish_event).with(
          Vanilla::Events::Types::COMMAND_ISSUED,
          input_handler,
          { command: move_command }
        )
        input_handler.handle_input('k')
      end

      it 'returns the created command' do
        expect(input_handler.handle_input('k')).to eq(move_command)
      end
    end
  end
end
