#!/usr/bin/env ruby

# This script generates a class diagram of the classes in the current directory.
# It uses the Mermaid syntax for class diagrams.
#
# To use it, run the script and then copy the output into a markdown file.
#
# USAGE:
# ruby generate_class_diagram.rb > class_diagram.md

require 'set'

def extract_classes(dir)
  classes = {}
  Dir.glob("#{dir}/**/*.rb").each do |file|
    content = File.read(file)
    content.scan(/^\s*class\s+(\w+)(?:\s*<\s*(\w+))?/) do |class_name, parent|
      classes[class_name] ||= { parent: parent, methods: Set.new, instance_vars: Set.new }
      # Extract public methods
      content.scan(/^\s*def\s+([a-z_][\w_]*)/) { |m| classes[class_name][:methods] << m[0] }
      # Extract instance variables (approximate)
      content.scan(/@(\w+)/) { |v| classes[class_name][:instance_vars] << v[0] }
    end
  end
  classes
end

def generate_mermaid(classes)
  puts "classDiagram"
  classes.each do |name, info|
    puts "  class #{name} {"
    info[:instance_vars].each { |var| puts "    -#{var}" }
    info[:methods].each { |method| puts "    +#{method}()" }
    puts "  }"
    puts "  #{info[:parent]} <|-- #{name}" if info[:parent]
  end
  # Manual relationships to be added
  puts "  Entity o--> \"many\" Component : contains"
  puts "  World o--> \"many\" Entity : manages"
  puts "  World o--> \"many\" System : manages"
end

classes = extract_classes('.')
generate_mermaid(classes)