require File.expand_path('../../spec_helper', __FILE__)

describe 'Path : File' do
  dosish_drive_letter = File.dirname('A:') == 'A:.'

  it 'atime, ctime, mtime' do
    Path(__FILE__).atime.should be_kind_of Time
    Path(__FILE__).ctime.should be_kind_of Time
    Path(__FILE__).mtime.should be_kind_of Time
  end

  it 'chmod', :tmpchdir do
    path = Path('a')
    path.write 'abc'
    old = path.stat.mode
    path.chmod(0444)
    (path.stat.mode & 0777).should == 0444
    path.chmod(old)
  end

  it 'lchmod', :tmpchdir, :symlink, :fails_on => [:rbx, :rbx19, :jruby] do
    Path('a').write 'abc'
    path = Path('l').make_symlink('a')
    old = path.lstat.mode
    begin
      path.lchmod(0444)
    rescue NotImplementedError
      next
    end
    (path.lstat.mode & 0777).should == 0444
    path.chmod(old)
  end

  it 'chown', :tmpchdir, :fails_on => [:rbx, :rbx19, :jruby, :jruby19] do
    path = Path('a')
    path.write 'abc'
    old_uid = path.stat.uid
    old_gid = path.stat.gid
    begin
      path.chown(0, 0)
    rescue Errno::EPERM
      next
    end
    path.stat.uid.should == 0
    path.stat.gid.should == 0
    path.chown(old_uid, old_gid)
  end

  it 'lchown', :tmpchdir, :symlink, :fails_on => [:rbx, :rbx19, :jruby] do
    Path('a').write 'abc'
    path = Path('l').make_symlink('a')
    old_uid = path.stat.uid
    old_gid = path.stat.gid
    begin
      path.lchown(0, 0)
    rescue Errno::EPERM
      next
    end
    path.stat.uid.should == 0
    path.stat.gid.should == 0
    path.lchown(old_uid, old_gid)
  end

  it 'ftype', :tmpchdir do
    f = Path('f')
    f.write 'abc'
    f.ftype.should == 'file'

    Path('d').mkdir.ftype.should == 'directory'
  end

  it 'make_link', :tmpchdir, :fails_on => [:jruby, :jruby19] do
    Path('a').write 'abc'
    Path('l').make_link('a').read.should == 'abc'
  end

  it 'readlink', :tmpchdir, :symlink, :fails_on => [:jruby] do
    a = Path('a')
    a.write 'abc'
    Path('l').make_symlink(a).readlink.should == a
  end

  it 'rename', :tmpchdir do
    a = Path('a')
    a.write 'abc'
    a.rename('b')
    Path('b').read.should == 'abc'
  end

  it 'stat', :tmpchdir do
    a = Path('a')
    a.write 'abc'
    a.stat.size.should == 3
  end

  it 'lstat', :tmpchdir, :symlink do
    a = Path('a')
    a.write 'abc'
    path = Path('l').make_symlink(a)
    path.lstat.should be_a_symlink
    path.stat.should_not be_a_symlink
    path.stat.size.should == 3
    a.lstat.should_not be_a_symlink
    a.lstat.size.should == 3
  end

  it 'size', :tmpchdir do
    f = Path('f')
    f.write 'abc'
    f.size.should == 3

    Path('z').touch.size.should == 0
    lambda { Path('not-exist').size }.should raise_error(Errno::ENOENT)
  end

  it 'make_symlink', :tmpchdir, :symlink do
    Path('a').write 'abc'
    Path('l').make_symlink('a').lstat.should be_a_symlink
  end

  it 'truncate', :tmpchdir do
    a = Path('a')
    a.write 'abc'
    a.truncate 2
    a.size.should == 2
    a.read.should == 'ab'
  end

  it 'utime', :tmpchdir do
    a = Path('a')
    a.write 'abc'
    atime, mtime = Time.utc(2000), Time.utc(1999)
    a.utime(atime, mtime)
    a.stat.atime.should == atime
    a.stat.mtime.should == mtime
  end

  it 'expand, expand_path' do
    r = dosish_drive_letter ? Dir.pwd.sub(/\/.*/, '') : ''
    Path('/a').expand_path.to_s.should == r+'/a'
    Path('a').expand('/').to_s.should == r+'/a'
    Path('a').expand(Path('/')).to_s.should == r+'/a'
    Path('/b').expand(Path('/a')).to_s.should == r+'/b'
    Path('b').expand(Path('/a')).to_s.should == r+'/a/b'
  end
end
