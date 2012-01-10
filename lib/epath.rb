# Enchanced Pathname
# Use the composite pattern with a Pathname

Dir.glob(File.expand_path('../epath/*.rb',__FILE__)) { |file| require file }

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
    elsif String === path
      @path = path.dup
    else
      @path = path.to_s
    end
    taint if @path.tainted?
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

  def add_extension(ext)
    return self if ext.empty?
    ext = ".#{ext}" unless ext.start_with? '.'
    Path.new @path+ext
  end
  alias_method :add_ext, :add_extension

  def without_extension
    Path.new @path[0..-extname.size-1]
  end
  alias_method :rm_ext, :without_extension

  def replace_extension(ext)
    return without_extension if ext.empty?
    ext = ".#{ext}" unless ext.start_with? '.'
    Path.new(@path[0..-extname.size-1] << ext)
  end
  alias_method :sub_ext, :replace_extension

  def entries
    (Dir.entries(@path) - DOTS).map { |entry| Path.new(@path, entry).cleanpath }
  end

  def glob(pattern, flags = 0)
    Dir.glob(join(pattern), flags).map(&Path)
  end

  def chdir(&block)
    Dir.chdir(self, &block)
  end

  def empty?
    size == 0
  end

  def write(contents, open_args = nil)
    if IO.respond_to? :write
      IO.write(@path, contents, *[open_args].compact)
    else
      open('w', *[open_args].compact) { |f| f.write(contents) }
    end
  end

  def append(contents, open_args = nil)
    if IO.respond_to? :write
      open_args = (Array(open_args) << {:mode => 'a'})
      IO.write(@path, contents, *open_args.compact)
    else
      open('a', *[open_args].compact) { |f| f.write(contents) }
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
  alias_method :dir?, :directory?
end

EPath = Path # to meet everyone's expectations

unless defined? NO_EPATH_GLOBAL_FUNCTION
  def Path(*args)
    Path.new(*args)
  end
end
