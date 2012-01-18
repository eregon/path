class Path
  def self.require_tree(directory = nil)
    directory ||= Path.dir(caller) # this can not be moved as a default argument, JRuby optimizes it
    new(directory).require_tree
  end

  def require_tree
    glob('**/*.rb').sort.each { |file| require file.expand(dir) }
  end
end
