# frozen_string_literal: true

require 'spec_helper'

# Issue #164: item use and drop are commands, like move and attack. Each
# delegates to its system and ends the turn only when the action happened.
RSpec.describe 'Item commands' do # rubocop:disable RSpec/DescribeClass -- two small commands with one shape
  let(:player) { Vanilla::Entities::Entity.new }
  let(:item) { Vanilla::Entities::Entity.new }
  let(:world) { instance_double(Vanilla::World, end_turn: nil) }

  {
    Vanilla::Commands::UseItemCommand => [Vanilla::Systems::ItemUseSystem, :use_item],
    Vanilla::Commands::DropItemCommand => [Vanilla::Systems::ItemDropSystem, :drop_item]
  }.each do |command_class, (system_class, action)|
    describe command_class do
      let(:system) { instance_double(system_class) }

      before do
        allow(world).to receive(:systems).and_return([[system, 3.5]])
        allow(system).to receive(:is_a?) { |klass| klass == system_class }
      end

      it "calls #{system_class.name.split('::').last}##{action} and ends the turn when it succeeds" do
        allow(system).to receive(action).with(player, item).and_return(true)

        expect(command_class.new(player, item).execute(world)).to be(true)
        expect(world).to have_received(:end_turn).once
      end

      it 'does not end the turn when the action fails' do
        allow(system).to receive(action).and_return(false)

        expect(command_class.new(player, item).execute(world)).to be(false)
        expect(world).not_to have_received(:end_turn)
      end

      it 'runs only once' do
        allow(system).to receive(action).and_return(true)
        command = command_class.new(player, item)

        command.execute(world)
        command.execute(world)

        expect(system).to have_received(action).once
      end

      it 'fails safely when the system is missing' do
        allow(world).to receive(:systems).and_return([])

        expect(command_class.new(player, item).execute(world)).to be(false)
      end
    end
  end
end
