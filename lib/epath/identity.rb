class Path
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
    @path.freeze
    freeze
  end

  # Compare this pathname with +other+.  The comparison is string-based.
  # Be aware that two different paths (<tt>foo.txt</tt> and <tt>./foo.txt</tt>)
  # can refer to the same file.
  def == other
    Path === other and @path == other.to_path
  end
  alias_method :eql?, :==

  # Provides for comparing pathnames, case-sensitively.
  def <=>(other)
    return nil unless Path === other
    @path.tr('/', "\0") <=> other.to_s.tr('/', "\0")
  end

  def hash
    @path.hash
  end

  # Return the path as a String.
  def to_s
    @path
  end

  # to_path is implemented so Path objects are usable with File.open, etc.
  alias_method :to_path, :to_s

  alias_method :to_str, :to_s if RUBY_VERSION < '1.9'

  def to_sym
    @path.to_sym
  end

  def inspect
    "#<Path #{@path}>"
  end
end

unless defined? NO_EPATH_GLOBAL_FUNCTION
  def Path(*args)
    Path.new(*args)
  end
end
