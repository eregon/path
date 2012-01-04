class Path
  class << self
    # See <tt>Dir.glob</tt>.  Returns or yields Path objects.
    def glob(*args) # :yield: pathname
      if block_given?
        Dir.glob(*args) {|f| yield new(f) }
      else
        Dir.glob(*args).map {|f| new(f) }
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
    Dir.foreach(@path) {|f| yield Path.new(f) }
  end

  # See <tt>Dir.mkdir</tt>.  Create the referenced directory.
  def mkdir(*args) Dir.mkdir(@path, *args) end

  # See <tt>Dir.rmdir</tt>.  Remove the referenced directory.
  def rmdir() Dir.rmdir(@path) end

  # See <tt>Dir.open</tt>.
  def opendir(&block) # :yield: dir
    Dir.open(@path, &block)
  end
end
