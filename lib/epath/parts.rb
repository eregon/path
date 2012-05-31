class Path
  # @!group Path parts

  # Returns the last component of the path. See +File.basename+.
  def basename(*args)
    Path.new(File.basename(@path, *args))
  end

  # basename(extname)
  def base
    basename(extname)
  end

  # Returns all but the last component of the path.
  #
  # Don't chain this when the path is relative:
  #     Path('.').dir # => #<Path .>
  # Use #parent instead.
  # See +File.dirname+.
  def dirname
    Path.new(File.dirname(@path))
  end
  alias :dir :dirname

  # Returns the extension, with a leading dot. See +File.extname+.
  def extname
    File.extname(@path)
  end

  # {#extname} without leading dot.
  def ext
    ext = extname
    ext.empty? ? ext : ext[1..-1]
  end

  # Returns the #dirname and the #basename in an Array. See +File.split+.
  def split
    File.split(@path).map(&Path)
  end

  # Adds +ext+ as an extension to +path+.
  # Handle both extensions with or without leading dot.
  # No-op if +ext+ is +empty?+.
  #
  #   Path('file').add_extension('txt') # => #<Path file.txt>
  def add_extension(ext)
    return self if ext.empty?
    Path.new @path+dotted_ext(ext)
  end
  alias :add_ext :add_extension

  # Removes the last extension of +path+.
  #
  #   Path('script.rb').without_extension # => #<Path script>
  #   Path('archive.tar.gz').without_extension # => #<Path archive.tar>
  def without_extension
    Path.new @path[0..-extname.size-1]
  end
  alias :rm_ext :without_extension

  # Replaces the last extension of +path+ with +ext+.
  # Handle both extensions with or without leading dot.
  # Removes last extension if +ext+ is +empty?+.
  #
  #   Path('main.c++').replace_extension('cc') # => #<Path main.cc>
  def replace_extension(ext)
    return without_extension if ext.empty?
    Path.new(@path[0..-extname.size-1] << dotted_ext(ext))
  end
  alias :sub_ext :replace_extension

  # Iterates over each component of the path.
  #
  #   Path.new("/usr/bin/ruby").each_filename { |filename| ... }
  #     # yields "usr", "bin", and "ruby".
  #
  # @yieldparam [String] filename
  def each_filename
    return to_enum(__method__) unless block_given?
    _, names = split_names(@path)
    names.each { |filename| yield filename }
    nil
  end

  # Iterates over each element in the given path in descending order.
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
  # @yieldparam [Path] path
  def descend
    return to_enum(:descend) unless block_given?
    vs = []
    ascend { |v| vs << v }
    vs.reverse_each { |v| yield v }
    nil
  end

  # Iterates over each element in the given path in ascending order.
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
  # @yieldparam [Path] path
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
