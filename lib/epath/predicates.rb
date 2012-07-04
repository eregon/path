class Path
  # @!group Path predicates

  # Whether a path is absolute.
  def absolute?
    is_absolute?(@path)
  end

  # Whether a path is relative.
  def relative?
    not absolute?
  end

  # #root? is a predicate for root directories. I.e. it returns +true+ if the
  # path consists of consecutive slashes.
  #
  # It doesn't access actual filesystem. So it may return +false+ for some
  # paths which points to roots such as +/usr/..+.
  def root?
    is_root?(@path)
  end

  # #mountpoint? returns +true+ if +self+ points to a mountpoint.
  def mountpoint?
    begin
      stat1 = lstat
      stat2 = parent.lstat
      stat1.dev != stat2.dev or stat1.ino == stat2.ino
    rescue Errno::ENOENT
      false
    end
  end
end
