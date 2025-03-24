# frozen_string_literal: true
# lib/rubocop/cop/ecs/component_behavior.rb
module RuboCop
  module Cop
    module ECS
      class ComponentBehavior < RuboCop::Cop::Base
        extend AutoCorrector
        MSG = 'Components should only have initialize and accessors, no behavior methods.'.freeze
        ALLOWED_METHODS = %w[initialize type to_hash from_hash].freeze

        def on_class(node)
          @full_class_name = full_name(node)
          @parent_class_name = node.parent_class ? full_name(node.parent_class) : nil
          @is_component = @full_class_name.end_with?('Component') ||
                          @parent_class_name&.end_with?('Component')
        end

        def on_def(node)
          return unless @is_component

          method_name = node.method_name.to_s
          return if ALLOWED_METHODS.include?(method_name) ||
                    method_name.match?(/^[a-z_]+=$/)

          add_offense(node, message: MSG)
        end

        def on_defs(node)
          return unless @is_component
          return unless node receiver&.self_type? # Only match `self.` methods

          method_name = node.method_name.to_s
          return if ALLOWED_METHODS.include?(method_name)

          add_offense(node, message: MSG)
        end

        private

        def full_name(node)
          return node.source unless node.const_type?

          parts = []
          current = node
          while current&.const_type?
            parts.unshift(current.const_name.to_s)
            current = current.children[0]
          end
          parts.join('::')
        end
      end
    end
  end
end
