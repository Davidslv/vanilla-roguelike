#!/usr/bin/env ruby
# analyze_codebase.rb
#
# This script analyzes the codebase and generates a Graphviz DOT file.
#
# USAGE:
# ruby analyze_codebase.rb > vanilla_ecs.dot
# 
# Requirements:
# - gem install parser
# - gem install graphviz
# - brew install graphviz
# - dot -Tpng vanilla_ecs.dot -o diagram.png
#
# For SVG
# dot -Tsvg vanilla_ecs.dot -o vanilla_ecs.svg


require 'set'
require 'parser/current' # gem install parser

# Class to store class info
class ClassInfo
  attr_reader :name, :parent, :methods, :instance_vars, :dependencies, :file
  attr_accessor :has_behavior

  def initialize(name, parent = nil, file = nil)
    @name = name
    @parent = parent
    @methods = Set.new
    @instance_vars = Set.new
    @dependencies = Set.new
    @has_behavior = false # Flag for ECS component smell
    @file = file
  end
end

# Analyze Ruby files and build class relationships
def analyze_codebase(dir)
  classes = {}
  Dir.glob("#{dir}/**/*.rb").each do |file|
    begin
      content = File.read(file)
      ast = Parser::CurrentRuby.parse(content)
      next unless ast # Skip if parsing fails (e.g., syntax error)

      # Traverse AST for class definitions
      traverse_ast(ast) do |node|
        next unless node.is_a?(Parser::AST::Node) && node.type == :class
        class_name = node.children[0].children[1].to_s # e.g., "PositionComponent"
        parent = node.children[1]&.children&.[](1)&.to_s # e.g., "Component"
        classes[class_name] ||= ClassInfo.new(class_name, parent, file)

        # Extract methods and instance vars from class body (node.children[2])
        process_class_body(node.children[2], classes[class_name]) if node.children[2]

        # Detect dependencies via method calls (basic heuristic)
        content.scan(/(\w+)\.\w+/) do |match|
          dep = match[0]
          classes[class_name].dependencies << dep if classes.key?(dep)
        end
      end
    rescue Parser::SyntaxError => e
      warn "Skipping #{file} due to syntax error: #{e.message}"
    end
  end
  classes
end

# Recursively traverse AST nodes
def traverse_ast(node, &block)
  return unless node.is_a?(Parser::AST::Node)
  yield node
  node.children.each { |child| traverse_ast(child, &block) if child.is_a?(Parser::AST::Node) }
end

# Process class body for methods and instance variables
def process_class_body(body, class_info)
  return unless body.is_a?(Parser::AST::Node)

  traverse_ast(body) do |child|
    case child.type
    when :def
      method_name = child.children[0].to_s
      class_info.methods << method_name
      # Flag behavior in components (excluding initialize)
      class_info.has_behavior = true if class_info.name.end_with?('Component') && method_name != 'initialize'
    when :ivasgn
      class_info.instance_vars << child.children[0].to_s[1..-1] # Strip @
    end
  end
end

# Generate Graphviz DOT file
def generate_dot(classes, output_file)
  File.open(output_file, 'w') do |f|
    f.puts "digraph VanillaECS {"
    f.puts "  rankdir=LR;" # Left-to-right layout
    f.puts "  node [shape=box];"

    # Define nodes with attributes
    classes.each do |name, info|
      color = info.has_behavior && name.end_with?('Component') ? 'red' : 'black'
      label = "#{name}\\n#{info.instance_vars.to_a.join(', ')}"
      f.puts "  #{name} [label=\"#{label}\", color=#{color}];"
      f.puts "  #{info.parent} -> #{name} [style=solid];" if info.parent && classes.key?(info.parent)
      info.dependencies.each do |dep|
        f.puts "  #{name} -> #{dep} [style=dashed];" if classes.key?(dep)
      end
    end

    # Add ECS-specific relationships (manual for now)
    f.puts "  Entity -> Component [label=\"contains\", style=diamond];"
    f.puts "  World -> Entity [label=\"manages\", style=diamond];"
    f.puts "  World -> System [label=\"manages\", style=diamond];"

    f.puts "}"
  end
end

# Main execution
dir = '.' # Adjust to your codebase root, e.g., 'frameworks/ecs'
output_file = 'vanilla_ecs.dot'
classes = analyze_codebase(dir)
generate_dot(classes, output_file)

# puts "Generated #{output_file}. Render with: dot -Tpng #{output_file} -o diagram.png"