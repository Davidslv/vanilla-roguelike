#!/usr/bin/env ruby

# Combines Ruby files into a single file
# Usage:
#   - Run without arguments: combines all .rb files in default directory
#   - Pass file paths as arguments: combines only specified files

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
default_directory = "/Users/davidslv/projects/vanilla/lib"
bin_play_location = "/Users/davidslv/projects/vanilla/bin/play.rb"

# Check if arguments were provided
if ARGV.empty?
  # No arguments: combine all files from default directory plus bin/play.rb
  files = Dir.glob("#{default_directory}/**/*.rb")
  files.append(bin_play_location)
  combine_files(output_file, files)
else
  # Arguments provided: combine only specified files
  combine_files(output_file, ARGV)
end
