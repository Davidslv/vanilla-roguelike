#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to wrap code lines in markdown files to 75 characters
# Only affects code blocks (between ``` markers)

require 'fileutils'

BOOK_DIR = File.join(__dir__, '..', 'book')
MAX_WIDTH = 70

def wrap_code_line(line, max_width, indent = 0)
  return line if line.length <= max_width

  stripped = line.lstrip
  original_indent = line[/^\s*/]
  continuation_indent = ' ' * (indent + 6)

  # Try to break at natural points
  # 1. After method calls with dots (before the dot)
  if stripped =~ /^(.{1,#{max_width - 15}})\.(\w+)(.+)$/
    first_part = Regexp.last_match(1)
    method_name = Regexp.last_match(2)
    rest = Regexp.last_match(3)
    return "#{original_indent}#{first_part}.\n#{continuation_indent}#{method_name}#{wrap_code_line(rest, max_width, indent + 6)}"
  end

  # 2. After commas (in method arguments)
  if stripped =~ /^(.{1,#{max_width - 10}}),\s*(.+)$/
    first_part = Regexp.last_match(1) + ','
    rest = Regexp.last_match(2)
    return "#{original_indent}#{first_part}\n#{continuation_indent}#{wrap_code_line(rest, max_width, indent + 6)}"
  end

  # 3. Before operators (&&, ||, etc.)
  if stripped =~ /^(.{1,#{max_width - 10}})\s+(&&|\|\||\+|\-|\*|\/)\s+(.+)$/
    first_part = Regexp.last_match(1)
    operator = Regexp.last_match(2)
    rest = Regexp.last_match(3)
    return "#{original_indent}#{first_part}\n#{continuation_indent}#{operator} #{wrap_code_line(rest, max_width, indent + 6)}"
  end

  # 4. After opening parentheses (for method calls)
  if stripped =~ /^(.{1,#{max_width - 10}})\((.+)$/
    first_part = Regexp.last_match(1) + '('
    rest = Regexp.last_match(2)
    return "#{original_indent}#{first_part}\n#{continuation_indent}#{wrap_code_line(rest, max_width, indent + 6)}"
  end

  # 5. Before hash rockets (=>)
  if stripped =~ /^(.{1,#{max_width - 10}})\s*=>\s*(.+)$/
    first_part = Regexp.last_match(1)
    rest = Regexp.last_match(2)
    return "#{original_indent}#{first_part}\n#{continuation_indent}=> #{wrap_code_line(rest, max_width, indent + 6)}"
  end

  # 6. Force break at space if nothing else works
  if stripped =~ /^(.{1,#{max_width}})\s+(.+)$/
    first_part = Regexp.last_match(1)
    rest = Regexp.last_match(2)
    return "#{original_indent}#{first_part}\n#{continuation_indent}#{wrap_code_line(rest, max_width, indent + 6)}"
  end

  # If we can't break nicely, return as is
  line
end

def process_file(file_path)
  content = File.read(file_path)
  lines = content.lines
  output = []
  in_code_block = false
  code_block_indent = 0

  lines.each_with_index do |line, index|
    # Check if we're entering/exiting a code block
    if line =~ /^```(\w+)?$/
      in_code_block = !in_code_block
      output << line
      next
    end

    if in_code_block
      # Process code lines
      original_line = line
      stripped = line.rstrip

      if stripped.length > MAX_WIDTH
        # Calculate current indentation
        indent = line[/^\s*/].length
        wrapped = wrap_code_line(stripped, MAX_WIDTH, indent)
        # Split into lines and ensure proper formatting
        wrapped_lines = wrapped.split("\n")
        output << wrapped_lines.join("\n") + "\n"
      else
        output << line
      end
    else
      output << line
    end
  end

  File.write(file_path, output.join)
end

# Process all markdown files
Dir.glob(File.join(BOOK_DIR, '*.md')).each do |file|
  puts "Processing #{File.basename(file)}..."
  process_file(file)
end

puts "\nDone! All code blocks have been wrapped to #{MAX_WIDTH} characters."

