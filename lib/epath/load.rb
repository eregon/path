class Path
  #
  # Path#load helps loading data from YAML, JSON and ruby files.
  #
  def load
    case extname
    when ".rb", ".ruby"
      ::Kernel.eval(self.read, TOPLEVEL_BINDING, self.to_s)
    when ".yml", ".yaml"
      require 'yaml'
      YAML.load(self.read)
    when ".json"
      require 'json'
      JSON.load(self.read)
    else
      raise "Unable to load #{self} (unrecognized extension)"
    end
  end
end
