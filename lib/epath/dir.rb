class Path
  class << self
    # See <tt>Dir.glob</tt>.  Returns or yields Path objects.
    def glob(*args) # :yield: pathname
      if block_given?
        Dir.glob(*args) { |f| yield new(f) }
      else
        Dir.glob(*args).map(&Path)
      end
    end

    # See <tt>Dir.getwd</tt>.  Returns the current working directory as a Path.
    def Path.getwd
      new Dir.getwd
    end
    alias pwd getwd
  end

  # Iterates over the entries (files and subdirectories) in the directory.  It
  # yields a Path object for each entry.
  def each_entry(&block) # :yield: pathname
    Dir.foreach(@path) { |f| yield Path.new(f) }
  end

  # See <tt>Dir.mkdir</tt>.  Create the referenced directory and returns self.
  def mkdir(*args)
    Dir.mkdir(@path, *args)
    self
  end

  # See <tt>Dir.rmdir</tt>.  Remove the referenced directory.
  def rmdir() Dir.rmdir(@path) end

  # See <tt>Dir.open</tt>.
  def opendir(&block) # :yield: dir
    Dir.open(@path, &block)
  end

  def glob(pattern, flags = 0)
    Dir.glob(join(pattern), flags).map(&Path)
  end

  # [DEPRECATED] Return the entries (files and subdirectories) in the directory.
  # Each Path only contains the filename.
  # The result may contain the current directory #<Path .> and the parent directory #<Path ..>.
  #
  # Path('/usr/local').entries
  # # => [#<Path share>, #<Path lib>, #<Path .>, #<Path ..>, <Path bin>, ...]
  #
  # This method is deprecated, since it is too low level and likely useless in Ruby.
  # But it is there for the sake of compatibility with Dir.entries (and Pathname#entries)
  #
  # Use #children instead.
  def entries
    Dir.entries(@path).map(&Path)
  end

  def chdir(&block)
    Dir.chdir(self, &block)
  end
end
