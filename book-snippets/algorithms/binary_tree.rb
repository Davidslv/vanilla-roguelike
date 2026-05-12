# frozen_string_literal: true

require_relative 'abstract_algorithm'
require_relative '../support/tile_type'

module Vanilla
  module Algorithms
# >> binary-tree
    class BinaryTree < AbstractAlgorithm
      def self.on(grid)
        grid.each_cell do |cell|
          has_north = !cell.north.nil?
          has_east  = !cell.east.nil?

          if has_north && has_east
            cell.link(cell: rand(2).zero? ? cell.north : cell.east, bidirectional: true)
          elsif has_north
            cell.link(cell: cell.north, bidirectional: true)
          elsif has_east
            cell.link(cell: cell.east, bidirectional: true)
          end
        end

        grid.each_cell do |cell|
          cell.tile = Vanilla::Support::TileType::WALL if cell.links.empty?
        end

        grid
      end
    end
# << binary-tree
  end
end
