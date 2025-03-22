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

        it "allows custom charges" do
          consumable = ConsumableComponent.new(charges: 3)
          expect(consumable.charges).to eq(3)
        end

        it "allows custom effects" do
          effects = [
            { type: :heal, amount: 10 },
            { type: :buff, stat: :strength, amount: 2, duration: 5 }
          ]
          consumable = ConsumableComponent.new(effects: effects)
          expect(consumable.effects).to eq(effects)
        end

        it "allows setting auto_identify" do
          consumable = ConsumableComponent.new(auto_identify: true)
          expect(consumable.auto_identify).to be true
        end
      end

      describe "#type" do
        it "returns :consumable" do
          consumable = ConsumableComponent.new
          expect(consumable.type).to eq(:consumable)
        end
      end

      describe "#has_charges?" do
        it "returns true when charges > 0" do
          consumable = ConsumableComponent.new(charges: 3)
          expect(consumable.has_charges?).to be true
        end

        it "returns false when charges = 0" do
          consumable = ConsumableComponent.new(charges: 0)
          expect(consumable.has_charges?).to be false
        end
      end

      describe "#consume" do
        let(:consumable) { ConsumableComponent.new(charges: 3) }
        let(:entity) { double("Entity") }

        it "returns false if no charges left" do
          no_charges = ConsumableComponent.new(charges: 0)
          expect(no_charges.consume(entity)).to be false
        end

        it "returns false if entity is nil" do
          expect(consumable.consume(nil)).to be false
        end

        it "reduces charges by 1 when successfully used" do
          # Stub the apply_effects method to return true
          allow(consumable).to receive(:apply_effects).and_return(true)

          expect {
            consumable.consume(entity)
          }.to change { consumable.charges }.from(3).to(2)
        end

        it "doesn't reduce charges when effects application fails" do
          # Stub the apply_effects method to return false
          allow(consumable).to receive(:apply_effects).and_return(false)

          expect {
            consumable.consume(entity)
          }.not_to change { consumable.charges }
        end

        it "applies effects to the entity" do
          # Spy on the private method
          expect(consumable).to receive(:apply_effects).with(entity).and_return(true)

          consumable.consume(entity)
        end

        it "returns true when effects are successfully applied" do
          allow(consumable).to receive(:apply_effects).and_return(true)
          expect(consumable.consume(entity)).to be true
        end

        it "returns false when effects application fails" do
          allow(consumable).to receive(:apply_effects).and_return(false)
          expect(consumable.consume(entity)).to be false
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

      describe "#apply_effects" do
        let(:entity) { instance_double("Entity") }
        let(:message_system) { instance_double("MessageSystem") }
        let(:consumable) { Vanilla::Components::ConsumableComponent.new(effects: [
          { type: :heal, amount: 10 },
          { type: :buff, stat: :strength, amount: 5, duration: 3 },
          { type: :teleport },
          { type: :damage, amount: 5, damage_type: :fire }
        ])}

        before do
          allow(Vanilla::ServiceRegistry).to receive(:get).with(:message_system).and_return(message_system)
          # These are the methods that would be called by apply_effects
          allow(consumable).to receive(:heal_entity).and_return(true)
          allow(consumable).to receive(:damage_entity).and_return(true)
          allow(consumable).to receive(:apply_buff).and_return(true)
          allow(consumable).to receive(:teleport_entity).and_return(true)
          allow(message_system).to receive(:log_message)
        end

        it "calls the appropriate effect application method for each effect" do
          # Make the method public for testing
          expect(consumable).to receive(:heal_entity).with(entity, 10).once
          expect(consumable).to receive(:apply_buff).with(entity, :strength, 5, 3).once
          expect(consumable).to receive(:teleport_entity).with(entity).once
          expect(consumable).to receive(:damage_entity).with(entity, 5, :fire).once

          consumable.apply_effects(entity)
        end

        it "returns true when all effects are applied successfully" do
          expect(consumable.apply_effects(entity)).to be true
        end

        it "returns false if any effect fails" do
          allow(consumable).to receive(:teleport_entity).and_return(false)
          expect(consumable.apply_effects(entity)).to be false
        end

        it "logs successful effects through the message system" do
          expect(message_system).to receive(:log_message).exactly(4).times

          consumable.apply_effects(entity)
        end
      end
    end
  end
end