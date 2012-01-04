class Path
  # See <tt>FileTest.blockdev?</tt>.
  def blockdev?() FileTest.blockdev?(@path) end

  # See <tt>FileTest.chardev?</tt>.
  def chardev?() FileTest.chardev?(@path) end

  # See <tt>FileTest.executable?</tt>.
  def executable?() FileTest.executable?(@path) end

  # See <tt>FileTest.executable_real?</tt>.
  def executable_real?() FileTest.executable_real?(@path) end

  # See <tt>FileTest.exist?</tt>.
  def exist?() FileTest.exist?(@path) end

  # See <tt>FileTest.grpowned?</tt>.
  def grpowned?() FileTest.grpowned?(@path) end

  # See <tt>FileTest.directory?</tt>.
  def directory?() FileTest.directory?(@path) end

  # See <tt>FileTest.file?</tt>.
  def file?() FileTest.file?(@path) end

  # See <tt>FileTest.pipe?</tt>.
  def pipe?() FileTest.pipe?(@path) end

  # See <tt>FileTest.socket?</tt>.
  def socket?() FileTest.socket?(@path) end

  # See <tt>FileTest.owned?</tt>.
  def owned?() FileTest.owned?(@path) end

  # See <tt>FileTest.readable?</tt>.
  def readable?() FileTest.readable?(@path) end

  if FileTest.respond_to? :world_readable?
    # See <tt>FileTest.world_readable?</tt>.
    def world_readable?() FileTest.world_readable?(@path) end
  else
    def world_readable?
      mode = File.stat(@path).mode & 0777
      mode if (mode & 04).nonzero?
    end
  end

  # See <tt>FileTest.readable_real?</tt>.
  def readable_real?() FileTest.readable_real?(@path) end

  # See <tt>FileTest.setuid?</tt>.
  def setuid?() FileTest.setuid?(@path) end

  # See <tt>FileTest.setgid?</tt>.
  def setgid?() FileTest.setgid?(@path) end

  # See <tt>FileTest.size</tt>.
  def size() FileTest.size(@path) end

  # See <tt>FileTest.size?</tt>.
  def size?() FileTest.size?(@path) end

  # See <tt>FileTest.sticky?</tt>.
  def sticky?() FileTest.sticky?(@path) end

  # See <tt>FileTest.symlink?</tt>.
  def symlink?() FileTest.symlink?(@path) end

  # See <tt>FileTest.writable?</tt>.
  def writable?() FileTest.writable?(@path) end

  if FileTest.respond_to? :world_writable?
    # See <tt>FileTest.world_writable?</tt>.
    def world_writable?() FileTest.world_writable?(@path) end
  else
    def world_writable?
      mode = File.stat(@path).mode & 0777
      mode if (mode & 02).nonzero?
    end
  end

  # See <tt>FileTest.writable_real?</tt>.
  def writable_real?() FileTest.writable_real?(@path) end

  # See <tt>FileTest.zero?</tt>.
  def zero?() FileTest.zero?(@path) end
end
