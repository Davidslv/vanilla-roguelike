# spec/binary_tree_generator_spec.rb
require_relative "../lib/binary_tree_generator"
require_relative "../lib/grid"

RSpec.describe BinaryTreeGenerator do
  it "generates a maze with outer walls" do
    grid = Grid.new(5, 5)
    generator = BinaryTreeGenerator.new(grid)
    generator.generate
    expect(grid.at(0, 0).is_wall).to be true  # Top-left wall
    expect(grid.at(4, 4).is_wall).to be true  # Bottom-right wall
  end
end
