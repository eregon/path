class Path
  # @!group IO

  # Opens the file for reading or writing. See +File.open+.
  # @yieldparam [File] file
  def open(*args, &block)
    File.open(@path, *args, &block)
  end

  # Iterates over the lines in the file. See +IO.foreach+.
  # @yieldparam [String] line
  def each_line(*args, &block)
    IO.foreach(@path, *args, &block)
  end
  alias :lines :each_line

  # Returns all data from the file, or the first +bytes+ bytes if specified.
  # See +IO.read+.
  def read(*args)
    IO.read(@path, *args)
  end

  if IO.respond_to? :binread
    # Returns all the bytes from the file, or the first +N+ if specified.
    # See +IO.binread+.
    def binread(*args)
      IO.binread(@path, *args)
    end
  else
    def binread(*args)
      open('rb', &:read)
    end
  end

  # Returns all the lines from the file. See +IO.readlines+.
  def readlines(*args)
    IO.readlines(@path, *args)
  end

  # See +IO.sysopen+.
  def sysopen(*args)
    IO.sysopen(@path, *args)
  end

  if IO.respond_to? :write
    # Writes +contents+ to +self+. See +IO.write+ or +IO#write+.
    def write(contents, *open_args)
      IO.write(@path, contents, *open_args)
    end
  else
    def write(contents, *open_args)
      open('w', *open_args) { |f| f.write(contents) }
    end
  end

  if IO.respond_to? :binwrite
    # Writes +contents+ to +self+. See +IO.binwrite+.
    def binwrite(contents, *open_args)
      IO.binwrite(@path, contents, *open_args)
    end
  else
    def binwrite(contents, *open_args)
      open('wb', *open_args) { |f| f.write(contents) }
    end
  end

  if IO.respond_to? :write and !RUBY_DESCRIPTION.start_with?('jruby')
    # Appends +contents+ to +self+. See +IO.write+ or +IO#write+.
    def append(contents, **open_args)
      open_args[:mode] = 'a'
      IO.write(@path, contents, **open_args)
    end
  else
    def append(contents, *open_args)
      open('a', *open_args) { |f| f.write(contents) }
    end
  end

  # Rewrites contents of +self+.
  #
  #    Path('file').rewrite { |contents| contents.reverse }
  #
  # @yieldparam [String] contents
  # @yieldreturn [String] contents to write
  def rewrite
    write yield read
  end

  # Returns the first +bytes+ bytes of the file.
  # If the file size is smaller than +bytes+, return the whole contents.
  def head(bytes)
    read(bytes)
  end

  # Returns the last +bytes+ bytes of the file.
  # If the file size is smaller than +bytes+, return the whole contents.
  def tail(bytes)
    return read if size < bytes
    open { |f|
      f.seek(-bytes, IO::SEEK_END)
      f.read
    }
  end
end
