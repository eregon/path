require File.expand_path('../../lib/epath', __FILE__)

dosish = File::ALT_SEPARATOR != nil

has_symlink = true
Path.tmpdir do |dir|
  begin
    File.symlink('a', "#{dir}/l")
  rescue NotImplementedError
    has_symlink = false
  end
end

ruby = (defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby').to_sym
ruby = :"#{ruby}19" if RUBY_VERSION > '1.9'
ruby = nil if $DEBUG

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.around(:each, :tmpchdir) { |example|
    Path.tmpchdir('path-test') do |dir|
      example.run
    end
  }

  config.filter_run_excluding :ruby => lambda { |version|
    version and RUBY_VERSION < version.to_s
  }
  config.filter_run_excluding :symlink => !has_symlink
  config.filter_run_excluding :unix => dosish
  config.filter_run_excluding :fails_on => lambda { |implementations|
    implementations and implementations.include? ruby
  }
end
