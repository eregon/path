# Path - a Path manipulation library

dir = File.expand_path('..', __FILE__)
Dir.glob("#{dir}/path/*.rb") { |file| require file }

require 'tempfile'
require 'rbconfig'

class Path
  class << self
    # {Path} to the current file +Path(__FILE__)+.
    def file(from = nil)
      from ||= caller # this can not be moved as a default argument, JRuby optimizes it
                                     # v This : is there to define a group without capturing
      new(from.first.rpartition(/:\d+(?:$|:in )/).first).expand
    end

    # {Path} to the directory of this file: +Path(__FILE__).dir+.
    def dir(from = nil)
      from ||= caller # this can not be moved as a default argument, JRuby optimizes it
      file(from).dir
    end

    # {Path} relative to the directory of this file.
    def relative(path, from = nil)
      from ||= caller # this can not be moved as a default argument, JRuby optimizes it
      new(path).expand dir(from)
    end

    # A {Path} to the home directory of +user+ (defaults to the current user).
    # The form with an argument (+user+) is not supported on Windows.
    def ~(user = '')
      new("~#{user}")
    end
    alias :home :~

    # A {Path} to the null device on the current platform.
    def null
      new case RbConfig::CONFIG['host_os']
      when /mswin|mingw/ then 'NUL'
      when /amiga/i then 'NIL:'
      when /openvms/i then 'NL:'
      else '/dev/null'
      end
    end

    # Same as +Path.file.backfind(path)+. See {#backfind}.
    def backfind(path)
      file(caller).backfind(path)
    end

    # @yieldparam [Path] tmpfile
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

    # @yieldparam [Path] tmpdir
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

    # @yieldparam [Path] tmpdir
    def tmpchdir(prefix_suffix = nil, *rest)
      tmpdir do |dir|
        dir.chdir do
          yield dir
        end
      end
    end
  end

  # Whether +self+ is inside +ancestor+, such that +ancestor+ is an ancestor of +self+.
  # This is pure String manipulation. Paths should be absolute.
  # +self+ is considered to be inside itself.
  def inside? ancestor
    @path == ancestor.to_s or @path.start_with?("#{ancestor}/")
  end

  # The opposite of {#inside?}.
  def outside? ancestor
    !inside?(ancestor)
  end

  # Ascends the parents until it finds the given +path+.
  #
  #   Path.backfind('lib') # => the lib folder
  #
  # It accepts an XPath-like context:
  #
  #   Path.backfind('.[.git]') # => the root of the repository
  def backfind(path)
    condition = path[/\[(.*)\]$/, 1] || ''
    path = $` unless condition.empty?

    result = ancestors.find { |ancestor| (ancestor/path/condition).exist? }
    result/path if result
  end

  # Relocates this path somewhere else.
  #
  # Without a block, this method is a simple shorcut for a longer
  # expression that proves difficult to remember in practice:
  #
  #   to / (self.sub_ext(new_ext) % from)
  #
  # That is, it relocates the original path to a target folder +to+
  # appended with the relative path from a source folder +from+. An
  # optional new extension can also be specified, as it is a common
  # use case.
  #
  # With a block, the relative path is passed to the block for user
  # update, without the last extension. +new_ext+ is added after (or
  # the original extension if not provided).
  #
  #   from = Path('pictures')
  #   to   = Path('output/public/thumbnails')
  #   earth = from / 'nature/earth.jpg'
  #
  #   earth.relocate(from, to)
  #   # => #<Path output/public/thumbnails/nature/earth.jpg>
  #
  #   earth.relocate(from, to, '.png') { |rel|
  #     "#{rel}-200"
  #   }
  #   # => #<Path output/public/thumbnails/nature/earth-200.png>
  def relocate(from, to, new_ext = ext, &updater)
    updater ||= lambda { |path| path }
    renamer = lambda { |rel|
      Path.new(updater.call(rel.rm_ext)).add_ext(new_ext)
    }
    Path.new(to) / renamer.call(self % from)
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
    eval path.read, nil, path.to_s
  end
end
