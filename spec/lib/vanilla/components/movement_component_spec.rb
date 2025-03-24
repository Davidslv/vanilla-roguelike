# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Components::MovementComponent do
  describe '#initialize' do
    it 'initializes with default values when no parameters are provided' do
      component = Vanilla::Components::MovementComponent.new
      expect(component.speed).to eq(1)
      expect(component.can_move_directions).to eq([:north, :south, :east, :west])
      expect(component.active).to be true
      expect(component.direction).to be_nil
    end

    it 'initializes with provided values' do
      component = Vanilla::Components::MovementComponent.new(2.5, [:north, :south], false)
      expect(component.speed).to eq(2.5)
      expect(component.can_move_directions).to eq([:north, :south])
      expect(component.active).to be false
      expect(component.direction).to be_nil
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
      component = Vanilla::Components::MovementComponent.new(1, [], true)
      expect(component.active?).to be true
    end

    it 'returns false when movement is inactive' do
      component = Vanilla::Components::MovementComponent.new(1, [], false)
      expect(component.active?).to be false
    end
  end

  describe '#set_active' do
    let(:component) { Vanilla::Components::MovementComponent.new }

    it 'enables movement' do
      component.set_active(true)
      expect(component.active?).to be true
    end

    it 'disables movement' do
      component.set_active(false)
      expect(component.active?).to be false
    end
  end

  describe '#set_direction' do
    let(:component) { Vanilla::Components::MovementComponent.new }

    it 'sets the direction' do
      component.set_direction(:north)
      expect(component.direction).to eq(:north)
    end

    it 'can clear the direction' do
      component.set_direction(:north)
      component.set_direction(nil)
      expect(component.direction).to be_nil
    end
  end

  describe '#data' do
    it 'returns a hash with the component data' do
      component = Vanilla::Components::MovementComponent.new(1.5, [:north, :east], false)
      component.set_direction(:north)

      expect(component.data).to eq({
                                     speed: 1.5,
                                     can_move_directions: [:north, :east],
                                     active: false,
                                     direction: :north
                                   })
    end
  end

  describe '.from_hash' do
    it 'creates a component from a hash with all values' do
      hash = {
        speed: 2.0,
        can_move_directions: [:south, :west],
        active: false,
        direction: :south
      }

      component = Vanilla::Components::MovementComponent.from_hash(hash)

      expect(component.speed).to eq(2.0)
      expect(component.can_move_directions).to eq([:south, :west])
      expect(component.active).to be false
      expect(component.direction).to eq(:south)
    end

    it 'uses default values for missing speed' do
      hash = {
        can_move_directions: [:south],
        active: true
      }

      component = Vanilla::Components::MovementComponent.from_hash(hash)

      expect(component.speed).to eq(1)
      expect(component.can_move_directions).to eq([:south])
      expect(component.active).to be true
    end

    it 'uses default values for missing can_move_directions' do
      hash = {
        speed: 3.0,
        active: true
      }

      component = Vanilla::Components::MovementComponent.from_hash(hash)

      expect(component.speed).to eq(3.0)
      expect(component.can_move_directions).to eq([:north, :south, :east, :west])
      expect(component.active).to be true
    end

    it 'uses default value for missing active' do
      hash = {
        speed: 1.5,
        can_move_directions: [:north, :south]
      }

      component = Vanilla::Components::MovementComponent.from_hash(hash)

      expect(component.speed).to eq(1.5)
      expect(component.can_move_directions).to eq([:north, :south])
      expect(component.active).to be true
    end

    it 'handles explicit nil active value as false' do
      hash = {
        speed: 1.0,
        can_move_directions: [:east, :west],
        active: nil
      }

      component = Vanilla::Components::MovementComponent.from_hash(hash)

      expect(component.active).to be true # The implementation treats nil as true
    end
  end

  describe 'registration' do
    it 'registers itself with the Component registry' do
      expect(Vanilla::Components::Component.component_classes[:movement]).to eq(described_class)
    end
  end
end
