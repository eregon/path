require File.expand_path('../../lib/epath', __FILE__)

dosish = File::ALT_SEPARATOR != nil

has_symlink = begin
  File.symlink(nil, nil)
rescue NotImplementedError
  false
rescue TypeError
  true
end

ruby = (defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby').to_sym

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.around(:each, :tmpchdir) { |example|
    Path.tmpdir('path-test') do |dir|
      dir = dir.realpath
      dir.chdir do
        example.run
      end
    end
  }

  config.filter_run_excluding :symlink => has_symlink
  config.filter_run_excluding :unix => !dosish
  config.filter_run_excluding :fails_on => lambda { |implementations|
    implementations.include? ruby
  }
end
