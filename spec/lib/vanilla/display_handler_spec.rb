# frozen_string_literal: true

require 'spec_helper'

# Regression cover for issue #141: DisplayHandler#cleanup called
# KeyboardHandler#cleanup, which was never defined, so quitting raised
# NoMethodError. These specs deliberately use the REAL KeyboardHandler --
# substituting a double is exactly what hid the defect from the harness.
RSpec.describe Vanilla::DisplayHandler do
  describe '#cleanup' do
    it 'tears down the real keyboard handler without raising' do
      handler = described_class.new

      expect { handler.cleanup }.not_to raise_error
    end

    it 'delegates to the keyboard handler' do
      handler = described_class.new

      expect(handler.keyboard_handler).to receive(:cleanup)

      handler.cleanup
    end
  end
end
