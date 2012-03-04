class Path
  class << self
    # See <tt>Dir.glob</tt>. Returns or yields Path objects.
    def glob(*args) # :yield: pathname
      if block_given?
        Dir.glob(*args) { |f| yield new(f) }
      else
        Dir.glob(*args).map(&Path)
      end
    end

    # See <tt>Dir.getwd</tt>. Returns the current working directory as a Path.
    def Path.getwd
      new Dir.getwd
    end
    alias pwd getwd
  end

  # Iterates over the entries (files and subdirectories) in the directory.
  # It yields a Path object for each entry.
  def each_entry(&block) # :yield: pathname
    Dir.foreach(@path) { |f| yield Path.new(f) }
  end

  # Create the referenced directory and returns self. See <tt>Dir.mkdir</tt>.
  def mkdir(*args)
    Dir.mkdir(@path, *args)
    self
  end

  # Remove the referenced directory. See <tt>Dir.rmdir</tt>.
  def rmdir
    Dir.rmdir(@path)
  end

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
    Dir.chdir(@path, &block)
  end

  # Returns the children of the directory (files and subdirectories, not
  # recursive) as an array of Path objects. By default, the returned
  # pathnames will have enough information to access the files. If you set
  # +with_directory+ to +false+, then the returned pathnames will contain the
  # filename only.
  #
  # For example:
  #   pn = Path("/usr/lib/ruby/1.8")
  #   pn.children
  #       # -> [ Path:/usr/lib/ruby/1.8/English.rb,
  #              Path:/usr/lib/ruby/1.8/Env.rb,
  #              Path:/usr/lib/ruby/1.8/abbrev.rb, ... ]
  #   pn.children(false)
  #       # -> [ Path:English.rb, Path:Env.rb, Path:abbrev.rb, ... ]
  #
  # Note that the results never contain the entries <tt>.</tt> and <tt>..</tt> in
  # the directory because they are not children.
  def children(with_directory=true)
    with_directory = false if @path == '.'
    result = []
    Dir.foreach(@path) { |e|
      next if e == '.' || e == '..'
      if with_directory
        result << Path.new(File.join(@path, e))
      else
        result << Path.new(e)
      end
    }
    result
  end

  # Iterates over the children of the directory
  # (files and subdirectories, not recursive).
  # It yields Path object for each child.
  # By default, the yielded pathnames will have enough information to access the files.
  # If you set +with_directory+ to +false+, then the returned pathnames will contain the filename only.
  #
  #   Path("/usr/local").each_child { |f| p f }
  #   #=> #<Path:/usr/local/share>
  #   #   #<Path:/usr/local/bin>
  #   #   #<Path:/usr/local/games>
  #   #   #<Path:/usr/local/lib>
  #   #   #<Path:/usr/local/include>
  #   #   #<Path:/usr/local/sbin>
  #   #   #<Path:/usr/local/src>
  #   #   #<Path:/usr/local/man>
  #
  #   Path("/usr/local").each_child(false) { |f| p f }
  #   #=> #<Path:share>
  #   #   #<Path:bin>
  #   #   #<Path:games>
  #   #   #<Path:lib>
  #   #   #<Path:include>
  #   #   #<Path:sbin>
  #   #   #<Path:src>
  #   #   #<Path:man>
  def each_child(with_directory=true, &b)
    children(with_directory).each(&b)
  end
end
