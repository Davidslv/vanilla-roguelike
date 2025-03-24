# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Vanilla::Components::Component do
  describe '#initialize' do
    it 'requires subclasses to implement type' do
      expect { described_class.new }.to raise_error(NotImplementedError)
    end
  end

  describe '.from_hash' do
    before do
      # Save the original component_classes
      @original_component_classes = Vanilla::Components::Component.component_classes.dup

      # Clear component_classes for this test
      Vanilla::Components::Component.instance_variable_set(:@component_classes, {})

      # Create and register a real test component
      class Vanilla::Components::TestPositionComponent < Vanilla::Components::Component
        attr_reader :row, :column

        def initialize(row: 0, column: 0)
          @row = row
          @column = column
          super()
        end

        def type
          :position
        end

        def self.from_hash(hash)
          new(row: hash[:row], column: hash[:column])
        end
      end

      # Register our test component
      Vanilla::Components::Component.register(Vanilla::Components::TestPositionComponent)
    end

    after do
      # Restore the original component_classes
      Vanilla::Components::Component.instance_variable_set(:@component_classes, @original_component_classes)

      # Remove our test class
      Vanilla::Components.send(:remove_const, :TestPositionComponent) if Vanilla::Components.const_defined?(:TestPositionComponent)
    end

    it 'creates the appropriate component type from a hash' do
      hash = { type: :position, row: 5, column: 10 }
      component = described_class.from_hash(hash)

      expect(component).to be_a(Vanilla::Components::TestPositionComponent)
      expect(component.row).to eq(5)
      expect(component.column).to eq(10)
    end

    it 'raises an error for unknown component types' do
      hash = { type: :unknown_component }
      expect { described_class.from_hash(hash) }.to raise_error(ArgumentError)
    end
  end

  describe '#to_hash' do
    let(:component_class) do
      Class.new(described_class) do
        def initialize
          super
        end

        def type
          :test
        end

        def data
          { value: 42 }
        end
      end
    end

    let(:component) { component_class.new }

    it 'serializes component type and data' do
      hash = component.to_hash
      expect(hash[:type]).to eq(:test)
      expect(hash[:value]).to eq(42)
    end
  end

  describe '#update' do
    let(:component_class) do
      Class.new(described_class) do
        def initialize
          super
        end

        def type
          :test
        end
      end
    end

    let(:component) { component_class.new }
    let(:entity) { double("Entity") }

    it 'has a default implementation that does nothing' do
      expect { component.update(entity, 1.0) }.not_to raise_error
    end
  end
end
