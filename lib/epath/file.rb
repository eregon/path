class Path
  # @!group File

  # Returns last access time. See +File.atime+.
  def atime
    File.atime(@path)
  end

  # Returns last (directory entry, not file) change time. See +File.ctime+.
  def ctime
    File.ctime(@path)
  end

  # Returns last modification time. See +File.mtime+.
  def mtime
    File.mtime(@path)
  end

  # Changes permissions. See +File.chmod+.
  def chmod(mode) File.chmod(mode, @path) end

  # See +File.lchmod+.
  def lchmod(mode) File.lchmod(mode, @path) end

  # Change owner and group of file. See +File.chown+.
  def chown(owner, group)
    File.chown(owner, group, @path)
  end

  # See +File.lchown+.
  def lchown(owner, group)
    File.lchown(owner, group, @path)
  end

  # Returns "type" of file ("file", "directory", etc). See +File.ftype+.
  def ftype
    File.ftype(@path)
  end

  # Creates a hard link to +target+ and returns self.
  #
  # Raises Errno::EEXIST if self already exist.
  # See +File.link+ (arguments are swapped).
  def make_link(target)
    File.link(target, @path)
    self
  end

  # Read symbolic link. See +File.readlink+.
  def readlink
    Path.new(File.readlink(@path))
  end

  # Rename the file and returns the new Path. See +File.rename+.
  def rename(to)
    File.rename(@path, to)
    Path(to)
  end

  # Returns a +File::Stat+ object. See +File.stat+.
  def stat
    File.stat(@path)
  end

  # See +File.lstat+.
  def lstat
    File.lstat(@path)
  end

  # See +File.size+.
  def size
    File.size(@path)
  end

  # Creates a symbolic link to +target+ and returns self.
  #
  # Raises Errno::EEXIST if self already exist.
  # See +File.symlink+ (arguments are swapped).
  def make_symlink(target)
    File.symlink(target, @path)
    self
  end

  # Truncate the file to +length+ bytes. See +File.truncate+.
  def truncate(length) File.truncate(@path, length) end

  # Update the access and modification times. See +File.utime+.
  def utime(atime, mtime) File.utime(atime, mtime, @path) end

  # See +File.expand_path+.
  def expand(*args)
    Path.new(File.expand_path(@path, *args))
  end
  alias :expand_path :expand

  # Returns the real (absolute) path of +self+ in the actual
  # filesystem not containing symlinks or useless dots.
  #
  # All components of the path must exist when this method is called.
  def realpath(basedir=nil)
    Path.new(real_path_internal(true, basedir))
  end

  # Returns the real (absolute) path of +self+ in the actual filesystem.
  # The real path doesn't contain symlinks or useless dots.
  #
  # The last component of the real path can be nonexistent.
  def realdirpath(basedir=nil)
    Path.new(real_path_internal(false, basedir))
  end
end
