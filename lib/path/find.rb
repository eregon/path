class Path
  # Iterates over the directory tree in a depth first
  # manner, yielding a Path for each file under "this" directory.
  #
  # Returns an Enumerator if no block is given.
  #
  # Since it is implemented by the standard library module Find, +Find.prune+
  # can be used to control the traversal.
  #
  # If +self+ is +.+, yielded paths begin with a filename in the
  # current directory, not +./+.
  #
  # See +Find.find+.
  #
  # @yieldparam [Path] path
  def find
    return to_enum(__method__) unless block_given?
    require 'find'
    if @path == '.'
      Find.find(@path) { |f| yield Path.new(f.sub(%r{\A\./}, '')) }
    else
      Find.find(@path) { |f| yield Path.new(f) }
    end
  end
end
