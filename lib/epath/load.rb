class Path
  LOADERS = {}

  def self.register_loader(*extensions, &loader)
    extensions.each { |ext| LOADERS[ext] = loader }
  end

  register_loader 'yml', 'yaml' do |path|
    require 'yaml'
    YAML.load_file(path)
  end

  register_loader 'json' do |path|
    require 'json'
    JSON.load(path.read)
  end

  # Path#load helps loading data from YAML, JSON and ruby files.
  def load
    if LOADERS.key? ext
      LOADERS[ext].call(self)
    else
      raise "Unable to load #{self} (unrecognized extension)"
    end
  end
end
