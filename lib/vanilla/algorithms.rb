# frozen_string_literal: true
module Vanilla
  module Algorithms
    require_relative 'algorithms/abstract_algorithm'
    require_relative 'algorithms/aldous_broder'
    require_relative 'algorithms/binary_tree'
    require_relative 'algorithms/dijkstra'
    require_relative 'algorithms/longest_path'
    require_relative 'algorithms/recursive_backtracker'
    require_relative 'algorithms/recursive_division'

    # Available Algorithms for the map
    AVAILABLE = [
      Vanilla::Algorithms::AldousBroder,
      Vanilla::Algorithms::BinaryTree,
      Vanilla::Algorithms::RecursiveDivision,
      Vanilla::Algorithms::RecursiveBacktracker,
    ].freeze
  end
end
