require 'spec_helper'

describe 'Path#require_tree' do
  around(:each) do |example|
    Path.tmpdir('path-require-tree') do |dir|
      %w[foo/foo1.rb
         foo/foo2.rb
         bar.rb
         baz.rb
        ].map { |path| (dir/path).touch! }
      @dir = dir
      example.run
    end
  end

  let(:dir) { @dir }
  let(:features) { $LOADED_FEATURES }

  it 'default directory' do
    expect {
      (dir/'bar.rb').write('Path.require_tree')
      require dir/:bar
    }.to change { features.size }.by 4
  end

  it 'given directory' do
    expect {
      (dir/'bar.rb').write('Path.require_tree "foo"')
      require dir/:bar
    }.to change { features.size }.by 3
  end
end
