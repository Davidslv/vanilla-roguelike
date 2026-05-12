# frozen_string_literal: true

require_relative 'spec_helper'
require 'map_utils/cell'

RSpec.describe Vanilla::MapUtils::Cell do
  let(:a) { described_class.new(row: 0, column: 0) }
  let(:b) { described_class.new(row: 0, column: 1) }

  it 'records its position' do
    expect(a.row).to eq(0)
    expect(a.column).to eq(0)
  end

  it 'starts with no links' do
    expect(a.links).to be_empty
    expect(a.linked?(b)).to be(false)
  end

  it 'links bidirectionally by default' do
    a.link(cell: b)
    expect(a.linked?(b)).to be(true)
    expect(b.linked?(a)).to be(true)
  end

  it 'returns compact list of neighbours' do
    a.east = b
    expect(a.neighbors).to eq([b])
  end
end
