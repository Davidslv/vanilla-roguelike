# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Components::MovementComponent do
  describe '#initialize' do
    it 'initializes with default values when no parameters are provided' do
      component = Vanilla::Components::MovementComponent.new
      expect(component.speed).to eq(1)
      expect(component.active?).to be true
    end

    it 'initializes with provided values' do
      component = Vanilla::Components::MovementComponent.new(active: false, speed: 2)
      expect(component.speed).to eq(2)
      expect(component.active?).to be false
    end
  end

  describe '#type' do
    it 'returns the correct component type' do
      component = Vanilla::Components::MovementComponent.new
      expect(component.type).to eq(:movement)
    end
  end

  describe '#active?' do
    it 'returns true when movement is active' do
      component = Vanilla::Components::MovementComponent.new(active: true, speed: 1)
      expect(component.active?).to be true
    end

    it 'returns false when movement is inactive' do
      component = Vanilla::Components::MovementComponent.new(active: false, speed: 1)
      expect(component.active?).to be false
    end
  end

  describe '.from_hash' do
    it 'creates a component from a hash with all values' do
      hash = {
        speed: 2.0,
        active: false
      }

      component = Vanilla::Components::MovementComponent.from_hash(hash)

      expect(component.speed).to eq(2.0)
      expect(component.active?).to be false
    end

    it 'uses default values for missing speed' do
      hash = {
        active: true
      }

      component = Vanilla::Components::MovementComponent.from_hash(hash)

      expect(component.speed).to eq(1)
      expect(component.active?).to be true
    end

    it 'uses default value for missing active' do
      hash = {
        speed: 1.5
      }

      component = Vanilla::Components::MovementComponent.from_hash(hash)

      expect(component.speed).to eq(1.5)
      expect(component.active?).to be true
    end

    it 'handles explicit nil active value as false' do
      hash = {
        speed: 1.0,
        active: nil
      }

      component = Vanilla::Components::MovementComponent.from_hash(hash)

      expect(component.active?).to be false
    end
  end

  describe 'registration' do
    it 'registers itself with the Component registry' do
      expect(Vanilla::Components::Component.component_classes[:movement]).to eq(described_class)
    end
  end
end
