class Path
  # @!group Path parts

  # remove the leading . of +ext+ if present.
  def self.pure_ext(ext)
    ext = ext.to_s and ext.start_with?('.') ? ext[1..-1] : ext
  end

  # add a leading . to +ext+ if missing. Returns '' if +ext+ is empty.
  def self.dotted_ext(ext)
    ext = ext.to_s and (ext.empty? or ext.start_with?('.')) ? ext : ".#{ext}"
  end

  # Returns the last component of the path. See +File.basename+.
  def base(*args)
    Path.new(File.basename(@path, *args))
  end
  alias :basename :base

  # Returns the last component of the path, without the extension: base(ext)
  def stem
    base(ext)
  end

  # Returns all but the last component of the path.
  #
  # Don't chain this when the path is relative:
  #     Path('.').dir # => #<Path .>
  # Use #parent instead.
  # See +File.dirname+.
  def dir
    Path.new(File.dirname(@path))
  end
  alias :dirname :dir

  # Returns the extension, with a leading dot. See +File.extname+.
  def ext
    File.extname(@path)
  end
  alias :extname :ext

  # {#ext} without leading dot.
  def pure_ext
    Path.pure_ext(extname)
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
    return self if ext.to_s.empty?
    Path.new @path + Path.dotted_ext(ext)
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
    return without_extension if ext.to_s.empty?
    Path.new(@path[0..-extname.size-1] << Path.dotted_ext(ext))
  end
  alias :sub_ext :replace_extension

  # Iterates over each component of the path.
  #
  #   Path.new("/usr/bin/ruby").each_filename { |filename| ... }
  #     # yields "usr", "bin", and "ruby".
  #
  # Returns an Enumerator if no block was given.
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
  # It doesn't access the filesystem.
  # @yieldparam [Path] path
  def descend
    return to_enum(:descend) unless block_given?
    ascend.reverse_each { |v| yield v }
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
  # It doesn't access the filesystem.
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
