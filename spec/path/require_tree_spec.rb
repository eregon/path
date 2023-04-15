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
    -> {
      (dir/'bar.rb').write('Path.require_tree')
      require dir/:bar
    }.should change { features.size }.by 5

    %w[baz.rb
       foo.rb
       foo/foo1.rb
       foo/foo2.rb
       bar.rb].map { |rel| dir/rel }.should be_required_in_order
  end

  it 'given directory' do
    -> {
      (dir/'bar.rb').write('Path.require_tree "foo"')
      require dir/:bar
    }.should change { features.size }.by 3

    %w[foo/foo1.rb
       foo/foo2.rb
       bar.rb].map { |rel| dir/rel }.should be_required_in_order
  end

  it 'default directory and :except prefix' do
    -> {
      (dir/'bar.rb').write('Path.require_tree(:except => %w[foo])')
      require dir/:bar
    }.should change { features.size }.by 2

    %w[baz.rb bar.rb].map { |rel| dir/rel }.should be_required_in_order
  end

  it 'default directory and :except dir' do
    -> {
      (dir/'bar.rb').write('Path.require_tree(:except => %w[foo/])')
      require dir/:bar
    }.should change { features.size }.by 3

    %w[baz.rb foo.rb bar.rb].map { |rel| dir/rel }.should be_required_in_order
  end

  it 'given directory and :except prefix' do
    -> {
      (dir/'bar.rb').write('Path.require_tree(".", :except => %w[foo])')
      require dir/:bar
    }.should change { features.size }.by 2

    %w[baz.rb bar.rb].map { |rel| dir/rel }.should be_required_in_order
  end

  it 'given directory and :except dir' do
    -> {
      (dir/'bar.rb').write('Path.require_tree(".", :except => %w[foo/])')
      require dir/:bar
    }.should change { features.size }.by 3

    %w[baz.rb foo.rb bar.rb].map { |rel| dir/rel }.should be_required_in_order
  end
end
