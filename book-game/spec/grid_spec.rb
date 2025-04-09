# spec/grid_spec.rb
require_relative "../lib/grid"
require_relative "../lib/binary_tree_generator"

RSpec.describe Grid do
  it "initializes with all walls" do
    grid = Grid.new(3, 3)
    expect(grid.at(1, 1).is_wall).to be true
  end

  it "generates a maze with a generator" do
    grid = Grid.new(5, 5)
    grid.generate_maze(BinaryTreeGenerator)
    expect(grid.cells.flatten.any? { |cell| !cell.is_wall }).to be true # Some paths exist
  end
end
