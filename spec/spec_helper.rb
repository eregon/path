if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_group 'lib', 'lib'
    add_group 'spec', 'spec'
  end
end

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

tmpdir = Path.tmpdir('path-test')

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.around(:each, :tmpchdir) { |example|
    tmpdir.chdir do
      example.run
      tmpdir.each_child(&:rm_r)
    end
  }

  unless ENV['TRAVIS'] and RUBY_DESCRIPTION =~ /^jruby/ # bugged on TravisCI
    config.after(:suite) {
      FileUtils.remove_entry_secure tmpdir
    }
  end

  config.filter_run_excluding :ruby => lambda { |version|
    version and RUBY_VERSION < version.to_s
  }
  config.filter_run_excluding :symlink => !has_symlink
  config.filter_run_excluding :unix => dosish
  config.filter_run_excluding :fails_on => lambda { |implementations|
    implementations and implementations.include? ruby
  }
end

RSpec::Matchers.define :exist do
  match do |actual|
    actual.exist?
  end
end
