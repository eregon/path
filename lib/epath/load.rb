class Path
  # @!group Loading

  # The list of loaders. See {Path.register_loader}.
  LOADERS = {}

  # Registers a new loader (a block which will be called with the Path to load)
  # for the given extensions (either with the leading dot or not)
  #
  #     Path.register_loader('.marshal') { |file| Marshal.load file.read }
  def self.register_loader(*extensions, &loader)
    extensions.each { |ext|
      LOADERS[pure_ext(ext)] = loader
    }
  end

  # Path#load helps loading data from various files.
  # JSON and YAML loaders are provided by default.
  # See {Path.register_loader}.
  def load
    if LOADERS.key? ext
      LOADERS[ext].call(self)
    else
      raise "Unable to load #{self} (unrecognized extension)"
    end
  end
end
