# spec/event_spec.rb
require_relative "../lib/event"

RSpec.describe Event do
  it "stores type and data" do
    event = Event.new(:key_pressed, { key: "w" })
    expect(event.type).to eq(:key_pressed)
    expect(event.data[:key]).to eq("w")
  end
end
