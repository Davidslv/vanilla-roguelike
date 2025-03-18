module Vanilla
  module Output
    class Terminal
      attr_reader :player, :messages
      attr_accessor :grid

      def initialize(grid:, player: nil, open_maze: true)
        @grid = grid
        @player = player
        @open_maze = open_maze
        @messages = []
      end

      def add_message(message)
        @messages << message
      end

      def clear_messages
        @messages.clear
      end

      def clear
        system('clear') || system('cls')
      end

      def to_s
        # Add seed and grid information
        output = "Seed: #{$seed} | Rows: #{grid.rows} | Columns: #{grid.columns}\n\n"

        # Add the maze
        output << if @open_maze
          draw_open_maze
        else
          draw_dead_end_maze
        end

        # Add player stats below the maze
        if @player
          output << "\nPlayer Stats:\n"
          output << "HP: #{@player.health}/#{@player.max_health}"
          output << " | Level: #{@player.level}"
          output << " | XP: #{@player.experience}/#{@player.experience_to_next_level}\n"
        end

        # Add messages below the stats
        unless @messages.empty?
          output << "\nCombat Log:\n"
          @messages.each do |msg|
            output << "#{msg}\n"
          end
        end

        output
      end

      def write
        puts to_s
        @messages.clear
      end

      def self.draw(grid)
        output = "+" + "---+" * grid.columns + "\n"

        grid.each_row do |row|
          top = "|"
          bottom = "+"

          row.each do |cell|
            next unless cell

            body = grid.contents_of(cell)
            body = " #{body} " if body.size == 1
            body = " #{body}" if body.size == 2

            east_boundary = (cell.linked?(cell.east) ? " " : "|")
            south_boundary = (cell.linked?(cell.south) ? "   " : "---")
            corner = "+"

            top << body << east_boundary
            bottom << south_boundary << corner
          end

          output << top << "\n"
          output << bottom << "\n"
        end

        puts output
      end

      private
        def draw_open_maze
          output = "+" + "---+" * @grid.columns + "\n"

          @grid.each_row do |row|
            top = "|"
            bottom = "+"

            row.each do |cell|
              next unless cell

              body = @grid.contents_of(cell)

              body = " #{body} " if body.size == 1
              body = " #{body}" if body.size == 2

              east_boundary = (cell.linked?(cell.east) ? " " : "|")
              south_boundary = (cell.linked?(cell.south) ? "   " : "---")
              corner = "+"

              top << body << east_boundary
              bottom << south_boundary << corner
            end

            output << top << "\n"
            output << bottom << "\n"
          end

          output
        end

        def draw_dead_end_maze
          output = '#' + '####' * @grid.columns + "\n"

          @grid.each_row do |row|
            top = '#'
            bottom = '#'

            row.each do |cell|
              next unless cell

              body = cell.dead_end? ? '###' : " #{@grid.contents_of(cell)} "
              east_boundary = (cell.linked?(cell.east) ? " " : '#')
              south_boundary = (cell.linked?(cell.south) ? "   " : '###')
              corner = '#'

              top << body << east_boundary
              bottom << south_boundary << corner
            end

            output << top << "\n"
            output << bottom << "\n"
          end

          output
        end
    end
  end
end
