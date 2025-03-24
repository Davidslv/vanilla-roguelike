# frozen_string_literal: true

require 'spec_helper'

module Vanilla
  module Components
    RSpec.describe EquippableComponent do
      let(:component) { EquippableComponent.new(slot: :right_hand) }

      describe "#initialize" do
        it "sets slot, stat_modifiers, and equipped status" do
          equippable = EquippableComponent.new(slot: :body, stat_modifiers: { defense: 5 }, equipped: true)
          expect(equippable.slot).to eq(:body)
          expect(equippable.stat_modifiers).to eq({ defense: 5 })
          expect(equippable.equipped?).to be true
        end

        it "defaults to not equipped" do
          equippable = EquippableComponent.new(slot: :head)
          expect(equippable.equipped?).to be false
        end

        it "defaults to empty stat modifiers" do
          equippable = EquippableComponent.new(slot: :feet)
          expect(equippable.stat_modifiers).to eq({})
        end

        it "raises an error for invalid slot types" do
          expect {
            EquippableComponent.new(slot: :invalid_slot)
          }.to raise_error(ArgumentError)
        end
      end

      describe "#type" do
        it "returns :equippable" do
          expect(component.type).to eq(:equippable)
        end
      end

      describe "#equipped?" do
        it "returns the equipped status" do
          component.equipped = true
          expect(component.equipped?).to be true

          component.equipped = false
          expect(component.equipped?).to be false
        end
      end

      describe "#equip" do
        let(:entity) { instance_double("Entity") }
        let(:inventory) { instance_double("InventoryComponent") }

        before do
          allow(entity).to receive(:has_component?).and_return(true)
          allow(entity).to receive(:get_component).with(:inventory).and_return(inventory)
        end

        it "returns false if already equipped" do
          component.equipped = true
          expect(component.equip(entity)).to be false
        end

        it "returns false if slot is occupied" do
          # Simulate a full slot
          allow(inventory).to receive(:items).and_return([
                                                           double("Item", has_component?: true,
                                                                          get_component: double("EquippableComponent", equipped?: true, slot: :right_hand))
                                                         ])
          expect(component.equip(entity)).to be false
        end

        it "applies stat modifiers when equipped" do
          # Simulate empty inventory
          allow(inventory).to receive(:items).and_return([])

          # Check if stat modifiers are applied
          expect(component).to receive(:apply_stat_modifiers)
          component.equip(entity)
        end

        it "sets equipped to true when successful" do
          # Simulate empty inventory
          allow(inventory).to receive(:items).and_return([])

          component.equip(entity)
          expect(component.equipped?).to be true
        end

        it "returns true when successful" do
          # Simulate empty inventory
          allow(inventory).to receive(:items).and_return([])

          expect(component.equip(entity)).to be true
        end
      end

      describe "#unequip" do
        let(:entity) { instance_double("Entity") }
        let(:inventory) { instance_double("InventoryComponent") }

        before do
          allow(entity).to receive(:has_component?).and_return(true)
          allow(entity).to receive(:get_component).with(:inventory).and_return(inventory)
          allow(inventory).to receive(:items).and_return([])
        end

        it "returns false if not equipped" do
          component.equipped = false
          expect(component.unequip(entity)).to be false
        end

        it "removes stat modifiers when unequipped" do
          component.equipped = true
          expect(component).to receive(:remove_stat_modifiers)
          component.unequip(entity)
        end

        it "sets equipped to false when successful" do
          component.equipped = true
          component.unequip(entity)
          expect(component.equipped?).to be false
        end

        it "returns true when successful" do
          component.equipped = true
          expect(component.unequip(entity)).to be true
        end
      end

      describe "#to_hash" do
        it "serializes to a hash" do
          equippable = EquippableComponent.new(
            slot: :head,
            stat_modifiers: { defense: 3, resistance: 2 },
            equipped: true
          )

          hash = equippable.to_hash
          expect(hash[:type]).to eq(:equippable)
          expect(hash[:slot]).to eq(:head)
          expect(hash[:stat_modifiers]).to eq({ defense: 3, resistance: 2 })
          expect(hash[:equipped]).to eq(true)
        end
      end

      describe ".from_hash" do
        it "deserializes from a hash" do
          hash = {
            type: :equippable,
            slot: :right_hand,
            stat_modifiers: { attack: 5 },
            equipped: true
          }

          equippable = EquippableComponent.from_hash(hash)
          expect(equippable.slot).to eq(:right_hand)
          expect(equippable.stat_modifiers).to eq({ attack: 5 })
          expect(equippable.equipped?).to be true
        end

        it "handles missing values in the hash" do
          hash = {
            slot: :body
          }

          equippable = EquippableComponent.from_hash(hash)
          expect(equippable.slot).to eq(:body)
          expect(equippable.stat_modifiers).to eq({})
          expect(equippable.equipped?).to be false
        end
      end
    end
  end
end
