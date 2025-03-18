module Vanilla
  module Output
    class Terminal
      def initialize(grid, open_maze: true)
        @grid = grid
        @open_maze = open_maze
      end

      def to_s
        if @open_maze
          draw_open_maze
        else
          draw_dead_end_maze
        end
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
              corner = '#' # this is the cell being repeated on RecursiveDivision in the middle of nowhere

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
