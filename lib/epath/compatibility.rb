class Path
  private

  if File.respond_to?(:realpath) and File.respond_to?(:realdirpath)
    def real_path_internal(strict = false, basedir = nil)
      strict ? File.realpath(@path, basedir) : File.realdirpath(@path, basedir)
    end
  else
    def realpath_rec(prefix, unresolved, h, strict, last = true)
      resolved = []
      until unresolved.empty?
        n = unresolved.shift
        if n == '..'
          resolved.pop
        else
          path = prepend_prefix(prefix, resolved + [n])
          if h.include? path
            if h[path] == :resolving
              raise Errno::ELOOP.new(path)
            else
              prefix, *resolved = h[path]
            end
          else
            begin
              s = File.lstat(path)
            rescue Errno::ENOENT => e
              raise e if strict || !last || !unresolved.empty?
              resolved << n
              break
            end
            if s.symlink?
              h[path] = :resolving
              link_prefix, link_names = split_names(File.readlink(path))
              if link_prefix == '' # if link is relative
                link_prefix, link_names = prefix, resolved.concat(link_names)
              end
              prefix, *resolved = h[path] = realpath_rec(link_prefix, link_names, h, strict, unresolved.empty?)
            else
              resolved << n
              h[path] = [prefix, *resolved]
            end
          end
        end
      end
      return prefix, *resolved
    end

    def real_path_internal(strict = false, basedir = nil)
      path = @path
      path = File.join(basedir, path) if basedir and relative?
      prefix, names = split_names(path)
      if prefix == ''
        prefix, names2 = split_names(Dir.pwd)
        names = names2.concat(names)
      end
      prefix, *names = realpath_rec(prefix, names, {}, strict)
      prepend_prefix(prefix, names)
    end
  end
end
