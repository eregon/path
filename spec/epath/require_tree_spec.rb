require File.expand_path('../../spec_helper', __FILE__)

describe 'Path#require_tree' do
  around(:each) do |example|
    Path.tmpchdir('path-test') do
      %w[foo/foo1.rb foo/foo2.rb bar.rb].map(&Path).each(&:touch!)
      example.run
    end
  end

  let(:features) { $LOADED_FEATURES }

  specify 'given directory' do
    expect { Path.require_tree 'foo' }.to change { features.size }.by 2
  end

  specify 'default directory' do
    expect {
      Path('bar.rb').write('Path.require_tree')
      require Path('bar.rb').expand
    }.to change { features.size }.by 3
  end

  specify 'epath directory' do
    expect { Path['foo'].require_tree }.to change { features.size }.by 2
  end
end
