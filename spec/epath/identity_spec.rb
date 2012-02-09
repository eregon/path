require File.expand_path('../../spec_helper', __FILE__)

frozen_error = RUBY_VERSION > '1.9' ? RuntimeError : TypeError

describe 'Path : identity' do
  it 'initialize' do
    p1 = Path.new('a')
    p1.to_s.should == 'a'
    p2 = Path.new(p1)
    p2.should == p1
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
  end

  it 'behaves like a path' do
    path = Path.new('/')
    [:to_s, :to_sym, :to_path].each do |meth|
      path.should respond_to meth
    end

    path.respond_to?(:to_str).should == (RUBY_VERSION < '1.9')
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

    %w[a a/ a/b a. a0].each_cons(2) { |p1,p2|
      (Path(p1) <=> Path(p2)).should == -1
    }

    (Path('a') <=> 'a').should be_nil
    ('a' <=> Path('a')).should be_nil
  end

  it 'destructive update of #to_s are not allowed' do
    path = Path('a')
    expect {
      path.to_s.replace 'b'
    }.to raise_error(frozen_error, /can't modify frozen/)
    path.to_s.should == 'a'
    path.should == Path('a')
  end

  it 'taint' do
    path = Path('a')
    expect {
      path.taint
    }.to raise_error(frozen_error, /can't modify frozen/)

    Path('a'      )           .should_not be_tainted
    Path('a'      )      .to_s.should_not be_tainted
    Path('a'.taint)           .should be_tainted
    Path('a'.taint)      .to_s.should be_tainted

    str = 'a'
    path = Path(str)
    str.taint
    path.should_not be_tainted
    path.to_s.should_not be_tainted
  end

  it 'untaint' do
    path = Path('a'.taint)
    expect {
      path.untaint
    }.to raise_error(frozen_error, /can't modify frozen/)
    path     .should be_tainted
    path.to_s.should be_tainted
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

  it 'freeze and taint', :fails_on => [:rbx, :rbx19] do
    path = Path('a').freeze
    path.should_not be_tainted
    expect {
      path.taint
    }.to raise_error(frozen_error, /can't modify frozen/)
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
end
