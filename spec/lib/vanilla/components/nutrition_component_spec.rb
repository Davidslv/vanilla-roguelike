# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Components::NutritionComponent do
  it 'starts with the default food and cap' do
    component = described_class.new

    expect(component.food_left).to eq(Vanilla::Hunger::START_FOOD)
    expect(component.max_food).to eq(Vanilla::Hunger::MAX_FOOD)
  end

  it 'has the :nutrition type' do
    expect(described_class.new.type).to eq(:nutrition)
  end

  it 'round-trips through to_hash and from_hash' do
    original = described_class.new(food_left: 42, max_food: 180)
    copy = described_class.from_hash(original.to_hash)

    expect([copy.food_left, copy.max_food]).to eq([42, 180])
  end

  it 'is registered, so Component.from_hash can rebuild it (#147)' do
    expect(Vanilla::Components::Component.get_class(:nutrition)).to eq(described_class)
  end
end
