source 'https://rubygems.org'

gem 'chef', '~> 11'
gem 'knife-essentials'
gem 'knife-spork'
gem 'knife-solve'

group :development do
  gem 'berkshelf', '~> 3'
  #gem 'vagrant',   github: 'mitchellh/vagrant'
  gem 'strainer', '~> 3'
end

group :plugins do
  gem 'vagrant-berkshelf', '~> 2'
  gem 'vagrant-omnibus', '~> 1'
end

group :lint do
  gem 'foodcritic', '~> 3'
  gem 'rubocop', '~> 0'
end

group :kitchen do
  gem 'test-kitchen', '~> 1'
  gem 'kitchen-vagrant'
  gem 'serverspec'
end

# group :unit do
#   gem 'chefspec', '~> 3'
# end

