require 'pry'

module Vanilla
  # required to use STDIN.getch
  # in order to avoid pressing enter to submit input to the game
  require 'io/console'

  # Keyboard arrow keys are compose of 3 characters
  #
  # UP    -> \e[A
  # DOWN  -> \e[B
  # RIGHT -> \e[C
  # LEFT  -> \e[D
  KEYBOARD_ARROWS = {
    A: :KEY_UP,
    B: :KEY_DOWN,
    C: :KEY_RIGHT,
    D: :KEY_LEFT
  }.freeze

  # logger
  require_relative 'vanilla/logger'

  # draw
  require_relative 'vanilla/draw'

  # map
  require_relative 'vanilla/map_utils'
  require_relative 'vanilla/map'

  # output
  require_relative 'vanilla/output/terminal'

  # algorithms
  require_relative 'vanilla/algorithms'

  # support
  require_relative 'vanilla/support/tile_type'

  # components (entity component system)
  require_relative 'vanilla/components'

  # systems (entity component system)
  require_relative 'vanilla/systems'

  # entities
  require_relative 'vanilla/entities'

  # commands
  require_relative 'vanilla/input_handler'

  # level
  require_relative 'vanilla/level'

  $seed = nil

  def self.run
    logger = Vanilla::Logger.instance
    logger.info("Starting game loop")

    level = Vanilla::Level.random
    logger.info("Level created")

    # Create an InputHandler for the game loop
    input_handler = Vanilla::InputHandler.new(logger)

    # Create a monster system for the current level
    monster_system = Vanilla::Systems::MonsterSystem.new(
      grid: level.grid,
      player: level.player,
      logger: logger
    )

    # Spawn monsters for the initial level
    monster_system.spawn_monsters(1) # Start with level 1 difficulty
    logger.info("Spawned initial monsters")

    # Draw the map to show monsters immediately
    Vanilla::Draw.map(level.grid)

    # Game loop
    while key = STDIN.getch
      # Given that arrow keys are compose of more than one character
      # we are taking advantage of STDIN repeatedly to represent the correct action.
      # It's not a perfect solution but it does avoid using Ncurses/Curses
      second_key = STDIN.getch if key == "\e"
      key        = STDIN.getch if second_key == "["
      key        = KEYBOARD_ARROWS[key.intern] || key

      logger.debug("Key pressed: #{key.inspect}")

      # Handle player input
      command = input_handler.handle_input(key, level.player, level.grid)

      # If a valid command was executed, update monsters
      if command && command.executed
        # Update monster positions and behaviors
        monster_system.update
        logger.debug("Updated #{monster_system.monsters.count} monsters")

        # Check for player-monster collision after monster movement
        player_pos = level.player.get_component(:position)
        monster = monster_system.monster_at(player_pos.row, player_pos.column)

        if monster
          # Handle combat (simple version - monster damages player)
          logger.info("Player encountered a #{monster.monster_type}!")
          # In a real implementation, you would handle combat here
          # For now, we just pretend the encounter happened
        end
      end

      # Check if player found stairs
      if level.player.found_stairs?
        current_level = level.difficulty || 1
        next_level = current_level + 1

        logger.info("Player found stairs, advancing to level #{next_level}")
        level = Vanilla::Level.random(difficulty: next_level)

        # Create new monster system for the new level
        monster_system = Vanilla::Systems::MonsterSystem.new(
          grid: level.grid,
          player: level.player,
          logger: logger
        )

        # Spawn monsters with increased difficulty
        monster_system.spawn_monsters(next_level)
        logger.info("Spawned monsters for level #{next_level}")

        # Draw the map to show monsters on the new level
        Vanilla::Draw.map(level.grid)
      end
    end
  end

  # @param rows [Integer] is the vertical length of the map
  # @param columns [Integer] is the  horizontal length of the map
  # @param algorithm [Object] choose the class object of the algorithm you would like to use
  # @param display_distances [Boolean] displays a distance from two random points on the grid
  # @param display_longest [Boolean] displays the longest possible distance between two points on the grid, uses Djikra's algorithm
  # @param open_maze [Boolean] displays a different render output
  # @param seed [Integer] is the number necessary to regenerate a given grid
  def self.play(rows: 10, columns: 10, algorithm: Vanilla::Algorithms::BinaryTree, display_distances: false, display_longest: false, open_maze: true, seed: nil)
    $seed = seed || rand(999_999_999_999_999)
    grid = Vanilla::Map.create(rows: rows, columns: columns, algorithm: algorithm, seed: seed)

    start, goal = self.start_and_goal_points(grid: grid)          if display_distances || display_longest
    self.display_distances(grid: grid, start: start, goal: goal)  if (display_distances && !display_longest)
    Vanilla::Algorithms::LongestPath.on(grid, start: start)       if display_longest

    Vanilla::Draw.map(grid, open_maze: open_maze)
  end

  # defines the start position and end position
  # recalculates end position when it is the same as start position
  def self.start_and_goal_points(grid:)
    start_position = grid[rand(0...grid.rows), rand(0...grid.columns)]
    end_position = grid[rand(0...grid.rows), rand(0...grid.columns)]

    until start_position != end_position
      end_position = grid[rand(0...grid.rows), rand(0...grid.columns)]
    end

    [start_position, end_position]
  end

  # uses Dijkstra's algorithm
  def self.display_distances(grid:, start:, goal:)
    puts "displaying path distance from start to goal:"

    distances = start.distances

    puts "start: [#{start.row}, #{start.column}] goal: [#{goal.row}, #{goal.column}]"

    grid.distances = distances.path_to(goal)

    grid
  end
end
