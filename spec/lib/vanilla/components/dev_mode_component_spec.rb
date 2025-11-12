# frozen_string_literal: true

require "spec_helper"
require "vanilla/components/dev_mode_component"

RSpec.describe Vanilla::Components::DevModeComponent do
  describe "#initialize" do
    it "sets fov_disabled to false by default" do
      component = described_class.new
      expect(component.fov_disabled).to be false
    end

    it "sets show_all_entities based on fov_disabled" do
      component = described_class.new
      expect(component.show_all_entities).to be false
    end

    it "allows initializing with fov_disabled: true" do
      component = described_class.new(fov_disabled: true)
      expect(component.fov_disabled).to be true
      expect(component.show_all_entities).to be true
    end
  end

  describe "#toggle_fov" do
    it "switches fov_disabled from false to true" do
      component = described_class.new(fov_disabled: false)
      component.toggle_fov

      expect(component.fov_disabled).to be true
    end

    it "switches fov_disabled from true to false" do
      component = described_class.new(fov_disabled: true)
      component.toggle_fov

      expect(component.fov_disabled).to be false
    end

    it "updates show_all_entities accordingly" do
      component = described_class.new(fov_disabled: false)
      component.toggle_fov

      expect(component.show_all_entities).to be true

      component.toggle_fov

      expect(component.show_all_entities).to be false
    end
  end

  describe "#type" do
    it "returns :dev_mode" do
      component = described_class.new
      expect(component.type).to eq(:dev_mode)
    end
  end

  describe "#to_hash" do
    it "serializes component data" do
      component = described_class.new(fov_disabled: true)
      hash = component.to_hash

      expect(hash[:fov_disabled]).to be true
      expect(hash[:show_all_entities]).to be true
    end
  end

  describe ".from_hash" do
    it "deserializes component data" do
      hash = {
        fov_disabled: true,
        show_all_entities: true
      }

      component = described_class.from_hash(hash)

      expect(component.fov_disabled).to be true
      expect(component.show_all_entities).to be true
    end
  end
end
