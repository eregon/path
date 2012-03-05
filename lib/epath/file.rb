class Path
  # Returns last access time. See <tt>File.atime</tt>.
  def atime
    File.atime(@path)
  end

  # Returns last (directory entry, not file) change time. See <tt>File.ctime</tt>.
  def ctime
    File.ctime(@path)
  end

  # Returns last modification time. See <tt>File.mtime</tt>.
  def mtime
    File.mtime(@path)
  end

  # Changes permissions. See <tt>File.chmod</tt>.
  def chmod(mode) File.chmod(mode, @path) end

  # See <tt>File.lchmod</tt>.
  def lchmod(mode) File.lchmod(mode, @path) end

  # Change owner and group of file. See <tt>File.chown</tt>.
  def chown(owner, group)
    File.chown(owner, group, @path)
  end

  # See <tt>File.lchown</tt>.
  def lchown(owner, group)
    File.lchown(owner, group, @path)
  end

  # Returns "type" of file ("file", "directory", etc). See <tt>File.ftype</tt>.
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

  # Read symbolic link. See <tt>File.readlink</tt>.
  def readlink
    Path.new(File.readlink(@path))
  end

  # Rename the file. See <tt>File.rename</tt>.
  def rename(to) File.rename(@path, to) end

  # Returns a <tt>File::Stat</tt> object. See <tt>File.stat</tt>.
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

  # Truncate the file to +length+ bytes. See <tt>File.truncate</tt>.
  def truncate(length) File.truncate(@path, length) end

  # Update the access and modification times. See <tt>File.utime</tt>.
  def utime(atime, mtime) File.utime(atime, mtime, @path) end

  # See <tt>File.expand_path</tt>.
  def expand_path(*args)
    Path.new(File.expand_path(@path, *args))
  end
  alias :expand :expand_path

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
