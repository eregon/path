require File.expand_path('../../spec_helper', __FILE__)

describe 'Path : FileUtils' do
  it 'mkpath', :tmpchdir do
    Path('a/b/c/d').mkpath.should be_a_directory
  end

  it 'rmtree', :tmpchdir do
    Path('a/b/c/d').mkpath.exist?.should be_true
    Path('a').rmtree.exist?.should be_false
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
    file.exist?.should be_false
    file.touch
    file.exist?.should be_true
    file.size.should == 0
  end

  it 'touch!', :tmpchdir do
    Path('foo/bar/baz.rb').touch!.should be_exist
  end
end
