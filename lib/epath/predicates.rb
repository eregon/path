class Path
  # Predicate method for testing whether a path is absolute.
  # It returns +true+ if the pathname begins with a slash.
  def absolute?
    !relative?
  end

  # The opposite of #absolute?
  def relative?
    path = @path
    while r = chop_basename(path)
      path, = r
    end
    path == ''
  end

  #
  # #root? is a predicate for root directories. I.e. it returns +true+ if the
  # pathname consists of consecutive slashes.
  #
  # It doesn't access actual filesystem. So it may return +false+ for some
  # pathnames which points to roots such as <tt>/usr/..</tt>.
  #
  def root?
    !!(chop_basename(@path) == nil && /#{SEPARATOR_PAT}/o =~ @path)
  end

  # #mountpoint? returns +true+ if <tt>self</tt> points to a mountpoint.
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
