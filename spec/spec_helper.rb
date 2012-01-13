require File.expand_path('../../lib/epath', __FILE__)

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
end
