Gem::Specification.new do |s|
  s.name = 'epath'
  s.summary = 'a Path manipulation library'
  s.author = 'eregon'
  s.email = 'eregontp@gmail.com'
  s.homepage = 'https://github.com/eregon/epath'
  s.files = Dir['lib/**/*.rb'] + %w[README.md LICENSE epath.gemspec]
  s.version = '0.1.0'

  s.add_development_dependency 'rspec'
end
