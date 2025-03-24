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
        end
      end

      describe "#type" do
        it "returns :item" do
          item = ItemComponent.new(name: "Test Item")
          expect(item.type).to eq(:item)
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
          expect(new_item.stack_size).to eq(3)
        end

        it "handles missing values in the hash" do
          hash = { type: :item, name: "Partial Item" }
          new_item = ItemComponent.from_hash(hash)

          expect(new_item.name).to eq("Partial Item")
          expect(new_item.description).to eq("")
          expect(new_item.item_type).to eq(:misc)
        end
      end
    end
  end
end
