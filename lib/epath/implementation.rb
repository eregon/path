# Path's low-level implementation based on Pathname

class Path
  # :stopdoc:
  SAME_PATHS = if File::FNM_SYSCASE.nonzero?
    proc { |a, b| a.casecmp(b).zero? }
  else
    proc { |a, b| a == b }
  end

  # :startdoc:

  def freeze() super; @path.freeze; self end
  def taint() super; @path.taint; self end
  def untaint() super; @path.untaint; self end

  #
  # Compare this pathname with +other+.  The comparison is string-based.
  # Be aware that two different paths (<tt>foo.txt</tt> and <tt>./foo.txt</tt>)
  # can refer to the same file.
  #
  def == other
    Path === other and @path == other.to_path
  end
  alias eql? ==

  # Provides for comparing pathnames, case-sensitively.
  def <=>(other)
    return nil unless Path === other
    @path.tr('/', "\0") <=> other.to_s.tr('/', "\0")
  end

  def hash # :nodoc:
    @path.hash
  end

  # Return the path as a String.
  def to_s
    @path.dup
  end

  # to_path is implemented so Path objects are usable with File.open, etc.
  def to_path
    @path
  end

  alias to_str to_path if RUBY_VERSION < '1.9'

  def inspect
    "#<Path #{@path}>"
  end

  if File::ALT_SEPARATOR
    SEPARATOR_LIST = "#{Regexp.quote File::ALT_SEPARATOR}#{Regexp.quote File::SEPARATOR}"
    SEPARATOR_PAT = /[#{SEPARATOR_LIST}]/
  else
    SEPARATOR_LIST = "#{Regexp.quote File::SEPARATOR}"
    SEPARATOR_PAT = /#{Regexp.quote File::SEPARATOR}/
  end

  # chop_basename(path) -> [pre-basename, basename] or nil
  def chop_basename(path)
    base = File.basename(path)
    if /\A#{SEPARATOR_PAT}?\z/o =~ base
      return nil
    else
      return path[0, path.rindex(base)], base
    end
  end
  private :chop_basename

  # split_names(path) -> prefix, [name, ...]
  def split_names(path)
    names = []
    while r = chop_basename(path)
      path, basename = r
      names.unshift basename
    end
    return path, names
  end
  private :split_names

  def prepend_prefix(prefix, relpath)
    if relpath.empty?
      File.dirname(prefix)
    elsif /#{SEPARATOR_PAT}/o =~ prefix
      prefix = File.dirname(prefix)
      prefix = File.join(prefix, "") if File.basename(prefix + 'a') != 'a'
      prefix + relpath
    else
      prefix + relpath
    end
  end
  private :prepend_prefix

  # Returns clean pathname of +self+ with consecutive slashes and useless dots
  # removed.  The filesystem is not accessed.
  #
  # If +consider_symlink+ is +true+, then a more conservative algorithm is used
  # to avoid breaking symbolic linkages.  This may retain more <tt>..</tt>
  # entries than absolutely necessary, but without accessing the filesystem,
  # this can't be avoided.  See #realpath.
  #
  def cleanpath(consider_symlink=false)
    if consider_symlink
      cleanpath_conservative
    else
      cleanpath_aggressive
    end
  end

  #
  # Clean the path simply by resolving and removing excess "." and ".." entries.
  # Nothing more, nothing less.
  #
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
    if /#{SEPARATOR_PAT}/o =~ File.basename(pre)
      names.shift while names[0] == '..'
    end
    Path.new(prepend_prefix(pre, File.join(*names)))
  end
  private :cleanpath_aggressive

  # has_trailing_separator?(path) -> bool
  def has_trailing_separator?(path)
    if r = chop_basename(path)
      pre, basename = r
      pre.length + basename.length < path.length
    else
      false
    end
  end
  private :has_trailing_separator?

  # add_trailing_separator(path) -> path
  def add_trailing_separator(path)
    if File.basename(path + 'a') == 'a'
      path
    else
      File.join(path, "") # xxx: Is File.join is appropriate to add separator?
    end
  end
  private :add_trailing_separator

  def del_trailing_separator(path)
    if r = chop_basename(path)
      pre, basename = r
      pre + basename
    elsif /#{SEPARATOR_PAT}+\z/o =~ path
      $` + File.dirname(path)[/#{SEPARATOR_PAT}*\z/o]
    else
      path
    end
  end
  private :del_trailing_separator

  def cleanpath_conservative
    path = @path
    names = []
    pre = path
    while r = chop_basename(pre)
      pre, base = r
      names.unshift base if base != '.'
    end
    if /#{SEPARATOR_PAT}/o =~ File.basename(pre)
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
  private :cleanpath_conservative

  if File.respond_to?(:realpath) and File.respond_to?(:realdirpath)
    def real_path_internal(strict = false, basedir = nil)
      strict ? File.realpath(@path, basedir) : File.realdirpath(@path, basedir)
    end
    private :real_path_internal
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
    private :realpath_rec

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
    private :real_path_internal
  end

  # #parent returns the parent directory.
  #
  # This is same as <tt>self + '..'</tt>.
  def parent
    self + '..'
  end

  #
  # Path#+ appends a pathname fragment to this one to produce a new Path
  # object.
  #
  #   p1 = Path.new("/usr")      # Path:/usr
  #   p2 = p1 + "bin/ruby"           # Path:/usr/bin/ruby
  #   p3 = p1 + "/etc/passwd"        # Path:/etc/passwd
  #
  # This method doesn't access the file system; it is pure string manipulation.
  #
  def +(other)
    other = Path.new(other) unless Path === other
    Path.new(plus(@path, other.to_s))
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
    if !r1 && /#{SEPARATOR_PAT}/o =~ File.basename(prefix1)
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
  private :plus

  #
  # Path#join joins pathnames.
  #
  # <tt>path0.join(path1, ..., pathN)</tt> is the same as
  # <tt>path0 + path1 + ... + pathN</tt>.
  #
  def join(*args)
    args.unshift self
    result = args.pop
    result = Path.new(result) unless Path === result
    return result if result.absolute?
    args.reverse_each { |arg|
      arg = Path.new(arg) unless Path === arg
      result = arg + result
      return result if result.absolute?
    }
    result
  end

  #
  # #relative_path_from returns a relative path from the argument to the
  # receiver.  If +self+ is absolute, the argument must be absolute too.  If
  # +self+ is relative, the argument must be relative too.
  #
  # #relative_path_from doesn't access the filesystem.  It assumes no symlinks.
  #
  # ArgumentError is raised when it cannot find a relative path.
  #
  def relative_path_from(base_directory)
    dest_directory = cleanpath.to_s
    base_directory = base_directory.cleanpath.to_s
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
    while !dest_names.empty? &&
          !base_names.empty? &&
          SAME_PATHS[dest_names.first, base_names.first]
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
      Path.new(File.join(*relpath_names))
    end
  end
end
