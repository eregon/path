require 'spec_helper'

frozen_error = RUBY_VERSION > '1.9' ? RuntimeError : TypeError
frozen_error = [frozen_error, /(?:can't|unable to) modify frozen/]

describe 'Path : identity' do
  it 'initialize' do
    p1 = Path.new('a')
    p1.to_s.should == 'a'
    p2 = Path.new(p1)
    p2.should == p1

    -> { Path.new("invalid path\0") }.should raise_error(ArgumentError, /null byte/)

    Path.new('/').to_s.should == '/'
    Path.new('/usr/bin/').to_s.should == '/usr/bin'
    Path.new('/usr/bin//').to_s.should == '/usr/bin'

    home = Path.new('~')
    home.to_s.should_not == '~'
    home.should be_absolute
  end

  it 'initialize unix', :unix do
    Path.new('//').to_s.should == '/'
  end

  it 'initialize win32', :dosish do
    str = 'C:\Users'
    Path.new(str).should == Path.new('C:/Users')
    Path.new(str).to_s.should == 'C:/Users'
    str.should == 'C:\Users'

    Path.new('C:\\').to_s.should == 'C:/'
    Path.new('C:\\\\').to_s.should == 'C:/'
    Path.new('C:\Users\Benoit\\').to_s.should == 'C:/Users/Benoit'
    Path.new('C:\Users\Benoit\\\\').to_s.should == 'C:/Users/Benoit'
  end

  it 'new' do
    path = Path.new('.')
    Path.new(path).should be path
  end

  it 'Path()' do
    Path('a').should == Path.new('a')
    Path('/usr', 'bin', 'ls').should == Path('/usr/bin/ls')
    (Path('/usr')/:bin/:ls).should == Path('/usr/bin/ls')
    Path(:path).to_s.should == 'path'

    File.open(__FILE__) { |file| Path(file) }.should == Path.file

    path = double(:to_str => 'to_str', :path => 'path', :to_path => 'to_path')
    Path(path).should == Path('to_path')
    path = double(:to_str => 'to_str', :path => 'path')
    Path(path).should == Path('path')
    path = double(:to_str => 'to_str')
    Path(path).should == Path('to_str')
    Path(42).should == Path('42') # call to_s
  end

  it 'behaves like a path' do
    path = Path.new('/a/b')

    path.path.should == '/a/b'
    :to_s.should be_an_alias_of :path
    :to_path.should be_an_alias_of :path

    path.respond_to?(:to_str).should == (RUBY_VERSION < '1.9')
    :to_str.should be_an_alias_of :path if RUBY_VERSION < '1.9'
  end

  it '&Path' do
    %w[foo bar].map(&Path).should == [Path('foo'), Path('bar')]
  end

  it '==' do
    anotherStringLike = Class.new do
      def initialize(s)
        @s = s
      end
      def to_str
        @s
      end
      def == other
        @s == other
      end
    end
    path, str, sym = Path('a'), 'a', :a
    ano = anotherStringLike.new('a')

    [str, sym, ano].each { |other|
      path.should_not == other
      other.should_not == path
    }

    path2 = Path('a')
    path.should == path2
    path.should === path2
    path.should eql path2
  end

  it 'hash, eql?' do
    h = {}
    h[Path.new('a')] = 1
    h[Path.new('a')] = 2
    h.should == { Path.new('a') => 2 }
  end

  it '<=>' do
    (Path('a') <=> Path('a')).should == 0
    (Path('b') <=> Path('a')).should == 1
    (Path('a') <=> Path('b')).should == -1

    (Path('a') <=> Path('a/b')).should == -1
    (Path('a/b') <=> Path('a-')).should == -1
    (Path('a-') <=> Path('a0')).should == -1

    (Path('a') <=> 'a').should be_nil
    ('a' <=> Path('a')).should be_nil
  end

  it 'Path.like?' do
    Path.like?(Object.new).should be false
    Path.like?(double(:path => 'path')).should be true
  end

  it 'Path.like' do
    (Path.like === Object.new).should be false
    (Path.like === double(:path => 'path')).should be true

    case path = double(:path => 'path')
    when Path.like
      Path(path)
    end.should == Path('path')

    [1, '2', :'3'].grep(Path.like).should == ['2']
  end

  it 'destructive update of #to_s are not allowed' do
    path = Path('a')
    -> {
      path.to_s.replace 'b'
    }.should raise_error(*frozen_error)
    path.to_s.should == 'a'
    path.should == Path('a')
  end

  it 'freeze' do
    path = Path('a')
    path.freeze.should be path

    Path('a'       )            .should be_frozen
    Path('a'.freeze)            .should be_frozen
    Path('a'       ).freeze     .should be_frozen
    Path('a'.freeze).freeze     .should be_frozen
    Path('a'       )       .to_s.should be_frozen
    Path('a'.freeze)       .to_s.should be_frozen
    Path('a'       ).freeze.to_s.should be_frozen
    Path('a'.freeze).freeze.to_s.should be_frozen
  end

  it 'inspect' do
    Path('dir/file').inspect.should == '#<Path dir/file>'
  end

  it 'to_s' do
    str = 'a'
    path = Path(str)
    path.to_s.should == str
    path.to_s.should_not be str
    path.to_s.should be path.to_s
  end

  it 'to_s.dup can be modified' do
    str = 'a'
    path = Path(str)
    dup = path.to_s.dup
    dup.should_not be_frozen
    dup.gsub!('a', 'b')
    dup.should == 'b'
    path.to_s.should == str
  end

  it 'to_sym' do
    Path('path').to_sym.should == :path
    Path('dir/file').to_sym.should == :"dir/file"
  end

  context 'dump/load' do
    let(:path) { Path('dir/file') }
    let(:paths) { [Path('dir/file'), Path('path')] }

    shared_examples_for 'a round-tripping dumping and loading module' do |impl|
      it 'can be dumped and loaded back' do
        load_method = impl == YAML && impl.respond_to?(:unsafe_load) ? :unsafe_load : :load

        reloaded = impl.send(load_method, impl.dump(path))

        reloaded.should == path
        path.should == reloaded
        reloaded.should_not be path

        reloaded.should be_frozen
        reloaded.to_s.should be_frozen

        impl.send(load_method, impl.dump(paths)).should == paths
      end
    end

    context YAML do
      it 'is dumped nicely' do
        yaml = <<-EOY
--- !ruby/object:Path
path: dir/file
EOY
        # Recent JRuby 1.9 adds "...\n" (end of document) at the end
        expected = [yaml, yaml+"...\n"]
        # Syck adds some space after the class name and ---
        actual = YAML.dump(path).gsub(/(Path) $/, '\1')
        expected.should include actual

        yaml = <<-EOY
---
- !ruby/object:Path
  path: dir/file
- !ruby/object:Path
  path: path
EOY
        # Recent JRuby 1.9 adds "...\n" (end of document) at the end
        expected = [yaml, yaml+"...\n"]
        # Syck adds some space after the class name and ---
        actual = YAML.dump(paths).gsub(/(Path|-{3}) $/, '\1')
        expected.should include actual
      end

      it_should_behave_like 'a round-tripping dumping and loading module', YAML
    end

    context JSON do
      it 'is dumped clearly' do
        json = [
          '{"json_class":"Path","data":"dir/file"}',
          '{"data":"dir/file","json_class":"Path"}'
        ]
        json.should include JSON.dump(path)

        json = [
          '[{"json_class":"Path","data":"dir/file"},{"json_class":"Path","data":"path"}]',
          '[{"data":"dir/file","json_class":"Path"},{"data":"path","json_class":"Path"}]'
        ]
        json.should include JSON.dump(paths)
      end

      it_should_behave_like 'a round-tripping dumping and loading module', JSON
    end

    context Marshal do
      it 'is dumped efficiently' do
        # Just dump and check if no exception
        Marshal.dump(path)
        Marshal.dump(paths)
      end

      it_should_behave_like 'a round-tripping dumping and loading module', Marshal
    end
  end
end
