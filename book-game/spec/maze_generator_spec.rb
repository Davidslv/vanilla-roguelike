# spec/maze_generator_spec.rb
require_relative "../lib/maze_generator"

RSpec.describe MazeGenerator do
  it "raises NotImplementedError for base generate" do
    grid = Grid.new(3, 3)
    generator = MazeGenerator.new(grid)
    expect { generator.generate }.to raise_error(NotImplementedError)
  end
end
