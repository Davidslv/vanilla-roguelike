# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/headless_game'

# Issue #161, played with real key presses.
RSpec.describe 'Hunger', type: :integration do
  let(:seed) { 20_261_004 }
  let(:game) { HeadlessGame.new(seed: seed) }
  let(:keys) { { north: 'k', south: 'j', east: 'l', west: 'h' } }
  let(:nutrition) { game.player.get_component(:nutrition) }

  after do
    game.cleanup
    Vanilla::ServiceRegistry.clear
  end

  before do
    game.start
    game.flush_pending_events
    game.world.entities.values.select { |e| e.has_tag?(:monster) }.each do |monster|
      game.world.remove_entity(monster.id)
      game.current_level.remove_entity(monster)
    end
  end

  def step_key
    cell = game.grid[*game.player_position]
    keys.find { |dir, _| cell.public_send(dir) && cell.linked?(cell.public_send(dir)) }.last
  end

  it 'costs one food per step and nothing for free keys' do
    start = nutrition.food_left

    %w[f z m m].each { |key| game.press(key) }
    expect(nutrition.food_left).to eq(start)

    game.press(step_key)
    expect(nutrition.food_left).to eq(start - 1)
  end

  it 'kills a starving player, and the game says why' do
    nutrition.food_left = 1
    game.player.get_component(:health).current_health = Vanilla::Hunger::STARVE_DAMAGE

    game.press(step_key)

    expect(game.game_over?).to be(true)
    expect(game.world.game_over[:cause]).to eq(:starvation)
    expect(game.recent_messages.map(&:content)).to include('hunger.starving', 'death.starvation')
  end
end
