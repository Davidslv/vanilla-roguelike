# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Components::InventoryComponent do
  describe '#initialize' do
    it 'creates empty inventory with default max_size' do
      component = described_class.new
      expect(component.items).to be_empty
      expect(component.max_size).to eq(20)
    end

    it 'accepts custom max_size' do
      component = described_class.new(max_size: 10)
      expect(component.max_size).to eq(10)
    end
  end

  describe '#type' do
    it 'returns :inventory' do
      component = described_class.new
      expect(component.type).to eq(:inventory)
    end
  end

  describe '#full?' do
    it 'returns false when inventory has space' do
      component = described_class.new(max_size: 2)
      expect(component.full?).to be false
    end

    it 'returns true when inventory is at max capacity' do
      component = described_class.new(max_size: 2)
      item1 = Vanilla::Entities::Entity.new
      item2 = Vanilla::Entities::Entity.new
      component.add(item1)
      component.add(item2)
      expect(component.full?).to be true
    end
  end

  describe '#add' do
    let(:item) do
      Vanilla::Entities::Entity.new.tap do |e|
        e.add_component(Vanilla::Components::ItemComponent.new(name: "Test Item", item_type: :misc, stackable: false))
      end
    end

    it 'adds item to inventory' do
      component = described_class.new
      result = component.add(item)
      expect(result).to be true
      expect(component.items).to include(item)
    end

    it 'returns false when inventory is full' do
      component = described_class.new(max_size: 1)
      item1 = Vanilla::Entities::Entity.new
      item2 = Vanilla::Entities::Entity.new
      component.add(item1)
      result = component.add(item2)
      expect(result).to be false
      expect(component.items).not_to include(item2)
    end

    context 'with stackable items' do
      let(:stackable_item) do
        Vanilla::Entities::Entity.new.tap do |e|
          e.add_component(Vanilla::Components::ItemComponent.new(name: "Stackable", item_type: :misc, stackable: true))
        end
      end

      it 'stacks items of same type' do
        component = described_class.new
        component.add(stackable_item)
        second_item = Vanilla::Entities::Entity.new.tap do |e|
          e.add_component(Vanilla::Components::ItemComponent.new(name: "Stackable", item_type: :misc, stackable: true))
        end
        result = component.add(second_item)
        expect(result).to be true
        expect(component.items.size).to eq(1) # Still only one item
        expect(component.items.first.get_component(:item).stack_size).to eq(2)
      end

      it 'adds new item if no matching stackable item exists' do
        component = described_class.new
        different_item = Vanilla::Entities::Entity.new.tap do |e|
          e.add_component(Vanilla::Components::ItemComponent.new(name: "Different", item_type: :weapon, stackable: true))
        end
        component.add(stackable_item)
        result = component.add(different_item)
        expect(result).to be true
        expect(component.items.size).to eq(2)
      end
    end
  end

  describe '#remove' do
    let(:item) { Vanilla::Entities::Entity.new }

    it 'removes item from inventory' do
      component = described_class.new
      component.add(item)
      result = component.remove(item)
      expect(result).to eq(item)
      expect(component.items).not_to include(item)
    end

    it 'returns nil if item not in inventory' do
      component = described_class.new
      result = component.remove(item)
      expect(result).to be_nil
    end

    context 'with stackable items' do
      let(:stackable_item) do
        Vanilla::Entities::Entity.new.tap do |e|
          item_comp = Vanilla::Components::ItemComponent.new(name: "Stackable", item_type: :misc, stackable: true)
          item_comp.stack_size = 3
          e.add_component(item_comp)
        end
      end

      it 'decreases stack size instead of removing when stack_size > 1' do
        component = described_class.new
        component.add(stackable_item)
        result = component.remove(stackable_item)
        expect(result).to eq(stackable_item)
        expect(component.items).to include(stackable_item)
        expect(stackable_item.get_component(:item).stack_size).to eq(2)
      end

      it 'removes item when stack_size becomes 1' do
        component = described_class.new
        item_comp = stackable_item.get_component(:item)
        item_comp.stack_size = 1
        component.add(stackable_item)
        result = component.remove(stackable_item)
        expect(result).to eq(stackable_item)
        expect(component.items).not_to include(stackable_item)
      end
    end
  end

  describe '#has?' do
    let(:weapon_item) do
      Vanilla::Entities::Entity.new.tap do |e|
        e.add_component(Vanilla::Components::ItemComponent.new(name: "Sword", item_type: :weapon))
      end
    end

    it 'returns true if inventory contains item of specified type' do
      component = described_class.new
      component.add(weapon_item)
      expect(component.has?(:weapon)).to be true
    end

    it 'returns false if inventory does not contain item of specified type' do
      component = described_class.new
      component.add(weapon_item)
      expect(component.has?(:potion)).to be false
    end

    it 'returns false for empty inventory' do
      component = described_class.new
      expect(component.has?(:weapon)).to be false
    end
  end

  describe '#count' do
    let(:potion_item) do
      Vanilla::Entities::Entity.new.tap do |e|
        e.add_component(Vanilla::Components::ItemComponent.new(name: "Potion", item_type: :potion, stackable: true))
      end
    end

    it 'counts items of specified type' do
      component = described_class.new
      component.add(potion_item)
      expect(component.count(:potion)).to eq(1)
    end

    it 'counts stackable items by stack size' do
      component = described_class.new
      item_comp = potion_item.get_component(:item)
      item_comp.stack_size = 5
      component.add(potion_item)
      expect(component.count(:potion)).to eq(5)
    end

    it 'returns 0 for items not in inventory' do
      component = described_class.new
      expect(component.count(:potion)).to eq(0)
    end
  end

  describe '#find_by_id' do
    let(:item) { Vanilla::Entities::Entity.new }

    it 'finds item by id' do
      component = described_class.new
      component.add(item)
      expect(component.find_by_id(item.id)).to eq(item)
    end

    it 'returns nil if item not found' do
      component = described_class.new
      expect(component.find_by_id("non-existent")).to be_nil
    end
  end

  describe '#to_hash' do
    it 'serializes component to hash' do
      component = described_class.new(max_size: 10)
      item = Vanilla::Entities::Entity.new
      component.add(item)
      hash = component.to_hash
      expect(hash[:type]).to eq(:inventory)
      expect(hash[:max_size]).to eq(10)
      expect(hash[:items]).to be_an(Array)
    end
  end

  describe '.from_hash' do
    it 'deserializes component from hash' do
      hash = { type: :inventory, max_size: 15 }
      component = described_class.from_hash(hash)
      expect(component.max_size).to eq(15)
      expect(component.items).to be_empty
    end
  end
end

