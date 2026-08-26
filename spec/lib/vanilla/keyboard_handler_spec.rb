# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::KeyboardHandler do
  describe '#cleanup' do
    it 'is part of the public interface DisplayHandler depends on' do
      expect(described_class.new).to respond_to(:cleanup)
    end

    it 'is a no-op: $stdin.raw restores terminal mode after each read' do
      expect { described_class.new.cleanup }.not_to raise_error
    end
  end
end
