# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Components::CurrencyComponent do
  describe '#initialize' do
    it 'sets value and currency_type' do
      component = described_class.new(100, :gold)
      expect(component.value).to eq(100)
      expect(component.currency_type).to eq(:gold)
    end

    it 'defaults to :gold currency_type' do
      component = described_class.new(50)
      expect(component.currency_type).to eq(:gold)
    end
  end

  describe '#type' do
    it 'returns :currency' do
      component = described_class.new(100)
      expect(component.type).to eq(:currency)
    end
  end

  describe '#combine' do
    it 'adds value from another currency component of same type' do
      component1 = described_class.new(50, :gold)
      component2 = described_class.new(25, :gold)
      result = component1.combine(component2)
      expect(component1.value).to eq(75)
      expect(result).to eq(75)
    end

    it 'does not combine different currency types' do
      component1 = described_class.new(50, :gold)
      component2 = described_class.new(25, :silver)
      result = component1.combine(component2)
      expect(component1.value).to eq(50)
      expect(result).to eq(50)
    end

    it 'does not combine with non-currency component' do
      component = described_class.new(50, :gold)
      other = double('NotCurrency')
      result = component.combine(other)
      expect(component.value).to eq(50)
      expect(result).to eq(50)
    end
  end

  describe '#split' do
    it 'splits off specified amount' do
      component = described_class.new(100, :gold)
      result = component.split(30)
      expect(component.value).to eq(70)
      expect(result).to eq(30)
    end

    it 'returns nil if amount exceeds value' do
      component = described_class.new(50, :gold)
      result = component.split(100)
      expect(component.value).to eq(50)
      expect(result).to be_nil
    end

    it 'can split entire value' do
      component = described_class.new(100, :gold)
      result = component.split(100)
      expect(component.value).to eq(0)
      expect(result).to eq(100)
    end
  end

  describe '#display_string' do
    it 'formats gold correctly for singular' do
      component = described_class.new(1, :gold)
      expect(component.display_string).to eq("1 gold coin")
    end

    it 'formats gold correctly for plural' do
      component = described_class.new(5, :gold)
      expect(component.display_string).to eq("5 gold coins")
    end

    it 'formats silver correctly' do
      component = described_class.new(3, :silver)
      expect(component.display_string).to eq("3 silver coins")
    end

    it 'formats copper correctly' do
      component = described_class.new(10, :copper)
      expect(component.display_string).to eq("10 copper coins")
    end

    it 'formats gems correctly for singular' do
      component = described_class.new(1, :gem)
      expect(component.display_string).to eq("1 gem")
    end

    it 'formats gems correctly for plural' do
      component = described_class.new(5, :gem)
      expect(component.display_string).to eq("5 gems")
    end

    it 'formats unknown currency types' do
      component = described_class.new(10, :platinum)
      expect(component.display_string).to eq("10 platinum")
    end
  end

  describe '#standard_value' do
    it 'returns gold value as-is' do
      component = described_class.new(100, :gold)
      expect(component.standard_value).to eq(100)
    end

    it 'converts copper to gold (100:1)' do
      component = described_class.new(100, :copper)
      expect(component.standard_value).to eq(1)
    end

    it 'converts silver to gold (10:1)' do
      component = described_class.new(30, :silver)
      expect(component.standard_value).to eq(3)
    end

    it 'converts gems to gold (1:5)' do
      component = described_class.new(2, :gem)
      expect(component.standard_value).to eq(10)
    end

    it 'returns value as-is for unknown types' do
      component = described_class.new(50, :platinum)
      expect(component.standard_value).to eq(50)
    end
  end

  describe '#to_hash' do
    it 'serializes component to hash' do
      component = described_class.new(100, :gold)
      hash = component.to_hash
      expect(hash).to eq({
        type: :currency,
        value: 100,
        currency_type: :gold
      })
    end
  end

  describe '.from_hash' do
    it 'deserializes component from hash' do
      hash = { type: :currency, value: 100, currency_type: :gold }
      component = described_class.from_hash(hash)
      expect(component.value).to eq(100)
      expect(component.currency_type).to eq(:gold)
    end

    it 'defaults to 0 value if missing' do
      hash = { type: :currency, currency_type: :gold }
      component = described_class.from_hash(hash)
      expect(component.value).to eq(0)
    end

    it 'defaults to :gold currency_type if missing' do
      hash = { type: :currency, value: 50 }
      component = described_class.from_hash(hash)
      expect(component.currency_type).to eq(:gold)
    end
  end
end

