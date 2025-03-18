require 'spec_helper'

RSpec.describe Vanilla::Components::RenderComponent do
  before do
    # Reset component registry to avoid test interference
    allow(Vanilla::Components::Component).to receive(:component_classes).and_return({})
    # Register component for testing
    Vanilla::Components::Component.register(described_class)
  end

  describe '#initialize' do
    it 'sets character, color, and layer' do
      component = described_class.new(character: 'X', color: :red, layer: 5)
      expect(component.character).to eq('X')
      expect(component.color).to eq(:red)
      expect(component.layer).to eq(5)
    end

    it 'defaults layer to 0' do
      component = described_class.new(character: 'X')
      expect(component.layer).to eq(0)
    end

    it 'defaults color to nil' do
      component = described_class.new(character: 'X')
      expect(component.color).to be_nil
    end
  end

  describe '#type' do
    it 'returns :render' do
      component = described_class.new(character: 'X')
      expect(component.type).to eq(:render)
    end
  end

  describe '#data' do
    it 'serializes render component data' do
      component = described_class.new(character: 'X', color: :blue, layer: 3)
      expect(component.data).to eq({
        character: 'X',
        color: :blue,
        layer: 3
      })
    end
  end

  describe '.from_hash' do
    it 'deserializes render component data' do
      hash = {
        character: 'Y',
        color: :green,
        layer: 7
      }

      component = described_class.from_hash(hash)
      expect(component.character).to eq('Y')
      expect(component.color).to eq(:green)
      expect(component.layer).to eq(7)
    end

    it 'handles missing layer in hash' do
      hash = {
        character: 'Z',
        color: :yellow
      }

      component = described_class.from_hash(hash)
      expect(component.character).to eq('Z')
      expect(component.color).to eq(:yellow)
      expect(component.layer).to eq(0) # Default value
    end
  end
end