# Enchanced Pathname
# Use the composite pattern with a Pathname

require File.expand_path('../epath/implementation', __FILE__)
require 'tempfile'

class Path
  DOTS = %w[. ..]

  class << self
    def new(*args)
      if args.size == 1 and Path === args[0]
        args[0]
      else
        super(*args)
      end
    end
    alias_method :[], :new

    def to_proc
      lambda { |path| new(path) }
    end

    def here(from = nil)
      from ||= caller
      new(from.first.split(/:\d+(?:$|:in)/).first).expand
    end
    alias_method :file, :here

    def dir(from = nil)
      from ||= caller
      file(from).dir
    end

    def home
      new(Dir.respond_to?(:home) ? Dir.home : new("~").expand)
    end

    def relative(path)
      new(path).expand dir(caller)
    end

    def backfind(path)
      here(caller).backfind(path)
    end

    def tmpfile(basename = '', tmpdir = nil, options = nil)
      tempfile = Tempfile.new(basename, *[tmpdir, options].compact)
      file = new tempfile
      if block_given?
        begin
          yield file
        ensure
          tempfile.close
          tempfile.unlink if file.exist?
        end
      end
      file
    end
    alias_method :tempfile, :tmpfile

    def tmpdir(prefix_suffix = nil, *rest)
      require 'tmpdir'
      dir = new Dir.mktmpdir(prefix_suffix, *rest)
      if block_given?
        begin
          yield dir
        ensure
          FileUtils.remove_entry_secure(dir) rescue nil
        end
      end
      dir
    end
  end

  def initialize(*parts)
    path = parts.size > 1 ? parts.join(File::SEPARATOR) : parts.first
    if Tempfile === path
      @_tmpfile = path # We would not want it to be GC'd
      @path = path.path
    else
      @path = path.to_s
    end
  end

  def / part
    join part.to_s
  end

  def base # basename(extname)
    basename(extname)
  end

  def ext # extname without leading .
    ext = extname
    ext.empty? ? ext : ext[1..-1]
  end

  def without_extension # rm_ext
    dir / base
  end

  # NOTE: Pathname has a similar feature named sub_ext
  # It might be a better method name
  def replace_extension(ext)
    ext = ".#{ext}" unless ext.start_with? '.'
    Path.new(without_extension.to_s + ext)
  end

  def entries
    (Dir.entries(@path) - DOTS).map { |entry| Path.new(@path, entry).cleanpath }
  end

  def glob(pattern, flags = 0)
    Dir.glob(join(pattern), flags).map(&Path)
  end

  def rm
    FileUtils.rm(@path)
    self
  end

  def rm_f
    FileUtils.rm_f(@path)
    self
  end

  def rm_rf
    FileUtils.rm_rf(@path)
    self
  end

  def mkdir_p
    FileUtils.mkdir_p(@path)
    self
  end

  def write(contents, open_args = nil)
    if IO.respond_to? :write
      IO.write(@path, contents, *[open_args].compact)
    else
      open('w', *[open_args].compact) { |f| f.write(contents) }
    end
  end

  def to_sym
    to_s.to_sym
  end

  def relative_to other
    relative_path_from Path.new other
  end
  alias_method :%, :relative_to

  def ancestors
    ancestors = lambda do |y|
      y << path = expand
      until (path = path.parent).root?
        y << path
      end
      y << path
    end
    RUBY_VERSION > '1.9' ? Enumerator.new(&ancestors) : ancestors.call([])
  end

  def backfind(path)
    condition = path[/\[(.*)\]$/, 1] || ''
    path = $` unless condition.empty?

    result = ancestors.find { |ancestor| (ancestor/path/condition).exist? }
    result/path if result
  end

  alias_method :expand, :expand_path
  alias_method :dir, :dirname
end

EPath = Path # to meet everyone's expectations

unless defined? NO_EPATH_GLOBAL_FUNCTION
  def Path(*args)
    Path.new(*args)
  end
end
