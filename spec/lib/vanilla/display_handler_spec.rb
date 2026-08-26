# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::DisplayHandler do
  describe '#cleanup' do
    it 'tears down the keyboard handler without raising' do
      handler = described_class.new
      expect { handler.cleanup }.not_to raise_error
    end
  end
end
