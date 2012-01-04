class Path
  # Removes a file or directory, using <tt>File.unlink</tt> or
  # <tt>Dir.unlink</tt> as necessary.
  def unlink()
    begin
      Dir.unlink @path
    rescue Errno::ENOTDIR
      File.unlink @path
    end
  end
  alias delete unlink
end
