class Path
  #
  # Path#load helps loading data from YAML, JSON and ruby files.
  #
  def load
    case extname
    when ".yml", ".yaml"
      require 'yaml'
      YAML.load_file(self)
    when ".json"
      require 'json'
      JSON.load(self.read)
    else
      raise "Unable to load #{self} (unrecognized extension)"
    end
  end
end
