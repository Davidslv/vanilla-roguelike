# frozen_string_literal: true

require 'spec_helper'

module Vanilla
  module Inventory
    RSpec.describe ItemFactory do
      let(:logger) { double('logger', debug: nil, info: nil, warn: nil, error: nil) }
      let(:factory) { ItemFactory.new(logger) }

      describe "#initialize" do
        it "creates an item factory with the given logger" do
          expect(factory.instance_variable_get(:@logger)).to eq(logger)
        end
      end

      describe "#create_item" do
        it "creates a basic item entity" do
          item = factory.create_item("Test Item")
          expect(item).to be_a(Vanilla::Components::Entity)
          expect(item.has_component?(:item)).to be true
          expect(item.has_component?(:render)).to be true
        end

        it "sets the item name correctly" do
          item = factory.create_item("Magic Sword")
          expect(item.get_component(:item).name).to eq("Magic Sword")
        end

        it "uses default values for optional parameters" do
          item = factory.create_item("Test Item")

          # Check render component defaults
          render = item.get_component(:render)
          expect(render.character).to eq('?')
          expect(render.color).to be_nil
          expect(render.layer).to eq(5)

          # Check item component defaults
          item_comp = item.get_component(:item)
          expect(item_comp.description).to eq("")
          expect(item_comp.item_type).to eq(:misc)
          expect(item_comp.weight).to eq(1)
          expect(item_comp.value).to eq(0)
          expect(item_comp.stackable?).to be false
        end

        it "allows custom options for the item" do
          options = {
            character: '$',
            color: :yellow,
            layer: 3,
            description: "A shiny gold coin",
            item_type: :currency,
            weight: 0.1,
            value: 1,
            stackable: true
          }

          item = factory.create_item("Gold Coin", options)

          # Check render component
          render = item.get_component(:render)
          expect(render.character).to eq('$')
          expect(render.color).to eq(:yellow)
          expect(render.layer).to eq(3)

          # Check item component
          item_comp = item.get_component(:item)
          expect(item_comp.description).to eq("A shiny gold coin")
          expect(item_comp.item_type).to eq(:currency)
          expect(item_comp.weight).to eq(0.1)
          expect(item_comp.value).to eq(1)
          expect(item_comp.stackable?).to be true
        end

        it "adds additional components if provided" do
          # Create a custom component to add
          durability = double('DurabilityComponent')
          allow(durability).to receive(:type).and_return(:durability)

          options = {
            components: [durability]
          }

          item = factory.create_item("Test Item", options)

          # The item factory adds the component
          expect(item.instance_variable_get(:@components)).to include(durability)
        end
      end

      describe "#create_weapon" do
        it "creates a weapon item with default values" do
          weapon = factory.create_weapon("Sword", 5)

          # Check item component
          item_comp = weapon.get_component(:item)
          expect(item_comp.name).to eq("Sword")
          expect(item_comp.item_type).to eq(:weapon)

          # Check render component
          render = weapon.get_component(:render)
          expect(render.character).to eq(')')  # Default for weapons

          # Check equippable component
          equippable = weapon.get_component(:equippable)
          expect(equippable).not_to be_nil
          expect(equippable.slot).to eq(:right_hand)  # Default slot
          expect(equippable.stat_modifiers).to eq({ attack: 5 })
          expect(equippable.equipped?).to be false
        end

        it "allows custom options for weapons" do
          options = {
            description: "A massive two-handed greatsword",
            slot: :both_hands,
            character: '/',
            value: 100
          }

          weapon = factory.create_weapon("Greatsword", 10, options)

          # Check item component
          item_comp = weapon.get_component(:item)
          expect(item_comp.description).to eq("A massive two-handed greatsword")
          expect(item_comp.value).to eq(100)

          # Check render component
          render = weapon.get_component(:render)
          expect(render.character).to eq('/')

          # Check equippable component
          equippable = weapon.get_component(:equippable)
          expect(equippable.slot).to eq(:both_hands)
        end
      end

      describe "#create_armor" do
        it "creates an armor item with default values" do
          armor = factory.create_armor("Leather Armor", 3)

          # Check item component
          item_comp = armor.get_component(:item)
          expect(item_comp.name).to eq("Leather Armor")
          expect(item_comp.item_type).to eq(:armor)

          # Check render component
          render = armor.get_component(:render)
          expect(render.character).to eq('[')  # Default for armor

          # Check equippable component
          equippable = armor.get_component(:equippable)
          expect(equippable).not_to be_nil
          expect(equippable.slot).to eq(:body)  # Default for "Leather Armor"
          expect(equippable.stat_modifiers).to eq({ defense: 3 })
          expect(equippable.equipped?).to be false
        end

        it "determines slot based on armor name" do
          helmet = factory.create_armor("Iron Helmet", 2)
          boots = factory.create_armor("Leather Boots", 1)
          gloves = factory.create_armor("Chain Gauntlets", 1)
          amulet = factory.create_armor("Magic Amulet", 1)
          ring = factory.create_armor("Gold Ring", 1)

          # Check slots
          expect(helmet.get_component(:equippable).slot).to eq(:head)
          expect(boots.get_component(:equippable).slot).to eq(:feet)
          expect(gloves.get_component(:equippable).slot).to eq(:hands)
          expect(amulet.get_component(:equippable).slot).to eq(:neck)
          expect(ring.get_component(:equippable).slot).to eq(:ring)
        end

        it "allows custom options for armor" do
          options = {
            description: "A magical robe of protection",
            slot: :body,  # Override slot detection
            character: '{',
            value: 200
          }

          armor = factory.create_armor("Wizard Robe", 2, options)

          # Check item component
          item_comp = armor.get_component(:item)
          expect(item_comp.description).to eq("A magical robe of protection")
          expect(item_comp.value).to eq(200)

          # Check render component
          render = armor.get_component(:render)
          expect(render.character).to eq('{')

          # Check equippable component
          equippable = armor.get_component(:equippable)
          expect(equippable.slot).to eq(:body)
        end
      end

      describe "#create_potion" do
        it "creates a potion item with default values" do
          potion = factory.create_potion("Healing Potion", :heal, 10)

          # Check item component
          item_comp = potion.get_component(:item)
          expect(item_comp.name).to eq("Healing Potion")
          expect(item_comp.item_type).to eq(:potion)
          expect(item_comp.stackable?).to be true  # Potions are stackable by default

          # Check render component
          render = potion.get_component(:render)
          expect(render.character).to eq('!')  # Default for potions

          # Check consumable component
          consumable = potion.get_component(:consumable)
          expect(consumable).not_to be_nil
          expect(consumable.charges).to eq(1)
          expect(consumable.effects.size).to eq(1)
          expect(consumable.effects.first[:type]).to eq(:heal)
          expect(consumable.effects.first[:amount]).to eq(10)
          expect(consumable.auto_identify).to be false
        end

        it "allows custom options for potions" do
          options = {
            description: "A potent strength potion",
            charges: 2,
            duration: 10,  # For the effect
            stat: :strength,  # For the effect
            auto_identify: true,
            character: 'p',
            value: 50
          }

          potion = factory.create_potion("Strength Potion", :buff, 3, options)

          # Check item component
          item_comp = potion.get_component(:item)
          expect(item_comp.description).to eq("A potent strength potion")
          expect(item_comp.value).to eq(50)

          # Check render component
          render = potion.get_component(:render)
          expect(render.character).to eq('p')

          # Check consumable component
          consumable = potion.get_component(:consumable)
          expect(consumable.charges).to eq(2)
          expect(consumable.auto_identify).to be true

          # Check effect
          effect = consumable.effects.first
          expect(effect[:type]).to eq(:buff)
          expect(effect[:amount]).to eq(3)
          expect(effect[:duration]).to eq(10)
          expect(effect[:stat]).to eq(:strength)
        end
      end

      describe "#create_scroll" do
        it "creates a scroll item with default values" do
          scroll = factory.create_scroll("Fireball Scroll", :damage, 15)

          # Check item component
          item_comp = scroll.get_component(:item)
          expect(item_comp.name).to eq("Fireball Scroll")
          expect(item_comp.item_type).to eq(:scroll)
          expect(item_comp.stackable?).to be false  # Scrolls not stackable by default

          # Check render component
          render = scroll.get_component(:render)
          expect(render.character).to eq('?')  # Default for scrolls

          # Check consumable component
          consumable = scroll.get_component(:consumable)
          expect(consumable).not_to be_nil
          expect(consumable.charges).to eq(1)
          expect(consumable.effects.size).to eq(1)
          expect(consumable.effects.first[:type]).to eq(:damage)
          expect(consumable.effects.first[:amount]).to eq(15)
          expect(consumable.auto_identify).to be false
        end

        it "allows custom options for scrolls" do
          options = {
            description: "A scroll of teleportation",
            auto_identify: true,
            character: 'T',
            value: 75,
            stackable: true  # Make stackable if desired
          }

          scroll = factory.create_scroll("Teleport Scroll", :teleport, 1, options)

          # Check item component
          item_comp = scroll.get_component(:item)
          expect(item_comp.description).to eq("A scroll of teleportation")
          expect(item_comp.value).to eq(75)
          expect(item_comp.stackable?).to be true

          # Check render component
          render = scroll.get_component(:render)
          expect(render.character).to eq('T')

          # Check consumable component
          consumable = scroll.get_component(:consumable)
          expect(consumable.auto_identify).to be true

          # Check effect
          effect = consumable.effects.first
          expect(effect[:type]).to eq(:teleport)
          expect(effect[:amount]).to eq(1)
        end
      end
    end
  end
end
