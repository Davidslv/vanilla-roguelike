# frozen_string_literal: true

require 'spec_helper'

module Vanilla
  module Systems
    RSpec.describe ItemInteractionSystem do
      let(:logger) { double('logger', debug: nil, info: nil, warn: nil, error: nil) }
      let(:message_system) { double('message_system', log_message: nil) }
      let(:inventory_system) { double('inventory_system') }
      let(:item_interaction_system) { ItemInteractionSystem.new(inventory_system) }

      let(:entity) do
        entity = Vanilla::Entities::Entity.new
        entity.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 10))
        entity.add_component(Vanilla::Components::InventoryComponent.new)
        entity
      end

      let(:item) do
        item = Vanilla::Entities::Entity.new
        item.add_component(Vanilla::Components::ItemComponent.new(name: "Test Item"))
        item.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 10))
        item
      end

      let(:level) do
        double('Level', all_entities: [entity, item], remove_entity: nil)
      end

      before do
        # Stub the ServiceRegistry to return our mock message_system
        allow(Vanilla::ServiceRegistry).to receive(:get)
          .with(:message_system).and_return(message_system)
      end

      describe "#initialize" do
        it "creates an item interaction system with the given inventory system" do
          expect(item_interaction_system.instance_variable_get(:@inventory_system)).to eq(inventory_system)
        end

        it "gets the message system from the service registry" do
          expect(item_interaction_system.instance_variable_get(:@message_system)).to eq(message_system)
        end
      end

      describe "#process_items_at_location" do
        it "returns false when entity is nil" do
          expect(item_interaction_system.process_items_at_location(nil, level, 5, 10)).to be false
        end

        it "returns false when level is nil" do
          expect(item_interaction_system.process_items_at_location(entity, nil, 5, 10)).to be false
        end

        it "returns false when no items are found at the location" do
          # Move the item to a different location
          item.get_component(:position).move_to(7, 7)

          expect(item_interaction_system.process_items_at_location(entity, level, 5, 10)).to be false
        end

        it "finds items at the specified position" do
          # This is testing a private method indirectly
          expect(item_interaction_system.process_items_at_location(entity, level, 5, 10)).to be true
        end

        it "logs a message when a single item is found" do
          expect(message_system).to receive(:log_message).with(
            "items.found.single",
            { item: "Test Item" },
            hash_including(category: :item)
          )

          item_interaction_system.process_items_at_location(entity, level, 5, 10)
        end

        it "logs a message when multiple items are found" do
          # Add another item at the same position
          other_item = Vanilla::Entities::Entity.new
          other_item.add_component(Vanilla::Components::ItemComponent.new(name: "Other Item"))
          other_item.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 10))

          # Update the level.all_entities to include the new item
          allow(level).to receive(:all_entities).and_return([entity, item, other_item])

          expect(message_system).to receive(:log_message).with(
            "items.found.multiple",
            { count: 2 },
            hash_including(category: :item)
          )

          item_interaction_system.process_items_at_location(entity, level, 5, 10)
        end
      end

      describe "#pickup_item" do
        it "returns false when entity is nil" do
          expect(item_interaction_system.pickup_item(nil, level, item)).to be false
        end

        it "returns false when level is nil" do
          expect(item_interaction_system.pickup_item(entity, nil, item)).to be false
        end

        it "returns false when item is nil" do
          expect(item_interaction_system.pickup_item(entity, level, nil)).to be false
        end

        it "returns false when entity has no position component" do
          entity_without_position = Vanilla::Entities::Entity.new
          entity_without_position.add_component(Vanilla::Components::InventoryComponent.new)

          expect(item_interaction_system.pickup_item(entity_without_position, level, item)).to be false
        end

        it "returns false when entity has no inventory component" do
          entity_without_inventory = Vanilla::Entities::Entity.new
          entity_without_inventory.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 10))

          expect(item_interaction_system.pickup_item(entity_without_inventory, level, item)).to be false
        end

        it "returns false when item has no position component" do
          item_without_position = Vanilla::Entities::Entity.new
          item_without_position.add_component(Vanilla::Components::ItemComponent.new(name: "No Position Item"))

          expect(item_interaction_system.pickup_item(entity, level, item_without_position)).to be false
        end

        it "returns false when entity and item are not at the same position" do
          # Move the item to a different location
          item.get_component(:position).move_to(7, 7)

          expect(message_system).to receive(:log_message).with(
            "items.not_here",
            hash_including(importance: :warning)
          )

          expect(item_interaction_system.pickup_item(entity, level, item)).to be false
        end

        it "adds the item to the entity's inventory" do
          # Stub the inventory system to simulate a successful addition
          expect(inventory_system).to receive(:add_item).with(entity, item).and_return(true)

          item_interaction_system.pickup_item(entity, level, item)
        end

        it "removes the item from the level when pickup succeeds" do
          # Stub the inventory system to simulate a successful addition
          allow(inventory_system).to receive(:add_item).with(entity, item).and_return(true)

          expect(level).to receive(:remove_entity).with(item)

          item_interaction_system.pickup_item(entity, level, item)
        end

        it "returns true when pickup succeeds" do
          # Stub the inventory system to simulate a successful addition
          allow(inventory_system).to receive(:add_item).with(entity, item).and_return(true)

          expect(item_interaction_system.pickup_item(entity, level, item)).to be true
        end

        it "does not remove the item from the level when pickup fails" do
          # Stub the inventory system to simulate a failed addition
          allow(inventory_system).to receive(:add_item).with(entity, item).and_return(false)

          expect(level).not_to receive(:remove_entity)

          item_interaction_system.pickup_item(entity, level, item)
        end

        it "returns false when inventory system cannot add the item" do
          # Stub the inventory system to simulate a failed addition
          allow(inventory_system).to receive(:add_item).with(entity, item).and_return(false)

          expect(item_interaction_system.pickup_item(entity, level, item)).to be false
        end
      end

      describe "#pickup_all_items" do
        let(:item2) do
          item = Vanilla::Entities::Entity.new
          item.add_component(Vanilla::Components::ItemComponent.new(name: "Another Item"))
          item.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 10))
          item
        end

        before do
          # Update the level.all_entities to include both items
          allow(level).to receive(:all_entities).and_return([entity, item, item2])
        end

        it "returns 0 when entity is nil" do
          expect(item_interaction_system.pickup_all_items(nil, level)).to eq(0)
        end

        it "returns 0 when level is nil" do
          expect(item_interaction_system.pickup_all_items(entity, nil)).to eq(0)
        end

        it "returns 0 when entity has no position component" do
          entity_without_position = Vanilla::Entities::Entity.new

          expect(item_interaction_system.pickup_all_items(entity_without_position, level)).to eq(0)
        end

        it "returns 0 when no items are at the entity's position" do
          # Move the entity to a different location
          entity.get_component(:position).move_to(7, 7)

          expect(item_interaction_system.pickup_all_items(entity, level)).to eq(0)
        end

        it "attempts to pickup each item at the entity's position" do
          # Spy on the pickup_item method
          expect(item_interaction_system).to receive(:pickup_item).with(entity, level, item).and_return(true)
          expect(item_interaction_system).to receive(:pickup_item).with(entity, level, item2).and_return(true)

          item_interaction_system.pickup_all_items(entity, level)
        end

        it "returns the number of items successfully picked up" do
          # Stub pickup_item to succeed for one item and fail for the other
          allow(item_interaction_system).to receive(:pickup_item).with(entity, level, item).and_return(true)
          allow(item_interaction_system).to receive(:pickup_item).with(entity, level, item2).and_return(false)

          expect(item_interaction_system.pickup_all_items(entity, level)).to eq(1)
        end

        it "logs a message when a single item is picked up" do
          # Setup
          allow(inventory_system).to receive(:add_item).and_return(true)
          allow(level).to receive(:all_entities).and_return([entity, item])
          allow(level).to receive(:remove_entity).with(item)

          expect(message_system).to receive(:log_message).with(
            "items.picked_up.single",
            hash_including(category: :item, importance: :normal)
          )

          item_interaction_system.pickup_all_items(entity, level)
        end

        it "logs a message when multiple items are picked up" do
          # Setup
          item2 = double('item2', has_component?: true)
          allow(item2).to receive(:get_component).with(:position).and_return(
            instance_double('PositionComponent', row: 5, column: 10)
          )
          allow(item2).to receive(:get_component).with(:item).and_return(
            instance_double('ItemComponent', name: "Another Item")
          )

          allow(inventory_system).to receive(:add_item).and_return(true)
          allow(level).to receive(:all_entities).and_return([entity, item, item2])
          allow(level).to receive(:remove_entity).with(item)
          allow(level).to receive(:remove_entity).with(item2)

          expect(message_system).to receive(:log_message).with(
            "items.picked_up.multiple",
            hash_including(category: :item, importance: :normal)
          )

          item_interaction_system.pickup_all_items(entity, level)
        end

        it "logs a warning when no items could be picked up due to full inventory" do
          # Setup
          allow(inventory_system).to receive(:add_item).and_return(false)
          allow(level).to receive(:all_entities).and_return([entity, item])

          expect(message_system).to receive(:log_message).with(
            "items.inventory_full",
            hash_including(category: :item, importance: :warning)
          )

          item_interaction_system.pickup_all_items(entity, level)
        end
      end
    end
  end
end
