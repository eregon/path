if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_group 'lib', 'lib'
    add_group 'spec', 'spec'
    command_name "RSpec with #{RUBY_DESCRIPTION} from user #{Process.euid}"
    merge_timeout 24*60*60 # 1 day timeout, so coverage can be run on Windows at ease
  end
end

require File.expand_path('../../lib/path', __FILE__)
require 'rspec'
require 'yaml'
require 'json'
require 'stringio'
require 'etc'

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

impl = (defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby').to_sym
ruby = RUBY_VERSION > '1.9' ? :"#{impl}19" : :"#{impl}18"
ruby, impl = nil, nil if $DEBUG

tmpdir = Path.tmpdir('path-test')

module PathSpecHelpers
  ACCUMULATOR = begin
    def (ary = []).to_proc
      clear
      lambda { |x| self << x }
    end
    ary
  end

  def accumulator
    ACCUMULATOR
  end

  def capture_io
    stdout, stderr = $stdout, $stderr
    $stdout, $stderr = StringIO.new, StringIO.new
    yield
    [$stdout.string, $stderr.string]
  ensure
    $stdout, $stderr = stdout, stderr
  end

  def verbosely(value = true)
    verbose = $VERBOSE
    $VERBOSE = value
    yield
  ensure
    $VERBOSE = verbose
  end

  def time_delta
    # Time zone seems to be lost on windows for file times
    (File::ALT_SEPARATOR != nil) ? Time.now.gmt_offset.abs + 1 : 1
  end
end

RSpec.configure do |config|
  config.include PathSpecHelpers

  config.expect_with(:rspec) { |c| c.syntax = :should }

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

  config.after(:suite) {
    FileUtils.remove_entry_secure tmpdir
  }

  config.filter_run_excluding :ruby => lambda { |version|
    RUBY_VERSION < version.to_s
  }
  config.filter_run_excluding :symlink => !has_symlink
  config.filter_run_excluding :unix => dosish
  config.filter_run_excluding :dosish => !dosish
  config.filter_run_excluding :dosish_drive => !dosish_drive
  config.filter_run_excluding :unc => !unc
  config.filter_run_excluding :fails_on => lambda { |rubies|
    rubies.include?(impl) or rubies.include?(ruby)
  }
end

RSpec::Matchers.define :be_an_alias_of do |expected|
  match do |actual|
    actual != expected and Path.instance_method(actual) == Path.instance_method(expected)
  end
end

RSpec::Matchers.define :be_required_in_order do
  match do |files|
    $LOADED_FEATURES.last(files.size) == files.map(&:to_s)
  end

  failure_message do |files|
    "Expected to load\n#{features.last(files.size) * "\n"}\nin this order\n#{files * "\n"}"
  end
end
