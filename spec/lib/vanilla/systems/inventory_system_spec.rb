# frozen_string_literal: true

require 'spec_helper'

module Vanilla
  module Systems
    RSpec.describe InventorySystem do
      let(:logger) { double('logger', debug: nil, info: nil, warn: nil, error: nil) }
      let(:message_system) { double('message_system', log_message: nil) }
      let(:inventory_system) { InventorySystem.new(logger) }

      let(:entity) do
        entity = Vanilla::Components::Entity.new
        inventory = Vanilla::Components::InventoryComponent.new
        entity.add_component(inventory)
        entity
      end

      let(:item) do
        item = Vanilla::Components::Entity.new
        item.add_component(Vanilla::Components::ItemComponent.new(name: "Test Item"))
        item
      end

      before do
        # Stub the ServiceRegistry to return our mock message_system
        allow(Vanilla::ServiceRegistry).to receive(:get)
          .with(:message_system).and_return(message_system)
      end

      describe "#initialize" do
        it "creates an inventory system with the given logger" do
          expect(inventory_system.instance_variable_get(:@logger)).to eq(logger)
        end

        it "gets the message system from the service registry" do
          expect(inventory_system.instance_variable_get(:@message_system)).to eq(message_system)
        end
      end

      describe "#add_item" do
        it "adds an item to the entity's inventory" do
          expect(entity.get_component(:inventory).items).to be_empty
          inventory_system.add_item(entity, item)
          expect(entity.get_component(:inventory).items).to include(item)
        end

        it "returns true when item is added successfully" do
          expect(inventory_system.add_item(entity, item)).to be true
        end

        it "returns false when entity is nil" do
          expect(inventory_system.add_item(nil, item)).to be false
        end

        it "returns false when item is nil" do
          expect(inventory_system.add_item(entity, nil)).to be false
        end

        it "returns false when entity has no inventory component" do
          entity_without_inventory = Vanilla::Components::Entity.new
          expect(inventory_system.add_item(entity_without_inventory, item)).to be false
        end

        it "returns false when inventory is full" do
          # Create a full inventory
          full_inventory = Vanilla::Components::InventoryComponent.new(max_size: 0)
          entity_with_full_inventory = Vanilla::Components::Entity.new
          entity_with_full_inventory.add_component(full_inventory)

          expect(inventory_system.add_item(entity_with_full_inventory, item)).to be false
        end

        it "logs a success message when item is added" do
          expect(message_system).to receive(:log_message).with(
            "items.add",
            hash_including(
              category: :item,
              importance: :normal,
              metadata: { item: "Test Item" }
            )
          )
          inventory_system.add_item(entity, item)
        end

        it "logs a warning message when inventory is full" do
          # Create a full inventory
          full_inventory = Vanilla::Components::InventoryComponent.new(max_size: 0)
          entity_with_full_inventory = Vanilla::Components::Entity.new
          entity_with_full_inventory.add_component(full_inventory)

          expect(message_system).to receive(:log_message).with(
            "items.inventory_full",
            hash_including(
              category: :item,
              importance: :warning
            )
          )
          inventory_system.add_item(entity_with_full_inventory, item)
        end
      end

      describe "#remove_item" do
        before do
          # Add the item to the inventory first
          entity.get_component(:inventory).add(item)
        end

        it "removes an item from the entity's inventory" do
          expect(entity.get_component(:inventory).items).to include(item)
          inventory_system.remove_item(entity, item)
          expect(entity.get_component(:inventory).items).not_to include(item)
        end

        it "returns the removed item" do
          expect(inventory_system.remove_item(entity, item)).to eq(item)
        end

        it "returns nil when entity is nil" do
          expect(inventory_system.remove_item(nil, item)).to be_nil
        end

        it "returns nil when item is nil" do
          expect(inventory_system.remove_item(entity, nil)).to be_nil
        end

        it "returns nil when entity has no inventory component" do
          entity_without_inventory = Vanilla::Components::Entity.new
          expect(inventory_system.remove_item(entity_without_inventory, item)).to be_nil
        end

        it "returns nil when item is not in the inventory" do
          other_item = Vanilla::Components::Entity.new
          other_item.add_component(Vanilla::Components::ItemComponent.new(name: "Other Item"))

          expect(inventory_system.remove_item(entity, other_item)).to be_nil
        end

        it "logs a message when item is removed" do
          expect(message_system).to receive(:log_message).with(
            "items.remove",
            hash_including(
              category: :item,
              importance: :normal,
              metadata: { item: "Test Item" }
            )
          )
          inventory_system.remove_item(entity, item)
        end
      end

      describe "#use_item" do
        let(:consumable_item) do
          item = Vanilla::Components::Entity.new
          item.add_component(Vanilla::Components::ItemComponent.new(name: "Potion"))
          item.add_component(Vanilla::Components::ConsumableComponent.new)
          item
        end

        let(:equippable_item) do
          item = Vanilla::Components::Entity.new
          item.add_component(Vanilla::Components::ItemComponent.new(name: "Sword"))
          item.add_component(Vanilla::Components::EquippableComponent.new(slot: :right_hand))
          item
        end

        before do
          # Add items to the inventory
          entity.get_component(:inventory).add(item)
          entity.get_component(:inventory).add(consumable_item)
          entity.get_component(:inventory).add(equippable_item)
        end

        it "returns false when entity is nil" do
          expect(inventory_system.use_item(nil, item)).to be false
        end

        it "returns false when item is nil" do
          expect(inventory_system.use_item(entity, nil)).to be false
        end

        it "returns false when entity has no inventory component" do
          entity_without_inventory = Vanilla::Components::Entity.new
          expect(inventory_system.use_item(entity_without_inventory, item)).to be false
        end

        it "returns false when item is not in inventory" do
          other_item = Vanilla::Components::Entity.new
          expect(inventory_system.use_item(entity, other_item)).to be false
        end

        it "uses a consumable item" do
          # Spy to verify the private method is called
          expect(inventory_system).to receive(:use_consumable).with(entity, consumable_item).and_return(true)

          inventory_system.use_item(entity, consumable_item)
        end

        it "toggles equipment for an equippable item" do
          # Spy to verify the private method is called
          expect(inventory_system).to receive(:toggle_equip).with(entity, equippable_item).and_return(true)

          inventory_system.use_item(entity, equippable_item)
        end

        it "handles regular items" do
          expect(message_system).to receive(:log_message).with(
            "items.use",
            hash_including(
              category: :item,
              importance: :normal,
              metadata: { item: "Test Item" }
            )
          )
          expect(inventory_system.use_item(entity, item)).to be true
        end
      end

      describe "#equip_item" do
        let(:equippable_item) do
          item = Vanilla::Components::Entity.new
          item.add_component(Vanilla::Components::ItemComponent.new(name: "Sword"))
          item.add_component(Vanilla::Components::EquippableComponent.new(slot: :right_hand))
          item
        end

        before do
          # Add the equippable item to the inventory
          entity.get_component(:inventory).add(equippable_item)
        end

        it "returns false when entity is nil" do
          expect(inventory_system.equip_item(nil, equippable_item)).to be false
        end

        it "returns false when item is nil" do
          expect(inventory_system.equip_item(entity, nil)).to be false
        end

        it "returns false when entity has no inventory component" do
          entity_without_inventory = Vanilla::Components::Entity.new
          expect(inventory_system.equip_item(entity_without_inventory, equippable_item)).to be false
        end

        it "returns false when item is not in inventory" do
          other_item = Vanilla::Components::Entity.new
          other_item.add_component(Vanilla::Components::EquippableComponent.new(slot: :left_hand))
          expect(inventory_system.equip_item(entity, other_item)).to be false
        end

        it "returns false when item is not equippable" do
          expect(inventory_system.equip_item(entity, item)).to be false
        end

        it "equips the item when possible" do
          # Check that it's not equipped initially
          expect(equippable_item.get_component(:equippable).equipped?).to be false

          # Equip it
          result = inventory_system.equip_item(entity, equippable_item)

          # Verify it was equipped
          expect(result).to be true
          expect(equippable_item.get_component(:equippable).equipped?).to be true
        end

        it "logs a message when item is equipped" do
          expect(message_system).to receive(:log_message).with(
            "items.equip",
            hash_including(
              category: :item,
              importance: :normal,
              metadata: { item: "Sword" }
            )
          )
          inventory_system.equip_item(entity, equippable_item)
        end

        it "logs a warning when item cannot be equipped" do
          # Make equip method return false to simulate failure
          allow(equippable_item.get_component(:equippable)).to receive(:equip).and_return(false)

          expect(message_system).to receive(:log_message).with(
            "items.cannot_equip",
            hash_including(
              category: :item,
              importance: :warning,
              metadata: { item: "Sword" }
            )
          )
          inventory_system.equip_item(entity, equippable_item)
        end
      end

      describe "#unequip_item" do
        let(:equipped_item) do
          item = Vanilla::Components::Entity.new
          item.add_component(Vanilla::Components::ItemComponent.new(name: "Sword"))
          equippable = Vanilla::Components::EquippableComponent.new(slot: :right_hand, equipped: true)
          item.add_component(equippable)
          item
        end

        before do
          # Add the equipped item to the inventory
          entity.get_component(:inventory).add(equipped_item)
        end

        it "returns false when entity is nil" do
          expect(inventory_system.unequip_item(nil, equipped_item)).to be false
        end

        it "returns false when item is nil" do
          expect(inventory_system.unequip_item(entity, nil)).to be false
        end

        it "returns false when entity has no inventory component" do
          entity_without_inventory = Vanilla::Components::Entity.new
          expect(inventory_system.unequip_item(entity_without_inventory, equipped_item)).to be false
        end

        it "returns false when item is not in inventory" do
          other_item = Vanilla::Components::Entity.new
          other_item.add_component(Vanilla::Components::EquippableComponent.new(slot: :left_hand, equipped: true))
          expect(inventory_system.unequip_item(entity, other_item)).to be false
        end

        it "returns false when item is not equippable" do
          expect(inventory_system.unequip_item(entity, item)).to be false
        end

        it "returns false when item is not equipped" do
          unequipped_item = Vanilla::Components::Entity.new
          unequipped_item.add_component(Vanilla::Components::ItemComponent.new(name: "Shield"))
          unequipped_item.add_component(Vanilla::Components::EquippableComponent.new(slot: :left_hand, equipped: false))
          entity.get_component(:inventory).add(unequipped_item)

          expect(inventory_system.unequip_item(entity, unequipped_item)).to be false
        end

        it "unequips the item when possible" do
          # Check that it's equipped initially
          expect(equipped_item.get_component(:equippable).equipped?).to be true

          # Unequip it
          result = inventory_system.unequip_item(entity, equipped_item)

          # Verify it was unequipped
          expect(result).to be true
          expect(equipped_item.get_component(:equippable).equipped?).to be false
        end

        it "logs a message when item is unequipped" do
          # Set item as already equipped
          equipped_item.get_component(:equippable).equipped = true

          expect(message_system).to receive(:log_message).with(
            "items.unequip",
            hash_including(
              category: :item,
              importance: :normal,
              metadata: { item: "Sword" }
            )
          )
          inventory_system.unequip_item(entity, equipped_item)
        end
      end

      describe "#drop_item" do
        let(:entity) { Vanilla::Components::Entity.new }
        let(:item) { Vanilla::Components::Entity.new }
        let(:inventory) { Vanilla::Components::InventoryComponent.new }
        let(:level) { double("Level") }
        let(:position_component) {
          instance_double("Vanilla::Components::PositionComponent",
                          row: 5, column: 10, coordinates: [5, 10])
        }
        let(:item_component) {
          instance_double("Vanilla::Components::ItemComponent",
                          name: "Test Item", stackable?: false)
        }

        before do
          # Configure entity
          entity.add_component(inventory)
          allow(entity).to receive(:has_component?).and_return(false)
          allow(entity).to receive(:has_component?).with(:inventory).and_return(true)
          allow(entity).to receive(:has_component?).with(:position).and_return(true)
          allow(entity).to receive(:get_component).with(:inventory).and_return(inventory)
          allow(entity).to receive(:get_component).with(:position).and_return(position_component)

          # Configure item
          allow(item).to receive(:has_component?).and_return(false)
          allow(item).to receive(:has_component?).with(:item).and_return(true)
          allow(item).to receive(:get_component).with(:item).and_return(item_component)

          # Add the item to the inventory
          inventory.add(item)

          # Setup level
          allow(level).to receive(:add_entity)
        end

        it "returns false when entity is nil" do
          expect(inventory_system.drop_item(nil, item, level)).to be false
        end

        it "returns false when item is nil" do
          expect(inventory_system.drop_item(entity, nil, level)).to be false
        end

        it "returns false when level is nil" do
          expect(inventory_system.drop_item(entity, item, nil)).to be false
        end

        it "returns false when entity has no inventory component" do
          entity_without_inventory = Vanilla::Components::Entity.new
          allow(entity_without_inventory).to receive(:has_component?).with(:inventory).and_return(false)
          expect(inventory_system.drop_item(entity_without_inventory, item, level)).to be false
        end

        it "returns false when entity has no position component" do
          entity_without_position = Vanilla::Components::Entity.new
          allow(entity_without_position).to receive(:has_component?).with(:inventory).and_return(true)
          allow(entity_without_position).to receive(:has_component?).with(:position).and_return(false)
          expect(inventory_system.drop_item(entity_without_position, item, level)).to be false
        end

        it "removes the item from inventory" do
          expect(inventory).to receive(:remove).with(item).and_call_original
          inventory_system.drop_item(entity, item, level)
        end

        it "positions the item at the entity's location" do
          # The item should get a position component if it doesn't have one
          allow(item).to receive(:has_component?).with(:position).and_return(false)
          allow(item).to receive(:add_component)

          inventory_system.drop_item(entity, item, level)

          # Verify the position component was added with the correct coordinates
          expect(item).to have_received(:add_component).with(
            an_instance_of(Vanilla::Components::PositionComponent)
          )
        end

        it "adds the item to the level" do
          expect(level).to receive(:add_entity).with(item)
          inventory_system.drop_item(entity, item, level)
        end

        it "logs a message when item is dropped" do
          expect(message_system).to receive(:log_message).with(
            "items.drop",
            hash_including(
              category: :item,
              importance: :normal,
              metadata: { item: "Test Item" }
            )
          )

          # We need to ignore the items.remove message that's also sent
          allow(message_system).to receive(:log_message).with(
            "items.remove",
            any_args
          )

          inventory_system.drop_item(entity, item, level)
        end

        context "with equipped items" do
          let(:equipped_item) do
            item = Vanilla::Components::Entity.new
            item.add_component(Vanilla::Components::ItemComponent.new(name: "Sword"))
            equippable = Vanilla::Components::EquippableComponent.new(slot: :right_hand, equipped: true)
            item.add_component(equippable)
            item
          end

          before do
            entity.get_component(:inventory).add(equipped_item)
          end

          it "unequips equipped items before dropping" do
            expect(inventory_system).to receive(:unequip_item).with(entity, equipped_item)

            inventory_system.drop_item(entity, equipped_item, level)
          end
        end
      end
    end
  end
end
