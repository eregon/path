class Path
  # @!group Requiring

  # Requires all .rb files recursively under +directory+
  # (or the current file's directory if not given).
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
  # @param directory [String] the directory to search,
  #                           or the current file's directory.
  # @option options [Array<String>] :except ([])
  #   a list of prefixes to ignore, relative to +directory+.
  def self.require_tree(directory = nil, options = {})
    directory, options = nil, directory if Hash === directory
    source = Path.file(caller)
    directory = Path.relative(directory || source.dir, caller)
    except = options[:except] || []

    directory.glob('**/*.rb').reject { |path|
      except.any? { |prefix| (path % directory).path.start_with?(prefix) }
    }.sort! { |a,b|
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
