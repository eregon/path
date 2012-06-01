require 'spec_helper'

describe 'Path : FileUtils', :tmpchdir do
  it 'mkpath' do
    Path('a/b/c/d').mkpath.should be_a_directory
  end

  it 'rmtree' do
    Path('a/b/c/d').mkpath.should exist
    Path('a').rmtree.should_not exist
  end

  it 'mkdir_p, rm_r, rm_rf', :tmpchdir => false do
    Path.tmpdir do |dir|
      d = (dir/:test/:mkdir)
      d.mkdir_p.should equal d
      test = d.parent
      test.rm_r.should equal test
      test.rm_rf.should equal test
    end
  end

  it 'rm, rm_f' do
    f = Path('f')
    f.rm_f

    f.touch.should exist
    f.rm.should_not exist

    f.touch.rm_f.should_not exist
  end

  it 'cp, copy' do
    f, g, h = Path('f'), Path('g'), Path('h')
    f.write 'cp'

    f.cp('g')
    g.read.should == 'cp'
    g.stat.mode.should == f.stat.mode

    f.chmod 0444
    (f.stat.mode & 0777).should == 0444
    f.cp h
    h.read.should == 'cp'
    (h.stat.mode & 0777).should == 0444
  end

  it 'cp_r', :tmpchdir => false do
    Path.tmpdir do |dir|
      from = dir/:test
      d = (from/:mkdir).mkdir_p
      (d/:file).touch
      (from/:root).touch

      to = dir/'to'
      from.cp_r to
      to.should exist
      to.should be_a_directory
      (to/:root).should exist
      (to/:mkdir).should be_a_directory
      (to/:mkdir/:file).should be_a_file
    end
  end

  it 'touch' do
    file = Path('file')
    expect { file.touch }.to change { file.exist? }.from(false).to(true)
    file.should be_empty

    old, now = Time.utc(2000), Time.now
    file.utime(old, old)
    file.atime.should be_within(1).of(old)
    file.mtime.should be_within(1).of(old)
    file.touch
    file.atime.should be_within(1).of(now)
    file.mtime.should be_within(1).of(now)
  end

  it 'touch!' do
    Path('foo/bar/baz.rb').touch!.should exist
    Path('foo').should be_a_directory
    Path('foo/bar').should be_a_directory
    Path('foo/bar/baz.rb').should be_a_file
    Path('foo/bar/baz.rb').should be_empty
  end

  it 'mv, move' do
    f, g = Path('f'), Path('g')
    f.write 'mv'
    f.mv g
    f.should_not exist
    g.should exist
    g.read.should == 'mv'

    d = Path('d').mkdir
    file = (d/:file).touch
    d.mv('e')
    (Path('e')/:file).should exist
  end

  it 'install' do
    f = Path('f').touch
    prefix = Path('prefix').mkdir
    prefix.install f
    installed = prefix/:f
    installed.should exist
    f.write 'ab'
    installed.should be_empty
    prefix.install f
    installed.read.should == 'ab'
  end

  it 'same_contents?' do
    f, g = Path('f'), Path('g')
    f.write 'f'
    f.cp g
    f.should have_same_contents('g')
  end

  it 'uptodate?' do
    f = Path('f').touch
    g = Path('g').touch
    older = f.mtime-1
    g.utime(older, older)
    f.should be_uptodate(g)
    newer = f.mtime+1
    g.utime(newer, newer)
    f.should_not be_uptodate(g)
  end
end
