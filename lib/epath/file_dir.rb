class Path
  # Removes a file or directory, using +File.unlink+ or
  # +Dir.unlink+ as necessary.
  def unlink
    if directory?
      Dir.unlink @path
    else
      File.unlink @path
    end
  end
  alias :delete :unlink
end
