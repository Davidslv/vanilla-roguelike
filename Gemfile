# frozen_string_literal: true

source 'https://rubygems.org'

# documentation
gem 'yard'

# Locatization
gem 'i18n', '~> 1.14'

gem 'logger'

# Optional graphical front-end (proof of concept). Not needed for the terminal
# game or the test suite. Requires SDL2 native libs (see bin/play_gui.rb).
# Install with: bundle install --with gui
group :gui, optional: true do
  gem 'ruby2d'
end

group :test do
  gem 'rspec'
  gem 'simplecov', require: false
end

group :test, :development do
  gem 'pry'
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
end
group :development do
  gem 'ast'
  gem 'solargraph', require: false
  gem 'solargraph-rspec', require: false
end
