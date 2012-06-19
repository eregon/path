class Path
  # @!group Requiring

  # Requires all .rb files recursively under +directory+
  # (or this file's directory if not given).
  #
  # The order of requires is alphabetical,
  # but files having the same basename as a directory
  # are required before files in this directory.
  #
  #   # in bar.rb
  #   Path.require_tree
  #   # require in this order:
  #   # foo.rb
  #   # foo/ext.rb
  #   # foo/sub.rb
  #
  def self.require_tree(directory = nil)
    source = Path.file(caller)
    directory = Path.relative(directory || source.dir, caller)

    directory.glob('**/*.rb').sort! { |a,b|
      if b.inside?(a.rm_ext)
        -1
      elsif a.inside?(b.rm_ext)
        +1
      else
        a <=> b
      end
    }.each { |file|
      require file.path unless source == file
    }
  end
end
