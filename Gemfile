source 'https://rubygems.org'

# documentation
gem 'yard'

# Locatization
gem "i18n", "~> 1.14"

gem 'logger'

group :test do
  gem 'rspec'
  gem 'simplecov', require: false
end

group :test, :development do
  gem 'pry'
  gem 'rubocop', require: false
end
group :development do
  gem 'ast'
  gem 'solargraph', require: false
  gem 'solargraph-rspec', require: false
end
