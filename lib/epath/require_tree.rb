class Path
  def self.require_tree(directory = nil)
    if directory
      new(directory).require_tree
    else
      file = Path.file(caller)
      file.dir.require_tree(file)
    end
  end

  def require_tree(source = nil)
    glob('**/*.rb').sort.each { |file| require file.expand(dir).to_s unless file == source }
  end
end
