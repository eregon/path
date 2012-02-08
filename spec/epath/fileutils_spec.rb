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

  it 'touch', :tmpchdir do
    file = Path('file')
    file.should_not exist
    file.touch
    file.should exist
    file.size.should == 0
  end

  it 'touch!', :tmpchdir do
    Path('foo/bar/baz.rb').touch!.should exist
  end
end
