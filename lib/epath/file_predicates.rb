# All methods from FileTest and all predicates from File are included

class Path
  # See <tt>File.blockdev?</tt>.
  def blockdev?
    File.blockdev?(@path)
  end

  # See <tt>File.chardev?</tt>.
  def chardev?
    File.chardev?(@path)
  end

  # See <tt>File.executable?</tt>.
  def executable?
    File.executable?(@path)
  end

  # See <tt>File.executable_real?</tt>.
  def executable_real?
    File.executable_real?(@path)
  end

  # See <tt>File.exist?</tt>.
  def exist?
    File.exist?(@path)
  end
  alias exists? exist?

  # See <tt>File.grpowned?</tt>.
  def grpowned?
    File.grpowned?(@path)
  end

  # See <tt>File.directory?</tt>.
  def directory?
    File.directory?(@path)
  end
  alias_method :dir?, :directory?

  # See <tt>File.file?</tt>.
  def file?
    File.file?(@path)
  end

  # See <tt>File.pipe?</tt>.
  def pipe?
    File.pipe?(@path)
  end

  # See <tt>File.socket?</tt>.
  def socket?
    File.socket?(@path)
  end

  # See <tt>File.owned?</tt>.
  def owned?
    File.owned?(@path)
  end

  # See <tt>File.readable?</tt>.
  def readable?
    File.readable?(@path)
  end

  if File.respond_to? :world_readable?
    # See <tt>File.world_readable?</tt>.
    def world_readable?
    File.world_readable?(@path)
  end
  else
    def world_readable?
      mode = File.stat(@path).mode & 0777
      mode if (mode & 04).nonzero?
    end
  end

  # See <tt>File.readable_real?</tt>.
  def readable_real?
    File.readable_real?(@path)
  end

  # See <tt>File.setuid?</tt>.
  def setuid?
    File.setuid?(@path)
  end

  # See <tt>File.setgid?</tt>.
  def setgid?
    File.setgid?(@path)
  end

  # See <tt>File.size?</tt>.
  def size?
    File.size?(@path)
  end

  # See <tt>File.sticky?</tt>.
  def sticky?
    File.sticky?(@path)
  end

  # See <tt>File.symlink?</tt>.
  def symlink?
    File.symlink?(@path)
  end

  # See <tt>File.writable?</tt>.
  def writable?
    File.writable?(@path)
  end

  if File.respond_to? :world_writable?
    # See <tt>File.world_writable?</tt>.
    def world_writable?
    File.world_writable?(@path)
  end
  else
    def world_writable?
      mode = File.stat(@path).mode & 0777
      mode if (mode & 02).nonzero?
    end
  end

  # See <tt>File.writable_real?</tt>.
  def writable_real?
    File.writable_real?(@path)
  end

  # See <tt>File.zero?</tt>.
  # empty? is not defined in File/FileTest, but is is clearer
  def zero?
    File.zero?(@path)
  end
  alias_method :empty?, :zero?

  # See <tt>File.identical?</tt>.
  def identical?(path)
    File.identical?(@path, path)
  end

  # Only in File, not FileTest

  # See <tt>File.fnmatch?</tt>.
  # Return +true+ if the receiver matches the given pattern.
  def fnmatch?(pattern, *args) File.fnmatch?(pattern, @path, *args) end
end
