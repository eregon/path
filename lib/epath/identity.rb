class Path
  class << self
    # @!group Identity

    def new(*args)
      if args.size == 1 and Path === args[0]
        args[0]
      else
        super(*args)
      end
    end
    alias :[] :new

    def to_proc
      lambda { |path| new(path) }
    end
  end

  # @!group Identity

  # Compare this path with +other+. The comparison is string-based.
  # Be aware that two different paths (+foo.txt+ and +./foo.txt+)
  # can refer to the same file.
  def == other
    Path === other and @path == other.to_path
  end
  alias :eql? :==

  # Provides for comparing paths, case-sensitively.
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
  alias :to_path :to_s

  alias :to_str :to_s if RUBY_VERSION < '1.9'

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
