# Enchanced Pathname
# Use the composite pattern with a Pathname

require 'pathname'
require 'fileutils'

class Path
  attr_reader :path

  class << self
    def new(*args)
      if args.size == 1 and EPath === args[0]
        args[0]
      else
        super(*args)
      end
    end
    alias_method :[], :new

    def here
      new(caller.first.split(':').first).expand
    end
    alias_method :file, :here

    def dir
      new(caller.first.split(':').first).expand.dir
    end
  end

  def initialize(*parts)
    path = parts.size > 1 ? parts.join(File::SEPARATOR) : parts.first
    @path = case path
    when Pathname
      path
    when String
      Pathname.new(path)
    else
      raise "Invalid arguments: #{parts}"
    end
  end

  def inspect
    "#<#{self.class} #{@path}>"
  end

  def == other
    Path === other and @path == other.path
  end
  alias_method :eql?, :==

  def / part
    join part.to_s
  end

  def base # basename(extname)
    Path.new @path.basename(@path.extname)
  end

  def ext # extname without leading .
    extname = @path.extname
    extname.empty? ? extname : extname[1..-1]
  end

  def without_extension # rm_ext
    dir / base
  end

  def replace_extension(ext)
    Path.new(without_extension.to_s + ext)
  end

  def glob(pattern, flags = 0)
    Dir.glob(join(pattern), flags).map { |path|
      Path.new(path)
    }
  end

  def rm_rf
    FileUtils.rm_rf(@path)
  end

  def mkdir_p
    FileUtils.mkdir_p(@path)
  end

  def write(contents, open_args = nil)
    if IO.respond_to? :write
      IO.write(@path, contents, *[open_args].compat)
    else
      open('w', *[open_args].compact) { |f| f.write(contents) }
    end
  end

  (Pathname.instance_methods(false) - instance_methods(false)).each do |meth|
    class_eval <<-METHOD, __FILE__, __LINE__+1
      def #{meth}(*args, &block)
        result = @path.#{meth}(*args, &block)
        Pathname === result ? #{self}.new(result) : result
      end
    METHOD
  end

  alias_method :expand, :expand_path
  alias_method :dir, :dirname
  alias_method :relative_to, :relative_path_from
end

EPath = Path # to meet everyone's expectations

unless defined? NO_EPATH_GLOBAL_FUNCTION
  def Path(*args)
    Path.new(*args)
  end
end
