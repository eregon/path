# epath - Enhanced Pathname

## Path is like Pathname

...

## Plus some extra goodness

* `Path.here` is similar to `__FILE__`
* `Path.dir`  is similar to (the missing) `__DIR__`
* `Path.home` is similar to `Dir.home` or `File.expand('~')`
* `Path.tmpfile` is similar to `Tempfile.new`
* `Path.tmpdir` is similar to `Dir.mktmpdir`
* `Path#backfind` finds a file in parent folders until it finds it
* `Path.backfind(...)` is equivalent to `Path.here.backfind(...)`

