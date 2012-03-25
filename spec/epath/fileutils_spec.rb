require 'spec_helper'

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

  it 'cp, copy', :tmpchdir do
    f, g, h = Path('f'), Path('g'), Path('h')
    f.write 'cp'

    f.cp('g')
    g.read.should == 'cp'
    g.stat.mode.should == f.stat.mode

    f.chmod 0755
    f.cp h
    h.read.should == 'cp'
    h.stat.mode.should == f.stat.mode
  end

  it 'cp_r' do
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

  it 'touch', :tmpchdir do
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

  it 'touch!', :tmpchdir do
    Path('foo/bar/baz.rb').touch!.should exist
    Path('foo').should be_a_directory
    Path('foo/bar').should be_a_directory
    Path('foo/bar/baz.rb').should be_a_file
    Path('foo/bar/baz.rb').should be_empty
  end
end
