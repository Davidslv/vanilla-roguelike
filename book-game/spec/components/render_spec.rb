# spec/components/render_spec.rb
require_relative "../../lib/components/render"

RSpec.describe Components::Render do
  it "serializes and deserializes correctly" do
    render = Components::Render.new("@", :red)
    expect(Components::Render.from_h(render.to_h).character).to eq("@")
  end
end
