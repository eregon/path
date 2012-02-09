require File.expand_path('../../spec_helper', __FILE__)

describe 'Path : File predicates' do
  let(:f) {
    f = Path('f')
    f.write 'abc'
    f
  }

  let(:d) { Path('d').mkdir }

  it 'blockdev?, chardev?', :tmpchdir do
    f.should_not be_a_blockdev
    f.should_not be_a_chardev
  end

  it 'executable?', :tmpchdir do
    f.should_not be_executable
  end

  it 'executable_real?', :tmpchdir do
    f.should_not be_executable_real
  end

  it 'exist?', :tmpchdir do
    f.should exist
    Path('not-exist').should_not exist
  end

  it 'grpowned?', :tmpchdir, :unix do
    f.chown(-1, Process.gid)
    f.should be_grpowned
  end

  it 'dir?, directory?', :tmpchdir do
    f.should_not be_a_directory
    d.should be_a_directory
    d.should be_a_dir
  end

  it 'file?', :tmpchdir do
    f.should be_a_file
    d.should_not be_a_file
  end

  it 'pipe?, socket?', :tmpchdir do
    f.should_not be_a_pipe
    f.should_not be_a_socket
  end

  it 'owned?', :tmpchdir do
    f.should be_owned
  end

  it 'readable?', :tmpchdir do
    f.should be_readable
  end

  it 'world_readable?', :tmpchdir, :unix do
    f.chmod 0400
    f.world_readable?.should be_nil
    f.chmod 0444
    f.world_readable?.should == 0444
  end

  it 'readable_real?', :tmpchdir do
    f.should be_readable_real
  end

  it 'setuid?, setgid?', :tmpchdir do
    f.should_not be_setuid
    f.should_not be_setgid
  end

  it 'size?', :tmpchdir do
    f.size?.should == 3

    Path('z').touch.size?.should be_nil

    Path('not-exist').size?.should be_nil
  end

  it 'sticky?', :tmpchdir, :unix do
    f.should_not be_sticky
  end

  it 'symlink?', :tmpchdir, :unix do
    f.should_not be_a_symlink
  end

  it 'writable?', :tmpchdir do
    f.should be_writable
  end

  it 'world_writable?', :tmpchdir, :unix do
    f.chmod 0600
    f.world_writable?.should be_nil
    f.chmod 0666
    f.world_writable?.should == 0666
  end

  it 'writable_real?', :tmpchdir do
    f.should be_writable_real
  end

  it 'zero?, empty?', :tmpchdir do
    f.should_not be_zero
    Path('z').touch.should be_zero
    Path('not-exist').should_not be_zero

    Path.tmpfile do |file|
      file.should be_empty
      file.write 'Hello World!'
      file.should_not be_empty
    end
  end

  it 'identical?', :tmpchdir, :fails_on => [:rbx] do
    a = Path('a').touch
    a.should be_identical(Path('a'))
    Path.getwd.should be_identical(Path('.'))
    Path('b').touch.should_not be_identical(a)
  end

  it 'fnmatch?' do
    Path('a').fnmatch?('*').should be_true
    Path('a').fnmatch?('*.*').should be_false
    Path('.foo').fnmatch?('*').should be_false
    Path('.foo').fnmatch?('*', File::FNM_DOTMATCH).should be_true
  end
end
