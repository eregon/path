require File.expand_path('../../spec_helper', __FILE__)

describe 'Path implementation' do

  dosish = File::ALT_SEPARATOR != nil
  dosish_drive_letter = File.dirname('A:') == 'A:.'
  dosish_unc = File.dirname('//') == '//'

  context 'cleanpath' do
    it 'aggressive' do
      cases = {
        '/' => '/',
        '' => '.',
        '.' => '.',
        '..' => '..',
        'a' => 'a',
        '/.' => '/',
        '/..' => '/',
        '/a' => '/a',
        './' => '.',
        '../' => '..',
        'a/' => 'a',
        'a//b' => 'a/b',
        'a/.' => 'a',
        'a/./' => 'a',
        'a/..' => '.',
        'a/../' => '.',
        '/a/.' => '/a',
        './..' => '..',
        '../.' => '..',
        './../' => '..',
        '.././' => '..',
        '/./..' => '/',
        '/../.' => '/',
        '/./../' => '/',
        '/.././' => '/',
        'a/b/c' => 'a/b/c',
        './b/c' => 'b/c',
        'a/./c' => 'a/c',
        'a/b/.' => 'a/b',
        'a/../.' => '.',
        '/../.././../a' => '/a',
        'a/b/../../../../c/../d' => '../../d',
      }

      platform = if dosish_unc
        { '//a/b/c/' => '//a/b/c' }
      else
        {
          '///' => '/',
          '///a' => '/a',
          '///..' => '/',
          '///.' => '/',
          '///a/../..' => '/',
        }
      end
      cases.merge!(platform)

      cases.each_pair do |path, expected|
        Path(path).cleanpath.to_s.should == expected
      end
    end

    it 'conservative' do
      cases = {
        '/' => '/',
        '' => '.',
        '.' => '.',
        '..' => '..',
        'a' => 'a',
        '/.' => '/',
        '/..' => '/',
        '/a' => '/a',
        './' => '.',
        '../' => '..',
        'a/' => 'a/',
        'a//b' => 'a/b',
        'a/.' => 'a/.',
        'a/./' => 'a/.',
        'a/../' => 'a/..',
        '/a/.' => '/a/.',
        './..' => '..',
        '../.' => '..',
        './../' => '..',
        '.././' => '..',
        '/./..' => '/',
        '/../.' => '/',
        '/./../' => '/',
        '/.././' => '/',
        'a/b/c' => 'a/b/c',
        './b/c' => 'b/c',
        'a/./c' => 'a/c',
        'a/b/.' => 'a/b/.',
        'a/../.' => 'a/..',
        '/../.././../a' => '/a',
        'a/b/../../../../c/../d' => 'a/b/../../../../c/../d',
      }
      cases['//'] = (dosish_unc ? '//' : '/')

      cases.each_pair do |path, expected|
        Path(path).cleanpath(true).to_s.should == expected
      end
    end
  end

  it 'has_trailing_separator?' do
    { '/' => false, '///' => false, 'a' => false, 'a/' => true }.each_pair do |path, expected|
      Path.allocate.send(:has_trailing_separator?, path).should == expected
    end
  end

  it 'del_trailing_separator' do
    cases = {
      '/' => '/',
      '/a' => '/a',
      '/a/' => '/a',
      '/a//' => '/a',
      '.' => '.',
      './' => '.',
      './/' => '.',
    }

    if dosish_drive_letter
      cases.merge!({
        'A:' => 'A:',
        'A:/' => 'A:/',
        'A://' => 'A:/', # fails on JRuby, File.basename('A://') = 'A:' vs '/' on MRI
        'A:.' => 'A:.',
        'A:./' => 'A:.',
        'A:.//' => 'A:.',
      })
    end

    cases["a\\"] = 'a' if dosish

    platform = if dosish_unc
      {
        '//' => '//',
        '//a' => '//a',
        '//a/' => '//a',
        '//a//' => '//a',
        '//a/b' => '//a/b',
        '//a/b/' => '//a/b',
        '//a/b//' => '//a/b',
        '//a/b/c' => '//a/b/c',
        '//a/b/c/' => '//a/b/c',
        '//a/b/c//' => '//a/b/c',
      }
    else
      { '///' => '/', '///a/' => '///a' }
    end
    cases.merge!(platform)

    cases.each_pair do |path, expected|
      Path.allocate.send(:del_trailing_separator, path).should == expected
    end
  end

  it 'del_trailing_separator win32', :if => dosish, :fails_on => [:jruby, :jruby19] do
    require 'Win32API'
    if Win32API.new('kernel32', 'GetACP', nil, 'L').call == 932
      Path.allocate.send(:del_trailing_separator, "\225\\\\").should == "\225\\" # SJIS
    end
  end

  it 'plus' do
    (Path('a') + Path('b')).should be_kind_of Path
    {
      ['/', '/'] => '/',
      ['a', 'b'] => 'a/b',
      ['a', '.'] => 'a',
      ['.', 'b'] => 'b',
      ['.', '.'] => '.',
      ['a', '/b'] => '/b',

      ['/', '..'] => '/',
      ['a', '..'] => '.',
      ['a/b', '..'] => 'a',
      ['..', '..'] => '../..',
      ['/', '../c'] => '/c',
      ['a', '../c'] => 'c',
      ['a/b', '../c'] => 'a/c',
      ['..', '../c'] => '../../c',

      ['a//b/c', '../d//e'] => 'a//b/d//e',
    }.each_pair do |(a, b), path|
      (Path(a) + Path(b)).to_s.should == path
    end
  end

  it 'parent' do
    {
      '/' => '/',
      '/a' => '/',
      '/a/b' => '/a',
      '/a/b/c' => '/a/b',
      'a' => '.',
      'a/b' => 'a',
      'a/b/c' => 'a/b',
      '.' => '..',
      '..' => '../..',
    }.each_pair do |path, parent|
      Path(path).parent.to_s.should == parent
    end
  end

  it 'join' do
    Path('a').join(Path('b'), Path('c')).should ==  Path('a/b/c')
  end

  it 'absolute?' do
    Path('/').should be_absolute
    Path('a').should_not be_absolute
  end

  it 'relative?' do
    Path('/').should_not be_relative
    Path('/a').should_not be_relative
    Path('/..').should_not be_relative
    Path('a').should be_relative
    Path('a/b').should be_relative

    if dosish_drive_letter
      Path('A:').should_not be_relative
      Path('A:/').should_not be_relative
      Path('A:/a').should_not be_relative
    end

    if File.dirname('//') == '//'
      [
        '//',
        '//a',
        '//a/',
        '//a/b',
        '//a/b/',
        '//a/b/c',
      ].each { |path| Path(path).should_not be_relative }
    end
  end

  it 'relative_path_from' do
    {
      ['a', 'b'] => '../a',
      ['a', 'b/'] => '../a',
      ['a/', 'b'] => '../a',
      ['a/', 'b/'] => '../a',
      ['/a', '/b'] => '../a',
      ['/a', '/b/'] => '../a',
      ['/a/', '/b'] => '../a',
      ['/a/', '/b/'] => '../a',

      ['a/b', 'a/c'] => '../b',
      ['../a', '../b'] => '../a',

      ['a', '.'] => 'a',
      ['.', 'a'] => '..',

      ['.', '.'] => '.',
      ['..', '..'] => '.',
      ['..', '.'] => '..',

      ['/a/b/c/d', '/a/b'] => 'c/d',
      ['/a/b', '/a/b/c/d'] => '../..',
      ['/e', '/a/b/c/d'] => '../../../../e',
      ['a/b/c', 'a/d'] => '../b/c',

      ['/../a', '/b'] => '../a',
      ['../a', 'b'] => '../../a',
      ['/a/../../b', '/b'] => '.',
      ['a/..', 'a'] => '..',
      ['a/../b', 'b'] => '.',

      ['a', 'b/..'] => 'a',
      ['b/c', 'b/..'] => 'b/c',
    }.each_pair do |(path, base), relpath|
      Path(path).relative_path_from(Path(base)).to_s.should == relpath
    end

    [
      ['/', '.'],
      ['.', '/'],
      ['a', '..'],
      ['.', '..'],
    ].each do |path, base|
      lambda {
        Path(path).relative_path_from(Path(base))
      }.should raise_error(ArgumentError)
    end
  end

  it 'realpath', :tmpchdir, :symlink, :fails_on => [:jruby] do
    dir = Path.getwd
    not_exist = dir/'not-exist'
    lambda { not_exist.realpath }.should raise_error(Errno::ENOENT)
    not_exist.make_symlink('not-exist-target')
    lambda { not_exist.realpath }.should raise_error(Errno::ENOENT)

    looop = dir/'loop'
    looop.make_symlink('loop')
    lambda { looop.realpath }.should raise_error(Errno::ELOOP)
    lambda { looop.realpath(dir) }.should raise_error(Errno::ELOOP)

    not_exist2 = dir/'not-exist2'
    not_exist2.make_symlink("../#{dir.basename}/./not-exist-target")
    lambda { not_exist2.realpath }.should raise_error(Errno::ENOENT)

    exist_target, exist2 = (dir/'exist-target').touch, dir/'exist2'
    exist2.make_symlink(exist_target)
    exist2.realpath.should == exist_target

    loop_relative = Path('loop-relative')
    loop_relative.make_symlink(loop_relative)
    lambda { loop_relative.realpath }.should raise_error(Errno::ELOOP)

    exist = Path('exist').mkdir
    exist.realpath.should == dir/'exist'
    lambda { Path('../loop').realpath(exist) }.should raise_error(Errno::ELOOP)

    Path('loop1').make_symlink('loop1/loop1')
    lambda { (dir/'loop1').realpath }.should raise_error(Errno::ELOOP)

    loop2, loop3 = Path('loop2'), Path('loop3')
    loop2.make_symlink(loop3)
    loop3.make_symlink(loop2)
    lambda { loop2.realpath }.should raise_error(Errno::ELOOP)

    b = dir/'b'
    Path('c').make_symlink(Path('b').mkdir)
    Path('c').realpath.should == b
    Path('c/../c').realpath.should == b
    Path('c/../c/../c/.').realpath.should == b

    Path('b/d').make_symlink('..')
    Path('c/d/c/d/c').realpath.should == b

    e = Path('e').make_symlink(b)
    e.realpath.should == b

    f = Path('f').mkdir
    g = dir / (f/'g').mkdir
    h = Path('h').make_symlink(g)
    f.chmod(0000)
    lambda { h.realpath }.should raise_error(Errno::EACCES)
    f.chmod(0755)
    h.realpath.should == g
  end

  it 'realdirpath', :symlink, :fails_on => [:jruby] do
    Dir.mktmpdir('realdirpath') do |dir|
      dir = Path(dir)
      rdir = dir.realpath
      not_exist = dir/'not-exist'

      not_exist.realdirpath.should == rdir/'not-exist'
      lambda { (not_exist/'not-exist-child').realdirpath }.should raise_error(Errno::ENOENT)

      not_exist.make_symlink('not-exist-target')
      not_exist.realdirpath.should == rdir/'not-exist-target'

      not_exist2 = (dir/'not-exist2').make_symlink("../#{dir.basename}/./not-exist-target")
      not_exist2.realdirpath.should == rdir/'not-exist-target'

      (dir/'exist-target').touch
      exist = (dir/'exist').make_symlink("../#{dir.basename}/./exist-target")
      exist.realdirpath.should == rdir/'exist-target'

      looop = (dir/'loop').make_symlink('loop')
      lambda { looop.realdirpath }.should raise_error(Errno::ELOOP)
    end
  end

  it 'descend' do
    Path('/a/b/c').descend.map(&:to_s).should == %w[/ /a /a/b /a/b/c]
    Path('a/b/c').descend.map(&:to_s).should == %w[a a/b a/b/c]
    Path('./a/b/c').descend.map(&:to_s).should == %w[. ./a ./a/b ./a/b/c]
    Path('a/').descend.map(&:to_s).should == %w[a/]
  end

  it 'ascend' do
    Path('/a/b/c').ascend.map(&:to_s).should == %w[/a/b/c /a/b /a /]
    Path('a/b/c').ascend.map(&:to_s).should == %w[a/b/c a/b a]
    Path('./a/b/c').ascend.map(&:to_s).should ==  %w[./a/b/c ./a/b ./a .]
    Path('a/').ascend.map(&:to_s).should == %w[a/]
  end

  it 'initialize' do
    p1 = Path.new('a')
    p1.to_s.should == 'a'
    p2 = Path.new(p1)
    p2.should == p1
  end

  it 'equality' do
    anotherStringLike = Class.new do
      def initialize(s) @s = s end
      def to_str() @s end
      def ==(other) @s == other end
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

  it 'sub_ext' do
    Path('a.c').sub_ext('.o').should == Path('a.o')
    Path('a.c++').sub_ext('.o').should == Path('a.o')
    Path('a.gif').sub_ext('.png').should == Path('a.png')
    Path('ruby.tar.gz').sub_ext('.bz2').should == Path('ruby.tar.bz2')
    Path('d/a.c').sub_ext('.o').should == Path('d/a.o')
    Path('foo.exe').sub_ext('').should == Path('foo')
    Path('lex.yy.c').sub_ext('.o').should == Path('lex.yy.o')
    Path('fooaa').sub_ext('.o').should == Path('fooaa.o')
    Path('d.e/aa').sub_ext('.o').should == Path('d.e/aa.o')
    Path('long_enough.not_to_be_embeded[ruby-core-31640]').
      sub_ext('.bug-3664').should == Path('long_enough.bug-3664')
  end

  it 'root?' do
    Path('/').should be_root
    Path('//').should be_root
    Path('///').should be_root
    Path('').should_not be_root
    Path('a').should_not be_root
  end

  it 'mountpoint?' do
    [true, false].should include Path('/').mountpoint?
  end

  it 'destructive update of #to_s should not affect the path' do
    path = Path('a')
    path.to_s.replace 'b'
    path.to_s.should == 'a'
    path.should == Path('a')
  end

  it 'taint' do
    path = Path('a')
    path.taint.should be path

    Path('a'      )           .should_not be_tainted
    Path('a'      )      .to_s.should_not be_tainted
    Path('a'      ).taint     .should be_tainted
    Path('a'      ).taint.to_s.should be_tainted
    Path('a'.taint)           .should be_tainted
    Path('a'.taint)      .to_s.should be_tainted
    Path('a'.taint).taint     .should be_tainted
    Path('a'.taint).taint.to_s.should be_tainted

    str = 'a'
    path = Path(str)
    str.taint
    path.should_not be_tainted
    path.to_s.should_not be_tainted
  end

  it 'untaint' do
    path = Path('a')
    path.taint
    path.untaint.should be path

    Path('a').taint.untaint     .should_not be_tainted
    Path('a').taint.untaint.to_s.should_not be_tainted

    str = 'a'.taint
    path = Path(str)
    str.untaint
    path     .should be_tainted
    path.to_s.should be_tainted
  end

  it 'freeze' do
    path = Path('a')
    path.freeze.should be path

    Path('a'       )            .should_not be_frozen
    Path('a'.freeze)            .should_not be_frozen
    Path('a'       ).freeze     .should be_frozen
    Path('a'.freeze).freeze     .should be_frozen
    Path('a'       )       .to_s.should_not be_frozen
    Path('a'.freeze)       .to_s.should_not be_frozen
    Path('a'       ).freeze.to_s.should_not be_frozen
    Path('a'.freeze).freeze.to_s.should_not be_frozen
  end

  it 'freeze and taint', :fails_on => [:rbx, :rbx19] do
    path = Path('a').freeze
    path.should_not be_tainted
    error = RUBY_VERSION > '1.9' ? RuntimeError : TypeError
    lambda { path.taint }.should raise_error(error)

    path = Path('a')
    path.taint
    path.should be_tainted
    path.freeze
    path.should be_tainted
    path.taint
  end

  it 'to_s' do
    str = 'a'
    path = Path(str)
    path.to_s.should == str
    path.to_s.should_not be str
    path.to_s.should_not be path.to_s
  end

  it 'Kernel#open', :fails_on => [:rbx, :rbx19, :jruby19] do
    count = 0
    Kernel.open(Path(__FILE__)) { |f|
      File.should be_identical(__FILE__, f) # failure is due to rb_stat able to deal with #File
      count += 1
      2
    }.should == 2
    count.should == 1
  end

  it 'each_filename' do
    result = []
    Path('/usr/bin/ruby').each_filename { |f| result << f }
    result.should == %w[usr bin ruby]
    Path('/usr/bin/ruby').each_filename.to_a.should == %w[usr bin ruby]
  end

  it 'Path()' do
    Path('a').should == Path.new('a')
  end

  it 'find', :tmpchdir do
    a, b = Path('a').touch, Path('b').touch
    d = Path('d').mkdir
    x, y = Path('d/x').touch, Path('d/y').touch
    here = Path('.')

    r = []
    here.find { |f| r << f }
    r.sort.should == [here, a, b, d, x, y]

    d.find.sort.should == [d, x, y]
  end

  it 'mkpath', :tmpchdir do
    Path('a/b/c/d').mkpath.should be_a_directory
  end

  it 'rmtree', :tmpchdir do
    Path('a/b/c/d').mkpath.exist?.should be_true
    Path('a').rmtree.exist?.should be_false
  end

  it 'unlink', :tmpchdir do
    f = Path('f')
    f.write 'abc'
    f.unlink
    f.exist?.should be_false

    d = Path('d').mkdir
    d.unlink
    d.exist?.should be_false
  end

  it 'can be used with File class-methods' do
    path = Path('foo/bar')
    File.basename(path).should == 'bar'
    File.dirname(path).should == 'foo'
    File.split(path).should == %w[foo bar]
    File.extname(Path('bar.baz')).should == '.baz'

    File.fnmatch('*.*', Path.new('bar.baz')).should be_true
    File.join(Path.new('foo'), Path.new('bar')).should == 'foo/bar'
    lambda {
      $SAFE = 1 unless RUBY_DESCRIPTION.start_with? 'jruby'
      File.join(Path.new('foo'), Path.new('bar').taint).should == 'foo/bar'
    }.call
  end
end
