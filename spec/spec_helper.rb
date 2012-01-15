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

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.around(:each, :tmpchdir) { |example|
    Path.tmpdir('path-test') do |dir|
      dir.chdir do
        example.run
      end
    end
  }

  config.filter_run_excluding :ruby => lambda { |version|
    RUBY_VERSION < version.to_s
  }
  config.filter_run_excluding :symlink => !has_symlink
  config.filter_run_excluding :unix => dosish
  config.filter_run_excluding :fails_on => lambda { |implementations|
    implementations.include? ruby
  }
end
