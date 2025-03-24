# frozen_string_literal: true

require 'spec_helper'

module Vanilla
  module Components
    RSpec.describe ConsumableComponent do
      describe "#initialize" do
        it "sets charges, effects, and auto_identify" do
          consumable = ConsumableComponent.new
          expect(consumable.charges).to eq(1)
          expect(consumable.effects).to eq([])
          expect(consumable.auto_identify).to be false
        end
      end

      describe "#type" do
        it "returns :consumable" do
          consumable = ConsumableComponent.new
          expect(consumable.type).to eq(:consumable)
        end
      end

      describe "#to_hash and .from_hash" do
        let(:consumable) do
          ConsumableComponent.new(
            charges: 3,
            effects: [
              { type: :heal, amount: 10 },
              { type: :buff, stat: :strength, amount: 2, duration: 5 }
            ],
            auto_identify: true
          )
        end

        it "serializes to a hash" do
          hash = consumable.to_hash
          expect(hash[:type]).to eq(:consumable)
          expect(hash[:charges]).to eq(3)
          expect(hash[:effects].size).to eq(2)
          expect(hash[:effects][0][:type]).to eq(:heal)
          expect(hash[:auto_identify]).to be true
        end

        it "deserializes from a hash" do
          hash = consumable.to_hash
          new_consumable = ConsumableComponent.from_hash(hash)

          expect(new_consumable.charges).to eq(3)
          expect(new_consumable.effects.size).to eq(2)
          expect(new_consumable.effects[0][:type]).to eq(:heal)
          expect(new_consumable.auto_identify).to be true
        end

        it "handles missing values in the hash" do
          hash = { type: :consumable }
          new_consumable = ConsumableComponent.from_hash(hash)

          expect(new_consumable.charges).to eq(1)
          expect(new_consumable.effects).to eq([])
          expect(new_consumable.auto_identify).to be false
        end
      end
    end
  end
end
