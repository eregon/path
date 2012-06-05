require 'spec_helper'

this = Path(__FILE__).expand
root = Path(File.expand_path('../..',__FILE__))
lib = Path(File.expand_path('../../lib',__FILE__))
lib_epath = Path(File.expand_path('../../lib/epath.rb',__FILE__))
spec = Path(File.expand_path('..',__FILE__))

describe Path do
  it '%, relative_to' do
    :%.should be_an_alias_of :relative_to
    Path('/a/b/Array/sort.rb').relative_to(Path('/')).should == Path('a/b/Array/sort.rb')
    Path('/a/b/Array/sort.rb').relative_to(Path('/a/b')).should == Path('Array/sort.rb')
    Path('/a/b/Array/sort.rb').relative_to(Path('/a/b/')).should == Path('Array/sort.rb')
  end

  it 'parent' do
    Path('a/b/c').parent.should == Path('a/b')
    Path('a').parent.should == Path('.')
    Path('.').parent.should == Path('..')
    Path('..').parent.should == Path('../..')
    Path('../..').parent.should == Path('../../..')
    Path('../a').parent.should == Path('..')
  end

  it 'here, file, dir' do
    Path.method(:here).should == Path.method(:file)
    # Test caller parsing
    file = Path('dir/file.rb').expand
    # MRI 1.8
    Path.file(["dir/file.rb:7"]).should == file
    Path.file(["dir/file.rb:2:in `meth'", "dir/file.rb:8"]).should == file
    # MRI 1.9
    Path.file(["dir/file.rb:7:in `<main>'"]).should == file
    Path.file(["dir/file.rb:2:in `meth'", "dir/file.rb:8:in `<main>'"]).should == file
    # Rubinius 1.8 & 1.9
    Path.file(["dir/file.rb:7:in `__script__'"]).should == file
    Path.file(["dir/file.rb:2:in `meth'", "dir/file.rb:8:in `__script__'"]).should == file
    # JRuby 1.8 & 1.9
    Path.file(["dir/file.rb:7:in `(root)'"]).should == file
    Path.file(["dir/file.rb:2:in `meth'", "dir/file.rb:8:in `(root)'"]).should == file

    # evil file names
    file = Path('dir/a:32').expand
    Path.file(["dir/a:32:7:in `<main>'"]).should == file
    Path.file(["dir/a:32:2:in `meth'", "dir/a:32:8:in `<main>'"]).should == file

    file = Path('dir/a:32:in').expand
    Path.file(["dir/a:32:in:7:in `<main>'"]).should == file
    Path.file(["dir/a:32:in:2:in `meth'", "dir/a:32:in:8:in `<main>'"]).should == file

    file = Path('dir/a:32:in ').expand
    Path.file(["dir/a:32:in :7:in `<main>'"]).should == file
    Path.file(["dir/a:32:in :2:in `meth'", "dir/a:32:in :8:in `<main>'"]).should == file

    Path.file.should == Path(__FILE__).expand
    Path.dir.should == Path(File.dirname(__FILE__)).expand
  end

  it 'relative' do
    Path.relative('epath_spec.rb').should == this
    Path.relative('..').should == root
    Path.relative('../spec').should == spec
    Path.relative('../lib/epath.rb').should == lib_epath
  end

  it '~, home' do
    Path.method(:~).should == Path.method(:home)
    Path.home.should == Path('~').expand # fails on JRuby 1.9 as Dir.home gives backslashes (only / on MRI)
  end

  it '~(user), home(user) (unix)', :unix do
    Path.~(Etc.getlogin).should == Path('~').expand
  end

  context 'inside?' do
    it 'works when paths are related' do
      this.inside?(this).should be_true
      this.inside?(spec).should be_true
      this.inside?(root).should be_true
      spec.inside?(this).should be_false
    end

    it 'works when paths are not related' do
      Path('/etc/passwd').inside?(spec).should be_false
    end

    it 'accepts a string' do
      this.inside?(spec.to_s).should be_true
    end

    it 'is negated as outside?' do
      this.outside?(root).should be_false
      spec.outside?(this).should be_true
    end
  end

  context 'backfind' do
    it 'simple' do
      Path.here.backfind('Rakefile').should == Path.relative('../Rakefile').expand
      Path.here.backfind('lib/epath.rb').should == lib_epath
      (Path.dir/'x/y/z').backfind('lib/epath.rb').should == lib_epath
      (Path.dir/'x/y/z').backfind('lib/nothin/such.rb').should be_nil
      Path('x/y/z').backfind('lib/nothin/such.rb').should be_nil # relative paths should work too
    end

    it 'class method' do
      Path.backfind('lib/epath.rb').should == lib_epath
    end

    it 'with xpath-like context' do
      Path.backfind('lib[epath.rb]').should == lib
      Path.backfind('.[.git]').should == root
      (Path.dir/'x/y/z').backfind('.[.git]').should == root
    end
  end

  it 'tmpfile' do
    tmpfile = nil
    Path.tmpfile do |file|
      tmpfile = file
      tmpfile.should exist
      tmpfile.write 'foo'
      tmpfile.read.should == 'foo'
    end
    tmpfile.should_not exist
  end

  it 'tmpdir' do
    tmpdir = nil
    Path.tmpdir do |dir|
      tmpdir = dir
      tmpdir.should exist
      (dir/:file).write 'foo'
      (dir/:file).read.should == 'foo'
    end
    # TODO: This may be delayed a bit, notably on JRuby
    # tmpdir.should_not exist
  end

  it 'tmpchdir', :fails_on => [:rbx] do
    Path.tmpchdir do |dir|
      dir.should be_identical(Path.getwd)
    end
  end
end
