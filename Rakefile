desc "Run specs"
task(:spec) do
  require 'rspec'
  exit RSpec::Core::Runner.run(%w[--format documentation --color spec])
end

task :default => [:spec]
