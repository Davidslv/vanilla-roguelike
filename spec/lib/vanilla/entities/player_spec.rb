# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Entities::Player do
  let(:row) { 5 }
  let(:column) { 10 }
  let(:player) { described_class.new(row: row, column: column) }

  it "Pending" do
    pending("Needs new unit tests")
  end
end
