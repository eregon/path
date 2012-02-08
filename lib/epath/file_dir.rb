class Path
  # Removes a file or directory, using <tt>File.unlink</tt> or
  # <tt>Dir.unlink</tt> as necessary.
  def unlink
    if directory?
      Dir.unlink @path
    else
      File.unlink @path
    end
  end
  alias delete unlink
end
