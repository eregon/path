require File.expand_path('../lib/path/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'path'
  s.summary = 'The Path manipulation library'
  s.description = 'Path is a library to easily manage paths and with a lot of extra goodness.'
  s.author = 'eregon'
  s.email = 'eregontp@gmail.com'
  s.homepage = 'https://github.com/eregon/path'
  s.files = Dir['lib/**/*.rb'] + %w[README.md LICENSE path.gemspec]
  s.version = Path::VERSION

  s.add_development_dependency 'rspec'
end
