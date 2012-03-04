class Path
  LOADERS = {}

  # Registers a new loader (a block which will be called with the Path to load)
  # for the given extensions (either with the leading dot or not)
  #
  #     Path.register_loader('.marshal') { |file| Marshal.load file.read }
  def self.register_loader(*extensions, &loader)
    extensions.each { |ext|
      ext = ext[1..-1] if ext.start_with? '.'
      LOADERS[ext] = loader
    }
  end

  register_loader 'yml', 'yaml' do |path|
    require 'yaml'
    YAML.load_file(path)
  end

  register_loader 'json' do |path|
    require 'json'
    JSON.load(path.read)
  end

  register_loader 'gemspec' do |path|
    eval path.read
  end

  # Path#load helps loading data from various files.
  # JSON and YAML loaders are provided by default.
  # See Path.register_loader.
  def load
    if LOADERS.key? ext
      LOADERS[ext].call(self)
    else
      raise "Unable to load #{self} (unrecognized extension)"
    end
  end
end
