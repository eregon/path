desc "Run specs"
task(:spec) do
  require 'rspec'
  exit RSpec::Core::Runner.run(%w[--color .])
end

task :default => [:spec]
