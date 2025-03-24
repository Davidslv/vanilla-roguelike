# frozen_string_literal: true

require 'spec_helper'

module Vanilla
  module Components
    RSpec.describe ItemComponent do
      describe "#initialize" do
        it "sets required properties" do
          item = ItemComponent.new(name: "Test Item")
          expect(item.name).to eq("Test Item")
        end

        it "sets default values" do
          item = ItemComponent.new(name: "Test Item")
          expect(item.description).to eq("")
          expect(item.item_type).to eq(:misc)
          expect(item.weight).to eq(1)
          expect(item.value).to eq(0)
          expect(item.stack_size).to eq(1)
          expect(item.stackable?).to be false
        end

        it "allows setting custom values" do
          item = ItemComponent.new(
            name: "Magic Potion",
            description: "Restores health",
            item_type: :potion,
            weight: 0.5,
            value: 50,
            stackable: true,
            stack_size: 3
          )
          expect(item.name).to eq("Magic Potion")
          expect(item.description).to eq("Restores health")
          expect(item.item_type).to eq(:potion)
          expect(item.weight).to eq(0.5)
          expect(item.value).to eq(50)
          expect(item.stack_size).to eq(3)
          expect(item.stackable?).to be true
        end
      end

      describe "#type" do
        it "returns :item" do
          item = ItemComponent.new(name: "Test Item")
          expect(item.type).to eq(:item)
        end
      end

      describe "#stackable?" do
        it "returns true for stackable items" do
          item = ItemComponent.new(name: "Gold Coin", stackable: true)
          expect(item.stackable?).to be true
        end

        it "returns false for non-stackable items" do
          item = ItemComponent.new(name: "Sword")
          expect(item.stackable?).to be false
        end
      end

      describe "#increase_stack and #decrease_stack" do
        context "with stackable items" do
          let(:stackable_item) { ItemComponent.new(name: "Arrow", stackable: true, stack_size: 1) }

          it "increases stack size" do
            expect {
              stackable_item.increase_stack
            }.to change { stackable_item.stack_size }.from(1).to(2)
          end

          it "decreases stack size" do
            stackable_item.stack_size = 3
            expect {
              stackable_item.decrease_stack
            }.to change { stackable_item.stack_size }.from(3).to(2)
          end

          it "doesn't decrease below zero" do
            stackable_item.stack_size = 1
            stackable_item.decrease_stack
            stackable_item.decrease_stack # Try to decrease below 0
            expect(stackable_item.stack_size).to eq(0)
          end
        end

        context "with non-stackable items" do
          let(:item) { ItemComponent.new(name: "Sword") }

          it "doesn't increase stack size" do
            expect {
              item.increase_stack
            }.not_to change { item.stack_size }
          end

          it "doesn't decrease stack size" do
            expect {
              item.decrease_stack
            }.not_to change { item.stack_size }
          end
        end
      end

      describe "#use" do
        it "returns false by default" do
          item = ItemComponent.new(name: "Test Item")
          entity = double("Entity")
          expect(item.use(entity)).to be false
        end
      end

      describe "#to_hash and .from_hash" do
        let(:item) {
          ItemComponent.new(
            name: "Magic Potion",
            description: "Restores health",
            item_type: :potion,
            weight: 0.5,
            value: 50,
            stackable: true,
            stack_size: 3
          )
        }

        it "serializes to a hash" do
          hash = item.to_hash
          expect(hash[:type]).to eq(:item)
          expect(hash[:name]).to eq("Magic Potion")
          expect(hash[:description]).to eq("Restores health")
          expect(hash[:item_type]).to eq(:potion)
          expect(hash[:weight]).to eq(0.5)
          expect(hash[:value]).to eq(50)
          expect(hash[:stackable]).to be true
          expect(hash[:stack_size]).to eq(3)
        end

        it "deserializes from a hash" do
          hash = item.to_hash
          new_item = ItemComponent.from_hash(hash)

          expect(new_item.name).to eq("Magic Potion")
          expect(new_item.description).to eq("Restores health")
          expect(new_item.item_type).to eq(:potion)
          expect(new_item.weight).to eq(0.5)
          expect(new_item.value).to eq(50)
          expect(new_item.stackable?).to be true
          expect(new_item.stack_size).to eq(3)
        end

        it "handles missing values in the hash" do
          hash = { type: :item, name: "Partial Item" }
          new_item = ItemComponent.from_hash(hash)

          expect(new_item.name).to eq("Partial Item")
          expect(new_item.description).to eq("")
          expect(new_item.item_type).to eq(:misc)
          expect(new_item.stackable?).to be false
        end
      end

      describe "#display_string" do
        it "returns just the name for non-stackable items" do
          item = ItemComponent.new(name: "Sword")
          expect(item.display_string).to eq("Sword")
        end

        it "returns name with stack size for stackable items with multiple stacks" do
          item = ItemComponent.new(name: "Arrow", stackable: true, stack_size: 20)
          expect(item.display_string).to eq("Arrow (20)")
        end

        it "returns just the name for stackable items with single stack" do
          item = ItemComponent.new(name: "Arrow", stackable: true, stack_size: 1)
          expect(item.display_string).to eq("Arrow")
        end
      end
    end
  end
end
