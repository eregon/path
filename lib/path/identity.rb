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

  # Creates a new Path.
  # If multiple arguments are given, they are joined with File.join.
  # The path will have File::ALT_SEPARATOR replaced with '/' and
  # if it begins with a '~', it will be expanded (using File.expand_path).
  # Accepts an Array of Strings, a Tempfile, anything that respond to #path,
  # #to_path or #to_str with a String and defaults to calling #to_s.
  #
  # @param parts [Array<String>, Tempfile, #to_path, #path, #to_str, #to_s] the path-like object(s)
  def initialize(*parts)
    path = parts.size > 1 ? File.join(*parts) : parts.first
    @path = case path
    when Tempfile
      @_tmpfile = path # We would not want it to be GC'd
      path.path.dup
    when String
      path.dup
    else
      if path.respond_to? :to_path and String === path.to_path
        path.to_path.dup
      elsif path.respond_to? :path and String === path.path
        path.path.dup
      elsif path.respond_to? :to_str and String === path.to_str
        path.to_str.dup
      else
        path.to_s.dup
      end
    end

    init
  end

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

  # Provides a case-sensitive comparison operator for paths.
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

  # YAML loading.
  def yaml_initialize(tag, ivars)
    @path = ivars['path']
    init
  end

  # Psych loading.
  def init_with(coder)
    @path = coder['path']
    init
  end

  # JSON dumping.
  def to_json(*args)
    {
      'json_class' => 'Path',
      'data'       => @path
    }.to_json(*args)
  end

  # JSON loading.
  def self.json_create json
    new json['data']
  end

  # Marshal dumping.
  def _dump level
    @path
  end

  # Marshal loading.
  def self._load path
    self.new(path)
  end
end

# @private The extension to define the global method Path()
module Kernel
  # A shorthand method to create a {Path}. Same as {Path.new}.
  def Path(*args)
    Path.new(*args)
  end
  private :Path
end
