#!/usr/bin/env ruby

require File.expand_path('../../lib/epath', __FILE__)
require 'test/unit'
require 'fileutils'
require 'tmpdir'
require 'enumerator'

class TestPathname < Test::Unit::TestCase
  def self.define_assertion(name, linenum, &block)
    name = "test_#{name}_#{linenum}"
    define_method(name, &block)
  end

  def self.get_linenum
    if /:(\d+):?/ =~ caller[1]
      $1.to_i
    else
      raise
    end
  end

  def self.defassert(name, result, *args)
    define_assertion(name, get_linenum) {
      mesg = "#{name}(#{args.map { |a| a.inspect }.join(', ')})"
      assert_nothing_raised(mesg) {
        assert_equal(result, self.send(name, *args), mesg)
      }
    }
  end

  def self.defassert_raise(name, exc, *args)
    define_assertion(name, get_linenum) {
      message = "#{name}(#{args.map { |a| a.inspect }.join(', ')})"
      assert_raise(exc, message) { self.send(name, *args) }
    }
  end

  DOSISH = File::ALT_SEPARATOR != nil
  DOSISH_DRIVE_LETTER = File.dirname("A:") == "A:."
  DOSISH_UNC = File.dirname("//") == "//"

  def ruby19?
    RUBY_VERSION > '1.9'
  end

  def cleanpath_aggressive(path)
    Path.new(path).cleanpath.to_s
  end

  defassert(:cleanpath_aggressive, '/',       '/')
  defassert(:cleanpath_aggressive, '.',       '')
  defassert(:cleanpath_aggressive, '.',       '.')
  defassert(:cleanpath_aggressive, '..',      '..')
  defassert(:cleanpath_aggressive, 'a',       'a')
  defassert(:cleanpath_aggressive, '/',       '/.')
  defassert(:cleanpath_aggressive, '/',       '/..')
  defassert(:cleanpath_aggressive, '/a',      '/a')
  defassert(:cleanpath_aggressive, '.',       './')
  defassert(:cleanpath_aggressive, '..',      '../')
  defassert(:cleanpath_aggressive, 'a',       'a/')
  defassert(:cleanpath_aggressive, 'a/b',     'a//b')
  defassert(:cleanpath_aggressive, 'a',       'a/.')
  defassert(:cleanpath_aggressive, 'a',       'a/./')
  defassert(:cleanpath_aggressive, '.',       'a/..')
  defassert(:cleanpath_aggressive, '.',       'a/../')
  defassert(:cleanpath_aggressive, '/a',      '/a/.')
  defassert(:cleanpath_aggressive, '..',      './..')
  defassert(:cleanpath_aggressive, '..',      '../.')
  defassert(:cleanpath_aggressive, '..',      './../')
  defassert(:cleanpath_aggressive, '..',      '.././')
  defassert(:cleanpath_aggressive, '/',       '/./..')
  defassert(:cleanpath_aggressive, '/',       '/../.')
  defassert(:cleanpath_aggressive, '/',       '/./../')
  defassert(:cleanpath_aggressive, '/',       '/.././')
  defassert(:cleanpath_aggressive, 'a/b/c',   'a/b/c')
  defassert(:cleanpath_aggressive, 'b/c',     './b/c')
  defassert(:cleanpath_aggressive, 'a/c',     'a/./c')
  defassert(:cleanpath_aggressive, 'a/b',     'a/b/.')
  defassert(:cleanpath_aggressive, '.',       'a/../.')
  defassert(:cleanpath_aggressive, '/a',      '/../.././../a')
  defassert(:cleanpath_aggressive, '../../d', 'a/b/../../../../c/../d')

  if DOSISH_UNC
    defassert(:cleanpath_aggressive, '//a/b/c', '//a/b/c/')
  else
    defassert(:cleanpath_aggressive, '/',       '///')
    defassert(:cleanpath_aggressive, '/a',      '///a')
    defassert(:cleanpath_aggressive, '/',       '///..')
    defassert(:cleanpath_aggressive, '/',       '///.')
    defassert(:cleanpath_aggressive, '/',       '///a/../..')
  end

  def cleanpath_conservative(path)
    Path.new(path).cleanpath(true).to_s
  end

  defassert(:cleanpath_conservative, '/',      '/')
  defassert(:cleanpath_conservative, '.',      '')
  defassert(:cleanpath_conservative, '.',      '.')
  defassert(:cleanpath_conservative, '..',     '..')
  defassert(:cleanpath_conservative, 'a',      'a')
  defassert(:cleanpath_conservative, '/',      '/.')
  defassert(:cleanpath_conservative, '/',      '/..')
  defassert(:cleanpath_conservative, '/a',     '/a')
  defassert(:cleanpath_conservative, '.',      './')
  defassert(:cleanpath_conservative, '..',     '../')
  defassert(:cleanpath_conservative, 'a/',     'a/')
  defassert(:cleanpath_conservative, 'a/b',    'a//b')
  defassert(:cleanpath_conservative, 'a/.',    'a/.')
  defassert(:cleanpath_conservative, 'a/.',    'a/./')
  defassert(:cleanpath_conservative, 'a/..',   'a/../')
  defassert(:cleanpath_conservative, '/a/.',   '/a/.')
  defassert(:cleanpath_conservative, '..',     './..')
  defassert(:cleanpath_conservative, '..',     '../.')
  defassert(:cleanpath_conservative, '..',     './../')
  defassert(:cleanpath_conservative, '..',     '.././')
  defassert(:cleanpath_conservative, '/',      '/./..')
  defassert(:cleanpath_conservative, '/',      '/../.')
  defassert(:cleanpath_conservative, '/',      '/./../')
  defassert(:cleanpath_conservative, '/',      '/.././')
  defassert(:cleanpath_conservative, 'a/b/c',  'a/b/c')
  defassert(:cleanpath_conservative, 'b/c',    './b/c')
  defassert(:cleanpath_conservative, 'a/c',    'a/./c')
  defassert(:cleanpath_conservative, 'a/b/.',  'a/b/.')
  defassert(:cleanpath_conservative, 'a/..',   'a/../.')
  defassert(:cleanpath_conservative, '/a',     '/../.././../a')
  defassert(:cleanpath_conservative, 'a/b/../../../../c/../d', 'a/b/../../../../c/../d')

  if DOSISH_UNC
    defassert(:cleanpath_conservative, '//',     '//')
  else
    defassert(:cleanpath_conservative, '/',      '//')
  end

  # has_trailing_separator?(path) -> bool
  def has_trailing_separator?(path)
    Path.allocate.__send__(:has_trailing_separator?, path)
  end

  defassert(:has_trailing_separator?, false, "/")
  defassert(:has_trailing_separator?, false, "///")
  defassert(:has_trailing_separator?, false, "a")
  defassert(:has_trailing_separator?, true, "a/")

  def add_trailing_separator(path)
    Path.allocate.__send__(:add_trailing_separator, path)
  end

  def del_trailing_separator(path)
    Path.allocate.__send__(:del_trailing_separator, path)
  end

  defassert(:del_trailing_separator, "/", "/")
  defassert(:del_trailing_separator, "/a", "/a")
  defassert(:del_trailing_separator, "/a", "/a/")
  defassert(:del_trailing_separator, "/a", "/a//")
  defassert(:del_trailing_separator, ".", ".")
  defassert(:del_trailing_separator, ".", "./")
  defassert(:del_trailing_separator, ".", ".//")

  if DOSISH_DRIVE_LETTER
    defassert(:del_trailing_separator, "A:", "A:")
    defassert(:del_trailing_separator, "A:/", "A:/")
    defassert(:del_trailing_separator, "A:/", "A://")
    defassert(:del_trailing_separator, "A:.", "A:.")
    defassert(:del_trailing_separator, "A:.", "A:./")
    defassert(:del_trailing_separator, "A:.", "A:.//")
  end

  if DOSISH_UNC
    defassert(:del_trailing_separator, "//", "//")
    defassert(:del_trailing_separator, "//a", "//a")
    defassert(:del_trailing_separator, "//a", "//a/")
    defassert(:del_trailing_separator, "//a", "//a//")
    defassert(:del_trailing_separator, "//a/b", "//a/b")
    defassert(:del_trailing_separator, "//a/b", "//a/b/")
    defassert(:del_trailing_separator, "//a/b", "//a/b//")
    defassert(:del_trailing_separator, "//a/b/c", "//a/b/c")
    defassert(:del_trailing_separator, "//a/b/c", "//a/b/c/")
    defassert(:del_trailing_separator, "//a/b/c", "//a/b/c//")
  else
    defassert(:del_trailing_separator, "/", "///")
    defassert(:del_trailing_separator, "///a", "///a/")
  end

  if DOSISH
    defassert(:del_trailing_separator, "a", "a\\")
    require 'Win32API'
    if Win32API.new('kernel32', 'GetACP', nil, 'L').call == 932
      defassert(:del_trailing_separator, "\225\\", "\225\\\\") # SJIS
    end
  end

  def test_plus
    assert_kind_of(Path, Path("a") + Path("b"))
  end

  def plus(path1, path2) # -> path
    (Path.new(path1) + Path.new(path2)).to_s
  end

  defassert(:plus, '/', '/', '/')
  defassert(:plus, 'a/b', 'a', 'b')
  defassert(:plus, 'a', 'a', '.')
  defassert(:plus, 'b', '.', 'b')
  defassert(:plus, '.', '.', '.')
  defassert(:plus, '/b', 'a', '/b')

  defassert(:plus, '/', '/', '..')
  defassert(:plus, '.', 'a', '..')
  defassert(:plus, 'a', 'a/b', '..')
  defassert(:plus, '../..', '..', '..')
  defassert(:plus, '/c', '/', '../c')
  defassert(:plus, 'c', 'a', '../c')
  defassert(:plus, 'a/c', 'a/b', '../c')
  defassert(:plus, '../../c', '..', '../c')

  defassert(:plus, 'a//b/d//e', 'a//b/c', '../d//e')

  def test_parent
    assert_equal(Path("."), Path("a").parent)
  end

  def parent(path) # -> path
    Path.new(path).parent.to_s
  end

  defassert(:parent, '/', '/')
  defassert(:parent, '/', '/a')
  defassert(:parent, '/a', '/a/b')
  defassert(:parent, '/a/b', '/a/b/c')
  defassert(:parent, '.', 'a')
  defassert(:parent, 'a', 'a/b')
  defassert(:parent, 'a/b', 'a/b/c')
  defassert(:parent, '..', '.')
  defassert(:parent, '../..', '..')

  def test_join
    r = Path("a").join(Path("b"), Path("c"))
    assert_equal(Path("a/b/c"), r)
  end

  def test_absolute
    assert_equal(true, Path("/").absolute?)
    assert_equal(false, Path("a").absolute?)
  end

  def relative?(path)
    Path.new(path).relative?
  end

  defassert(:relative?, false, '/')
  defassert(:relative?, false, '/a')
  defassert(:relative?, false, '/..')
  defassert(:relative?, true, 'a')
  defassert(:relative?, true, 'a/b')

  if DOSISH_DRIVE_LETTER
    defassert(:relative?, false, 'A:')
    defassert(:relative?, false, 'A:/')
    defassert(:relative?, false, 'A:/a')
  end

  if File.dirname('//') == '//'
    defassert(:relative?, false, '//')
    defassert(:relative?, false, '//a')
    defassert(:relative?, false, '//a/')
    defassert(:relative?, false, '//a/b')
    defassert(:relative?, false, '//a/b/')
    defassert(:relative?, false, '//a/b/c')
  end

  def relative_path_from(dest_directory, base_directory)
    Path.new(dest_directory).relative_path_from(Path.new(base_directory)).to_s
  end

  defassert(:relative_path_from, "../a", "a", "b")
  defassert(:relative_path_from, "../a", "a", "b/")
  defassert(:relative_path_from, "../a", "a/", "b")
  defassert(:relative_path_from, "../a", "a/", "b/")
  defassert(:relative_path_from, "../a", "/a", "/b")
  defassert(:relative_path_from, "../a", "/a", "/b/")
  defassert(:relative_path_from, "../a", "/a/", "/b")
  defassert(:relative_path_from, "../a", "/a/", "/b/")

  defassert(:relative_path_from, "../b", "a/b", "a/c")
  defassert(:relative_path_from, "../a", "../a", "../b")

  defassert(:relative_path_from, "a", "a", ".")
  defassert(:relative_path_from, "..", ".", "a")

  defassert(:relative_path_from, ".", ".", ".")
  defassert(:relative_path_from, ".", "..", "..")
  defassert(:relative_path_from, "..", "..", ".")

  defassert(:relative_path_from, "c/d", "/a/b/c/d", "/a/b")
  defassert(:relative_path_from, "../..", "/a/b", "/a/b/c/d")
  defassert(:relative_path_from, "../../../../e", "/e", "/a/b/c/d")
  defassert(:relative_path_from, "../b/c", "a/b/c", "a/d")

  defassert(:relative_path_from, "../a", "/../a", "/b")
  defassert(:relative_path_from, "../../a", "../a", "b")
  defassert(:relative_path_from, ".", "/a/../../b", "/b")
  defassert(:relative_path_from, "..", "a/..", "a")
  defassert(:relative_path_from, ".", "a/../b", "b")

  defassert(:relative_path_from, "a", "a", "b/..")
  defassert(:relative_path_from, "b/c", "b/c", "b/..")

  defassert_raise(:relative_path_from, ArgumentError, "/", ".")
  defassert_raise(:relative_path_from, ArgumentError, ".", "/")
  defassert_raise(:relative_path_from, ArgumentError, "a", "..")
  defassert_raise(:relative_path_from, ArgumentError, ".", "..")

  def with_tmpchdir(base=nil)
    Dir.mktmpdir(base) { |d|
      d = Path.new(d).realpath.to_s
      Dir.chdir(d) {
        yield d
      }
    }
  end

  def has_symlink?
    begin
      File.symlink(nil, nil)
    rescue NotImplementedError
      return false
    rescue TypeError
    end
    return true
  end

  def realpath(path, basedir=nil)
    Path.new(path).realpath(basedir).to_s
  end

  def test_realpath
    return if !has_symlink?
    with_tmpchdir('rubytest-pathname') { |dir|
      assert_raise(Errno::ENOENT) { realpath("#{dir}/not-exist") }
      File.symlink("not-exist-target", "#{dir}/not-exist")
      assert_raise(Errno::ENOENT) { realpath("#{dir}/not-exist") }

      File.symlink("loop", "#{dir}/loop")
      assert_raise(Errno::ELOOP) { realpath("#{dir}/loop") }
      assert_raise(Errno::ELOOP) { realpath("#{dir}/loop", dir) }

      File.symlink("../#{File.basename(dir)}/./not-exist-target", "#{dir}/not-exist2")
      assert_raise(Errno::ENOENT) { realpath("#{dir}/not-exist2") }

      File.open("#{dir}/exist-target", "w") {}
      File.symlink("../#{File.basename(dir)}/./exist-target", "#{dir}/exist2")
      assert_nothing_raised { realpath("#{dir}/exist2") }

      File.symlink("loop-relative", "loop-relative")
      assert_raise(Errno::ELOOP) { realpath("#{dir}/loop-relative") }

      Dir.mkdir("exist")
      assert_equal("#{dir}/exist", realpath("exist"))
      assert_raise(Errno::ELOOP) { realpath("../loop", "#{dir}/exist") }

      File.symlink("loop1/loop1", "loop1")
      assert_raise(Errno::ELOOP) { realpath("#{dir}/loop1") }

      File.symlink("loop2", "loop3")
      File.symlink("loop3", "loop2")
      assert_raise(Errno::ELOOP) { realpath("#{dir}/loop2") }

      Dir.mkdir("b")

      File.symlink("b", "c")
      assert_equal("#{dir}/b", realpath("c"))
      assert_equal("#{dir}/b", realpath("c/../c"))
      assert_equal("#{dir}/b", realpath("c/../c/../c/."))

      File.symlink("..", "b/d")
      assert_equal("#{dir}/b", realpath("c/d/c/d/c"))

      File.symlink("#{dir}/b", "e")
      assert_equal("#{dir}/b", realpath("e"))

      Dir.mkdir("f")
      Dir.mkdir("f/g")
      File.symlink("f/g", "h")
      assert_equal("#{dir}/f/g", realpath("h"))
      File.chmod(0000, "f")
      assert_raise(Errno::EACCES) { realpath("h") }
      File.chmod(0755, "f")
    }
  end

  def realdirpath(path)
    Path.new(path).realdirpath.to_s
  end

  def test_realdirpath
    return if !has_symlink?
    Dir.mktmpdir('rubytest-pathname') { |dir|
      rdir = realpath(dir)
      assert_equal("#{rdir}/not-exist", realdirpath("#{dir}/not-exist"))
      assert_raise(Errno::ENOENT) { realdirpath("#{dir}/not-exist/not-exist-child") }
      File.symlink("not-exist-target", "#{dir}/not-exist")
      assert_equal("#{rdir}/not-exist-target", realdirpath("#{dir}/not-exist"))
      File.symlink("../#{File.basename(dir)}/./not-exist-target", "#{dir}/not-exist2")
      assert_equal("#{rdir}/not-exist-target", realdirpath("#{dir}/not-exist2"))
      File.open("#{dir}/exist-target", "w") {}
      File.symlink("../#{File.basename(dir)}/./exist-target", "#{dir}/exist")
      assert_equal("#{rdir}/exist-target", realdirpath("#{dir}/exist"))
      File.symlink("loop", "#{dir}/loop")
      assert_raise(Errno::ELOOP) { realdirpath("#{dir}/loop") }
    }
  end

  def descend(path)
    Path.new(path).enum_for(:descend).map { |v| v.to_s }
  end

  defassert(:descend, %w[/ /a /a/b /a/b/c], "/a/b/c")
  defassert(:descend, %w[a a/b a/b/c], "a/b/c")
  defassert(:descend, %w[. ./a ./a/b ./a/b/c], "./a/b/c")
  defassert(:descend, %w[a/], "a/")

  def ascend(path)
    Path.new(path).enum_for(:ascend).map { |v| v.to_s }
  end

  defassert(:ascend, %w[/a/b/c /a/b /a /], "/a/b/c")
  defassert(:ascend, %w[a/b/c a/b a], "a/b/c")
  defassert(:ascend, %w[./a/b/c ./a/b ./a .], "./a/b/c")
  defassert(:ascend, %w[a/], "a/")

  def test_initialize
    p1 = Path.new('a')
    assert_equal('a', p1.to_s)
    p2 = Path.new(p1)
    assert_equal(p1, p2)
  end

  class AnotherStringLike # :nodoc:
    def initialize(s) @s = s end
    def to_str() @s end
    def ==(other) @s == other end
  end

  def test_equality
    obj = Path.new("a")
    str = "a"
    sym = :a
    ano = AnotherStringLike.new("a")
    assert_equal(false, obj == str)
    assert_equal(false, str == obj)
    assert_equal(false, obj == ano)
    assert_equal(false, ano == obj)
    assert_equal(false, obj == sym)
    assert_equal(false, sym == obj)

    obj2 = Path.new("a")
    assert_equal(true, obj == obj2)
    assert_equal(true, obj === obj2)
    assert_equal(true, obj.eql?(obj2))
  end

  def test_hashkey
    h = {}
    h[Path.new("a")] = 1
    h[Path.new("a")] = 2
    assert_equal(1, h.size)
  end

  def assert_pathname_cmp(e, s1, s2)
    p1 = Path.new(s1)
    p2 = Path.new(s2)
    r = p1 <=> p2
    assert(e == r,
      "#{p1.inspect} <=> #{p2.inspect}: <#{e}> expected but was <#{r}>")
  end
  def test_comparison
    assert_pathname_cmp( 0, "a", "a")
    assert_pathname_cmp( 1, "b", "a")
    assert_pathname_cmp(-1, "a", "b")
    ss = %w(
      a
      a/
      a/b
      a.
      a0
    )
    s1 = ss.shift
    ss.each { |s2|
      assert_pathname_cmp(-1, s1, s2)
      s1 = s2
    }
  end

  def test_comparison_string
    assert_equal(nil, Path.new("a") <=> "a")
    assert_equal(nil, "a" <=> Path.new("a"))
  end

  def pathsubext(path, repl) Path.new(path).sub_ext(repl).to_s end
  defassert(:pathsubext, 'a.o', 'a.c', '.o')
  defassert(:pathsubext, 'a.o', 'a.c++', '.o')
  defassert(:pathsubext, 'a.png', 'a.gif', '.png')
  defassert(:pathsubext, 'ruby.tar.bz2', 'ruby.tar.gz', '.bz2')
  defassert(:pathsubext, 'd/a.o', 'd/a.c', '.o')
  defassert(:pathsubext, 'foo', 'foo.exe', '')
  defassert(:pathsubext, 'lex.yy.o', 'lex.yy.c', '.o')
  defassert(:pathsubext, 'fooaa.o', 'fooaa', '.o')
  defassert(:pathsubext, 'd.e/aa.o', 'd.e/aa', '.o')
  defassert(:pathsubext, 'long_enough.bug-3664', 'long_enough.not_to_be_embeded[ruby-core-31640]', '.bug-3664') # [ruby-core:31640]

  def root?(path)
    Path.new(path).root?
  end

  defassert(:root?, true, "/")
  defassert(:root?, true, "//")
  defassert(:root?, true, "///")
  defassert(:root?, false, "")
  defassert(:root?, false, "a")

  def test_mountpoint?
    r = Path("/").mountpoint?
    assert([true, false].include? r)
  end

  def test_destructive_update
    path = Path.new("a")
    path.to_s.replace "b"
    assert_equal(Path.new("a"), path)
  end

  def test_taint
    obj = Path.new("a"); assert_same(obj, obj.taint)
    obj = Path.new("a"); assert_same(obj, obj.untaint)

    assert_equal(false, Path.new("a"      )           .tainted?)
    assert_equal(false, Path.new("a"      )      .to_s.tainted?)
    assert_equal(true,  Path.new("a"      ).taint     .tainted?)
    assert_equal(true,  Path.new("a"      ).taint.to_s.tainted?)
    assert_equal(true,  Path.new("a".taint)           .tainted?)
    assert_equal(true,  Path.new("a".taint)      .to_s.tainted?)
    assert_equal(true,  Path.new("a".taint).taint     .tainted?)
    assert_equal(true,  Path.new("a".taint).taint.to_s.tainted?)

    str = "a"
    path = Path.new(str)
    str.taint
    assert_equal(false, path     .tainted?)
    assert_equal(false, path.to_s.tainted?)
  end

  def test_untaint
    obj = Path.new("a"); assert_same(obj, obj.untaint)

    assert_equal(false, Path.new("a").taint.untaint     .tainted?)
    assert_equal(false, Path.new("a").taint.untaint.to_s.tainted?)

    str = "a".taint
    path = Path.new(str)
    str.untaint
    assert_equal(true, path     .tainted?)
    assert_equal(true, path.to_s.tainted?)
  end

  def test_freeze
    obj = Path.new("a"); assert_same(obj, obj.freeze)

    assert_equal(false, Path.new("a"       )            .frozen?)
    assert_equal(false, Path.new("a".freeze)            .frozen?)
    assert_equal(true,  Path.new("a"       ).freeze     .frozen?)
    assert_equal(true,  Path.new("a".freeze).freeze     .frozen?)
    assert_equal(false, Path.new("a"       )       .to_s.frozen?)
    assert_equal(false, Path.new("a".freeze)       .to_s.frozen?)
    assert_equal(false, Path.new("a"       ).freeze.to_s.frozen?)
    assert_equal(false, Path.new("a".freeze).freeze.to_s.frozen?)
  end

  def test_freeze_and_taint
    obj = Path.new("a")
    obj.freeze
    assert_equal(false, obj.tainted?)
    assert_raise(ruby19? ? RuntimeError : TypeError) { obj.taint }

    obj = Path.new("a")
    obj.taint
    assert_equal(true, obj.tainted?)
    obj.freeze
    assert_equal(true, obj.tainted?)
    assert_nothing_raised { obj.taint }
  end

  def test_to_s
    str = "a"
    obj = Path.new(str)
    assert_equal(str, obj.to_s)
    assert_not_same(str, obj.to_s)
    assert_not_same(obj.to_s, obj.to_s)
  end

  def test_kernel_open
    count = 0
    result = Kernel.open(Path.new(__FILE__)) { |f|
      assert(File.identical?(__FILE__, f))
      count += 1
      2
    }
    assert_equal(1, count)
    assert_equal(2, result)
  end

  def test_each_filename
    result = []
    Path.new("/usr/bin/ruby").each_filename { |f| result << f }
    assert_equal(%w[usr bin ruby], result)
    assert_equal(%w[usr bin ruby], Path.new("/usr/bin/ruby").each_filename.to_a)
  end

  def test_kernel_pathname
    assert_equal(Path.new("a"), Path("a"))
  end

  def test_children
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") {}
      open("b", "w") {}
      Dir.mkdir("d")
      open("d/x", "w") {}
      open("d/y", "w") {}
      assert_equal([Path("a"), Path("b"), Path("d")], Path(".").children.sort)
      assert_equal([Path("d/x"), Path("d/y")], Path("d").children.sort)
      assert_equal([Path("x"), Path("y")], Path("d").children(false).sort)
    }
  end

  def test_each_child
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") {}
      open("b", "w") {}
      Dir.mkdir("d")
      open("d/x", "w") {}
      open("d/y", "w") {}
      a = []; Path(".").each_child { |v| a << v }; a.sort!
      assert_equal([Path("a"), Path("b"), Path("d")], a)
      a = []; Path("d").each_child { |v| a << v }; a.sort!
      assert_equal([Path("d/x"), Path("d/y")], a)
      a = []; Path("d").each_child(false) { |v| a << v }; a.sort!
      assert_equal([Path("x"), Path("y")], a)
    }
  end

  def test_each_line
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.puts 1, 2 }
      a = []
      Path("a").each_line { |line| a << line }
      assert_equal(["1\n", "2\n"], a)

      a = []
      Path("a").each_line("2") { |line| a << line }
      assert_equal(["1\n2", "\n"], a)

      if ruby19?
        a = []
        Path("a").each_line(1) { |line| a << line }
        assert_equal(["1", "\n", "2", "\n"], a)

        a = []
        Path("a").each_line("2", 1) { |line| a << line }
        assert_equal(["1", "\n", "2", "\n"], a)
      end

      a = []
      enum = Path("a").each_line
      enum.each { |line| a << line }
      assert_equal(["1\n", "2\n"], a)
    }
  end

  def test_readlines
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.puts 1, 2 }
      a = Path("a").readlines
      assert_equal(["1\n", "2\n"], a)
    }
  end

  def test_read
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.puts 1, 2 }
      assert_equal("1\n2\n", Path("a").read)
    }
  end

  def test_binread
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      assert_equal("abc", Path("a").read)
    }
  end

  def test_sysopen
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      fd = Path("a").sysopen
      io = IO.new(fd)
      begin
        assert_equal("abc", io.read)
      ensure
        io.close
      end
    }
  end

  def test_atime
    assert_kind_of(Time, Path(__FILE__).atime)
  end

  def test_ctime
    assert_kind_of(Time, Path(__FILE__).ctime)
  end

  def test_mtime
    assert_kind_of(Time, Path(__FILE__).mtime)
  end

  def test_chmod
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      path = Path("a")
      old = path.stat.mode
      path.chmod(0444)
      assert_equal(0444, path.stat.mode & 0777)
      path.chmod(old)
    }
  end

  def test_lchmod
    return if !has_symlink?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      File.symlink("a", "l")
      path = Path("l")
      old = path.lstat.mode
      begin
        path.lchmod(0444)
      rescue NotImplementedError
        next
      end
      assert_equal(0444, path.lstat.mode & 0777)
      path.chmod(old)
    }
  end

  def test_chown
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      path = Path("a")
      old_uid = path.stat.uid
      old_gid = path.stat.gid
      begin
        path.chown(0, 0)
      rescue Errno::EPERM
        next
      end
      assert_equal(0, path.stat.uid)
      assert_equal(0, path.stat.gid)
      path.chown(old_uid, old_gid)
    }
  end

  def test_lchown
    return if !has_symlink?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      File.symlink("a", "l")
      path = Path("l")
      old_uid = path.stat.uid
      old_gid = path.stat.gid
      begin
        path.lchown(0, 0)
      rescue Errno::EPERM
        next
      end
      assert_equal(0, path.stat.uid)
      assert_equal(0, path.stat.gid)
      path.lchown(old_uid, old_gid)
    }
  end

  def test_fnmatch
    path = Path("a")
    assert_equal(true, path.fnmatch("*"))
    assert_equal(false, path.fnmatch("*.*"))
    assert_equal(false, Path(".foo").fnmatch("*"))
    assert_equal(true, Path(".foo").fnmatch("*", File::FNM_DOTMATCH))
  end

  def test_fnmatch?
    path = Path("a")
    assert_equal(true, path.fnmatch?("*"))
    assert_equal(false, path.fnmatch?("*.*"))
  end

  def test_ftype
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal("file", Path("f").ftype)
      Dir.mkdir("d")
      assert_equal("directory", Path("d").ftype)
    }
  end

  def test_make_link
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      Path("l").make_link(Path("a"))
      assert_equal("abc", Path("l").read)
    }
  end

  def test_open
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      path = Path("a")

      path.open { |f|
        assert_equal("abc", f.read)
      }

      path.open("r") { |f|
        assert_equal("abc", f.read)
      }

      Path("b").open("w", 0444) { |f| f.write "def" }
      assert_equal(0444, File.stat("b").mode & 0777)
      assert_equal("def", File.read("b"))

      if ruby19?
        Path("c").open("w", 0444, {}) { |f| f.write "ghi" }
        assert_equal(0444, File.stat("c").mode & 0777)
        assert_equal("ghi", File.read("c"))
      end

      g = path.open
      assert_equal("abc", g.read)
      g.close
    }
  end

  def test_readlink
    return if !has_symlink?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      File.symlink("a", "l")
      assert_equal(Path("a"), Path("l").readlink)
    }
  end

  def test_rename
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      Path("a").rename(Path("b"))
      assert_equal("abc", File.read("b"))
    }
  end

  def test_stat
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      s = Path("a").stat
      assert_equal(3, s.size)
    }
  end

  def test_lstat
    return if !has_symlink?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      File.symlink("a", "l")
      s = Path("l").lstat
      assert_equal(true, s.symlink?)
      s = Path("l").stat
      assert_equal(false, s.symlink?)
      assert_equal(3, s.size)
      s = Path("a").lstat
      assert_equal(false, s.symlink?)
      assert_equal(3, s.size)
    }
  end

  def test_make_symlink
    return if !has_symlink?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      Path("l").make_symlink(Path("a"))
      s = Path("l").lstat
      assert_equal(true, s.symlink?)
    }
  end

  def test_truncate
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      Path("a").truncate(2)
      assert_equal("ab", File.read("a"))
    }
  end

  def test_utime
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") { |f| f.write "abc" }
      atime = Time.utc(2000)
      mtime = Time.utc(1999)
      Path("a").utime(atime, mtime)
      s = File.stat("a")
      assert_equal(atime, s.atime)
      assert_equal(mtime, s.mtime)
    }
  end

  def test_basename
    assert_equal(Path("basename"), Path("dirname/basename").basename)
    assert_equal(Path("bar"), Path("foo/bar.x").basename(".x"))
  end

  def test_dirname
    assert_equal(Path("dirname"), Path("dirname/basename").dirname)
  end

  def test_extname
    assert_equal(".ext", Path("basename.ext").extname)
  end

  def test_expand_path
    drv = DOSISH_DRIVE_LETTER ? Dir.pwd.sub(%r(/.*), '') : ""
    assert_equal(Path(drv + "/a"), Path("/a").expand_path)
    assert_equal(Path(drv + "/a"), Path("a").expand_path("/"))
    assert_equal(Path(drv + "/a"), Path("a").expand_path(Path("/")))
    assert_equal(Path(drv + "/b"), Path("/b").expand_path(Path("/a")))
    assert_equal(Path(drv + "/a/b"), Path("b").expand_path(Path("/a")))
  end

  def test_split
    assert_equal([Path("dirname"), Path("basename")], Path("dirname/basename").split)
  end

  def test_blockdev?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(false, Path("f").blockdev?)
    }
  end

  def test_chardev?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(false, Path("f").chardev?)
    }
  end

  def test_executable?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(false, Path("f").executable?)
    }
  end

  def test_executable_real?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(false, Path("f").executable_real?)
    }
  end

  def test_exist?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(true, Path("f").exist?)
    }
  end

  def test_grpowned?
    skip "Unix file owner test" if DOSISH
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      File.chown(-1, Process.gid, "f")
      assert_equal(true, Path("f").grpowned?)
    }
  end

  def test_directory?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(false, Path("f").directory?)
      Dir.mkdir("d")
      assert_equal(true, Path("d").directory?)
    }
  end

  def test_file?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(true, Path("f").file?)
      Dir.mkdir("d")
      assert_equal(false, Path("d").file?)
    }
  end

  def test_pipe?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(false, Path("f").pipe?)
    }
  end

  def test_socket?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(false, Path("f").socket?)
    }
  end

  def test_owned?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(true, Path("f").owned?)
    }
  end

  def test_readable?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(true, Path("f").readable?)
    }
  end

  def test_world_readable?
    skip "Unix file mode bit test" if DOSISH
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      File.chmod(0400, "f")
      assert_equal(nil, Path("f").world_readable?)
      File.chmod(0444, "f")
      assert_equal(0444, Path("f").world_readable?)
    }
  end

  def test_readable_real?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(true, Path("f").readable_real?)
    }
  end

  def test_setuid?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(false, Path("f").setuid?)
    }
  end

  def test_setgid?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(false, Path("f").setgid?)
    }
  end

  def test_size
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(3, Path("f").size)
      open("z", "w") {}
      assert_equal(0, Path("z").size)
      assert_raise(Errno::ENOENT) { Path("not-exist").size }
    }
  end

  def test_size?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(3, Path("f").size?)
      open("z", "w") {}
      assert_equal(nil, Path("z").size?)
      assert_equal(nil, Path("not-exist").size?)
    }
  end

  def test_sticky?
    skip "Unix file mode bit test" if DOSISH
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(false, Path("f").sticky?)
    }
  end

  def test_symlink?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(false, Path("f").symlink?)
    }
  end

  def test_writable?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(true, Path("f").writable?)
    }
  end

  def test_world_writable?
    skip "Unix file mode bit test" if DOSISH
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      File.chmod(0600, "f")
      assert_equal(nil, Path("f").world_writable?)
      File.chmod(0666, "f")
      assert_equal(0666, Path("f").world_writable?)
    }
  end

  def test_writable_real?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(true, Path("f").writable?)
    }
  end

  def test_zero?
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      assert_equal(false, Path("f").zero?)
      open("z", "w") {}
      assert_equal(true, Path("z").zero?)
      assert_equal(false, Path("not-exist").zero?)
    }
  end

  def test_s_glob
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      Dir.mkdir("d")
      assert_equal([Path("d"), Path("f")], Path.glob("*").sort)
      a = []
      Path.glob("*") { |path| a << path }
      a.sort!
      assert_equal([Path("d"), Path("f")], a)
    }
  end

  def test_s_getwd
    wd = Path.getwd
    assert_kind_of(Path, wd)
  end

  def test_s_pwd
    wd = Path.pwd
    assert_kind_of(Path, wd)
  end

  def test_entries
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") {}
      open("b", "w") {}
      assert_equal([Path("a"), Path("b")], Path(".").entries.sort)
    }
  end

  def test_each_entry
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") {}
      open("b", "w") {}
      a = []
      Path(".").each_entry { |v| a << v }
      assert_equal([Path("."), Path(".."), Path("a"), Path("b")], a.sort)
    }
  end

  def test_mkdir
    with_tmpchdir('rubytest-pathname') { |dir|
      Path("d").mkdir
      assert(File.directory?("d"))
      Path("e").mkdir(0770)
      assert(File.directory?("e"))
    }
  end

  def test_rmdir
    with_tmpchdir('rubytest-pathname') { |dir|
      Path("d").mkdir
      assert(File.directory?("d"))
      Path("d").rmdir
      assert(!File.exists?("d"))
    }
  end

  def test_opendir
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") {}
      open("b", "w") {}
      a = []
      Path(".").opendir { |d|
        d.each { |e| a << e }
      }
      assert_equal([".", "..", "a", "b"], a.sort)
    }
  end

  def test_find
    with_tmpchdir('rubytest-pathname') { |dir|
      open("a", "w") {}
      open("b", "w") {}
      Dir.mkdir("d")
      open("d/x", "w") {}
      open("d/y", "w") {}
      a = []; Path(".").find { |v| a << v }; a.sort!
      assert_equal([Path("."), Path("a"), Path("b"), Path("d"), Path("d/x"), Path("d/y")], a)
      a = []; Path("d").find { |v| a << v }; a.sort!
      assert_equal([Path("d"), Path("d/x"), Path("d/y")], a)
      a = Path(".").find.sort
      assert_equal([Path("."), Path("a"), Path("b"), Path("d"), Path("d/x"), Path("d/y")], a)
      a = Path("d").find.sort
      assert_equal([Path("d"), Path("d/x"), Path("d/y")], a)
    }
  end

  def test_mkpath
    with_tmpchdir('rubytest-pathname') { |dir|
      Path("a/b/c/d").mkpath
      assert(File.directory?("a/b/c/d"))
    }
  end

  def test_rmtree
    with_tmpchdir('rubytest-pathname') { |dir|
      Path("a/b/c/d").mkpath
      assert(File.exist?("a/b/c/d"))
      Path("a").rmtree
      assert(!File.exist?("a"))
    }
  end

  def test_unlink
    with_tmpchdir('rubytest-pathname') { |dir|
      open("f", "w") { |f| f.write "abc" }
      Path("f").unlink
      assert(!File.exist?("f"))
      Dir.mkdir("d")
      Path("d").unlink
      assert(!File.exist?("d"))
    }
  end

  def test_file_basename
    assert_equal("bar", File.basename(Path.new("foo/bar")))
  end

  def test_file_dirname
    assert_equal("foo", File.dirname(Path.new("foo/bar")))
  end

  def test_file_split
    assert_equal(["foo", "bar"], File.split(Path.new("foo/bar")))
  end

  def test_file_extname
    assert_equal(".baz", File.extname(Path.new("bar.baz")))
  end

  def test_file_fnmatch
    assert(File.fnmatch("*.*", Path.new("bar.baz")))
  end

  def test_file_join
    assert_equal("foo/bar", File.join(Path.new("foo"), Path.new("bar")))
    lambda {
      $SAFE = 1
      assert_equal("foo/bar", File.join(Path.new("foo"), Path.new("bar").taint))
    }.call
  end
end
