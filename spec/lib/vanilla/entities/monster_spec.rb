# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Entities::Monster do
  let(:row) { 10 }
  let(:column) { 15 }
  let(:monster) { described_class.new(monster_type: 'troll', row: row, column: column, health: 10) }

  it 'has a render component' do
    expect(monster.has_component?(:render)).to be(true)
  end

  it 'has a position component' do
    expect(monster.has_component?(:position)).to be(true)
  end

  it 'has a movement component' do
    expect(monster.has_component?(:movement)).to be(true)
  end

  it 'has a health component' do
    expect(monster.has_component?(:health)).to be(true)
  end
end
