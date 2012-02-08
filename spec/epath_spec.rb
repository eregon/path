require File.expand_path('../spec_helper', __FILE__)

this = Path(__FILE__).expand
root = Path(File.expand_path('../..',__FILE__))
lib = Path(File.expand_path('../../lib',__FILE__))
lib_epath = Path(File.expand_path('../../lib/epath.rb',__FILE__))
spec = Path(File.expand_path('..',__FILE__))
spec_helper = Path(File.expand_path('../spec_helper.rb',__FILE__))

describe Path do
  it 'behaves like a path' do
    path = Path.new('/')
    [:to_s, :to_sym, :to_path].each do |meth|
      path.should respond_to meth
    end

    if RUBY_VERSION > '1.9'
      path.should_not respond_to :to_str
    else
      path.should respond_to :to_str
    end
  end

  it 'Path(), new, &Path' do
    Path.new('/').to_s.should == '/'
    Path('/usr', 'bin', 'ls').should == Path('/usr/bin/ls')
    (Path('/usr')/:bin/:ls).should == Path('/usr/bin/ls')
    Path(:path).to_s.should == 'path'

    path = Path.new('.')
    Path.new(path).should be path

    %w[foo bar].map(&Path).should == [Path('foo'), Path('bar')]
  end

  it '%, relative_to' do
    Path('/a/b/Array/sort.rb').relative_to(Path('/')).should == Path('a/b/Array/sort.rb')
    Path('/a/b/Array/sort.rb').relative_to(Path('/a/b')).should == Path('Array/sort.rb')
    Path('/a/b/Array/sort.rb').relative_to(Path('/a/b/')).should == Path('Array/sort.rb')
    (Path('/a/b/Array/sort.rb') % Path('/a/b/')).should == Path('Array/sort.rb')
  end

  it 'empty?' do
    Path.tmpfile do |file|
      file.should be_empty
      file.write 'Hello World!'
      file.should_not be_empty
    end
  end

  it 'parent' do
    Path('a/b/c').parent.should == Path('a/b')
    Path('a').parent.should == Path('.')
    Path('.').parent.should == Path('..')
    Path('..').parent.should == Path('../..')
    Path('../..').parent.should == Path('../../..')
    Path('../a').parent.should == Path('..')
  end

  it 'here, dir' do
    Path.here.should == Path(__FILE__).expand
    Path.dir.should == Path(File.dirname(__FILE__)).expand
  end

  it 'relative' do
    Path.relative('epath_spec.rb').should == this
    Path.relative('..').should == root
    Path.relative('../spec').should == spec
    Path.relative('../lib/epath.rb').should == lib_epath
  end

  it 'home' do
    Path.home.should == Path('~').expand # fails on JRuby 1.9 as Dir.home gives backslashes (only / on MRI)
  end

  it 'ancestors' do
    r = Path.new(File.dirname('C:') != '.' ? 'C:/' : '/')
    (r/'usr/bin/ls').ancestors.to_a.should == [
      r/'usr/bin/ls', r/'usr/bin', r/'usr', r]
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
      tmpfile.exist?.should be_true
      tmpfile.write 'foo'
      tmpfile.read.should == 'foo'
    end
    tmpfile.exist?.should be_false
  end

  it 'tmpdir' do
    tmpdir = nil
    Path.tmpdir do |dir|
      tmpdir = dir
      tmpdir.exist?.should be_true
      (dir/:file).write 'foo'
      (dir/:file).read.should == 'foo'
    end
    # This may be delayed a bit, notably on JRuby
    # tmpdir.exist?.should be_false
  end

  it 'tmpchdir', :fails_on => [:rbx] do
    Path.tmpchdir do |dir|
      dir.should be_identical(Path.getwd)
    end
  end
end
