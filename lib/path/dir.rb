class Path
  class << self
    # @!group Directory

    # Escape the path to be suitable for globbing
    # (so it contains no globbing special characters)
    def glob_escape(path)
      path.gsub(/\[|\]|\*|\?|\{|\}/, '\\\\' + '\0')
    end

    # Returns or yields Path objects. See +Dir.glob+.
    # @yieldparam [Path] path
    def glob(pattern, flags = 0)
      if block_given?
        Dir.glob(pattern, flags) { |f| yield new(f) }
      else
        Dir.glob(pattern, flags).map(&Path)
      end
    end

    # Returns the current working directory as a Path. See +Dir.getwd+.
    def Path.getwd
      new Dir.getwd
    end
    alias :cwd :getwd
    alias :pwd :getwd
  end

  # @!group Directory

  # Iterates over the entries (files and subdirectories) in the directory.
  #
  #   Path("/usr/local").each_entry { |entry| p entry } # =>
  #   #<Path .>
  #   #<Path ..>
  #   #<Path lib>
  #   #<Path share>
  #   # ...
  #
  # @deprecated Use {#each_child} instead.
  #   This method is deprecated since it is too low level and likely useless in Ruby.
  #   But it is there for the sake of compatibility with Dir.foreach and Pathname#each_entry.
  # @yieldparam [Path] entry
  def each_entry(&block)
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
  # @yieldparam [Dir] dir
  def opendir(&block)
    Dir.open(@path, &block)
  end

  # Returns or yields Path objects.
  # Prepends the (escaped for globbing) +path+ to the pattern.
  # See +Dir.glob+.
  # @yieldparam [Path] path
  def glob(pattern, flags = 0)
    pattern = "#{Path.glob_escape(@path)}/#{pattern}"
    if block_given?
      Dir.glob(pattern, flags) { |f| yield Path.new(f) }
    else
      Dir.glob(pattern, flags).map(&Path)
    end
  end

  # Return the entries (files and subdirectories) in the directory.
  # Each Path only contains the filename.
  # The result may contain the current directory #<Path .> and the parent directory #<Path ..>.
  #
  #   Path('/usr/local').entries
  #   # => [#<Path share>, #<Path lib>, #<Path .>, #<Path ..>, <Path bin>, ...]
  #
  # @deprecated Use {#children} instead.
  #   This method is deprecated since it is too low level and likely useless in Ruby.
  #   But it is there for the sake of compatibility with Dir.entries (and Pathname#entries).
  def entries
    Dir.entries(@path).map(&Path)
  end

  # Changes the current working directory of the process to self. See Dir.chdir.
  # The recommended way to use it is to use the block form, or not use it all!
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

  # Iterates over the children of the directory (files and subdirectories, not recursive).
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
  #
  # @yieldparam [Path] child
  def each_child(with_directory=true, &b)
    children(with_directory).each(&b)
  end

  # Equivalent of +parent.children - [self]+.
  # Returns the siblings, the files in the same directory as the current +path+.
  # Returns only the root if +path+ is the root.
  def siblings(with_directory = true)
    if root?
      [self]
    else
      parent.children(with_directory) - [(with_directory ? self : basename)]
    end
  end
end
