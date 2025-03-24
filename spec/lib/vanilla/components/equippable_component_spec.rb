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
          expect(equippable.equipped).to be true
        end

        it "defaults to not equipped" do
          equippable = EquippableComponent.new(slot: :head)
          expect(equippable.equipped).to be false
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
          expect(equippable.equipped).to be true
        end

        it "handles missing values in the hash" do
          hash = {
            slot: :body
          }

          equippable = EquippableComponent.from_hash(hash)
          expect(equippable.slot).to eq(:body)
          expect(equippable.stat_modifiers).to eq({})
          expect(equippable.equipped).to be false
        end
      end
    end
  end
end
