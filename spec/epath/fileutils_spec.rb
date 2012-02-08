require File.expand_path('../../spec_helper', __FILE__)

describe 'Path : FileUtils' do
  it 'mkpath', :tmpchdir do
    Path('a/b/c/d').mkpath.should be_a_directory
  end

  it 'rmtree', :tmpchdir do
    Path('a/b/c/d').mkpath.should exist
    Path('a').rmtree.should_not exist
  end

  it 'mkdir_p, rm_rf' do
    Path.tmpdir do |dir|
      d = (dir/:test/:mkdir)
      d.mkdir_p.should equal d
      test = d.parent
      test.rm_rf.should equal test
    end
  end

  it 'rm, rm_f', :tmpchdir do
    f = Path('f')
    f.rm_f

    f.touch.should exist
    f.rm.should_not exist

    f.touch.rm_f.should_not exist
  end

  it 'touch', :tmpchdir do
    file = Path('file')
    file.should_not exist
    file.touch
    file.should exist
    file.should be_empty
  end

  it 'touch!', :tmpchdir do
    Path('foo/bar/baz.rb').touch!.should exist
    Path('foo').should be_a_directory
    Path('foo/bar').should be_a_directory
    Path('foo/bar/baz.rb').should be_a_file
    Path('foo/bar/baz.rb').should be_empty
  end
end
