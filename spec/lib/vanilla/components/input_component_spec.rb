require 'spec_helper'

RSpec.describe Vanilla::Components::InputComponent do
  let(:component) { Vanilla::Components::InputComponent.new }

  describe '#initialize' do
    it 'initializes with default values' do
      expect(component.move_direction).to be_nil
      expect(component.action_triggered).to be false
    end
  end

  describe '#set_move_direction' do
    it 'sets the movement direction' do
      component.set_move_direction(:north)
      expect(component.move_direction).to eq(:north)
    end
  end

  describe '#set_action_triggered' do
    it 'sets the action triggered flag' do
      component.set_action_triggered(true)
      expect(component.action_triggered).to be true
    end

    it 'sets action parameters when triggered' do
      params = { target: 'monster' }
      component.set_action_triggered(true, params)
      expect(component.action_triggered).to be true
      expect(component.action_params).to eq(params)
    end

    it 'clears action parameters when not triggered' do
      component.set_action_triggered(true, { target: 'monster' })
      component.set_action_triggered(false)
      expect(component.action_triggered).to be false
      expect(component.action_params).to eq({})
    end
  end

  describe '#clear' do
    it 'resets all input state' do
      component.set_move_direction(:north)
      component.set_action_triggered(true, { target: 'monster' })

      component.clear

      expect(component.move_direction).to be_nil
      expect(component.action_triggered).to be false
      expect(component.action_params).to eq({})
    end
  end

  describe '#to_hash' do
    it 'serializes the component state' do
      component.set_move_direction(:north)
      component.set_action_triggered(true, { target: 'monster' })

      hash = component.to_hash

      expect(hash[:type]).to eq(:input)
      expect(hash[:move_direction]).to eq(:north)
      expect(hash[:action_triggered]).to be true
      expect(hash[:action_params]).to eq({ target: 'monster' })
    end
  end

  describe '.from_hash' do
    it 'deserializes the component state' do
      hash = {
        type: :input,
        move_direction: :south,
        action_triggered: true,
        action_params: { target: 'goblin' }
      }

      component = Vanilla::Components::InputComponent.from_hash(hash)

      expect(component.move_direction).to eq(:south)
      expect(component.action_triggered).to be true
      expect(component.action_params).to eq({ target: 'goblin' })
    end
  end

  describe '.component_type' do
    it 'returns the component type' do
      expect(Vanilla::Components::InputComponent.component_type).to eq(:input)
    end
  end
end