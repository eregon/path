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

  # Predicate for root directories. Returns +true+ if the
  # path consists of consecutive slashes.
  #
  # It doesn't access the filesystem. So it may return +false+ for some
  # paths which points to roots such as +/usr/..+.
  def root?
    is_root?(@path)
  end

  # Returns +true+ if +self+ points to a mountpoint.
  def mountpoint?
    begin
      stat1 = lstat
      stat2 = parent.lstat
      stat1.dev != stat2.dev or stat1.ino == stat2.ino
    rescue Errno::ENOENT
      false
    end
  end

  # Whether this is a hidden path, i.e. starting with a dot.
  def hidden?
    basename.to_s.start_with?('.')
  end
end
