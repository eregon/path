class Path
  class << self
    # Returns or yields Path objects. See +Dir.glob+.
    def glob(*args) # :yield: path
      if block_given?
        Dir.glob(*args) { |f| yield new(f) }
      else
        Dir.glob(*args).map(&Path)
      end
    end

    # Returns the current working directory as a Path. See +Dir.getwd+.
    def Path.getwd
      new Dir.getwd
    end
    alias :pwd :getwd
  end

  # Iterates over the entries (files and subdirectories) in the directory.
  # It yields a Path object for each entry.
  def each_entry(&block) # :yield: path
    Dir.foreach(@path) { |f| yield Path.new(f) }
  end

  # Create the referenced directory and returns self. See +Dir.mkdir+.
  def mkdir(*args)
    Dir.mkdir(@path, *args)
    self
  end

  # Remove the referenced directory. See +Dir.rmdir+.
  def rmdir
    Dir.rmdir(@path)
  end

  # See +Dir.open+.
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
    Dir.chdir(@path, &block)
  end

  # Returns the children of the directory (files and subdirectories, not
  # recursive) as an array of Path objects. By default, the returned
  # paths will have enough information to access the files. If you set
  # +with_directory+ to +false+, then the returned paths will contain the
  # filename only.
  #
  # For example:
  #   pn = Path("/usr/lib/ruby/1.8")
  #   pn.children
  #       # -> [ #<Path /usr/lib/ruby/1.8/English.rb>,
  #              #<Path /usr/lib/ruby/1.8/Env.rb>,
  #              #<Path /usr/lib/ruby/1.8/abbrev.rb>, ... ]
  #   pn.children(false)
  #       # -> [ #<Path English.rb>, #<Path Env.rb>, #<Path abbrev.rb>, ... ]
  #
  # Note that the results never contain the entries +.+ and +..+ in
  # the directory because they are not children.
  def children(with_directory=true)
    with_directory = false if @path == '.'
    result = []
    Dir.foreach(@path) { |e|
      next if e == '.' || e == '..'
      if with_directory
        result << Path.new(@path, e)
      else
        result << Path.new(e)
      end
    }
    result
  end

  # Iterates over the children of the directory
  # (files and subdirectories, not recursive).
  # It yields Path object for each child.
  # By default, the yielded paths will have enough information to access the files.
  # If you set +with_directory+ to +false+, then the returned paths will contain the filename only.
  #
  #   Path("/usr/local").each_child { |f| p f } # =>
  #       #<Path /usr/local/share>
  #       #<Path /usr/local/bin>
  #       #<Path /usr/local/games>
  #       #<Path /usr/local/lib>
  #       #<Path /usr/local/include>
  #       #<Path /usr/local/sbin>
  #       #<Path /usr/local/src>
  #       #<Path /usr/local/man>
  #
  #   Path("/usr/local").each_child(false) { |f| p f } # =>
  #       #<Path share>
  #       #<Path bin>
  #       #<Path games>
  #       #<Path lib>
  #       #<Path include>
  #       #<Path sbin>
  #       #<Path src>
  #       #<Path man>
  def each_child(with_directory=true, &b)
    children(with_directory).each(&b)
  end
end
