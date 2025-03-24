# frozen_string_literal: true

# Combines all files in a lib directory into a single file

output_file = "combined_game.rb"
directory = "/Users/davidslv/projects/vanilla/lib" # Change this to your directory path if needed
bin_play_location = "/Users/davidslv/projects/vanilla/bin/play.rb"

File.open(output_file, "w") do |output|
  files = Dir.glob("#{directory}/**/*.rb")
  files.append(bin_play_location)

  puts "Files found: #{files.size}"

  files.each do |filename|
    next if filename == "./#{File.basename(__FILE__)}"  # Skip this merger script
    next if filename == "./#{output_file}"              # Skip the output file

    output.puts "# Begin #{filename}"
    output.puts File.read(filename)
    output.puts "# End #{filename}"
    output.puts "\n"
  end
end

puts "Files merged into #{output_file}"
