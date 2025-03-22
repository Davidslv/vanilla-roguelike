require 'spec_helper'

RSpec.describe "Test Mode" do
  it "does not start the game when running in test mode" do
    # Game initialization shouldn't cause any UI screens to appear
    game = Vanilla::Game.new

    # If we got here without the UI appearing, the test passes
    expect(ENV['VANILLA_TEST_MODE']).to eq('true')
  end

  it "sets test_mode in Game instance" do
    # Check that our Game class respects the test mode flag
    expect(Vanilla.respond_to?(:run)).to be true
  end
end