class Path
  def self.require_tree(directory='.')
    new(directory).glob('**/*.rb').sort.each {|it| require it.expand_path }
  end
end
