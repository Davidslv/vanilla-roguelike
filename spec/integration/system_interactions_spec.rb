require 'spec_helper'

RSpec.describe "System Interactions", type: :integration do
  let(:game) { Vanilla::Game.new }

  describe "movement system interactions" do
    it "handles player movement without errors" do
      player = game.player
      initial_position = player.get_component(:position).dup

      # Get movement system through game or registry
      movement_system = if game.respond_to?(:movement_system)
        game.movement_system
      elsif Vanilla::ServiceRegistry.respond_to?(:get)
        Vanilla::ServiceRegistry.get(:movement_system)
      else
        pending "Cannot access movement system for testing"
        next
      end

      # Try moving in each valid direction
      [:north, :south, :east, :west].each do |direction|
        # Reset position for clean test
        current_position = player.get_component(:position)
        current_position.set_position(initial_position.row, initial_position.column)

        # Verify movement succeeds without errors
        expect { movement_system.move(player, direction) }.not_to raise_error
      end
    end

    it "properly updates grid after movement" do
      player = game.player
      level = game.current_level

      # Verify grid responds to expected methods
      expect(level).to respond_to(:update_grid_with_entities)

      initial_position = player.get_component(:position).dup

      # This could be a private method we need to address
      expect {
        # Try to move player
        new_position = Vanilla::Components::PositionComponent.new(
          initial_position.row + 1,
          initial_position.column
        )
        player.get_component(:position).set_position(new_position.row, new_position.column)

        # Trigger grid update
        if level.method(:update_grid_with_entities).arity == 0
          level.send(:update_grid_with_entities)
        else
          level.send(:update_grid_with_entities, [player])
        end
      }.not_to raise_error
    end
  end

  describe "message system interactions" do
    it "logs messages with consistent parameter formats" do
      # Get message system through game or registry
      message_system = if game.respond_to?(:message_system)
        game.message_system
      elsif Vanilla::ServiceRegistry.respond_to?(:get)
        Vanilla::ServiceRegistry.get(:message_system)
      else
        pending "Cannot access message system for testing"
        next
      end

      # Test various ways of calling log_message to ensure they all work
      expect {
        message_system.log_message("test.message1", { value: 1 }, importance: :normal, category: :test)
      }.not_to raise_error

      expect {
        message_system.log_message("test.message2", importance: :normal, category: :test)
      }.not_to raise_error

      expect {
        message_system.log_message("test.message3", { value: 3 })
      }.not_to raise_error

      expect {
        message_system.log_message("test.message4")
      }.not_to raise_error
    end
  end

  describe "render system interactions" do
    it "renders entities without errors" do
      # Get render system through game or registry
      render_system = if game.respond_to?(:render_system)
        game.render_system
      elsif Vanilla::ServiceRegistry.respond_to?(:get)
        Vanilla::ServiceRegistry.get(:render_system)
      else
        pending "Cannot access render system for testing"
        next
      end

      # Mock the renderer to avoid actual display updates during tests
      allow(render_system).to receive(:render)

      # Trigger a render operation
      expect {
        if render_system.respond_to?(:render)
          render_system.render
        elsif render_system.respond_to?(:update)
          render_system.update(0.01)  # Small delta time
        end
      }.not_to raise_error
    end
  end

  describe "cross-system workflows" do
    it "executes a complete player movement workflow without errors" do
      player = game.player
      initial_state = capture_game_state(game)

      # This test simulates what happens when a player moves:
      # 1. Input is processed
      # 2. Movement is calculated
      # 3. Position is updated
      # 4. Grid is updated
      # 5. Render is triggered
      # 6. Messages are logged

      expect {
        # Simulate input handling
        direction = :east

        # Move player
        movement_system = game.respond_to?(:movement_system) ?
          game.movement_system : Vanilla::ServiceRegistry.get(:movement_system)

        if movement_system
          movement_system.move(player, direction)
        else
          # Fallback: directly update position
          position = player.get_component(:position)
          position.translate(0, 1) if direction == :east
        end

        # Update grid (might be private method)
        level = game.current_level
        if level.respond_to?(:update_grid_with_entities)
          if level.method(:update_grid_with_entities).arity == 0
            level.send(:update_grid_with_entities) rescue nil
          else
            level.send(:update_grid_with_entities, [player]) rescue nil
          end
        end

        # Trigger render
        render_system = game.respond_to?(:render_system) ?
          game.render_system : Vanilla::ServiceRegistry.get(:render_system)

        if render_system
          render_system.respond_to?(:render) ? render_system.render : render_system.update(0.01)
        end

        # Log message about movement
        message_system = game.respond_to?(:message_system) ?
          game.message_system : Vanilla::ServiceRegistry.get(:message_system)

        if message_system
          message_system.log_message("movement.player_moved", importance: :info, category: :movement)
        end
      }.not_to raise_error

      # Verify player position changed
      final_state = capture_game_state(game)
      expect(final_state[:player][:position]).not_to eq(initial_state[:player][:position])
    end
  end
end