class Path
  def self.require_tree(directory=Path.dir(caller))
    new(directory).require_tree
  end

  def require_tree
    glob('**/*.rb').sort.each {|it| require it.expand_path }
  end
end
