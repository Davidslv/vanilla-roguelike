# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Vanilla::Events::Storage::EventStore do
  let(:store) { described_class.new }
  let(:event) { Vanilla::Events::Event.new("test_event", "test_source", { data: "value" }) }

  describe 'interface methods' do
    it 'raises NotImplementedError for #store' do
      expect { store.store(event) }.to raise_error(
        NotImplementedError,
        "#{described_class} must implement store(event)"
      )
    end

    it 'raises NotImplementedError for #query' do
      expect { store.query }.to raise_error(
        NotImplementedError,
        "#{described_class} must implement query(options)"
      )
    end

    it 'raises NotImplementedError for #load_session' do
      expect { store.load_session }.to raise_error(
        NotImplementedError,
        "#{described_class} must implement load_session(session_id)"
      )
    end

    it 'raises NotImplementedError for #list_sessions' do
      expect { store.list_sessions }.to raise_error(
        NotImplementedError,
        "#{described_class} must implement list_sessions"
      )
    end

    it 'provides a default implementation for #close' do
      expect { store.close }.not_to raise_error
    end
  end
end
