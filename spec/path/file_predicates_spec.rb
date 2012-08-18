require 'spec_helper'

describe 'Path : File predicates', :tmpchdir do
  let(:f) {
    f = Path('f')
    f.write 'abc'
    f
  }

  let(:d) { Path('d').mkdir }

  it 'blockdev?, chardev?' do
    f.should_not be_a_blockdev
    f.should_not be_a_chardev
  end

  it 'executable?' do
    f.should_not be_executable
  end

  it 'executable_real?' do
    f.should_not be_executable_real
  end

  it 'exist?' do
    f.should exist
    Path('not-exist').should_not exist
  end

  it 'grpowned?', :unix do
    f.chown(-1, Process.gid)
    f.should be_grpowned
  end

  it 'dir?, directory?' do
    :dir?.should be_an_alias_of :directory?
    f.should_not be_a_directory
    d.should be_a_directory
  end

  it 'file?' do
    f.should be_a_file
    d.should_not be_a_file
  end

  it 'pipe?, socket?' do
    f.should_not be_a_pipe
    f.should_not be_a_socket
  end

  it 'owned?' do
    f.should be_owned
  end

  it 'readable?' do
    f.should be_readable
  end

  it 'world_readable?', :unix do
    f.chmod 0400
    f.world_readable?.should be_nil
    f.chmod 0444
    f.world_readable?.should == 0444
  end

  it 'readable_real?' do
    f.should be_readable_real
  end

  it 'setuid?, setgid?' do
    f.should_not be_setuid
    f.should_not be_setgid
  end

  it 'size?' do
    f.size?.should == 3

    Path('z').touch.size?.should be_nil

    Path('not-exist').size?.should be_nil
  end

  it 'sticky?', :unix do
    f.should_not be_sticky
  end

  it 'symlink?', :unix do
    f.should_not be_a_symlink
  end

  it 'writable?' do
    f.should be_writable
  end

  it 'world_writable?', :unix do
    f.chmod 0600
    f.world_writable?.should be_nil
    f.chmod 0666
    f.world_writable?.should == 0666
  end

  it 'writable_real?' do
    f.should be_writable_real
  end

  it 'zero?, empty?' do
    :empty?.should be_an_alias_of :zero?
    f.should_not be_empty
    Path('z').touch.should be_empty
    Path('not-exist').should_not be_empty

    Path.tmpfile do |file|
      file.should be_empty
      file.write 'Hello World!'
      file.should_not be_empty
    end
  end

  it 'identical?' do
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
