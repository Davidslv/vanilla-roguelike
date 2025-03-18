require 'spec_helper'

RSpec.describe Vanilla::Components::StairsComponent do
  describe '#initialize' do
    it 'defaults found_stairs to false' do
      component = described_class.new
      expect(component.found_stairs).to be false
      expect(component.found_stairs?).to be false
    end

    it 'accepts custom found_stairs value' do
      component = described_class.new(found_stairs: true)
      expect(component.found_stairs).to be true
      expect(component.found_stairs?).to be true
    end
  end

  describe '#type' do
    it 'returns :stairs' do
      component = described_class.new
      expect(component.type).to eq(:stairs)
    end
  end

  describe '#to_hash' do
    it 'serializes stairs data' do
      component = described_class.new(found_stairs: true)
      hash = component.to_hash
      expect(hash[:type]).to eq(:stairs)
      expect(hash[:found_stairs]).to be true
    end
  end

  describe '.from_hash' do
    it 'deserializes stairs data' do
      hash = { type: :stairs, found_stairs: true }
      component = described_class.from_hash(hash)
      expect(component).to be_a(described_class)
      expect(component.found_stairs).to be true
    end
  end

  describe '#found_stairs=' do
    let(:component) { described_class.new }

    it 'sets the found_stairs flag' do
      component.found_stairs = true
      expect(component.found_stairs).to be true
      expect(component.found_stairs?).to be true

      component.found_stairs = false
      expect(component.found_stairs).to be false
      expect(component.found_stairs?).to be false
    end
  end
end