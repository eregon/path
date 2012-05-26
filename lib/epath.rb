# Path - a Path manipulation library

Dir.glob(File.expand_path('../epath/*.rb',__FILE__)) { |file| require file }

require 'tempfile'

class Path
  class << self
    def file(from = nil)
      from ||= caller # this can not be moved as a default argument, JRuby optimizes it
                                     # v This : is there to define a group without capturing
      new(from.first.rpartition(/:\d+(?:$|:in )/).first).expand
    end
    alias :here :file

    def dir(from = nil)
      from ||= caller # this can not be moved as a default argument, JRuby optimizes it
      file(from).dir
    end

    def relative(path, from = nil)
      from ||= caller # this can not be moved as a default argument, JRuby optimizes it
      new(path).expand dir(from)
    end

    def ~(user = '')
      new("~#{user}")
    end
    alias :home :~

    def backfind(path)
      file(caller).backfind(path)
    end

    def tmpfile(basename = '', tmpdir = nil, options = nil)
      tempfile = Tempfile.new(basename, *[tmpdir, options].compact)
      file = new tempfile
      if block_given?
        begin
          yield file
        ensure
          tempfile.close!
        end
      end
      file
    end
    alias :tempfile :tmpfile

    def tmpdir(prefix_suffix = nil, *rest)
      require 'tmpdir'
      dir = new Dir.mktmpdir(prefix_suffix, *rest)
      if block_given?
        begin
          yield dir
        ensure
          FileUtils.remove_entry_secure(dir) rescue nil
        end
      end
      dir
    end

    def tmpchdir(prefix_suffix = nil, *rest)
      tmpdir do |dir|
        dir.chdir do
          yield dir
        end
      end
    end
  end

  alias :/ :+

  alias :relative_to :relative_path_from
  alias :% :relative_path_from

  def inside? ancestor
    @path == ancestor.to_s or @path.start_with?("#{ancestor}/")
  end

  def outside? ancestor
    !inside?(ancestor)
  end

  def backfind(path)
    condition = path[/\[(.*)\]$/, 1] || ''
    path = $` unless condition.empty?

    result = ancestors.find { |ancestor| (ancestor/path/condition).exist? }
    result/path if result
  end

  # Setup
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
end

EPath = Path # to meet everyone's expectations
