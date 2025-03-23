#!/usr/bin/env ruby
# analyze_codebase_mermaid.rb
#
# This script analyzes the codebase and generates a Mermaid class diagram.
#
# USAGE:
# ruby scripts/analyze_codebase_mermaid.rb > vanilla_ecs.mmd
#
# ruby scripts/analyze_codebase_mermaid.rb Systems > vanilla_ecs_systems.mmd
#
# ruby scripts/analyze_codebase_mermaid.rb Components > vanilla_ecs_components.mmd
#
# ruby scripts/analyze_codebase_mermaid.rb Core > vanilla_ecs_core.mmd


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
      next unless ast

      traverse_ast(ast) do |node|
        next unless node.is_a?(Parser::AST::Node) && node.type == :class
        class_name = node.children[0].children[1].to_s
        parent = node.children[1]&.children&.[](1)&.to_s
        classes[class_name] ||= ClassInfo.new(class_name, parent, file)

        process_class_body(node.children[2], classes[class_name]) if node.children[2]

        # Detect dependencies via method calls and ECS-specific interactions
        content.scan(/(\w+)\.\w+/) do |match|
          dep = match[0]
          classes[class_name].dependencies << dep if classes.key?(dep)
        end
        # Detect event emissions with underscore notation
        content.scan(/emit_event\(\:(\w+)/) do |event|
          classes[class_name].dependencies << "World : emits_#{event[0]}"
        end
        # Detect command queueing with underscore notation
        content.scan(/queue_command\(\:(\w+)/) do |command|
          classes[class_name].dependencies << "World : queues_#{command[0]}"
        end
      end
    rescue Parser::SyntaxError => e
      warn "Skipping #{file} due to syntax error: #{e.message}"
    end
  end
  # Filter out legacy and benchmark classes
  classes.reject! { |name, _| name.start_with?('Legacy') || name.end_with?('Benchmark') }
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
      class_info.has_behavior = true if class_info.name.end_with?('Component') && method_name != 'initialize'
    when :ivasgn
      class_info.instance_vars << child.children[0].to_s[1..-1]
    end
  end
end

# Generate Mermaid class diagram with subgraphs
def generate_mermaid(classes, output_file)
  File.open(output_file, 'w') do |f|
    f.puts "classDiagram"

    # Core classes (e.g., Entity, World)
    core = classes.select { |n, _| %w[Entity Component System World].include?(n) }
    unless core.empty?
      f.puts "  subgraph Core"
      core.each do |name, info|
        f.puts "    class #{name} {"
        info.instance_vars.each { |var| f.puts "      -#{var}" }
        info.methods.each { |method| f.puts "      +#{method}()" }
        f.puts "    }"
        f.puts "    #{info.parent} <|-- #{name}" if info.parent && classes.key?(info.parent)
      end
      f.puts "  end"
    end

    # Components
    components = classes.select { |n, _| n.end_with?('Component') }
    unless components.empty?
      f.puts "  subgraph Components"
      components.each do |name, info|
        color = info.has_behavior ? "#ffcccc" : "#ffffff" # Red for behavior smell
        f.puts "    class #{name} {"
        info.instance_vars.each { |var| f.puts "      -#{var}" }
        info.methods.each { |method| f.puts "      +#{method}()" }
        f.puts "    }"
        f.puts "    #{info.parent} <|-- #{name}" if info.parent && classes.key?(info.parent)
        f.puts "    style #{name} fill:#{color}"
      end
      f.puts "  end"
    end

    # Systems
    systems = classes.select { |n, _| n.end_with?('System') }
    unless systems.empty?
      f.puts "  subgraph Systems"
      systems.each do |name, info|
        f.puts "    class #{name} {"
        info.instance_vars.each { |var| f.puts "      -#{var}" }
        info.methods.each { |method| f.puts "      +#{method}()" }
        f.puts "    }"
        f.puts "    #{info.parent} <|-- #{name}" if info.parent && classes.key?(info.parent)
      end
      f.puts "  end"
    end

    # Other classes (e.g., Game, Level)
    others = classes.reject { |n, _| n.end_with?('Component') || n.end_with?('System') || %w[Entity Component System World].include?(n) }
    unless others.empty?
      f.puts "  subgraph Others"
      others.each do |name, info|
        f.puts "    class #{name} {"
        info.instance_vars.each { |var| f.puts "      -#{var}" }
        info.methods.each { |method| f.puts "      +#{method}()" }
        f.puts "    }"
        f.puts "    #{info.parent} <|-- #{name}" if info.parent && classes.key?(info.parent)
      end
      f.puts "  end"
    end

    # Relationships
    f.puts "  %% Relationships"
    classes.each do |name, info|
      info.dependencies.each do |dep|
        target, label = dep.split(' :', 2)
        if label
          f.puts "  #{name} --> #{target} : #{label}" if classes.key?(target)
        else
          f.puts "  #{name} --> #{dep} : uses" if classes.key?(dep)
        end
      end
    end
    f.puts "  Entity o--> \"many\" Component : contains" if classes.key?('Entity') && classes.key?('Component')
    f.puts "  World o--> \"many\" Entity : manages" if classes.key?('World') && classes.key?('Entity')
    f.puts "  World o--> \"many\" System : manages" if classes.key?('World') && classes.key?('System')
  end
end

# Generate Mermaid sub-diagram based on filter
def generate_mermaid_subdiagram(classes, filter, output_file)
  filtered = case filter
             when 'core' then classes.select { |n, _| %w[Entity Component System World].include?(n) }
             when 'components' then classes.select { |n, _| n.end_with?('Component') }
             when 'systems' then classes.select { |n, _| n.end_with?('System') }
             else classes
             end
  generate_mermaid(filtered, output_file)
end

# Main execution
dir = '.' # Adjust to your codebase root, e.g., 'frameworks/ecs'
classes = analyze_codebase(dir)

# Generate sub-diagrams
generate_mermaid_subdiagram(classes, 'core', 'core.mmd')
generate_mermaid_subdiagram(classes, 'components', 'components.mmd')
generate_mermaid_subdiagram(classes, 'systems', 'systems.mmd')
generate_mermaid(classes, 'full.mmd') # Full diagram as fallback

warn "Generated core.mmd, components.mmd, systems.mmd, and full.mmd. View at: https://mermaid.live or in VS Code with Mermaid Preview"