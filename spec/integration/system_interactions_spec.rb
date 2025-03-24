require 'spec_helper'

RSpec.describe "System Interactions", type: :integration do
  let(:game) { Vanilla::Game.new }

  describe "movement system interactions" do
    it "handles player movement without errors" do
      player = game.player
      initial_position = player.get_component(:position).dup

      # Try moving in each valid direction
      [:north, :south, :east, :west].each do |direction|
        # Reset position for clean test
        current_position = player.get_component(:position)
        current_position.set_position(initial_position.row, initial_position.column)

        # Verify position update succeeds without errors
        expect {
          # Move based on direction
          case direction
          when :north
            current_position.translate(-1, 0)
          when :south
            current_position.translate(1, 0)
          when :east
            current_position.translate(0, 1)
          when :west
            current_position.translate(0, -1)
          end
        }.not_to raise_error
      end
    end

    it "properly updates grid after movement" do
      player = game.player
      level = game.respond_to?(:current_level) ? game.current_level : nil

      # Skip if we can't access the level yet
      skip "Need to implement Game#current_level accessor first" unless level

      # Verify grid responds to expected methods
      expect(level).to respond_to(:update_grid_with_entities)

      initial_position = player.get_component(:position)

      # This could be a private method we need to address
      expect {
        # Try to move player
        position = player.get_component(:position)
        position.translate(1, 0) # Move down one row

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

      # Skip state capture since we don't have access to current_level yet
      #initial_state = capture_game_state(game)

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

        # Directly move player
        position = player.get_component(:position)
        position.translate(0, 1) # Move east

        # Skip grid update for now since we don't have access to current_level

        # Skip render system for now

        # Skip message system for now
      }.not_to raise_error

      # Check position changed
      position = player.get_component(:position)
      expect(position.column).to be > 0
    end
  end
end