require_relative '../utils/performance_monitor'

module Vanilla
  module Simulation
    # GameSimulator provides an automated way to test the game functionality
    # without requiring manual input
    class GameSimulator
      attr_reader :results

      def initialize(seed: nil, capture_output: false)
        @seed = seed
        @capture_output = capture_output
        @performance_monitor = Vanilla::Utils::PerformanceMonitor.new
        @results = {
          movements: [],
          player_positions: [],
          messages: [],
          levels_completed: 0,
          errors: [],
          actions_performed: 0
        }
        @display_rendering = true # Always show rendering by default
      end

      # Set up a new game instance
      # @return [Game] the game instance
      def setup_game
        @performance_monitor.time(:setup) do
          # Set random seed if provided
          srand(@seed) if @seed

          # Capture console output if requested
          if @capture_output
            @original_stdout = $stdout
            $stdout = StringIO.new
          end

          # Create a new game instance
          @game = Vanilla::Game.new

          # Store direct reference to the level when it's created
          # We need to patch this since the core game design doesn't expose level directly
          original_method = @game.method(:initialize_level)
          @game.define_singleton_method(:initialize_level) do |**args|
            level = original_method.call(**args)
            @simulator_level = level  # Store reference for simulator access
            level
          end
          @game.instance_variable_set(:@simulator, self)

          # Start the game to initialize the level
          # This is normally done in the start method, but we'll do just enough to get a level
          @level = @game.send(:initialize_level, difficulty: 1)

          # Record initial player position
          @initial_position = player_position
          @results[:player_positions] << @initial_position

          @game
        end
      end

      # Run a sequence of actions and return the results
      # @param actions [Array<Hash>] the actions to perform
      # @return [Hash] the results of the simulation
      def run(actions)
        # setup_game now handles its own timing internally
        setup_game

        begin
          # Process each action in the sequence
          actions.each do |action|
            @results[:actions_performed] += 1
            process_action(action)
          end

          # Add performance metrics to results
          @results[:performance] = @performance_monitor.summary

        rescue StandardError => e
          @results[:errors] << {
            error: e.class.name,
            message: e.message,
            backtrace: e.backtrace.first(5),
            action_index: @results[:actions_performed] - 1
          }
        ensure
          # Restore stdout if it was captured
          if @capture_output
            $stdout = @original_stdout
          end
        end

        @results
      end

      # Simulate player movement in a specified direction
      # @param direction [Symbol] the direction to move (:up, :down, :left, :right)
      # @param count [Integer] number of times to attempt movement
      # @return [Array<Hash>] results of the movement attempts
      def simulate_movement(direction, count = 1)
        movement_results = []

        count.times do
          start_pos = player_position

          # Perform the movement
          @performance_monitor.time(:movement) do
            # Convert direction to keyboard input
            case direction.to_sym
            when :up
              input = 'A'
              key_code = :KEY_UP
            when :down
              input = 'B'
              key_code = :KEY_DOWN
            when :left
              input = 'D'
              key_code = :KEY_LEFT
            when :right
              input = 'C'
              key_code = :KEY_RIGHT
            else
              raise "Invalid direction: #{direction}"
            end

            # Process_input is private, so we need to use send
            # But first we need to patch STDIN.getch to return our input
            sequence_index = 0
            input_sequence = ["\e", "[", input]

            STDIN.define_singleton_method(:getch) do
              val = input_sequence[sequence_index]
              sequence_index += 1
              val
            end

            # Create a temporary game loop that just processes one turn
            @game.define_singleton_method(:one_turn) do |level|
              # Process input and return the command
              command = send(:process_input, level)

              # Update monster positions according to AI
              monster_system = level.instance_variable_get(:@monster_system)
              monster_system.update if monster_system

              # Render the updated state
              all_entities = level.all_entities + (monster_system ? monster_system.monsters : [])
              @render_system.render(all_entities, level.grid)

              command
            end

            # Call our one_turn method to process the input
            @game.one_turn(@level)

            # Increment turn counter
            @game.instance_variable_set(:@current_turn, @game.instance_variable_get(:@current_turn).to_i + 1)
          end

          # Record performance metrics
          @performance_monitor.record_memory_usage

          # Check if the movement was successful
          end_pos = player_position
          moved = start_pos != end_pos

          # Record the result
          result = {
            direction: direction,
            start_position: start_pos,
            end_position: end_pos,
            moved: moved,
            success: true,
            turn: @game.instance_variable_get(:@current_turn).to_i
          }

          movement_results << result
          @results[:movements] << result
          @results[:player_positions] << end_pos

          # Add any messages that were triggered by this move
          collect_messages
        end

        movement_results
      end

      # Attempt to find and use stairs to go to the next level
      # @param max_attempts [Integer] maximum number of attempts to find stairs
      # @return [Boolean] true if stairs were used successfully
      def find_and_use_stairs(max_attempts: 10)
        initial_level = @level
        success = false
        attempts = 0
        stairs_found = false  # Initialize here
        stairs_x = nil
        stairs_y = nil

        @performance_monitor.time(:use_stairs) do
          # Find stairs on the current level
          level_grid = @level.grid

          # Debugging: log the grid details
          @results[:debug] ||= []
          @results[:debug] << "Grid: #{level_grid.rows}x#{level_grid.columns}"

          # Try to find stairs in the grid using each_cell method
          cell_count = 0
          stairs_cell = nil

          # Output progress if display_rendering is enabled
          puts "Searching for stairs..." if @display_rendering

          level_grid.each_cell do |cell|
            cell_count += 1

            # Different ways to check for stairs
            is_stairs = false

            # Method 1: direct method
            if cell.respond_to?(:stairs?)
              is_stairs = cell.stairs?
            end

            # Method 2: check cell_type
            if !is_stairs && cell.respond_to?(:cell_type) && cell.cell_type
              if cell.cell_type.respond_to?(:stairs?)
                is_stairs = cell.cell_type.stairs?
              elsif cell.cell_type.respond_to?(:properties) &&
                    cell.cell_type.properties.is_a?(Hash) &&
                    cell.cell_type.properties[:stairs]
                is_stairs = true
              end
            end

            # Method 3: check tile property
            if !is_stairs && cell.respond_to?(:tile) && cell.tile == Vanilla::Support::TileType::STAIRS
              is_stairs = true
            end

            if is_stairs
              stairs_x = cell.column
              stairs_y = cell.row
              stairs_found = true
              stairs_cell = cell
              break
            end
          end

          # Debugging: log if stairs were found
          @results[:debug] << "Checked #{cell_count} cells, stairs found: #{stairs_found}"
          @results[:debug] << "Stairs at: [#{stairs_x}, #{stairs_y}]" if stairs_found
          @results[:debug] << "Stairs cell: #{stairs_cell.inspect}" if stairs_cell

          # Display clear message to user when stairs are found or not found
          if @display_rendering
            if stairs_found
              puts "✓ Stairs found at position [#{stairs_y}, #{stairs_x}]"
            else
              puts "✗ No stairs found in this level!"
              # Short-circuit and return false if no stairs were found
              return false
            end
          end

          if stairs_found
            # Calculate path to stairs (simplified version - just move in that direction)
            player_x, player_y = player_position
            @results[:debug] << "Player at: [#{player_x}, #{player_y}]"
            puts "Player at: [#{player_y}, #{player_x}], moving toward stairs..." if @display_rendering

            # Try to move toward stairs with a maximum number of attempts
            # to avoid infinite loops in case of obstacles
            while player_x != stairs_x && attempts < max_attempts
              direction = player_x < stairs_x ? :right : :left
              @results[:debug] << "Moving #{direction} to get to stairs X (attempt #{attempts+1})"
              puts "Moving #{direction} to reach stairs (X coordinate, attempt #{attempts+1})" if @display_rendering
              simulate_movement(direction)

              # Get updated position
              new_x, new_y = player_position

              # If we didn't move, we're probably blocked
              if new_x == player_x && new_y == player_y
                attempts += 1  # Count as a failed attempt
                @results[:debug] << "Blocked while trying to reach stairs X"
                puts "Blocked while trying to reach stairs X coordinate" if @display_rendering
              end

              player_x, player_y = new_x, new_y
              @results[:debug] << "Player now at: [#{player_x}, #{player_y}]"
            end

            while player_y != stairs_y && attempts < max_attempts
              direction = player_y < stairs_y ? :down : :up
              @results[:debug] << "Moving #{direction} to get to stairs Y (attempt #{attempts+1})"
              puts "Moving #{direction} to reach stairs (Y coordinate, attempt #{attempts+1})" if @display_rendering
              simulate_movement(direction)

              # Get updated position
              new_x, new_y = player_position

              # If we didn't move, we're probably blocked
              if new_x == player_x && new_y == player_y
                attempts += 1  # Count as a failed attempt
                @results[:debug] << "Blocked while trying to reach stairs Y"
                puts "Blocked while trying to reach stairs Y coordinate" if @display_rendering
              end

              player_x, player_y = new_x, new_y
              @results[:debug] << "Player now at: [#{player_x}, #{player_y}]"
            end

            # Only try to use stairs if we reached them
            if player_x == stairs_x && player_y == stairs_y
              @results[:debug] << "At stairs position, attempting to use stairs"
              puts "At stairs position, attempting to use them..." if @display_rendering

              # Use the stairs - patch STDIN and use our one_turn method
              STDIN.define_singleton_method(:getch) { '>' }
              @game.one_turn(@level)

              # Check if we moved to a new level
              if @level != initial_level
                @results[:levels_completed] += 1
                success = true
                @results[:debug] << "Successfully moved to a new level"
                puts "✓ Successfully transitioned to a new level!" if @display_rendering
              else
                @results[:debug] << "Failed to move to a new level"
                puts "✗ Failed to transition to a new level" if @display_rendering
              end
            else
              @results[:debug] << "Could not reach stairs position"
              puts "✗ Could not reach stairs position after #{attempts} attempts" if @display_rendering
            end
          else
            @results[:debug] << "No stairs found in this level"
          end
        end

        # Collect messages related to using stairs
        collect_messages

        # Record the result in the results
        @results[:stairs_attempt] = {
          found: stairs_found,
          success: success,
          attempts: attempts,
          max_attempts_reached: attempts >= max_attempts
        }

        success
      end

      # Verify a specific condition
      # @param condition [Symbol] the condition to verify
      # @param params [Hash] parameters for the verification
      # @return [Boolean] true if the condition is met
      def verify(condition, params = {})
        case condition
        when :position
          current_pos = player_position
          expected_pos = params[:position]
          current_pos == expected_pos
        when :movement
          # Verify player can move in a specified direction
          direction = params[:direction]
          start_pos = player_position
          simulate_movement(direction)
          end_pos = player_position

          # Reset position if requested
          if params[:reset]
            # Move back to original position
            opposite = {
              up: :down,
              down: :up,
              left: :right,
              right: :left
            }
            simulate_movement(opposite[direction])
          end

          start_pos != end_pos
        when :message_received
          # Check if a specific message was received
          category = params[:category]
          content = params[:content]

          @results[:messages].any? do |msg|
            (category.nil? || msg[:category] == category) &&
            (content.nil? || msg[:content].include?(content))
          end
        else
          raise "Unknown verification condition: #{condition}"
        end
      end

      # Get various game metrics
      # Provides a comprehensive snapshot of the current game state, including:
      # - Current turn number
      # - Player position
      # - Whether the player has moved from initial position
      # - Number of levels completed
      # - Number of actions performed
      # - Performance metrics (timing, memory usage)
      #
      # This is essential for test verification and performance monitoring,
      # allowing tests to check game state at any point and track resource usage.
      #
      # @return [Hash] metrics including turn count, player position, and performance data
      def metrics
        {
          current_turn: @game.instance_variable_get(:@current_turn).to_i,
          player_position: player_position,
          player_moved: player_position != @initial_position,
          levels_completed: @results[:levels_completed],
          actions_performed: @results[:actions_performed],
          performance: @performance_monitor.summary
        }
      end

      # Add temporary stairs to the grid to test level transitions
      # This method programmatically adds stairs to a specific position on the grid,
      # which is crucial for testing level transitions in a controlled, deterministic manner.
      #
      # The method attempts multiple approaches to add stairs based on the available APIs:
      # 1. Using cell_type factory to create/register a stairs cell type if possible
      # 2. Setting the cell's tile property directly as a fallback
      #
      # Creating test stairs allows us to:
      # - Ensure the test can find stairs consistently
      # - Place stairs in a known, reachable location near the player
      # - Test level transitions without relying on random level generation
      #
      # @param row [Integer] row position for stairs
      # @param column [Integer] column position for stairs
      # @return [Boolean] true if stairs were placed successfully, false otherwise
      def add_test_stairs(row: 1, column: 1)
        return false unless @level

        grid = @level.grid
        cell = grid[row, column]
        return false unless cell

        @results[:debug] ||= []
        @results[:debug] << "Attempting to add test stairs at [#{row}, #{column}]"

        # Check if we can modify this cell
        if cell.respond_to?(:cell_type=)
          # Create a stairs cell type
          factory = Vanilla::MapUtils::Grid.cell_type_factory
          # Try to get or create a stairs cell type
          if factory.respond_to?(:get_cell_type) && factory.respond_to?(:register)
            begin
              stairs_type = factory.get_cell_type(:stairs)
            rescue ArgumentError
              # If it doesn't exist, register it
              stairs_type = factory.register(:stairs, '%', { stairs: true, walkable: true })
            end

            # Set the cell type
            cell.cell_type = stairs_type
            @results[:debug] << "Successfully added stairs at [#{row}, #{column}]"
            return true
          end
        end

        # Fallback method - try to set tile directly
        if cell.respond_to?(:tile=)
          cell.tile = Vanilla::Support::TileType::STAIRS
          @results[:debug] << "Added stairs via tile property at [#{row}, #{column}]"
          return true
        end

        @results[:debug] << "Failed to add stairs - cell doesn't support modification"
        false
      end

      # Find path to stairs using Dijkstra's algorithm
      # This method uses Dijkstra's pathfinding algorithm to find the optimal path
      # from the player's current position to stairs on the current level.
      #
      # The method handles multiple ways to identify stairs in the game:
      # 1. Via direct `stairs?` method on cells
      # 2. Via cell_type properties that indicate stairs
      # 3. Via tile property matching the STAIRS constant
      #
      # The method provides detailed debugging information about:
      # - How the stairs were detected
      # - The computed path to the stairs
      # - Any issues encountered during pathfinding
      #
      # This is critical for level transition testing to ensure deterministic movement
      # toward stairs rather than relying on random searches.
      #
      # @return [Array<Symbol>] Array of movement directions (:up, :down, :left, :right) to reach stairs
      def find_path_to_stairs
        return [] unless @level

        grid = @level.grid
        player = @level.player
        player_cell = nil
        stairs_cell = nil

        @results[:debug] ||= []
        @results[:debug] << "Finding path to stairs..."

        # Find player and stairs cells
        cell_count = 0
        grid.each_cell do |cell|
          cell_count += 1

          # Check if this is the player's cell
          player_pos = player_position
          if cell.row == player_pos[0] && cell.column == player_pos[1]
            player_cell = cell
            @results[:debug] << "Found player cell at [#{cell.row}, #{cell.column}]"
          end

          # Check if this is a stairs cell (using the various methods)
          is_stairs = false

          # Method 1: direct method
          if cell.respond_to?(:stairs?)
            is_stairs = cell.stairs?
            @results[:debug] << "Cell [#{cell.row}, #{cell.column}] stairs? method: #{is_stairs}" if is_stairs
          end

          # Method 2: check cell_type
          if !is_stairs && cell.respond_to?(:cell_type) && cell.cell_type
            if cell.cell_type.respond_to?(:stairs?)
              is_stairs = cell.cell_type.stairs?
              @results[:debug] << "Cell [#{cell.row}, #{cell.column}] cell_type.stairs?: #{is_stairs}" if is_stairs
            elsif cell.cell_type.respond_to?(:properties) &&
                  cell.cell_type.properties.is_a?(Hash) &&
                  cell.cell_type.properties[:stairs]
              is_stairs = true
              @results[:debug] << "Cell [#{cell.row}, #{cell.column}] cell_type.properties[:stairs]: #{is_stairs}"
            end
          end

          # Method 3: check tile property
          if !is_stairs && cell.respond_to?(:tile) && cell.tile == Vanilla::Support::TileType::STAIRS
            is_stairs = true
            @results[:debug] << "Cell [#{cell.row}, #{cell.column}] tile == STAIRS: #{is_stairs}"
          end

          if is_stairs
            stairs_cell = cell
            @results[:debug] << "Found stairs cell at [#{cell.row}, #{cell.column}]"
          end
        end

        @results[:debug] << "Checked #{cell_count} cells, player_cell: #{player_cell ? 'found' : 'not found'}, stairs_cell: #{stairs_cell ? 'found' : 'not found'}"

        # Return empty path if we couldn't find both cells
        unless player_cell && stairs_cell
          @results[:debug] << "Cannot find path: missing player_cell or stairs_cell"
          return []
        end

        begin
          # Use Dijkstra's algorithm to find the shortest path
          @results[:debug] << "Using Dijkstra to find path from [#{player_cell.row}, #{player_cell.column}] to [#{stairs_cell.row}, #{stairs_cell.column}]"
          path_cells = Vanilla::Algorithms::Dijkstra.shortest_path(grid, start: player_cell, goal: stairs_cell)

          # Convert the path to movement directions
          directions = []
          current_cell = player_cell

          path_cells.each do |next_cell|
            next if next_cell == current_cell

            # Determine direction
            dir = nil
            if next_cell.row < current_cell.row
              dir = :up
            elsif next_cell.row > current_cell.row
              dir = :down
            elsif next_cell.column < current_cell.column
              dir = :left
            elsif next_cell.column > current_cell.column
              dir = :right
            end

            directions << dir if dir
            @results[:debug] << "Path step: [#{current_cell.row}, #{current_cell.column}] -> [#{next_cell.row}, #{next_cell.column}] = #{dir}"

            current_cell = next_cell
          end

          @results[:debug] << "Found path with #{directions.size} steps: #{directions.inspect}"
          directions
        rescue => e
          @results[:debug] << "Error in Dijkstra pathfinding: #{e.message}"
          @results[:errors] << {
            error: e.class.name,
            message: e.message,
            backtrace: e.backtrace&.first(5),
            context: "Finding path to stairs with Dijkstra"
          }
          []
        end
      end

      # Capture the current screen state to verify rendering
      # This method grabs the current state of the terminal buffer to use for
      # verification of visual updates. It handles different buffer formats and provides
      # fallbacks for different renderer implementations.
      #
      # The screen capture is critical for verifying that player movements actually
      # update the visual display that a human player would see.
      #
      # @return [Array<String>] The captured screen buffer as an array of strings, with each string representing a row
      def capture_screen
        return [] unless @level && @game.respond_to?(:render_system)

        render_system = @game.instance_variable_get(:@render_system)
        return [] unless render_system && render_system.respond_to?(:renderer)

        renderer = render_system.renderer
        return [] unless renderer

        # Get the current buffer (screen state)
        # Terminal renderer uses a 2D array buffer
        buffer = renderer.instance_variable_get(:@buffer)

        if buffer.is_a?(Array)
          # Convert the buffer to a consistent string format for comparison
          screen_state = []

          # Handle either a 1D or 2D buffer
          if buffer.first.is_a?(Array)
            # 2D array - convert each row to a string
            screen_state = buffer.map { |row| row.join('') }
          else
            # 1D array - treat as a single row
            screen_state = [buffer.join('')]
          end

          # Display the screen to the user for visual feedback
          if @display_rendering
            puts "\nCurrent Game Screen:"
            puts "===================="
            screen_state.each do |line|
              puts line
            end
            puts "===================="
          end

          # Store in results for later verification
          @results[:screen_states] ||= []
          @results[:screen_states] << {
            turn: @game.instance_variable_get(:@current_turn).to_i,
            player_position: player_position,
            buffer: screen_state
          }

          screen_state
        else
          # If the buffer isn't directly accessible, try to render to a string
          if renderer.respond_to?(:to_s)
            render_str = renderer.to_s
            puts "\nCurrent Game Screen:\n#{render_str}" if @display_rendering
            [render_str]
          else
            # Last resort - force a render and return something to compare
            render_system.render(@level.all_entities, @level.grid) rescue nil
            screen_info = "Rendered at turn #{@game.instance_variable_get(:@current_turn).to_i}"
            puts "\nCurrent Game Screen:\n#{screen_info}" if @display_rendering
            [screen_info]
          end
        end
      end

      # Verify that the player is rendered at the expected position
      # This method checks that the player character (@) appears at the position
      # reported by the player_position method. This is critical for ensuring that
      # the visual representation matches the internal game state.
      #
      # The method includes several fallbacks and diagnostic information to help
      # debug rendering issues:
      # - Forces a new render to ensure the screen is up-to-date
      # - Attempts to find the player character anywhere on screen if not at expected position
      # - Records detailed information about the verification attempt for diagnostics
      #
      # @return [Boolean] true if the player is rendered at the correct position, false otherwise
      def verify_player_rendering
        return false unless @level

        # Get current player position
        row, col = player_position
        return false if row.nil? || col.nil?

        @results[:debug] ||= []
        @results[:debug] << "Verifying player at position [#{row}, #{col}]"

        # Force a render to make sure we have the latest state
        begin
          level_grid = @level.grid
          render_system = @game.instance_variable_get(:@render_system)
          all_entities = @level.all_entities

          # Add monsters if available
          monster_system = @level.instance_variable_get(:@monster_system)
          all_entities += monster_system.monsters if monster_system && monster_system.respond_to?(:monsters)

          # Force render
          render_system.render(all_entities, level_grid) if render_system
        rescue => e
          @results[:debug] << "Error forcing render: #{e.message}"
        end

        # Capture current screen after forcing render
        screen = capture_screen
        @results[:debug] << "Captured screen with #{screen.size} lines"
        return false if screen.empty?

        # Get the player character - default is '@'
        player_char = Vanilla::Support::TileType::PLAYER
        actual_char = nil
        is_correct = false

        # Check if player character is at the expected position
        # Need to handle screens that might have borders or offset content
        if screen.size > row && row >= 0
          line = screen[row]
          @results[:debug] << "Line #{row}: '#{line}'"

          # Check if column is within range
          if line.length > col && col >= 0
            actual_char = line[col]
            @results[:debug] << "Char at [#{row},#{col}]: '#{actual_char}'"
            is_correct = (actual_char == player_char)
          else
            @results[:debug] << "Column #{col} out of range (line length: #{line.length})"
          end
        else
          @results[:debug] << "Row #{row} out of range (screen lines: #{screen.size})"
        end

        # If not found at direct position, try scanning the entire screen for player char
        if !is_correct
          # Scan the entire screen for the player character
          found_at = nil
          screen.each_with_index do |line, r|
            if c = line.index(player_char)
              found_at = [r, c]
              break
            end
          end

          if found_at
            @results[:debug] << "Found player char '@' at position [#{found_at[0]},#{found_at[1]}] instead of [#{row},#{col}]"
          else
            @results[:debug] << "Player char '@' not found anywhere on screen"
          end
        end

        # Record the check result
        @results[:rendering_checks] ||= []
        @results[:rendering_checks] << {
          turn: @game.instance_variable_get(:@current_turn).to_i,
          expected_position: [row, col],
          expected_char: player_char,
          actual_char: actual_char,
          correct: is_correct,
          screen_bounds: [screen.size, screen.first&.length]
        }

        is_correct
      end

      # Simulate player movement with rendering verification
      # This method combines movement simulation with screen rendering verification.
      # It captures the screen state before and after movement, verifies that:
      # 1. The player character moved to the expected position in the game state
      # 2. The player character appears at the new position on screen
      # 3. The screen content actually changed to reflect the movement
      #
      # This is essential for ensuring that players receive proper visual feedback
      # when moving their character - one of the most fundamental interactions
      # in a roguelike game.
      #
      # @param direction [Symbol] the direction to move (:up, :down, :left, :right)
      # @param count [Integer] number of steps to move in the specified direction
      # @param verify_render [Boolean] whether to verify rendering (can be disabled for performance)
      # @return [Array<Hash>] detailed results of each movement with rendering verification data
      def simulate_movement_with_render_check(direction, count = 1, verify_render: true)
        results = []

        count.times do
          # Display direction information
          puts "\nAttempting to move #{direction.to_s.upcase}" if @display_rendering

          # First, capture the screen before movement
          puts "\nBEFORE MOVEMENT:" if @display_rendering
          pre_move_screen = capture_screen
          pre_move_pos = player_position

          puts "\nPlayer position: [#{pre_move_pos[0]}, #{pre_move_pos[1]}]" if @display_rendering

          # Perform the movement
          move_result = simulate_movement(direction, 1).first

          # Capture the screen after movement
          puts "\nAFTER MOVEMENT:" if @display_rendering
          post_move_screen = capture_screen
          post_move_pos = player_position

          puts "\nPlayer position: [#{post_move_pos[0]}, #{post_move_pos[1]}]" if @display_rendering
          puts "\nMovement successful: #{move_result[:moved]}" if @display_rendering

          # Check if the player moved
          moved = move_result[:moved]

          # Verify rendering if requested and if the player moved
          rendering_correct = !verify_render || verify_player_rendering

          # Check if the screen actually changed
          screen_changed = pre_move_screen != post_move_screen

          # Add all data to the result
          result = move_result.merge({
            screen_changed: screen_changed,
            rendering_correct: rendering_correct,
            rendering_verified: verify_render
          })

          results << result

          # Add detailed rendering data
          if verify_render
            @results[:rendering_data] ||= []
            @results[:rendering_data] << {
              turn: @game.instance_variable_get(:@current_turn).to_i,
              direction: direction,
              pre_position: pre_move_pos,
              post_position: post_move_pos,
              moved: moved,
              screen_changed: screen_changed,
              rendering_correct: rendering_correct
            }
          end
        end

        results
      end

      # Helper method to get player position
      # @return [Array<Integer>] [row, column]
      def player_position
        player_position_obj = nil

        begin
          player = current_level&.player
          if player.nil?
            @results[:debug] ||= []
            @results[:debug] << "Player is nil in current_level"
            return [nil, nil]
          end

          # Try different ways to get position component data
          if player.respond_to?(:position)
            player_position_obj = player.position
          else
            # Try to get it from components
            player_position_obj = player.get_component(:position)
          end

          # Debugging
          if player_position_obj.nil?
            @results[:debug] ||= []
            @results[:debug] << "Could not get position component from player"
            return [nil, nil]
          end

          # Extract coordinates
          if player_position_obj.respond_to?(:row) && player_position_obj.respond_to?(:column)
            [player_position_obj.row, player_position_obj.column]
          elsif player_position_obj.respond_to?(:x) && player_position_obj.respond_to?(:y)
            [player_position_obj.y, player_position_obj.x] # Note: x/y to row/col conversion
          else
            # If we can't determine the format, return nil coordinates
            @results[:debug] ||= []
            @results[:debug] << "Unknown position format: #{player_position_obj.inspect}"
            [nil, nil]
          end
        rescue => e
          @results[:errors] << {
            error: e.class.name,
            message: e.message,
            backtrace: e.backtrace&.first(3),
            context: "Getting player position"
          }
          [nil, nil]
        end
      end

      private

      # Process a single action from the action sequence
      def process_action(action)
        case action[:type]
        when :move
          direction = action[:direction]
          count = action[:count] || 1
          simulate_movement(direction, count)
        when :wait
          turns = action[:turns] || 1
          turns.times do
            @game.current_turn += 1
            collect_messages
          end
        when :use_stairs
          find_and_use_stairs
        when :custom
          # Execute a custom block with this simulator as argument
          action[:block].call(self) if action[:block]
        else
          raise "Unknown action type: #{action[:type]}"
        end
      end

      # Collect messages from the message system if available
      def collect_messages
        # Check if the message manager is available
        if defined?(Vanilla::Messages::MessageManager) &&
           Vanilla::Messages::MessageManager.respond_to?(:instance) &&
           manager = Vanilla::Messages::MessageManager.instance

          # Get the current turn
          current_turn = @game.instance_variable_get(:@current_turn).to_i

          # Get the last turn's messages
          new_messages = manager.get_messages(turn: current_turn)

          # Add to our results
          new_messages.each do |msg|
            @results[:messages] << {
              content: msg.content,
              category: msg.category,
              turn: msg.turn
            }
          end
        end
      end

      # Helper method to get the current level
      # @return [Vanilla::Level] Current level
      def current_level
        @level || (@game&.instance_variable_get(:@current_level) || @game&.instance_variable_get(:@simulator_level))
      end
    end
  end
end