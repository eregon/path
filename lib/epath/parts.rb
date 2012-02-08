class Path
  # Returns the last component of the path. See <tt>File.basename</tt>.
  def basename(*args)
    Path.new(File.basename(@path, *args))
  end

  # basename(extname)
  def base
    basename(extname)
  end

  # Returns all but the last component of the path. See <tt>File.dirname</tt>.
  def dirname
    Path.new(File.dirname(@path))
  end
  alias_method :dir, :dirname

  # See <tt>File.extname</tt>.  Returns the file's extension.
  def extname
    File.extname(@path)
  end

  # extname without leading .
  def ext
    ext = extname
    ext.empty? ? ext : ext[1..-1]
  end

  # Returns the #dirname and the #basename in an Array. See <tt>File.split</tt>.
  def split
    File.split(@path).map(&Path)
  end

  def add_extension(ext)
    return self if ext.empty?
    ext = ".#{ext}" unless ext.start_with? '.'
    Path.new @path+ext
  end
  alias_method :add_ext, :add_extension

  def without_extension
    Path.new @path[0..-extname.size-1]
  end
  alias_method :rm_ext, :without_extension

  def replace_extension(ext)
    return without_extension if ext.empty?
    ext = ".#{ext}" unless ext.start_with? '.'
    Path.new(@path[0..-extname.size-1] << ext)
  end
  alias_method :sub_ext, :replace_extension
end
