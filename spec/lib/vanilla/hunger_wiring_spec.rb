# frozen_string_literal: true

require 'spec_helper'

# The small pieces that connect hunger to the rest of the game (#161).
RSpec.describe 'Hunger wiring' do # rubocop:disable RSpec/DescribeClass -- checks EntityFactory and LootSystem together
  it 'gives a new player START_FOOD' do
    player = Vanilla::EntityFactory.create_player(0, 0)

    expect(player.get_component(:nutrition).food_left).to eq(Vanilla::Hunger::START_FOOD)
  end

  it 'makes apples restore APPLE_FOOD as well as heal' do
    world = instance_double(Vanilla::World)
    apple = Vanilla::Systems::LootSystem.new(world).create_apple

    expect(apple.get_component(:consumable).effects)
      .to contain_exactly({ type: :heal, amount: 20 }, { type: :nourish, amount: Vanilla::Hunger::APPLE_FOOD })
  end
end
