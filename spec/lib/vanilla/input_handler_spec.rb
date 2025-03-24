require 'spec_helper'

RSpec.describe Vanilla::InputHandler do
  let(:grid) { instance_double('Vanilla::MapUtils::Grid') }
  let(:entity) { instance_double('Vanilla::Components::Entity') }
  let(:logger) { instance_double('Vanilla::Logger') }
  let(:render_system) { instance_double('Vanilla::Systems::RenderSystem') }
  let(:move_command) { instance_double('Vanilla::Commands::MoveCommand') }
  let(:exit_command) { instance_double('Vanilla::Commands::ExitCommand') }
  let(:null_command) { instance_double('Vanilla::Commands::NullCommand') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:debug)

    allow(Vanilla::Systems::RenderSystemFactory).to receive(:create).and_return(render_system)

    allow(Vanilla::Commands::MoveCommand).to receive(:new).and_return(move_command)
    allow(Vanilla::Commands::ExitCommand).to receive(:new).and_return(exit_command)
    allow(Vanilla::Commands::NullCommand).to receive(:new).and_return(null_command)

    allow(move_command).to receive(:execute)
    allow(exit_command).to receive(:execute)
    allow(null_command).to receive(:execute)
  end

  describe '#handle_input' do
    context 'with movement keys' do
      it 'creates and executes up movement command' do
        input_handler = described_class.new(logger, nil, render_system)

        expect(Vanilla::Commands::MoveCommand).to receive(:new).with(entity, :up, grid, render_system).and_return(move_command)
        expect(move_command).to receive(:execute)
        expect(logger).to receive(:info).with('Player attempting to move UP')

        input_handler.handle_input('k', entity, grid)
      end

      it 'creates and executes down movement command' do
        input_handler = described_class.new(logger, nil, render_system)

        expect(Vanilla::Commands::MoveCommand).to receive(:new).with(entity, :down, grid, render_system).and_return(move_command)
        expect(move_command).to receive(:execute)
        expect(logger).to receive(:info).with('Player attempting to move DOWN')

        input_handler.handle_input('j', entity, grid)
      end

      it 'creates and executes right movement command' do
        input_handler = described_class.new(logger, nil, render_system)

        expect(Vanilla::Commands::MoveCommand).to receive(:new).with(entity, :right, grid, render_system).and_return(move_command)
        expect(move_command).to receive(:execute)
        expect(logger).to receive(:info).with('Player attempting to move RIGHT')

        input_handler.handle_input('l', entity, grid)
      end

      it 'creates and executes left movement command' do
        input_handler = described_class.new(logger, nil, render_system)

        expect(Vanilla::Commands::MoveCommand).to receive(:new).with(entity, :left, grid, render_system).and_return(move_command)
        expect(move_command).to receive(:execute)
        expect(logger).to receive(:info).with('Player attempting to move LEFT')

        input_handler.handle_input('h', entity, grid)
      end
    end

    context 'with exit key' do
      it 'creates and executes exit command' do
        input_handler = described_class.new(logger, nil, render_system)

        expect(Vanilla::Commands::ExitCommand).to receive(:new).and_return(exit_command)
        expect(exit_command).to receive(:execute)

        input_handler.handle_input('q', entity, grid)
      end
    end

    context 'with unknown key' do
      it 'creates and executes null command' do
        input_handler = described_class.new(logger, nil, render_system)

        expect(Vanilla::Commands::NullCommand).to receive(:new).and_return(null_command)
        expect(null_command).to receive(:execute)
        expect(logger).to receive(:debug).with('Unknown key pressed: "x"')

        input_handler.handle_input('x', entity, grid)
      end
    end

    context 'when no render_system is provided' do
      it 'creates one via factory' do
        expect(Vanilla::Systems::RenderSystemFactory).to receive(:create).and_return(render_system)

        input_handler = described_class.new(logger)
        expect(Vanilla::Commands::MoveCommand).to receive(:new).with(entity, :up, grid, render_system).and_return(move_command)

        input_handler.handle_input('k', entity, grid)
      end
    end
  end
end
