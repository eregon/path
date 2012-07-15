require 'spec_helper'

this = Path(__FILE__).expand
root = Path(File.expand_path('../..',__FILE__))
lib = Path(File.expand_path('../../lib',__FILE__))
lib_path = Path(File.expand_path('../../lib/path.rb',__FILE__))
spec = Path(File.expand_path('..',__FILE__))

describe Path do
  it "can be required as 'epath' for compatibility" do
    epath = Path.relative('../lib/epath.rb')
    epath.should exist
    epath.lines.should include "require File.expand_path('../path.rb', __FILE__)\n"
  end

  context '+ configuration', :order_dependent do # just a reader tip
    it 'defaults to :warning' do
      out, err = capture_io { (Path('p') + 'a').should == Path('p/a') }
      out.should == ''
      err.should start_with 'Warning: use of deprecated Path#+ as Path#/: #<Path p> + "a"'
    end

    it ':defined' do
      Path + :defined
      capture_io { (Path('p') + 'a').should == Path('p/a') }.should == ['', '']
    end

    it 'gives an error' do
      expect { Path + :unknown_config }.to raise_error ArgumentError, /:unknown_config/
    end

    it 'gives an error if already configured once' do
      expect { Path + :error }.to raise_error(/^Path\.\+ has already been called: .+path_spec\.rb:\d+/)
    end

    it ':error' do
      Path.instance_variable_set(:@plus_configured, nil)
      Path + :error
      expect { Path('p') + 'a' }.to raise_error(NoMethodError)
    end

    it ':string' do
      Path.instance_variable_set(:@plus_configured, nil)
      Path + :string
      verbosely(nil) do
        capture_io { (Path('p') + 'a').should == Path('pa') }.should == ['', '']
      end
      verbosely do
        out, err = capture_io { (Path('p') + 'a').should == Path('pa') }
        out.should == ''
        err.should start_with 'Warning: use of deprecated Path#+ as String#+: #<Path p> + "a"'
      end
    end
  end

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
    Path.relative('path_spec.rb').should == this
    Path.relative('..').should == root
    Path.relative('../spec').should == spec
    Path.relative('../lib/path.rb').should == lib_path
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
      Path.here.backfind('lib/path.rb').should == lib_path
      (Path.dir/'x/y/z').backfind('lib/path.rb').should == lib_path
      (Path.dir/'x/y/z').backfind('lib/nothin/such.rb').should be_nil
      Path('x/y/z').backfind('lib/nothin/such.rb').should be_nil # relative paths should work too
    end

    it 'class method' do
      Path.backfind('lib/path.rb').should == lib_path
    end

    it 'with xpath-like context' do
      Path.backfind('lib[path.rb]').should == lib
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

  it 'tmpchdir', :fails_on => [:rbx18] do
    Path.tmpchdir do |dir|
      dir.should be_identical(Path.getwd)
    end
  end

  context 'relocate' do
    let(:from)   { Path('pictures') }
    let(:to)     { Path('output/thumbails') }
    let(:source) { from / 'nature/earth.jpg' }

    it 'works with from and to only' do
      source.relocate(from, to).should == to/'nature/earth.jpg'
    end

    it 'supports a new extension' do
      source.relocate(from, to, "png").should == to/'nature/earth.png'
    end

    it 'supports a block' do
      source.relocate(from, to) { |rel|
        rel.should == (source % from).rm_ext
        rel.to_s.upcase
      }.should == to/'NATURE/EARTH.jpg'
    end

    it 'supports a block and new extension' do
      source.relocate(from, to, 'png') { |rel|
        rel.should == (source % from).rm_ext
        rel.to_s.upcase
      }.should == to/'NATURE/EARTH.png'
    end

    it 'supports multiple extensions' do
      source.add_ext('gz').relocate(from, to, :zip).should == to/'nature/earth.jpg.zip'
    end
  end
end
