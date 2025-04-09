# spec/systems/render_system_spec.rb
require_relative "../../lib/systems/render_system"
require_relative "../../lib/entity"
require_relative "../../lib/components/position"
require_relative "../../lib/components/render"

RSpec.describe Systems::RenderSystem do
  it "renders entities to the grid" do
    entity = Entity.new(1)
                   .add_component(Components::Position.new(1, 1))
                   .add_component(Components::Render.new("@"))
    system = Systems::RenderSystem.new(3, 3)
    expect { system.process([entity]) }.to output(/\. \. \.\n\. @ \.\n\. \. \./).to_stdout
  end
end
