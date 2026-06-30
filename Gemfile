# frozen_string_literal: true

source 'https://rubygems.org'

# documentation
gem 'yard'

# Locatization
gem 'i18n', '~> 1.14'

gem 'logger'

# Browser-playable POC (bin/play_web.rb). Pure-Ruby stdlib HTTP server, no
# native dependencies. Kept in its own group so the core build/tests are
# unaffected.
group :web do
  gem 'webrick', '~> 1.9'
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
