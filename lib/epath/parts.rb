class Path
  # Returns the last component of the path. See +File.basename+.
  def basename(*args)
    Path.new(File.basename(@path, *args))
  end

  # basename(extname)
  def base
    basename(extname)
  end

  # Returns all but the last component of the path. See +File.dirname+.
  def dirname
    Path.new(File.dirname(@path))
  end
  alias :dir :dirname

  # Returns the file's extension. See +File.extname+.
  def extname
    File.extname(@path)
  end

  # extname without leading .
  def ext
    ext = extname
    ext.empty? ? ext : ext[1..-1]
  end

  # Returns the #dirname and the #basename in an Array. See +File.split+.
  def split
    File.split(@path).map(&Path)
  end

  def add_extension(ext)
    return self if ext.empty?
    Path.new @path+dotted_ext(ext)
  end
  alias :add_ext :add_extension

  def without_extension
    Path.new @path[0..-extname.size-1]
  end
  alias :rm_ext :without_extension

  def replace_extension(ext)
    return without_extension if ext.empty?
    Path.new(@path[0..-extname.size-1] << dotted_ext(ext))
  end
  alias :sub_ext :replace_extension

  # Iterates over each component of the path.
  #
  #   Path.new("/usr/bin/ruby").each_filename { |filename| ... }
  #     # yields "usr", "bin", and "ruby".
  def each_filename # :yield: filename
    return to_enum(__method__) unless block_given?
    _, names = split_names(@path)
    names.each { |filename| yield filename }
    nil
  end

  # Iterates over and yields a new Path object
  # for each element in the given path in descending order.
  #
  #  Path.new('/path/to/some/file.rb').descend { |v| p v }
  #     #<Path />
  #     #<Path /path>
  #     #<Path /path/to>
  #     #<Path /path/to/some>
  #     #<Path /path/to/some/file.rb>
  #
  #  Path.new('path/to/some/file.rb').descend { |v| p v }
  #     #<Path path>
  #     #<Path path/to>
  #     #<Path path/to/some>
  #     #<Path path/to/some/file.rb>
  #
  # It doesn't access actual filesystem.
  def descend
    return to_enum(:descend) unless block_given?
    vs = []
    ascend { |v| vs << v }
    vs.reverse_each { |v| yield v }
    nil
  end

  # Iterates over and yields a new Path object
  # for each element in the given path in ascending order.
  #
  #  Path.new('/path/to/some/file.rb').ascend { |v| p v }
  #     #<Path /path/to/some/file.rb>
  #     #<Path /path/to/some>
  #     #<Path /path/to>
  #     #<Path /path>
  #     #<Path />
  #
  #  Path.new('path/to/some/file.rb').ascend { |v| p v }
  #     #<Path path/to/some/file.rb>
  #     #<Path path/to/some>
  #     #<Path path/to>
  #     #<Path path>
  #
  # It doesn't access actual filesystem.
  def ascend
    return to_enum(:ascend) unless block_given?
    path = @path
    yield self
    while r = chop_basename(path)
      path, = r
      break if path.empty?
      yield Path.new(del_trailing_separator(path))
    end
  end
  alias :ancestors :ascend
end
