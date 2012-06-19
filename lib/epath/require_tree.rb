class Path
  # @!group Requiring

  # Requires all .rb files recursively (in alphabetic order)
  # under +directory+ (or this file's directory if not given).
  def self.require_tree(directory = nil)
    source = Path.file(caller)
    directory = Path.relative(directory || source.dir, caller)

    directory.glob('**/*.rb').sort.each { |file|
      require file.path unless source == file
    }
  end
end
