# Enchanced Pathname
# Use the composite pattern with a Pathname

require 'pathname'
require 'fileutils'

autoload :Tempfile, 'tempfile'

class Path
  DOTS = %w[. ..]

  attr_reader :path

  class << self
    def new(*args)
      if args.size == 1 and EPath === args[0]
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
      new(path).expand file(caller).dir
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
    @path = case path
    when Pathname
      path
    when String
      Pathname.new(path)
    when Symbol
      Pathname.new(path.to_s)
    when Tempfile
      @_tmpfile = path # We would not want it to be GC'd
      Pathname.new(path.path)
    else
      raise "Invalid arguments: #{parts}"
    end
  end

  def inspect
    "#<#{self.class} #{@path}>"
  end

  def == other
    Path === other and @path == other.path
  end
  alias_method :eql?, :==

  def / part
    join part.to_s
  end

  def base # basename(extname)
    Path.new @path.basename(@path.extname)
  end

  def ext # extname without leading .
    extname = @path.extname
    extname.empty? ? extname : extname[1..-1]
  end

  def without_extension # rm_ext
    dir / base
  end

  def replace_extension(ext)
    ext = ".#{ext}" unless ext.start_with? '.'
    Path.new(without_extension.to_s + ext)
  end

  def entries
    (Dir.entries(@path) - DOTS).map { |entry| Path.new(@path, entry) }
  end

  def glob(pattern, flags = 0)
    Dir.glob(join(pattern), flags).map(&Path)
  end

  def rm_rf
    FileUtils.rm_rf(@path)
  end

  def mkdir_p
    FileUtils.mkdir_p(@path)
  end

  def write(contents, open_args = nil)
    if IO.respond_to? :write
      IO.write(@path, contents, *[open_args].compact)
    else
      open('w', *[open_args].compact) { |f| f.write(contents) }
    end
  end

  def to_sym
    @path.to_s.to_sym
  end

  def relative_to other
    Path.new @path.relative_path_from Path.new other
  end
  alias_method :%, :relative_to

  def backfind(path)
    path, cond = /^(.*?)(\[(.*)\])?$/.match(path).values_at(1, 3)
    cond ||= ""
    cur = self.expand
    until (cur/path/cond).exist?
      return nil if cur.root?
      cur = cur.parent
    end
    cur/path
  end

  (Pathname.instance_methods(false) - instance_methods(false)).each do |meth|
    class_eval <<-METHOD, __FILE__, __LINE__+1
      def #{meth}(*args, &block)
        result = @path.#{meth}(*args, &block)
        Pathname === result ? #{self}.new(result) : result
      end
    METHOD
  end

  alias_method :to_path, :to_s unless method_defined? :to_path
  alias_method :to_str, :to_s unless method_defined? :to_str

  alias_method :expand, :expand_path
  alias_method :dir, :dirname
end

EPath = Path # to meet everyone's expectations

unless defined? NO_EPATH_GLOBAL_FUNCTION
  def Path(*args)
    Path.new(*args)
  end
end
