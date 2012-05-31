class Path
  # @!group Requiring

  # Requires all .rb files recursively (in alphabetic order)
  # under +directory+ (or this file's directory if not given).
  def self.require_tree(directory = nil)
    if directory
      new(directory).require_tree
    else
      file = Path.file(caller)
      file.dir.require_tree(file)
    end
  end

  # @api private
  # See {Path.require_tree}.
  # It is not a real private method because {Path.require_tree}
  # (so the {Path} class) needs to be able to call it.
  def require_tree(source = nil)
    glob('**/*.rb').sort.each { |file| require file.expand(dir).to_s unless file == source }
  end
end
