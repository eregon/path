# Path's low-level implementation based on Pathname

class Path
  # @private
  SAME_PATHS = if File::FNM_SYSCASE.nonzero?
    lambda { |a,b| a.casecmp(b).zero? }
  else
    lambda { |a,b| a == b }
  end

  # Returns a cleaned version of +self+ with consecutive slashes and useless dots removed.
  # The filesystem is not accessed.
  #
  # If +consider_symlink+ is +true+, then a more conservative algorithm is used
  # to avoid breaking symbolic linkages. This may retain more +..+
  # entries than absolutely necessary, but without accessing the filesystem,
  # this can't be avoided. See {#realpath}.
  def clean(consider_symlink = false)
    consider_symlink ? cleanpath_conservative : cleanpath_aggressive
  end
  alias :cleanpath :clean

  # #parent returns the parent directory.
  # This can be chained.
  def parent
    self / '..'
  end

  # Path#/ appends a path fragment to this one to produce a new Path.
  #
  #   p = Path.new("/usr")  # => #<Path /usr>
  #   p / "bin/ruby"        # => #<Path /usr/bin/ruby>
  #   p / "/etc/passwd"     # => #<Path /etc/passwd>
  #
  # This method doesn't access the file system, it is pure string manipulation.
  def /(other)
    Path.new(plus(@path, other.to_s))
  end

  # Configures the behavior of {Path#+}. The default is +:warning+.
  #
  #   Path + :defined # aliased to Path#/
  #   Path + :warning # calls Path#/ but warns
  #   Path + :error   # not defined
  #   Path + :string  # like String#+. Warns if $VERBOSE (-w)
  #
  # @param config [:defined, :warning, :error, :string] the configuration value
  def Path.+(config)
    unless [:defined, :warning, :error, :string].include? config
      raise ArgumentError, "Invalid configuration: #{config.inspect}"
    end
    if @plus_configured
      raise "Path.+ has already been called: #{@plus_configured}"
    end
    remove_method :+ if method_defined? :+
    case config
    when :defined
      alias :+ :/
    when :warning
      def +(other)
        warn 'Warning: use of deprecated Path#+ as Path#/: ' <<
             "#{inspect} + #{other.inspect}\n#{caller.first}"
        self / other
      end
    when :error
      # nothing to do, the method has been removed
    when :string
      def +(other)
        warn 'Warning: use of deprecated Path#+ as String#+: ' <<
             "#{inspect} + #{other.inspect}\n#{caller.first}" if $VERBOSE
        Path(to_s + other.to_s)
      end
    end
    @plus_configured = caller.first
  end

  @plus_configured = nil # Initialization
  Path + :warning
  @plus_configured = nil # Let the user overrides this default configuration

  # @!method +(other)
  #   The behavior depends on the configuration with Path.{Path.+}.
  #   It might behave as {Path#/}, String#+, give warnings,
  #   or not be defined at all.

  # Joins paths.
  #
  #   path0.join(path1, ..., pathN)
  #   # is the same as
  #   path0 / path1 / ... / pathN
  def join(*paths)
    result = nil
    paths.reverse_each { |path|
      result = Path.new(path) / result
      return result if result.absolute?
    }
    self / result
  end

  # #relative_path_from returns a relative path from the argument to the
  # receiver. If +self+ is absolute, the argument must be absolute too.
  # If +self+ is relative, the argument must be relative too.
  #
  # #relative_path_from doesn't access the filesystem. It assumes no symlinks.
  #
  # ArgumentError is raised when it cannot find a relative path.
  def relative_path_from(base_directory)
    dest_directory = clean.path
    base_directory = Path.new(base_directory).clean.path
    dest_prefix = dest_directory
    dest_names = []
    while r = chop_basename(dest_prefix)
      dest_prefix, basename = r
      dest_names.unshift basename if basename != '.'
    end
    base_prefix = base_directory
    base_names = []
    while r = chop_basename(base_prefix)
      base_prefix, basename = r
      base_names.unshift basename if basename != '.'
    end
    unless SAME_PATHS[dest_prefix, base_prefix]
      raise ArgumentError, "different prefix: #{dest_prefix.inspect} and #{base_directory.inspect}"
    end
    until dest_names.empty? or base_names.empty? or !SAME_PATHS[dest_names.first, base_names.first]
      dest_names.shift
      base_names.shift
    end
    if base_names.include? '..'
      raise ArgumentError, "base_directory has ..: #{base_directory.inspect}"
    end
    base_names.fill('..')
    relpath_names = base_names + dest_names
    if relpath_names.empty?
      Path.new('.')
    else
      Path.new(*relpath_names)
    end
  end
  alias :relative_to :relative_path_from
  alias :% :relative_path_from

  # @private
  module Helpers
    private

    # remove the leading . of +ext+ if present.
    def pure_ext(ext)
      ext = ext.to_s and ext.start_with?('.') ? ext[1..-1] : ext
    end

    # add a leading . to +ext+ if missing. Returns '' if +ext+ is empty.
    def dotted_ext(ext)
      ext = ext.to_s and (ext.empty? or ext.start_with?('.')) ? ext : ".#{ext}"
    end
  end

  include Helpers
  extend Helpers

  private

  def init
    @path = validate(@path)

    taint if @path.tainted?
    @path.freeze
    freeze
  end

  def validate(path)
    raise ArgumentError, "path contains a null byte: #{path.inspect}" if path.include? "\0"
    path.gsub!(File::ALT_SEPARATOR, '/') if File::ALT_SEPARATOR
    path = File.expand_path(path) if path.start_with? '~'
    path
  end

  # chop_basename(path) -> [pre-basename, basename] or nil
  def chop_basename(path)
    base = File.basename(path)
    if base.empty? or base == '/'
      return nil
    else
      return path[0, path.rindex(base)], base
    end
  end

  def is_root?(path)
    chop_basename(path) == nil and path.include?('/')
  end

  # split_names(path) -> prefix, [name, ...]
  def split_names(path)
    names = []
    while r = chop_basename(path)
      path, basename = r
      names.unshift basename
    end
    return path, names
  end

  def prepend_prefix(prefix, relpath)
    if relpath.empty?
      File.dirname(prefix)
    elsif prefix.include? '/'
      add_trailing_separator(File.dirname(prefix)) + relpath
    else
      prefix + relpath
    end
  end

  def has_trailing_separator?(path)
    !is_root?(path) and path.end_with?('/')
  end

  def add_trailing_separator(path)
    if File.basename(path + 'a') == 'a'
      path
    else
      path + '/'
    end
  end

  def del_trailing_separator(path)
    if r = chop_basename(path)
      pre, basename = r
      pre + basename
    elsif %r{/+\z} =~ path
      $` + File.dirname(path)[%r{/*\z}]
    else
      path
    end
  end

  # Clean the path simply by resolving and removing excess "." and ".." entries.
  # Nothing more, nothing less.
  def cleanpath_aggressive
    path = @path
    names = []
    pre = path
    while r = chop_basename(pre)
      pre, base = r
      case base
      when '.'
      when '..'
        names.unshift base
      else
        if names.first == '..'
          names.shift
        else
          names.unshift base
        end
      end
    end
    if File.basename(pre).include? '/'
      names.shift while names.first == '..'
    end
    Path.new(prepend_prefix(pre, File.join(*names)))
  end

  def cleanpath_conservative
    path = @path
    names = []
    pre = path
    while r = chop_basename(pre)
      pre, base = r
      names.unshift base if base != '.'
    end
    if File.basename(pre).include? '/'
      names.shift while names.first == '..'
    end
    if names.empty?
      Path.new(File.dirname(pre))
    else
      if names.last != '..' && File.basename(path) == '.'
        names << '.'
      end
      result = prepend_prefix(pre, File.join(*names))
      if /\A(?:\.|\.\.)\z/ !~ names.last && has_trailing_separator?(path)
        Path.new(add_trailing_separator(result))
      else
        Path.new(result)
      end
    end
  end

  def plus(path1, path2) # -> path
    prefix2 = path2
    index_list2 = []
    basename_list2 = []
    while r2 = chop_basename(prefix2)
      prefix2, basename2 = r2
      index_list2.unshift prefix2.length
      basename_list2.unshift basename2
    end
    return path2 if prefix2 != ''
    prefix1 = path1
    while true
      while !basename_list2.empty? && basename_list2.first == '.'
        index_list2.shift
        basename_list2.shift
      end
      break unless r1 = chop_basename(prefix1)
      prefix1, basename1 = r1
      next if basename1 == '.'
      if basename1 == '..' || basename_list2.empty? || basename_list2.first != '..'
        prefix1 = prefix1 + basename1
        break
      end
      index_list2.shift
      basename_list2.shift
    end
    r1 = chop_basename(prefix1)
    if !r1 && File.basename(prefix1).include?('/')
      while !basename_list2.empty? && basename_list2.first == '..'
        index_list2.shift
        basename_list2.shift
      end
    end
    if !basename_list2.empty?
      suffix2 = path2[index_list2.first..-1]
      r1 ? File.join(prefix1, suffix2) : prefix1 + suffix2
    else
      r1 ? prefix1 : File.dirname(prefix1)
    end
  end
end
