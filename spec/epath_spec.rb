require 'rspec/autorun'
$: << '../lib'
require 'epath'

this = Path(__FILE__).expand
root = Path(File.expand_path('../..',__FILE__))
lib = Path(File.expand_path('../../lib',__FILE__))
lib_epath = Path(File.expand_path('../../lib/epath.rb',__FILE__))
spec = Path(File.expand_path('..',__FILE__))

describe Path do
  it 'behaves like a path' do
    path = Path.new('/')
    [:to_s, :to_str, :to_path, :to_sym].each do |meth|
      path.should respond_to meth
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

  it 'base, basename' do
    Path('file.ext').basename.should == Path('file.ext')
    Path('file.ext').basename('xt').should == Path('file.e')
    Path('file.ext').basename('.ext').should == Path('file')
    Path('file.ext').base.should == Path('file')
    Path('dir/file.ext').basename.should == Path('file.ext')
    Path('dir/file.ext').base.should == Path('file')
  end

  it 'ext, extname' do
    Path('file.rb').extname.should == '.rb'
    Path('file.rb').ext.should == 'rb'
    Path('.hidden').extname.should == ''
    Path('.hidden').ext.should == ''
  end

  it 'without_extension' do
    Path('/usr/bin/ls').without_extension.should == Path('/usr/bin/ls')
    Path('/usr/bin/ls.rb').without_extension.should == Path('/usr/bin/ls')
  end

  it 'replace_extension' do
    Path('hello/world.rb').replace_extension('.ext').should == Path('hello/world.ext')
    Path('hello/world').replace_extension('.ext').should == Path('hello/world.ext')

    # should add a '.' if missing (consistent with #ext)
    Path('hello/world').replace_extension('ext').should == Path('hello/world.ext')
  end

  it 'relative_to' do
    Path('/a/b/Array/sort.rb').relative_to(Path('/')).should == Path('a/b/Array/sort.rb')
    Path('/a/b/Array/sort.rb').relative_to(Path('/a/b')).should == Path('Array/sort.rb')
    Path('/a/b/Array/sort.rb').relative_to(Path('/a/b/')).should == Path('Array/sort.rb')
    (Path('/a/b/Array/sort.rb') % Path('/a/b/')).should == Path('Array/sort.rb')
  end

  it 'read, write, size' do
    contents = this.read
    this.read.should == contents
    this.read.size.should == this.size

    begin
      tmp = Path('.tmp')
      tmp.write(contents)
      tmp.read.should == contents
    ensure
      tmp.unlink if tmp.exist?
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
    Path.home.should == Path('~').expand
  end

  it 'ancestors' do
    Path('/usr/bin/ls').ancestors.to_a.should == [
      Path('/usr/bin/ls'), Path('/usr/bin'), Path('/usr'), Path('/')]
  end

  context 'backfind' do
    it 'simple' do
      Path.here.backfind('Rakefile').should == Path.relative('../Rakefile').expand
      Path.here.backfind('lib/epath.rb').should == lib_epath
      (Path.dir/'x/y/z').backfind('lib/epath.rb').should == lib_epath
      (Path.dir/'x/y/z').backfind('lib/nothin/such.rb').should be_nil
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

  it 'entries' do
    spec.entries.should == [this]
  end

  it 'glob' do
    spec.glob('*.rb').should == [this]
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
    tmpdir.exist?.should be_false
  end
end
