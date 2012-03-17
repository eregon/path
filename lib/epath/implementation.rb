# Path's low-level implementation based on Pathname

class Path
  # @private
  SAME_PATHS = if File::FNM_SYSCASE.nonzero?
    lambda { |a,b| a.casecmp(b).zero? }
  else
    lambda { |a,b| a == b }
  end

  def initialize(*parts)
    path = parts.size > 1 ? File.join(parts) : parts.first
    @path = case path
    when Tempfile
      @_tmpfile = path # We would not want it to be GC'd
      path.path.dup
    when String
      path.dup
    else
      path.to_s.dup
    end

    init
  end

  def yaml_initialize(tag, ivars)
    @path = ivars['path']
    init
  end

  def marshal_dump
    @path
  end

  def marshal_load path
    @path = path
    init
  end

  # Returns clean path of +self+ with consecutive slashes and useless dots removed.
  # The filesystem is not accessed.
  #
  # If +consider_symlink+ is +true+, then a more conservative algorithm is used
  # to avoid breaking symbolic linkages. This may retain more +..+
  # entries than absolutely necessary, but without accessing the filesystem,
  # this can't be avoided. See #realpath.
  def cleanpath(consider_symlink=false)
    if consider_symlink
      cleanpath_conservative
    else
      cleanpath_aggressive
    end
  end

  # #parent returns the parent directory.
  #
  # This is same as <tt>self + '..'</tt>.
  def parent
    self + '..'
  end

  # Path#+ appends a path fragment to this one to produce a new Path.
  #
  #   p1 = Path.new("/usr")   # => #<Path /usr>
  #   p2 = p1 + "bin/ruby"    # => #<Path /usr/bin/ruby>
  #   p3 = p1 + "/etc/passwd" # => #<Path /etc/passwd>
  #
  # This method doesn't access the file system, it is pure string manipulation.
  def +(other)
    Path.new(plus(@path, other.to_s))
  end

  # Path#join joins paths.
  #
  # <tt>path0.join(path1, ..., pathN)</tt> is the same as
  # <tt>path0 + path1 + ... + pathN</tt>.
  def join(*args)
    args.unshift self
    result = Path.new(args.pop)
    return result if result.absolute?
    args.reverse_each { |arg|
      arg = Path.new(arg)
      result = arg + result
      return result if result.absolute?
    }
    result
  end

  # #relative_path_from returns a relative path from the argument to the
  # receiver. If +self+ is absolute, the argument must be absolute too.
  # If +self+ is relative, the argument must be relative too.
  #
  # #relative_path_from doesn't access the filesystem. It assumes no symlinks.
  #
  # ArgumentError is raised when it cannot find a relative path.
  def relative_path_from(base_directory)
    dest_directory = cleanpath.to_s
    base_directory = Path.new(base_directory).cleanpath.to_s
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

  # @private
  module Helpers
    private

    # remove the leading . of +ext+ if present.
    def pure_ext(ext)
      ext.start_with?('.') ? ext[1..-1] : ext
    end

    # add a leading . to +ext+ if missing. Returns '' if +ext+ is empty.
    def dotted_ext(ext)
      (ext.empty? or ext.start_with?('.')) ? ext : ".#{ext}"
    end
  end

  include Helpers
  extend Helpers

  private

  def init
    validate(@path)

    taint if @path.tainted?
    @path.freeze
    freeze
  end

  def validate(path)
    raise ArgumentError, "path contains a null byte: #{path.inspect}" if path.include? "\0"
    path.gsub!(File::ALT_SEPARATOR, '/') if File::ALT_SEPARATOR
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
    if r = chop_basename(path)
      pre, basename = r
      pre.length + basename.length < path.length
    else
      false
    end
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
    elsif /\/+\z/o =~ path
      $` + File.dirname(path)[/\/*\z/o]
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
        if names[0] == '..'
          names.shift
        else
          names.unshift base
        end
      end
    end
    if File.basename(pre).include? '/'
      names.shift while names[0] == '..'
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
      names.shift while names[0] == '..'
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

  if File.respond_to?(:realpath) and File.respond_to?(:realdirpath)
    def real_path_internal(strict = false, basedir = nil)
      strict ? File.realpath(@path, basedir) : File.realdirpath(@path, basedir)
    end
  else
    def realpath_rec(prefix, unresolved, h, strict, last = true)
      resolved = []
      until unresolved.empty?
        n = unresolved.shift
        if n == '.'
          next
        elsif n == '..'
          resolved.pop
        else
          path = prepend_prefix(prefix, File.join(*(resolved + [n])))
          if h.include? path
            if h[path] == :resolving
              raise Errno::ELOOP.new(path)
            else
              prefix, *resolved = h[path]
            end
          else
            begin
              s = File.lstat(path)
            rescue Errno::ENOENT => e
              raise e if strict || !last || !unresolved.empty?
              resolved << n
              break
            end
            if s.symlink?
              h[path] = :resolving
              link_prefix, link_names = split_names(File.readlink(path))
              if link_prefix == ''
                prefix, *resolved = h[path] = realpath_rec(prefix, resolved + link_names, h, strict, unresolved.empty?)
              else
                prefix, *resolved = h[path] = realpath_rec(link_prefix, link_names, h, strict, unresolved.empty?)
              end
            else
              resolved << n
              h[path] = [prefix, *resolved]
            end
          end
        end
      end
      return prefix, *resolved
    end

    def real_path_internal(strict = false, basedir = nil)
      path = @path
      path = File.join(basedir, path) if basedir and relative?
      prefix, names = split_names(path)
      if prefix == ''
        prefix, names2 = split_names(Dir.pwd)
        names = names2 + names
      end
      prefix, *names = realpath_rec(prefix, names, {}, strict)
      prepend_prefix(prefix, File.join(*names))
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
