# Path - a Path manipulation library

Dir.glob(File.expand_path('../epath/*.rb',__FILE__)) { |file| require file }

require 'tempfile'

class Path
  class << self
    def file(from = nil)
      from ||= caller # this can not be moved as a default argument, JRuby optimizes it
      new(from.first.split(/:\d+(?:$|:in)/).first).expand
    end
    alias_method :here, :file

    def dir(from = nil)
      from ||= caller # this can not be moved as a default argument, JRuby optimizes it
      file(from).dir
    end

    def home
      new(Dir.respond_to?(:home) ? Dir.home : new("~").expand)
    end

    def relative(path)
      new(path).expand dir(caller)
    end

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
          tempfile.close
          tempfile.unlink if file.exist?
        end
      end
      file
    end
    alias_method :tempfile, :tmpfile

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

  def / part
    join part.to_s
  end

  def inside? ancestor
    @path == ancestor.to_s or @path.start_with?(ancestor.to_s + File::SEPARATOR)
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
end

EPath = Path # to meet everyone's expectations
