class Path
  # See <tt>File.atime</tt>.  Returns last access time.
  def atime
    File.atime(@path)
  end

  # See <tt>File.ctime</tt>.  Returns last (directory entry, not file) change time.
  def ctime
    File.ctime(@path)
  end

  # See <tt>File.mtime</tt>.  Returns last modification time.
  def mtime
    File.mtime(@path)
  end

  # See <tt>File.chmod</tt>.  Changes permissions.
  def chmod(mode) File.chmod(mode, @path) end

  # See <tt>File.lchmod</tt>.
  def lchmod(mode) File.lchmod(mode, @path) end

  # See <tt>File.chown</tt>.  Change owner and group of file.
  def chown(owner, group) File.chown(owner, group, @path) end

  # See <tt>File.lchown</tt>.
  def lchown(owner, group) File.lchown(owner, group, @path) end

  # See <tt>File.ftype</tt>.  Returns "type" of file ("file", "directory",
  # etc).
  def ftype
    File.ftype(@path)
  end

  # Creates a hard link to +target+ and returns self.
  #
  # Raises Errno::EEXIST if self already exist.
  # See <tt>File.link</tt> (arguments are swapped).
  def make_link(target)
    File.link(target, @path)
    self
  end

  # See <tt>File.readlink</tt>.  Read symbolic link.
  def readlink
    Path.new(File.readlink(@path))
  end

  # See <tt>File.rename</tt>.  Rename the file.
  def rename(to) File.rename(@path, to) end

  # See <tt>File.stat</tt>.  Returns a <tt>File::Stat</tt> object.
  def stat
    File.stat(@path)
  end

  # See <tt>File.lstat</tt>.
  def lstat
    File.lstat(@path)
  end

  # See <tt>File.size</tt>.
  def size
    File.size(@path)
  end

  # Creates a symbolic link to +target+ and returns self.
  #
  # Raises Errno::EEXIST if self already exist.
  # See <tt>File.symlink</tt> (arguments are swapped).
  def make_symlink(target)
    File.symlink(target, @path)
    self
  end

  # See <tt>File.truncate</tt>.  Truncate the file to +length+ bytes.
  def truncate(length) File.truncate(@path, length) end

  # See <tt>File.utime</tt>.  Update the access and modification times.
  def utime(atime, mtime) File.utime(atime, mtime, @path) end

  # See <tt>File.expand_path</tt>.
  def expand_path(*args) Path.new(File.expand_path(@path, *args)) end
  alias_method :expand, :expand_path

  #
  # Returns the real (absolute) pathname of +self+ in the actual
  # filesystem not containing symlinks or useless dots.
  #
  # All components of the pathname must exist when this method is
  # called.
  #
  def realpath(basedir=nil)
    Path.new(real_path_internal(true, basedir))
  end

  #
  # Returns the real (absolute) pathname of +self+ in the actual filesystem.
  # The real pathname doesn't contain symlinks or useless dots.
  #
  # The last component of the real pathname can be nonexistent.
  #
  def realdirpath(basedir=nil)
    Path.new(real_path_internal(false, basedir))
  end
end
