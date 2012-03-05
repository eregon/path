require 'fileutils'

class Path
  # Creates a full path, including any intermediate directories that don't yet exist.
  # See +FileUtils.mkpath+.
  def mkpath
    FileUtils.mkpath(@path)
    self
  end
  alias :mkdir_p :mkpath

  # Deletes a directory and all beneath it. See +FileUtils.rm_r+.
  def rmtree
    # The name "rmtree" is borrowed from File::Path of Perl.
    # File::Path provides "mkpath" and "rmtree".
    FileUtils.rm_r(@path)
    self
  end
  alias :rm_r :rmtree

  def rm
    FileUtils.rm(@path)
    self
  end

  def rm_f
    FileUtils.rm_f(@path)
    self
  end

  def rm_rf
    FileUtils.rm_rf(@path)
    self
  end

  def touch
    FileUtils.touch(@path)
    self
  end

  def touch!
    dirname.mkpath
    touch
  end
end
