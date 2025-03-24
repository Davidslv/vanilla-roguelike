require 'spec_helper'

RSpec.describe Vanilla::Components::RenderComponent do
  before do
    # Reset component registry to avoid test interference
    allow(Vanilla::Components::Component).to receive(:component_classes).and_return({})
    # Register component for testing
    Vanilla::Components::Component.register(described_class)

    # Allow TileType validation to pass for test characters
    allow(Vanilla::Support::TileType).to receive(:valid?).and_return(true)
  end

  describe '#initialize' do
    it 'sets character, color, and layer' do
      component = described_class.new(character: '@', color: :red, layer: 5)
      expect(component.character).to eq('@')
      expect(component.color).to eq(:red)
      expect(component.layer).to eq(5)
    end

    it 'defaults layer to 0' do
      component = described_class.new(character: '@')
      expect(component.layer).to eq(0)
    end

    it 'defaults color to nil' do
      component = described_class.new(character: '@')
      expect(component.color).to be_nil
    end

    it 'defaults entity_type to character if not provided' do
      component = described_class.new(character: '@')
      expect(component.entity_type).to eq('@')
    end

    it 'allows specifying entity_type' do
      component = described_class.new(character: '@', entity_type: 'player')
      expect(component.entity_type).to eq('player')
    end
  end

  describe '#type' do
    it 'returns :render' do
      component = described_class.new(character: '@')
      expect(component.type).to eq(:render)
    end
  end

  describe '#data' do
    it 'serializes render component data' do
      component = described_class.new(character: '@', color: :blue, layer: 3, entity_type: 'player')
      expect(component.data).to eq({
        character: '@',
        color: :blue,
        layer: 3,
        entity_type: 'player'
      })
    end
  end

  describe '.from_hash' do
    it 'deserializes render component data' do
      hash = {
        character: '@',
        color: :green,
        layer: 7,
        entity_type: 'monster'
      }

      component = described_class.from_hash(hash)
      expect(component.character).to eq('@')
      expect(component.color).to eq(:green)
      expect(component.layer).to eq(7)
      expect(component.entity_type).to eq('monster')
    end

    it 'handles missing layer in hash' do
      hash = {
        character: '@',
        color: :yellow
      }

      component = described_class.from_hash(hash)
      expect(component.character).to eq('@')
      expect(component.color).to eq(:yellow)
      expect(component.layer).to eq(0) # Default value
      expect(component.entity_type).to eq('@') # Default to character
    end
  end

  describe '#tile' do
    it 'returns character for backward compatibility with TileComponent' do
      component = described_class.new(character: '@')
      expect(component.tile).to eq('@')
    end
  end
end
