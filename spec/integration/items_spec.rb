# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/headless_game'

# Issue #164: using an item from the inventory menu did nothing. This plays
# the whole loop with real key presses: kill, pick up, open the inventory,
# then use or drop.
RSpec.describe 'Inventory items', type: :integration do # rubocop:disable RSpec/DescribeClass -- a flow across menus, commands and systems
  let(:seed) { 3 }
  let(:game) { HeadlessGame.new(seed: seed) }
  let(:health) { game.player.get_component(:health) }
  let(:inventory) { game.player.get_component(:inventory) }

  after do
    game.cleanup
    Vanilla::ServiceRegistry.clear
  end

  # Kill a one-hit goblin next to the player whose loot is a single apple,
  # and pick the apple up. Leaves the menu closed.
  def kill_goblin_and_take_apple
    game.start
    game.flush_pending_events
    game.world.entities.values.select { |e| e.has_tag?(:monster) }.each do |monster|
      game.world.remove_entity(monster.id)
      game.current_level.remove_entity(monster)
    end

    cell = game.grid[*game.player_position]
    direction, key = { north: 'k', south: 'j', east: 'l', west: 'h' }.find do |dir, _|
      cell.public_send(dir) && cell.linked?(cell.public_send(dir))
    end
    target = cell.public_send(direction)
    goblin = Vanilla::EntityFactory.create_monster('goblin', target.row, target.column, 1, 1)
    goblin.remove_component(:movement)
    game.world.add_entity(goblin)
    game.current_level.add_entity(goblin)

    loot_system = game.world.systems.find { |s, _| s.is_a?(Vanilla::Systems::LootSystem) }.first
    allow(loot_system).to receive(:generate_loot) { { gold: 0, items: [loot_system.create_apple] } }

    game.press(key)  # step into the goblin
    game.press('1')  # attack
    game.press('1')  # pick up the loot
  end

  it 'eats the apple: heals, removes it, and takes a turn' do
    kill_goblin_and_take_apple
    expect(inventory.items.map(&:name)).to eq(['Apple'])
    health.current_health = 50
    turns_before = game.turn

    %w[m i 1 1].each { |key| game.press(key) } # menu, inventory, apple, use

    expect(health.current_health).to eq(70)
    expect(inventory.items).to be_empty
    expect(game.turn).to eq(turns_before + 1)
    expect(game.events(:item_used).size).to eq(1)
    expect(game.recent_messages.map(&:content)).to include('inventory.item_used')
    expect(game.selection_mode?).to be(false)
  end

  it 'drops the apple under the player and takes a turn' do
    kill_goblin_and_take_apple
    apple = inventory.items.first
    turns_before = game.turn

    %w[m i 1 2].each { |key| game.press(key) } # menu, inventory, apple, drop

    expect(inventory.items).to be_empty
    expect(game.world.get_entity(apple.id)).to eq(apple)
    position = apple.get_component(:position)
    expect([position.row, position.column]).to eq(game.player_position)
    expect(game.turn).to eq(turns_before + 1)
    expect(game.events(:item_dropped).size).to eq(1)
  end
end
