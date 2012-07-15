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

  # Removes the file using +FileUtils.rm+.
  def rm
    FileUtils.rm(@path)
    self
  end

  # Removes the file, ignoring errors, using +FileUtils.rm_f+.
  def rm_f
    FileUtils.rm_f(@path)
    self
  end
  alias :safe_unlink :rm_f

  # Removes the file or directory recursively, ignoring errors,
  # using +FileUtils.rm_f+.
  def rm_rf
    FileUtils.rm_rf(@path)
    self
  end

  # Copies the file to +to+. See +FileUtils.cp+.
  def cp(to)
    # TODO: remove :preserve when all implement it correctly (r31123)
    FileUtils.cp(@path, to, :preserve => true)
  end
  alias :copy :cp

  # Copies the file or directory recursively to the directory +to+.
  # See +FileUtils.cp_r+.
  def cp_r(to)
    FileUtils.cp_r(@path, to)
  end

  # Updates access and modification time or create an empty file.
  def touch
    if exist?
      now = Time.now
      File.utime(now, now, @path)
    else
      open('w') {}
    end
    self
  end

  # {#touch} preceded by +dir.+{#mkpath}.
  def touch!
    dir.mkpath
    touch
  end

  # Moves +self+ to the +to+ directory.
  def mv(to)
    FileUtils.mv(@path, to)
    to
  end
  alias :move :mv

  # Install +file+ into +path+ (the "prefix", which should be a directory).
  # If +file+ is not same as +path/file+, replaces it.
  # See +FileUtils.install+ (arguments are swapped).
  def install(file, options = {})
    FileUtils.install(file, @path, options)
  end

  # Recusively changes permissions. See +FileUtils.chmod_R+ and +File.chmod+.
  def chmod_r(mode)
    FileUtils.chmod_R(mode, @path)
  end

  # Recusively changes owner and group. See +FileUtils.chown_R+ and +File.chown+.
  def chown_r(owner, group)
    FileUtils.chown_R(owner, group, @path)
  end

  # Whether the contents of +path+ and +file+ are identical.
  # See +FileUtils.compare_file+.
  def has_same_contents?(file)
    FileUtils.compare_file(@path, file)
  end

  # Returns whether +self+ is newer than all +others+.
  # Non-existent files are older than any file.
  # See +FileUtils.uptodate?+.
  def uptodate?(*others)
    FileUtils.uptodate?(@path, others)
  end
end
