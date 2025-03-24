# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Components::InputComponent do
  describe '#initialize' do
    it 'initializes with default values' do
      component = Vanilla::Components::InputComponent.new
      expect(component.move_direction).to be_nil
    end
  end

  describe '#type' do
    it 'returns the correct component type' do
      component = Vanilla::Components::InputComponent.new
      expect(component.type).to eq(:input)
    end
  end

  describe '#to_hash' do
    let(:component) { Vanilla::Components::InputComponent.new }

    it 'returns a hash with the component data' do
      component.move_direction = :east

      expect(component.to_hash).to eq(
        {
          move_direction: :east
        }
      )
    end
  end

  describe '.from_hash' do
    it 'creates a component from a hash' do
      hash = {
        move_direction: :west
      }

      component = Vanilla::Components::InputComponent.from_hash(hash)

      expect(component.move_direction).to eq(:west)
    end
  end

  describe '.component_type' do
    it 'returns the correct component type' do
      expect(Vanilla::Components::InputComponent.component_type).to eq(:input)
    end
  end
end
