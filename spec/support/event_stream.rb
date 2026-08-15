# frozen_string_literal: true

# Normalises captured event streams for run-to-run comparison (Proposal 012).
#
# Two runs of the same seed and key script must produce identical event
# streams — identical types, order, and payloads — except for fields that are
# entropy-based by design and sit outside the determinism contract:
#
# - Event ids and timestamps (SecureRandom.uuid / Time.now per publish);
#   normalize simply drops them by keeping only type and data.
# - Entity ids embedded in payloads (Entities::Entity ids are SecureRandom
#   uuids). These are canonicalised to stable tokens ("uuid-0", "uuid-1", …)
#   in first-appearance order, so two streams compare equal when their
#   entities correspond positionally even though the raw uuids differ.
# - Live objects embedded in payloads (command_issued carries the command
#   instance). Object identity differs every run; they are reduced to their
#   class name, which is the deterministic part of their meaning.
#
# Used by the determinism tripwire spec and, later, the replay regression
# tapes (Epic #129).
module EventStream
  UUID = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

  module_function

  # @param events [Array<Vanilla::Events::Event>]
  # @return [Array<Hash>] one { type:, data: } per event, uuids canonicalised
  def normalize(events)
    mapping = Hash.new { |seen, uuid| seen[uuid] = "uuid-#{seen.size}" }
    events.map { |event| { type: event.type, data: canonicalize(event.data, mapping) } }
  end

  # Recursively replace every uuid string in a payload with its stable token.
  def canonicalize(value, mapping)
    case value
    when Hash then value.transform_values { |nested| canonicalize(nested, mapping) }
    when Array then value.map { |nested| canonicalize(nested, mapping) }
    when String then value.match?(UUID) ? mapping[value] : value
    when Numeric, Symbol, true, false, nil then value
    else "#<#{value.class.name}>"
    end
  end
end
