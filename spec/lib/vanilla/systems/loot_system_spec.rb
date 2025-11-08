# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Systems::LootSystem do
  let(:world) { instance_double('Vanilla::World') }
  let(:system) { described_class.new(world) }
  let(:logger) { instance_double('Vanilla::Logger') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(world).to receive(:emit_event)
  end

  describe '#generate_loot' do
    it 'generates loot with gold 90% of the time' do
      gold_count = 0
      100.times do
        loot = system.generate_loot
        gold_count += 1 if loot[:gold] > 0
      end
      
      # Should be around 90% (allow 80-100% for randomness)
      expect(gold_count).to be >= 80
      expect(gold_count).to be <= 100
    end

    it 'generates gold amount between 1 and 10' do
      100.times do
        loot = system.generate_loot
        if loot[:gold] > 0
          expect(loot[:gold]).to be >= 1
          expect(loot[:gold]).to be <= 10
        end
      end
    end

    it 'can generate apple' do
      apple_found = false
      100.times do
        loot = system.generate_loot
        apple_found = true if loot[:items].any? { |item| item.name == "Apple" }
      end
      
      # Should find at least one apple in 100 tries
      expect(apple_found).to be true
    end

    it 'can generate nothing' do
      nothing_found = false
      100.times do
        loot = system.generate_loot
        if loot[:gold] == 0 && loot[:items].empty?
          nothing_found = true
          break
        end
      end
      
      # Should be possible to get nothing
      expect(nothing_found).to be true
    end

    it 'returns loot hash with gold and items keys' do
      loot = system.generate_loot
      expect(loot).to have_key(:gold)
      expect(loot).to have_key(:items)
      expect(loot[:gold]).to be_a(Integer)
      expect(loot[:items]).to be_a(Array)
    end

    context 'when stubbing random values' do
      it 'generates gold when rand < 0.9' do
        allow(system).to receive(:rand).and_return(0.5) # < 0.9, so gold
        loot = system.generate_loot
        expect(loot[:gold]).to be > 0
      end

      it 'generates no gold when rand >= 0.9' do
        allow(system).to receive(:rand).and_return(0.95) # >= 0.9, so no gold
        loot = system.generate_loot
        expect(loot[:gold]).to eq(0)
      end

      it 'generates apple when rand < 0.3 for apple chance' do
        # First rand for gold (0.5 < 0.9, so gold)
        # Second rand for apple (0.2 < 0.3, so apple)
        allow(system).to receive(:rand).and_return(0.5, 0.2)
        loot = system.generate_loot
        expect(loot[:items].any? { |item| item.name == "Apple" }).to be true
      end

      it 'generates no apple when rand >= 0.3 for apple chance' do
        # First rand for gold, second for apple (0.5 >= 0.3, so no apple)
        allow(system).to receive(:rand).and_return(0.5, 0.5)
        loot = system.generate_loot
        expect(loot[:items].select { |item| item.name == "Apple" }).to be_empty
      end
    end
  end

  describe '#create_apple' do
    it 'creates an apple entity with consumable component' do
      apple = system.create_apple
      expect(apple).to be_a(Vanilla::Entities::Entity)
      expect(apple.name).to eq("Apple")
      expect(apple.has_component?(:item)).to be true
      expect(apple.has_component?(:consumable)).to be true
    end

    it 'creates apple with correct item properties' do
      apple = system.create_apple
      item_comp = apple.get_component(:item)
      expect(item_comp.name).to eq("Apple")
      expect(item_comp.item_type).to eq(:food)
    end
  end
end

