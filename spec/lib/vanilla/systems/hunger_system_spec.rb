# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Systems::HungerSystem do
  let(:world) { instance_double(Vanilla::World, subscribe: nil, emit_event: nil, player_died: nil) }
  let(:system) { described_class.new(world) }
  let(:nutrition) { Vanilla::Components::NutritionComponent.new(food_left: 100) }
  let(:health) { Vanilla::Components::HealthComponent.new(max_health: 100) }
  let(:player) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.add_tag(:player)
      e.add_component(nutrition)
      e.add_component(health)
    end
  end

  before { allow(world).to receive(:query_entities).with([:nutrition]).and_return([player]) }

  def tick(times = 1)
    times.times { system.handle_event(:turn_ended, { turn: 1 }) }
  end

  it 'listens for turn_ended' do
    system
    expect(world).to have_received(:subscribe).with(:turn_ended, system)
  end

  it 'costs one food per turn' do
    tick(3)

    expect(nutrition.food_left).to eq(97)
  end

  it 'ignores other events' do
    system.handle_event(:entity_moved, {})

    expect(nutrition.food_left).to eq(100)
  end

  it 'announces a status change once, when the threshold is crossed' do
    nutrition.food_left = Vanilla::Hunger::HUNGRY_AT + 1

    tick(3)

    expect(world).to have_received(:emit_event)
      .with(:hunger_status_changed, { entity_id: player.id, from: :ok, to: :hungry, food_left: Vanilla::Hunger::HUNGRY_AT }).once
  end

  it 'never goes below zero food' do
    nutrition.food_left = 0

    tick

    expect(nutrition.food_left).to eq(0)
  end

  it 'costs STARVE_DAMAGE health per turn while starving' do
    nutrition.food_left = 0

    tick(2)

    expect(health.current_health).to eq(100 - (2 * Vanilla::Hunger::STARVE_DAMAGE))
    expect(world).to have_received(:emit_event).with(:starvation_damage, hash_including(entity_id: player.id)).twice
  end

  it 'does no damage while there is food left after the turn' do
    nutrition.food_left = 2

    expect { tick }.not_to change(health, :current_health)
  end

  it 'ends the game with cause :starvation when health runs out' do
    nutrition.food_left = 0
    health.current_health = Vanilla::Hunger::STARVE_DAMAGE

    tick

    expect(health.current_health).to eq(0)
    expect(world).to have_received(:player_died).with(cause: :starvation)
  end
end
