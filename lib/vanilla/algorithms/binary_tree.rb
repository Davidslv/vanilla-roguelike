# frozen_string_literal: true

# lib/vanilla/algorithms/binary_tree.rb
module Vanilla
  module Algorithms
    class BinaryTree < AbstractAlgorithm
      def self.on(grid)
        grid.each_cell do |cell|
          has_north = !cell.north.nil?
          has_east = !cell.east.nil?
          if has_north && has_east
            cell.link(cell: rand(2) == 0 ? cell.north : cell.east, bidirectional: true)
          elsif has_north
            cell.link(cell: cell.north, bidirectional: true)
          elsif has_east
            cell.link(cell: cell.east, bidirectional: true)
          end
        end

        grid.each_cell do |cell|
          if cell.links.empty?
            cell.tile = Vanilla::Support::TileType::WALL
          end
        end

        grid
      end
    end
  end
end
