require 'fileutils'

class Path
  # @!group File utilities

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
  alias :safe_unlink :rm_f

  def rm_r
    FileUtils.rm_r(@path)
    self
  end

  def rm_rf
    FileUtils.rm_rf(@path)
    self
  end

  def cp(to)
    # TODO: remove :preserve when all implement it correctly (r31123)
    FileUtils.cp(@path, to, :preserve => true)
  end
  alias :copy :cp

  def cp_r(to)
    FileUtils.cp_r(@path, to)
  end

  def touch
    if exist?
      now = Time.now
      File.utime(now, now, @path)
    else
      open('w') {}
    end
    self
  end

  def touch!
    dir.mkpath
    touch
  end

  def mv(to)
    FileUtils.mv(@path, to)
    to
  end
  alias :move :mv

  # reversed args!
  def install(file, options = {})
    FileUtils.install(file, @path, options)
  end

  def chmod_r(mode)
    FileUtils.chmod_R(mode, @path)
  end

  def chown_r(owner, group)
    FileUtils.chown_R(owner, group, @path)
  end

  # See +FileUtils.compare_file+
  def has_same_contents?(file)
    FileUtils.compare_file(@path, file)
  end

  def uptodate?(*others)
    FileUtils.uptodate?(@path, others)
  end
end
