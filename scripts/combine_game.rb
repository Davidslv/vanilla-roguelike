#!/usr/bin/env ruby

# Combines Ruby files into a single file
# Usage:
#   - Run without arguments: combines all .rb files in default directory + bin/play.rb
#   - Pass file paths as arguments: combines only specified files
#   - Use --folder PATH or -f PATH: combines all .rb files in specified folder

require 'optparse'

def combine_files(output_filename, file_list)
  File.open(output_filename, "w") do |output|
    puts "Files to combine: #{file_list.size}"

    file_list.each do |filename|
      next unless File.exist?(filename)
      next if filename == "./#{File.basename(__FILE__)}" # Skip this merger script
      next if filename == "./#{output_filename}" # Skip the output file

      output.puts "# Begin #{filename}"
      output.puts File.read(filename)
      output.puts "# End #{filename}"
      output.puts "\n"
    end
  end
  puts "Files merged into #{output_filename}"
end

# Default settings
output_file = "combined_game.rb"
default_directory = File.join(Dir.pwd, 'lib')
bin_play_location = File.join(Dir.pwd, 'bin', 'play.rb')

# Parse command-line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} [options] [files...]"

  opts.on("-f", "--folder PATH", "Specify a folder to combine all .rb files from") do |path|
    options[:folder] = path
  end
end.parse!

# Process based on arguments
if options[:folder]
  # Folder specified: combine all .rb files from that folder
  folder = options[:folder]
  unless Dir.exist?(folder)
    puts "Error: Directory '#{folder}' does not exist"
    exit 1
  end
  files = Dir.glob("#{folder}/**/*.rb")
  combine_files(output_file, files)
elsif ARGV.empty?
  # No arguments: combine all files from default directory plus bin/play.rb
  files = Dir.glob("#{default_directory}/**/*.rb")
  files.append(bin_play_location)
  combine_files(output_file, files)
else
  # Arguments provided: combine only specified files
  combine_files(output_file, ARGV)
end
