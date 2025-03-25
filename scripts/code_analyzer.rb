require 'parser/current'
require 'find'

class CodeAnalyzer
  def initialize(directory_path, debug: false)
    @directory_path = directory_path
    @debug = debug
    @classes = {}
    @modules = {}
    @methods_defined = {}
    @classes_used = Set.new
    @modules_used = Set.new
    @methods_called = Set.new
    @analyzed_files = Set.new
    @processed_locations = Set.new
    @current_class_context = nil
  end

  def analyze
    Find.find(@directory_path) do |path|
      next unless File.file?(path) && path.end_with?('.rb')

      begin
        code = File.read(path)
        buffer = Parser::Source::Buffer.new(path)
        buffer.source = code
        parser = Parser::CurrentRuby.new
        ast = parser.parse(buffer)

        unless ast
          puts "Failed to parse #{path}" if @debug
          next
        end

        @analyzed_files << path
        process_node(ast, path)
      rescue Parser::SyntaxError => e
        puts "Syntax error in #{path}: #{e.message}"
      rescue StandardError => e
        puts "Error processing #{path}: #{e.message}"
        puts e.backtrace.join("\n") if @debug
      end
    end

    self
  end

  def process_node(node, file_path, class_context = nil)
    return unless node.is_a?(Parser::AST::Node)

    @current_class_context = class_context
    return unless node.location # Skip if no location information

    location_key = "#{file_path}:#{node.location.line}:#{node.type}"
    return if @processed_locations.include?(location_key)

    puts "Processing #{node.type} at #{file_path}:#{node.location.line}" if @debug

    case node.type
    when :class
      class_name = node.children[0]&.children&.[](1)
      return unless class_name # Skip if no valid class name

      inherited_from = node.children[1]&.children&.last
      @classes[class_name] ||= []
      unless @classes[class_name].any? { |loc| loc[:file] == file_path && loc[:line] == node.location.line }
        @classes[class_name] << {
          file: file_path,
          line: node.location.line,
          inherited_from: [inherited_from].compact
        }
      end
      @classes_used << inherited_from if inherited_from
      process_node(node.children[2], file_path, class_name) if node.children[2]

    when :module
      module_name = node.children[0]&.children&.[](1)
      return unless module_name

      @modules[module_name] ||= []
      unless @modules[module_name].any? { |loc| loc[:file] == file_path && loc[:line] == node.location.line }
        @modules[module_name] << {
          file: file_path,
          line: node.location.line
        }
      end
      process_node(node.children[1], file_path, class_context) if node.children[1]

    when :def
      method_name = node.children[0]
      return unless method_name

      @methods_defined[method_name] ||= []
      method_location = {
        file: file_path,
        line: node.location.line,
        class_context: class_context
      }
      @methods_defined[method_name] << method_location unless @methods_defined[method_name].any? do |loc|
        loc[:file] == file_path && loc[:line] == node.location.line
      end

    when :send
      method_name = node.children[1]
      @methods_called << method_name if method_name

      if node.children[1] == :new && node.children[0]&.type == :const
        @classes_used << node.children[0].children[1]
      end

    when :const
      const_name = node.children[1]
      if const_name
        @classes_used << const_name
        @modules_used << const_name
      end

    when :casgn
      const_name = node.children[1]
      @classes_used << const_name if const_name

    when :block
      if node.children[0]&.type == :send
        receiver = node.children[0].children[0]
        method = node.children[0].children[1]
        if method == :new && receiver&.type == :const
          @classes_used << receiver.children[1]
        end
      end
    end

    @processed_locations << location_key

    node.children.each do |child|
      process_node(child, file_path, class_context) if child.is_a?(Parser::AST::Node)
    end

    @current_class_context = nil if [:class, :module].include?(node.type)
  end

  def unused_methods
    unused = {}
    @methods_defined.each do |method_name, locations|
      next if method_name == :initialize

      unless @methods_called.include?(method_name)
        unused[method_name] = locations
      end
    end
    unused
  end

  def unused_classes
    unused = {}
    @classes.each do |class_name, locations|
      unless @classes_used.include?(class_name)
        unused[class_name] = locations
      end
    end
    unused
  end

  def unused_modules
    unused = {}
    @modules.each do |module_name, locations|
      unless @modules_used.include?(module_name) || @classes_used.include?(module_name)
        unused[module_name] = locations
      end
    end
    unused
  end

  def report(options = { unused_only: true })
    full_report = {
      analyzed_files: @analyzed_files.to_a,
      classes: @classes,
      modules: @modules,
      methods_defined: @methods_defined,
      methods_called: @methods_called.to_a.sort,
      unused_methods: unused_methods,
      unused_classes: unused_classes,
      unused_modules: unused_modules
    }

    return full_report unless options[:unused_only]

    {
      unused_methods: unused_methods,
      unused_classes: unused_classes,
      unused_modules: unused_modules
    }
  end

  def print_report(options = { unused_only: true })
    report_data = report(options)

    puts "\nCode Analysis Report"
    puts "==================="

    if options[:unused_only]
      puts "Unused methods (#{report_data[:unused_methods].length}):"
      if report_data[:unused_methods].empty?
        puts "  None found"
      else
        report_data[:unused_methods].each do |method_name, locations|
          puts "\n  #{method_name}:"
          locations.each do |loc|
            context = loc[:class_context] ? " (in #{loc[:class_context]})" : ""
            puts "    #{loc[:file]}:#{loc[:line]}#{context}"
          end
        end
      end

      puts "\nUnused classes (#{report_data[:unused_classes].length}):"
      if report_data[:unused_classes].empty?
        puts "  None found"
      else
        report_data[:unused_classes].each do |class_name, locations|
          puts "\n  #{class_name}:"
          locations.each do |loc|
            inherited = loc[:inherited_from].empty? ? "" : " (inherits #{loc[:inherited_from].join(', ')})"
            puts "    #{loc[:file]}:#{loc[:line]}#{inherited}"
          end
        end
      end

      puts "\nUnused modules (#{report_data[:unused_modules].length}):"
      if report_data[:unused_modules].empty?
        puts "  None found"
      else
        report_data[:unused_modules].each do |module_name, locations|
          puts "\n  #{module_name}:"
          locations.each { |loc| puts "    #{loc[:file]}:#{loc[:line]}" }
        end
      end
    else
      # Full report implementation remains the same
      puts "Analyzed files (#{report_data[:analyzed_files].length}):"
      report_data[:analyzed_files].each { |file| puts "  #{file}" }

      puts "\nClasses found (#{report_data[:classes].length}):"
      report_data[:classes].each do |c, locs|
        puts "  #{c}:"
        locs.each do |loc|
          inherited = loc[:inherited_from].empty? ? "" : " (inherits #{loc[:inherited_from].join(', ')})"
          puts "    #{loc[:file]}:#{loc[:line]}#{inherited}"
        end
      end

      puts "\nModules found (#{report_data[:modules].length}):"
      report_data[:modules].each do |m, locs|
        puts "  #{m}:"
        locs.each { |loc| puts "    #{loc[:file]}:#{loc[:line]}" }
      end

      puts "\nMethods defined (#{report_data[:methods_defined].length}):"
      report_data[:methods_defined].each do |m, locs|
        puts "  #{m}:"
        locs.each do |loc|
          context = loc[:class_context] ? " (in #{loc[:class_context]})" : ""
          puts "    #{loc[:file]}:#{loc[:line]}#{context}"
        end
      end

      puts "\nMethods called (#{report_data[:methods_called].length}):"
      report_data[:methods_called].each { |m| puts "  #{m}" }

      puts "\nUnused methods (#{report_data[:unused_methods].length}):"
      report_data[:unused_methods].each do |m, locs|
        puts "  #{m}:"
        locs.each do |loc|
          context = loc[:class_context] ? " (in #{loc[:class_context]})" : ""
          puts "    #{loc[:file]}:#{loc[:line]}#{context}"
        end
      end

      puts "\nUnused classes (#{report_data[:unused_classes].length}):"
      report_data[:unused_classes].each do |c, locs|
        puts "  #{c}:"
        locs.each do |loc|
          inherited = loc[:inherited_from].empty? ? "" : " (inherits #{loc[:inherited_from].join(', ')})"
          puts "    #{loc[:file]}:#{loc[:line]}#{inherited}"
        end
      end

      puts "\nUnused modules (#{report_data[:unused_modules].length}):"
      report_data[:unused_modules].each do |m, locs|
        puts "  #{m}:"
        locs.each { |loc| puts "    #{loc[:file]}:#{loc[:line]}" }
      end
    end
  end
end

if ARGV.empty?
  puts "Please provide a directory path to analyze"
  puts "Usage: ruby code_analyzer.rb /path/to/directory [--full] [--debug]"
else
  options = {
    unused_only: !ARGV.include?('--full'),
    debug: ARGV.include?('--debug')
  }
  analyzer = CodeAnalyzer.new(ARGV[0], debug: options[:debug]).analyze
  analyzer.print_report(options)
end
