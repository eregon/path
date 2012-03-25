if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_group 'lib', 'lib'
    add_group 'spec', 'spec'
  end
end

require File.expand_path('../../lib/epath', __FILE__)
require 'yaml'

dosish = File::ALT_SEPARATOR != nil
dosish_drive = File.dirname('A:') == 'A:.'
unc = File.dirname('//') == '//'

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
    if example.metadata[:tmpchdir]
      tmpdir.chdir do
        example.run
        tmpdir.each_child(&:rm_r)
      end
    else
      example.run
    end
  }

  unless ENV['TRAVIS'] and RUBY_DESCRIPTION.start_with?('jruby') # bugged on TravisCI
    config.after(:suite) {
      FileUtils.remove_entry_secure tmpdir
    }
  end

  config.filter_run_excluding :ruby => lambda { |version|
    RUBY_VERSION < version.to_s
  }
  config.filter_run_excluding :symlink => !has_symlink
  config.filter_run_excluding :unix => dosish
  config.filter_run_excluding :dosish => !dosish
  config.filter_run_excluding :dosish_drive => !dosish_drive
  config.filter_run_excluding :unc => !unc
  config.filter_run_excluding :fails_on => lambda { |implementations|
    implementations.include? ruby
  }
end
