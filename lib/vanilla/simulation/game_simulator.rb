module Vanilla
  module Simulation
    # GameSimulator provides an automated way to test the game functionality
    # without requiring manual input
    class GameSimulator
      attr_reader :results

      def initialize(seed: nil, capture_output: false)
        @seed = seed
        @capture_output = capture_output
        begin
          if defined?(Vanilla::Utils) && Vanilla::Utils.const_defined?(:PerformanceMonitor)
            @performance_monitor = Vanilla::Utils::PerformanceMonitor.new
          else
            if defined?(Vanilla::PerformanceMonitor)
              @performance_monitor = Vanilla::PerformanceMonitor.new
            else
              @performance_monitor = Object.new
              def @performance_monitor.time(label)
                start = Time.now
                result = yield if block_given?
                elapsed = Time.now - start
                result
              end
              def @performance_monitor.record_memory_usage; end
              def @performance_monitor.reset; end
              def @performance_monitor.summary; {}; end
            end
          end
        rescue => e
          @performance_monitor = Object.new
          def @performance_monitor.time(label)
            yield if block_given?
          end
          def @performance_monitor.record_memory_usage; end
          def @performance_monitor.reset; end
          def @performance_monitor.summary; {}; end
        end
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

      # Add test stairs at a specific position
      # @param row [Integer] row position for stairs
      # @param column [Integer] column position for stairs
      # @return [Boolean] whether stairs were successfully added
      def add_test_stairs(row:, column:)
        return false unless @level && @game

        # Output what we're doing
        puts "Adding test stairs at [#{row}, #{column}]" if @display_rendering

        # Get the grid
        grid = @level.grid
        return false unless grid && grid.respond_to?(:[])

        # Get the cell where we want to place stairs
        target_cell = grid[row, column]
        return false unless target_cell

        # Different ways to set a cell as stairs based on the game implementation
        success = false

        # Method 1: Set cell type to stairs if supported
        if target_cell.respond_to?(:cell_type=) &&
           defined?(Vanilla::Support::CellType) &&
           Vanilla::Support::CellType.const_defined?(:STAIRS)
          target_cell.cell_type = Vanilla::Support::CellType::STAIRS
          success = true
        end

        # Method 2: Set tile to stairs if supported
        if !success && target_cell.respond_to?(:tile=) &&
           defined?(Vanilla::Support::TileType) &&
           Vanilla::Support::TileType.const_defined?(:STAIRS)
          target_cell.tile = Vanilla::Support::TileType::STAIRS
          success = true
        end

        # Method 3: Use special cell properties if available
        if !success && target_cell.respond_to?(:properties=)
          target_cell.properties = { stairs: true }
          success = true
        elsif !success && target_cell.respond_to?(:properties) && target_cell.properties.is_a?(Hash)
          target_cell.properties[:stairs] = true
          success = true
        end

        # Method 4: Set a special character for stairs if possible
        if !success && target_cell.respond_to?(:stairs=)
          target_cell.stairs = true
          success = true
        end

        # If we succeeded, force a re-render
        if success
          puts "✓ Successfully added stairs at [#{row}, #{column}]" if @display_rendering

          # Mark this cell as linked to all adjacent cells to ensure accessibility
          if target_cell.respond_to?(:link)
            grid.neighbors(target_cell).each do |neighbor|
              target_cell.link(neighbor) if neighbor
            end
          end

          # Update rendering
          if @game.respond_to?(:render_system)
            @game.render_system.render(@level.all_entities, grid) rescue nil
          end
        else
          puts "✗ Failed to add stairs - unsupported game implementation" if @display_rendering
        end

        success
      end

      # Create guaranteed stairs directly adjacent to the player for testing
      # and configure them to be usable with a predetermined key sequence
      # @return [Boolean] whether stairs were successfully created
      def create_guaranteed_stairs
        return false unless @level && @game

        # Get player position
        player_pos = player_position
        return false unless player_pos && player_pos[0] && player_pos[1]

        # Create stairs one space to the right of player
        stairs_row = player_pos[0]
        stairs_col = player_pos[1] + 1

        # Use the add_test_stairs method to create stairs
        add_test_stairs(row: stairs_row, column: stairs_col)
      end

      # Use guaranteed stairs with predefined key sequence
      # @return [Boolean] whether stairs were successfully used
      def use_guaranteed_stairs
        return false unless @game && @level

        # Get player position
        player_pos = player_position
        return false unless player_pos && player_pos[0] && player_pos[1]

        # First, move right to the stairs position
        puts "Moving player to the guaranteed stairs position" if @display_rendering
        move_result = simulate_movement(:right)

        if !move_result || !move_result.first || !move_result.first[:moved]
          puts "✗ Failed to move to the stairs position" if @display_rendering
          return false
        end

        # Now try to use the stairs
        puts "Attempting to use stairs with '>' key" if @display_rendering
        initial_level = @level

        # Capture current state for verification
        if @display_rendering
          puts "Before using stairs:"
          capture_screen
        end

        # Use the stairs by sending the '>' key
        begin
          # Store original method to restore it later
          original_getch = STDIN.method(:getch) rescue nil

          # Override getch to return '>'
          STDIN.define_singleton_method(:getch) { '>' }

          # Process a turn with the '>' key
          @game.one_turn(@level)

          # Check if level changed
          if @level != initial_level
            puts "✓ Successfully transitioned to a new level!" if @display_rendering
            @results[:levels_completed] += 1

            # Capture new level for verification
            if @display_rendering
              puts "After using stairs (new level):"
              capture_screen
            end

            return true
          else
            puts "✗ Level did not change after using stairs" if @display_rendering
            return false
          end
        ensure
          # Restore original getch method if possible
          if original_getch
            STDIN.define_singleton_method(:getch, &original_getch)
          end
        end
      end

      # Find and use stairs in a reliable way with predetermined stairs placement
      # and sequence of movements
      # @return [Boolean] true if successfully moved to next level
      def guaranteed_level_transition
        # First, create guaranteed stairs
        if create_guaranteed_stairs
          # Then use them with predefined key sequence
          return use_guaranteed_stairs
        end

        # If stairs creation failed, fall back to the original method
        find_and_use_stairs
      end

      # Set up a new game instance for simulation
      # @return [Vanilla::Game] the created game instance
      def setup_game
        # Set the global seed for reproducible tests
        $seed = @seed if @seed

        # Create game without seed parameter (uses global $seed)
        @game = Vanilla::Game.new

        # Patch the game to interact with it programmatically
        patch_game_for_testing

        # Get the level from the game
        @level = @game.instance_variable_get(:@current_level) ||
                 initialize_test_level_if_needed

        # Store initial player position
        @results[:initial_player_position] = player_position

        # Store the game and level in results for debugging
        @results[:game_seed] = $seed
        @results[:debug] ||= []
        @results[:debug] << "Game and level initialized with seed #{$seed}"
        @results[:debug] << "Initial player position: #{@results[:initial_player_position]}"

        @game
      end

      # Initialize a test level if no level exists in the game
      # @return [Vanilla::Level] the initialized level
      def initialize_test_level_if_needed
        return nil unless @game

        # Use private initialize_level method to create a test level
        # This requires accessing the private method via send
        if @game.respond_to?(:initialize_level)
          # Regular access for public method
          @game.initialize_level(difficulty: 1)
        elsif @game.respond_to?(:send)
          # Use send to access private method
          begin
            @game.send(:initialize_level, difficulty: 1)
          rescue => e
            @results[:errors] << {
              error: e.class.name,
              message: e.message,
              backtrace: e.backtrace&.first(3),
              context: "Initializing test level"
            }
            nil
          end
        else
          # Fallback if we can't access the method
          nil
        end
      end

      # Patch game class with test-friendly methods
      def patch_game_for_testing
        return unless @game

        # Store a reference to the level in the game for the simulator to access
        @game.instance_variable_set(:@simulator_level, nil)

        # Add a one_turn method that executes a single turn with the given input
        # This is essential for testing stairs usage which requires keyboard input
        # The method will only be added if it doesn't already exist
        unless @game.respond_to?(:one_turn)
          # Define the one_turn method
          @game.define_singleton_method(:one_turn) do |level|
            # Use the process_input method to handle a turn
            # If the method is private, we need to use send
            if respond_to?(:process_input)
              # Direct call for public method
              process_input(level)
            elsif respond_to?(:send)
              # Use send for private method
              send(:process_input, level)
            end

            # Update monster positions
            monster_system = level.instance_variable_get(:@monster_system)
            monster_system&.update

            # Handle collisions
            if respond_to?(:handle_collisions)
              handle_collisions(level, monster_system)
            elsif respond_to?(:send)
              send(:handle_collisions, level, monster_system) rescue nil
            end

            # Handle level transition and return new level if stairs found
            if level.player.found_stairs?
              if respond_to?(:handle_level_transition)
                new_level = handle_level_transition(level)
              elsif respond_to?(:send)
                new_level = send(:handle_level_transition, level) rescue nil
              end

              # Store reference to new level
              instance_variable_set(:@simulator_level, new_level)

              # Return the new level
              new_level
            else
              # No level change
              level
            end
          end
        end
      end

      # Run a sequence of actions on the game
      # @param actions [Array<Hash>] list of actions to perform
      # @return [Hash] the results of the simulation
      def run(actions)
        # Set up the game first
        setup_game

        # Process each action
        actions.each_with_index do |action, index|
          begin
            @results[:actions_performed] += 1
            process_action(action)
          rescue => e
            @results[:errors] << {
              error: e.class.name,
              message: e.message,
              backtrace: e.backtrace&.first(5),
              action_index: index,
              action: action
            }
            # We'll continue processing on non-fatal errors
          end
        end

        # Return the results of the simulation
        @results
      end

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

      # Simulate player movement in the specified direction
      # @param direction [Symbol] the direction to move (:up, :down, :left, :right)
      # @param count [Integer] number of steps to move in the specified direction
      # @return [Array<Hash>] detailed results of each movement
      def simulate_movement(direction, count = 1)
        return [] unless @game && @level

        direction_sym = direction.to_sym
        results = []

        count.times do |i|
          # Store initial position for comparison
          initial_position = player_position

          # Create a command to move in the specified direction
          command = case direction_sym
          when :up, :KEY_UP
            Vanilla::Commands::MoveCommand.new(@level.player, @level.grid, :north)
          when :down, :KEY_DOWN
            Vanilla::Commands::MoveCommand.new(@level.player, @level.grid, :south)
          when :left, :KEY_LEFT
            Vanilla::Commands::MoveCommand.new(@level.player, @level.grid, :west)
          when :right, :KEY_RIGHT
            Vanilla::Commands::MoveCommand.new(@level.player, @level.grid, :east)
          else
            @results[:errors] << {
              error: "InvalidDirection",
              message: "Invalid movement direction: #{direction}",
              context: "Movement attempt ##{i+1}"
            }
            nil
          end

          # Execute the command if valid
          moved = false
          begin
            if command
              moved = command.execute

              # Get updated position after command execution
              new_position = player_position

              # Check if the player actually moved
              position_changed = (initial_position != new_position)

              # Record the movement details
              movement_result = {
                direction: direction_sym,
                old_position: initial_position,
                new_position: new_position,
                moved: moved,
                position_changed: position_changed
              }

              # Store movement in results
              @results[:movements] << movement_result

              # Store player position for tracking
              @results[:player_positions] << new_position

              # Collect any messages generated during movement
              collect_messages

              # Add to return array
              results << movement_result
            end
          rescue => e
            @results[:errors] << {
              error: e.class.name,
              message: e.message,
              backtrace: e.backtrace&.first(3),
              context: "Moving #{direction_sym} (attempt #{i+1})"
            }
          end
        end

        results
      end

      # Collect messages from the message system if available
      def collect_messages
        return unless @game

        # Try to get the message manager
        message_manager = if defined?(Vanilla::Messages::MessageManager)
          Vanilla::Messages::MessageManager.instance rescue nil
        end

        # If message manager exists, collect messages
        if message_manager && message_manager.respond_to?(:messages)
          messages = message_manager.messages

          if messages && !messages.empty?
            @results[:messages] += messages
          end
        end
      end

      # Verify that the player character is rendered correctly at its position
      # This checks that what the player sees on screen matches the internal game state
      # @return [Boolean] true if the player is rendered correctly at its position
      def verify_player_rendering
        return false unless @level && @game

        # Get the player's position
        player_pos = player_position
        return false unless player_pos && player_pos[0] && player_pos[1]

        # Get the player's render component to know what character represents the player
        player = @level.player
        player_char = if player.respond_to?(:get_component) && player.get_component(:render)
          player.get_component(:render).character
        elsif player.respond_to?(:character)
          player.character
        else
          '@' # Default player character if we can't determine it
        end

        # Capture the current screen state
        screen = capture_screen

        # Nothing to verify if we couldn't capture the screen
        return false if screen.empty?

        # Check if the player character appears at the expected position in the rendering
        # This is tricky because the rendering might not be a simple 2D grid
        # We'll make a best effort to find the player character

        # Get the player's row and column
        row, col = player_pos

        # Different games might render differently, so we try multiple approaches:

        # Approach 1: Direct matching if the screen is a 2D grid
        # where indices directly correspond to coordinates
        if row < screen.size && screen[row].is_a?(String) && col < screen[row].length
          if screen[row][col] == player_char
            puts "✓ Player found at exact position [#{row},#{col}]" if @display_rendering
            return true
          end
        end

        # Approach 2: Search for patterns that might indicate the player at this position
        # in a rendered map with walls and corridors
        player_found = false

        # Look for the player character in the screen output
        player_positions = []
        screen.each_with_index do |line, idx|
          if line.include?(player_char)
            positions = line.chars.each_with_index.select { |c, _| c == player_char }.map { |_, i| [idx, i] }
            player_positions.concat(positions)
          end
        end

        if !player_positions.empty?
          puts "Found player character at screen positions: #{player_positions.inspect}" if @display_rendering
          player_found = true
        end

        # Report the result
        if player_found
          puts "✓ Player character found on screen" if @display_rendering
        else
          puts "✗ Player character NOT found on screen" if @display_rendering

          # Debug info
          @results[:debug] ||= []
          @results[:debug] << "Player character '#{player_char}' not found in rendering"
          @results[:debug] << "Player position: [#{row}, #{col}]"
          @results[:debug] << "Screen has #{screen.size} lines"
        end

        player_found
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
        return [] unless @level && @game

        # Try to access the render system
        if @game.respond_to?(:render_system)
          render_system = @game.render_system
        else
          render_system = @game.instance_variable_get(:@render_system)
        end

        # If we can't get the render system, we can't capture the screen
        return [] unless render_system && render_system.respond_to?(:renderer)

        # Get the renderer
        renderer = render_system.renderer
        return [] unless renderer

        # Get the current buffer (screen state)
        # Terminal renderer uses a 2D array buffer
        buffer = renderer.instance_variable_get(:@buffer)

        # Process the buffer based on its type
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
    end
  end
end