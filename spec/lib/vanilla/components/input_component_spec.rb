require 'spec_helper'

RSpec.describe Vanilla::Components::InputComponent do
  describe '#initialize' do
    it 'initializes with default values' do
      component = Vanilla::Components::InputComponent.new
      expect(component.move_direction).to be_nil
      expect(component.action_triggered).to be false
      expect(component.action_params).to eq({})
    end
  end

  describe '#type' do
    it 'returns the correct component type' do
      component = Vanilla::Components::InputComponent.new
      expect(component.type).to eq(:input)
    end
  end

  describe '#set_move_direction' do
    let(:component) { Vanilla::Components::InputComponent.new }

    it 'sets the move direction' do
      component.set_move_direction(:north)
      expect(component.move_direction).to eq(:north)
    end

    it 'can set the move direction to nil' do
      component.set_move_direction(:north)
      component.set_move_direction(nil)
      expect(component.move_direction).to be_nil
    end
  end

  describe '#set_action_triggered' do
    let(:component) { Vanilla::Components::InputComponent.new }

    it 'sets the action triggered flag' do
      component.set_action_triggered(true)
      expect(component.action_triggered).to be true
    end

    it 'sets action params when triggered' do
      params = { target: 'door', action: 'open' }
      component.set_action_triggered(true, params)
      expect(component.action_triggered).to be true
      expect(component.action_params).to eq(params)
    end

    it 'does not set action params when not triggered' do
      params = { target: 'door', action: 'open' }
      component.set_action_triggered(false, params)
      expect(component.action_triggered).to be false
      expect(component.action_params).to eq({})
    end
  end

  describe '#action_params' do
    let(:component) { Vanilla::Components::InputComponent.new }

    it 'returns empty hash by default' do
      expect(component.action_params).to eq({})
    end

    it 'returns the set action params' do
      params = { target: 'door', action: 'open' }
      component.set_action_triggered(true, params)
      expect(component.action_params).to eq(params)
    end
  end

  describe '#clear' do
    let(:component) { Vanilla::Components::InputComponent.new }

    it 'resets all input state' do
      component.set_move_direction(:north)
      component.set_action_triggered(true, { target: 'door' })

      component.clear

      expect(component.move_direction).to be_nil
      expect(component.action_triggered).to be false
      expect(component.action_params).to eq({})
    end
  end

  describe '#data' do
    let(:component) { Vanilla::Components::InputComponent.new }

    it 'returns a hash with the component data' do
      component.set_move_direction(:east)
      component.set_action_triggered(true, { target: 'door' })

      expect(component.data).to eq({
        move_direction: :east,
        action_triggered: true,
        action_params: { target: 'door' }
      })
    end
  end

  describe '.from_hash' do
    it 'creates a component from a hash' do
      hash = {
        move_direction: :west,
        action_triggered: true,
        action_params: { target: 'chest', action: 'open' }
      }

      component = Vanilla::Components::InputComponent.from_hash(hash)

      expect(component.move_direction).to eq(:west)
      expect(component.action_triggered).to be true
      expect(component.action_params).to eq({ target: 'chest', action: 'open' })
    end

    it 'handles missing action_params' do
      hash = {
        move_direction: :west,
        action_triggered: true
      }

      component = Vanilla::Components::InputComponent.from_hash(hash)

      expect(component.move_direction).to eq(:west)
      expect(component.action_triggered).to be true
      expect(component.action_params).to eq({})
    end
  end

  describe '.component_type' do
    it 'returns the correct component type' do
      expect(Vanilla::Components::InputComponent.component_type).to eq(:input)
    end
  end
end
