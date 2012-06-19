require 'spec_helper'

describe 'Path#require_tree' do
  around(:each) do |example|
    Path.tmpdir('path-require-tree') do |dir|
      @dir = dir
      files.each(&:touch!)
      example.run
    end
  end

  let(:dir) { @dir }
  let(:files) {
    %w[bar.rb
       baz.rb
       foo.rb
       foo/foo1.rb
       foo/foo2.rb
      ].map { |path| dir/path }
  }
  let(:features) { $LOADED_FEATURES }

  it 'default directory' do
    expect {
      (dir/'bar.rb').write('Path.require_tree')
      require dir/:bar
    }.to change { features.size }.by 5

    features.last(5).map { |path|
      Path(path) % dir
    }.should == %w[
      baz.rb
      foo.rb
      foo/foo1.rb
      foo/foo2.rb
      bar.rb
    ].map(&Path)
  end

  it 'given directory' do
    expect {
      (dir/'bar.rb').write('Path.require_tree "foo"')
      require dir/:bar
    }.to change { features.size }.by 3

    features.last(3).map { |path|
      Path(path) % dir
    }.should == %w[foo/foo1.rb foo/foo2.rb bar.rb].map(&Path)
  end
end
