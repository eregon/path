# All methods from FileTest and all predicates from File are included

class Path
  # See +File.blockdev?+.
  def blockdev?
    File.blockdev?(@path)
  end

  # See +File.chardev?+.
  def chardev?
    File.chardev?(@path)
  end

  # See +File.executable?+.
  def executable?
    File.executable?(@path)
  end

  # See +File.executable_real?+.
  def executable_real?
    File.executable_real?(@path)
  end

  # See +File.exist?+.
  def exist?
    File.exist?(@path)
  end
  alias :exists? :exist?

  # See +File.grpowned?+.
  def grpowned?
    File.grpowned?(@path)
  end

  # See +File.directory?+.
  def directory?
    File.directory?(@path)
  end
  alias :dir? :directory?

  # See +File.file?+.
  def file?
    File.file?(@path)
  end

  # See +File.pipe?+.
  def pipe?
    File.pipe?(@path)
  end

  # See +File.socket?+.
  def socket?
    File.socket?(@path)
  end

  # See +File.owned?+.
  def owned?
    File.owned?(@path)
  end

  # See +File.readable?+.
  def readable?
    File.readable?(@path)
  end

  if File.respond_to? :world_readable?
    # See +File.world_readable?+.
    def world_readable?
      File.world_readable?(@path)
    end
  else
    def world_readable?
      mode = File.stat(@path).mode & 0777
      mode if (mode & 04).nonzero?
    end
  end

  # See +File.readable_real?+.
  def readable_real?
    File.readable_real?(@path)
  end

  # See +File.setuid?+.
  def setuid?
    File.setuid?(@path)
  end

  # See +File.setgid?+.
  def setgid?
    File.setgid?(@path)
  end

  # See +File.size?+.
  def size?
    File.size?(@path)
  end

  # See +File.sticky?+.
  def sticky?
    File.sticky?(@path)
  end

  # See +File.symlink?+.
  def symlink?
    File.symlink?(@path)
  end

  # See +File.writable?+.
  def writable?
    File.writable?(@path)
  end

  if File.respond_to? :world_writable?
    # See +File.world_writable?+.
    def world_writable?
      File.world_writable?(@path)
    end
  else
    def world_writable?
      mode = File.stat(@path).mode & 0777
      mode if (mode & 02).nonzero?
    end
  end

  # See +File.writable_real?+.
  def writable_real?
    File.writable_real?(@path)
  end

  # See +File.zero?+.
  # empty? is not defined in File/FileTest, but is is clearer
  def zero?
    File.zero?(@path)
  end
  alias :empty? :zero?

  # See +File.identical?+.
  def identical?(path)
    File.identical?(@path, path)
  end

  # Only in File, not FileTest

  # Return +true+ if the receiver matches the given pattern.
  # See +File.fnmatch?+.
  def fnmatch?(pattern, *args)
    File.fnmatch?(pattern, @path, *args)
  end
end
