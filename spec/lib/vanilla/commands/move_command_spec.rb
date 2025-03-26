# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Commands::MoveCommand do
  let(:world) { double('World') }
  let(:entity) do
    entity = Vanilla::Entities::Entity.new
    entity.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 5))
    entity
  end
  let(:movement_system) { Vanilla::Systems::MovementSystem.new(world) }

  describe '#execute' do
    context 'when movement is successful' do
      it 'clears old position and updates display' do
        command = described_class.new(entity, :north)
        position_component = entity.get_component(:position)

        # Mock ServiceRegistry for game access
        game = double('Game')
        level = double('Level')

        allow(Vanilla::ServiceRegistry).to receive(:get).with(:game).and_return(game)
        allow(game).to receive(:level).and_return(level)
        allow(level).to receive(:update_grid_with_entities)
        allow(level).to receive(:all_entities).and_return([entity])

        allow(world).to receive(:systems).and_return([[movement_system, 1]])

        # Mock the movement to change position
        expect(movement_system).to receive(:move).with(entity, :north) do
          position_component.set_position(4, 5) # Simulate movement up
          true # Return success
        end

        result = command.execute(world)
        expect(result).to be true
      end
    end
  end
end
