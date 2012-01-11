require 'rspec/autorun'
require File.expand_path('../../lib/epath', __FILE__)

this = Path(__FILE__).expand
root = Path(File.expand_path('../..',__FILE__))
lib = Path(File.expand_path('../../lib',__FILE__))
lib_epath = Path(File.expand_path('../../lib/epath.rb',__FILE__))
spec = Path(File.expand_path('..',__FILE__))
fixtures = Path(File.expand_path('../fixtures',__FILE__))
test_implementation = Path(File.expand_path('../test_implementation.rb',__FILE__))

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

  it 'file?, dir?' do
    Path.tmpdir do |tmpdir|
      dir, file = Path('dir'), Path('file')
      tmpdir.chdir do
        dir.mkdir
        file.touch
        dir.dir?.should be_true
        dir.file?.should be_false
        file.file?.should be_true
        file.dir?.should be_false
      end
    end
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

  it 'add_ext, add_extension' do
    path = Path('file')
    path = path.add_extension('.txt')
    path.ext.should == 'txt'
    path = path.add_extension('.mkv')
    path.ext.should == 'mkv'
    path = path.add_ext('tar.gz')
    path.ext.should == 'gz'
    path.to_s.should == 'file.txt.mkv.tar.gz'
  end

  it 'rm_ext, without_extension' do
    Path('/usr/bin/ls').without_extension.should == Path('/usr/bin/ls')
    Path('/usr/bin/ls.rb').rm_ext.should == Path('/usr/bin/ls')
  end

  it 'sub_ext, replace_extension' do
    Path('hello/world.rb').replace_extension('.ext').should == Path('hello/world.ext')
    Path('hello/world').replace_extension('.ext').should == Path('hello/world.ext')

    # should add a '.' if missing (consistent with #ext)
    Path('hello/world').replace_extension('ext').should == Path('hello/world.ext')
  end

  it '%, relative_to' do
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

  it 'append' do
    begin
      tmp = Path('.tmp')
      tmp.write("hello\n")
      tmp.append("world\n")
      tmp.read.should eq("hello\nworld\n")
    ensure
      tmp.unlink if tmp.exist?
    end
  end

  it 'touch' do
    Path.tmpdir do |dir|
      dir.chdir do
        file = Path('file')
        file.exist?.should be_false
        file.touch
        file.exist?.should be_true
        file.size.should == 0
      end
    end
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
    Path.home.should == Path('~').expand
  end

  it 'ancestors' do
    r = Path.new(File.dirname('C:') != '.' ? 'C:/' : '/')
    (r/'usr/bin/ls').ancestors.to_a.should == [
      r/'usr/bin/ls', r/'usr/bin', r/'usr', r]
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

  it 'chdir' do
    called = false
    spec.chdir do
      called = true
      Path.getwd.should == spec
    end
    called.should be_true
  end

  it 'entries' do
    spec.entries.sort.should == [Path('.'), Path('..'), Path('epath_spec.rb'), Path('fixtures'), Path('test_implementation.rb')]
  end

  it 'glob' do
    spec.glob('*.rb').sort.should == [this, test_implementation]
    spec.chdir do
      Path.glob('*.rb').map(&:expand).sort.should == [this, test_implementation]
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

  it 'mkdir_p, rm_rf' do
    Path.tmpdir do |dir|
      d = (dir/:test/:mkdir)
      d.mkdir_p.should equal d
      test = d.parent
      test.rm_rf.should equal test
    end
  end
  
  it 'load' do
    (fixtures/"data.yml").load.should == {"kind" => "yml"}
    (fixtures/"data.yaml").load.should == {"kind" => "yaml"}
    (fixtures/"data.json").load.should == {"kind" => "json"}
    (fixtures/"data.rb").load.should == {"kind" => "rb"}
    (fixtures/"data.ruby").load.should == {"kind" => "ruby"}
  end
end
