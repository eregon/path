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
        'A://' => 'A:/', # fails on JRuby, File.basename('A://') = 'A:' vs 'A:/' on MRI
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

  it 'del_trailing_separator win32', :dosish, :fails_on => [:jruby, :jruby19] do
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
    Path('a').join(Path('b'), Path('c')).should == Path('a/b/c')
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
      expect {
        Path(path).relative_path_from(Path(base))
      }.to raise_error(ArgumentError)
    end
  end

  it 'realpath', :tmpchdir, :symlink, :fails_on => [:jruby, :jruby19] do
    dir = Path.getwd
    not_exist = dir/'not-exist'
    expect { not_exist.realpath }.to raise_error(Errno::ENOENT)
    not_exist.make_symlink('not-exist-target')
    expect { not_exist.realpath }.to raise_error(Errno::ENOENT)

    looop = dir/'loop'
    looop.make_symlink('loop')
    expect { looop.realpath }.to raise_error(Errno::ELOOP)
    expect { looop.realpath(dir) }.to raise_error(Errno::ELOOP)

    not_exist2 = dir/'not-exist2'
    not_exist2.make_symlink("../#{dir.basename}/./not-exist-target")
    expect { not_exist2.realpath }.to raise_error(Errno::ENOENT)

    exist_target, exist2 = (dir/'exist-target').touch, dir/'exist2'
    exist2.make_symlink(exist_target)
    exist2.realpath.should == exist_target

    loop_relative = Path('loop-relative')
    loop_relative.make_symlink(loop_relative)
    expect { loop_relative.realpath }.to raise_error(Errno::ELOOP)

    exist = Path('exist').mkdir
    exist.realpath.should == dir/'exist'
    expect { Path('../loop').realpath(exist) }.to raise_error(Errno::ELOOP)

    Path('loop1').make_symlink('loop1/loop1')
    expect { (dir/'loop1').realpath }.to raise_error(Errno::ELOOP)

    loop2, loop3 = Path('loop2'), Path('loop3')
    loop2.make_symlink(loop3)
    loop3.make_symlink(loop2)
    expect { loop2.realpath }.to raise_error(Errno::ELOOP)

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
    expect { h.realpath }.to raise_error(Errno::EACCES) unless Process.uid == 0
    f.chmod(0755)
    h.realpath.should == g
  end

  it 'realdirpath', :symlink, :fails_on => [:jruby, :jruby19] do
    Dir.mktmpdir('realdirpath') do |dir|
      dir = Path(dir)
      rdir = dir.realpath
      not_exist = dir/'not-exist'

      not_exist.realdirpath.should == rdir/'not-exist'
      expect { (not_exist/'not-exist-child').realdirpath }.to raise_error(Errno::ENOENT)

      not_exist.make_symlink('not-exist-target')
      not_exist.realdirpath.should == rdir/'not-exist-target'

      not_exist2 = (dir/'not-exist2').make_symlink("../#{dir.basename}/./not-exist-target")
      not_exist2.realdirpath.should == rdir/'not-exist-target'

      (dir/'exist-target').touch
      exist = (dir/'exist').make_symlink("../#{dir.basename}/./exist-target")
      exist.realdirpath.should == rdir/'exist-target'

      looop = (dir/'loop').make_symlink('loop')
      expect { looop.realdirpath }.to raise_error(Errno::ELOOP)
    end
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
      File.join(Path.new('foo'), Path.new('bar'.taint)).should == 'foo/bar'
    }.call
  end
end
