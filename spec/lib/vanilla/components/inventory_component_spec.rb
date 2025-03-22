require 'spec_helper'

module Vanilla
  module Components
    RSpec.describe InventoryComponent do
      let(:inventory) { InventoryComponent.new }
      let(:item) do
        item = Entity.new
        item.add_component(ItemComponent.new(name: "Test Item"))
        item
      end
      let(:stackable_item) do
        item = Entity.new
        item.add_component(ItemComponent.new(
          name: "Stackable Item",
          stackable: true
        ))
        item
      end

      describe "#initialize" do
        it "creates an empty inventory" do
          expect(inventory.items).to be_empty
        end

        it "sets the default max size" do
          expect(inventory.max_size).to eq(20)
        end

        it "allows custom max size" do
          custom_inventory = InventoryComponent.new(max_size: 10)
          expect(custom_inventory.max_size).to eq(10)
        end
      end

      describe "#type" do
        it "returns :inventory" do
          expect(inventory.type).to eq(:inventory)
        end
      end

      describe "#full?" do
        it "returns false when inventory is not full" do
          expect(inventory.full?).to be false
        end

        it "returns true when inventory is full" do
          small_inventory = InventoryComponent.new(max_size: 1)
          small_inventory.add(item)
          expect(small_inventory.full?).to be true
        end
      end

      describe "#add" do
        it "adds an item to the inventory" do
          inventory.add(item)
          expect(inventory.items).to include(item)
        end

        it "returns true when item is added successfully" do
          expect(inventory.add(item)).to be true
        end

        it "returns false when inventory is full" do
          small_inventory = InventoryComponent.new(max_size: 0)
          expect(small_inventory.add(item)).to be false
        end

        context "with stackable items" do
          it "stacks items of the same type" do
            inventory.add(stackable_item)

            # Create a similar stackable item
            similar_item = Entity.new
            similar_item.add_component(ItemComponent.new(
              name: "Stackable Item",
              stackable: true,
              item_type: :potion
            ))

            # Both should have the same item_type
            stackable_item.get_component(:item).instance_variable_set(:@item_type, :potion)

            # Add the similar item
            expect {
              inventory.add(similar_item)
            }.not_to change { inventory.items.count }

            # But the stack size should increase
            expect(stackable_item.get_component(:item).stack_size).to eq(2)
          end
        end
      end

      describe "#remove" do
        before { inventory.add(item) }

        it "removes an item from the inventory" do
          inventory.remove(item)
          expect(inventory.items).not_to include(item)
        end

        it "returns the removed item" do
          expect(inventory.remove(item)).to eq(item)
        end

        it "returns nil if item is not in inventory" do
          other_item = Entity.new
          expect(inventory.remove(other_item)).to be_nil
        end

        context "with stackable items" do
          before do
            inventory.add(stackable_item)
            # Manually set stack size to 2
            stackable_item.get_component(:item).stack_size = 2
          end

          it "decreases stack size for stackable items with multiple stacks" do
            expect {
              inventory.remove(stackable_item)
            }.not_to change { inventory.items.count }

            expect(stackable_item.get_component(:item).stack_size).to eq(1)
          end

          it "removes the item when last stack is removed" do
            # First removal decreases to 1
            inventory.remove(stackable_item)
            # Second removal should remove the item
            inventory.remove(stackable_item)
            expect(inventory.items).not_to include(stackable_item)
          end
        end
      end

      describe "#has?" do
        before do
          weapon = Entity.new
          weapon.add_component(ItemComponent.new(
            name: "Sword",
            item_type: :weapon
          ))
          inventory.add(weapon)
        end

        it "returns true if inventory has an item of specified type" do
          expect(inventory.has?(:weapon)).to be true
        end

        it "returns false if inventory doesn't have an item of specified type" do
          expect(inventory.has?(:potion)).to be false
        end
      end

      describe "#count" do
        before do
          # Add 2 potions (one with stack of 2)
          potion1 = Entity.new
          potion1.add_component(ItemComponent.new(
            name: "Healing Potion",
            item_type: :potion,
            stackable: true,
            stack_size: 2
          ))

          potion2 = Entity.new
          potion2.add_component(ItemComponent.new(
            name: "Mana Potion",
            item_type: :potion
          ))

          inventory.add(potion1)
          inventory.add(potion2)
        end

        it "counts the total number of items of a specific type, including stacks" do
          expect(inventory.count(:potion)).to eq(3)
        end

        it "returns 0 for item types not in inventory" do
          expect(inventory.count(:weapon)).to eq(0)
        end
      end

      describe "#find_by_id" do
        it "returns an item with the matching ID" do
          inventory.add(item)
          expect(inventory.find_by_id(item.id)).to eq(item)
        end

        it "returns nil if no item matches the ID" do
          expect(inventory.find_by_id("non-existent-id")).to be_nil
        end
      end

      describe "#to_hash and .from_hash" do
        it "serializes the inventory to a hash" do
          hash = inventory.to_hash
          expect(hash[:type]).to eq(:inventory)
          expect(hash[:max_size]).to eq(20)
          expect(hash[:items]).to be_an(Array)
        end

        it "deserializes from a hash" do
          hash = { type: :inventory, max_size: 15, items: [] }
          new_inventory = InventoryComponent.from_hash(hash)
          expect(new_inventory).to be_a(InventoryComponent)
          expect(new_inventory.max_size).to eq(15)
        end
      end
    end
  end
end