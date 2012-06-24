class Path
  class << self
    # @!group Identity

    # Creates a new Path. See {#initialize}.
    def new(*args)
      if args.size == 1 and Path === args.first
        args.first
      else
        super(*args)
      end
    end
    alias :[] :new

    # A class constructor.
    #
    #   %w[foo bar].map(&Path) # == [Path('foo'), Path('bar')]
    def to_proc
      lambda { |path| new(path) }
    end

    # Whether +object+ looks like a path.
    # The current test checks if the object responds to
    # #to_path, #path or #to_str.
    def like? object
      [:to_path, :path, :to_str].any? { |meth| object.respond_to? meth }
    end

    # A matcher responding to #===. Useful for case clauses, grep, etc.
    # See {Path.like?}.
    #
    #   case obj
    #   when Path.like then Path(obj)
    #   # ...
    #   end
    def like
      @like ||= begin
        matcher = Object.new
        def matcher.===(object)
          Path.like?(object)
        end
        matcher
      end
    end
  end

  # @!group Identity

  # Returns the +path+ as a String.
  # {#path} is implemented for better readability (+file.path+ instead of +file.to_s+) and as an accessor.
  # {#to_path} is implemented so Path objects are usable with +open+, etc.
  # {#to_str} is implemented so Path objects are usable with +open+, etc with Ruby 1.8 (it is not defined in Ruby 1.9).
  attr_reader :path
  alias :to_s :path
  alias :to_path :path
  alias :to_str :path if RUBY_VERSION < '1.9'

  # Compare this path with +other+. The comparison is string-based.
  # Be aware that two different paths (+foo.txt+ and +./foo.txt+)
  # can refer to the same file.
  def == other
    Path === other and @path == other.path
  end
  alias :eql? :==

  # Provides for comparing paths, case-sensitively.
  def <=>(other)
    return nil unless Path === other
    @path.tr('/', "\0") <=> other.path.tr('/', "\0")
  end

  # The hash value of the +path+.
  def hash
    @path.hash
  end

  # Returns the +path+ as a Symbol.
  def to_sym
    @path.to_sym
  end

  # A representation of the +path+.
  def inspect
    "#<Path #{@path}>"
  end
end

unless defined? NO_EPATH_GLOBAL_FUNCTION
  # A shorthand method to create a {Path}. Same as {Path.new}.
  def Path(*args)
    Path.new(*args)
  end
end
