# Path - a Path manipulation library

Path is a library to manage paths.  
It is similar to Pathname, but has some extra goodness.  
The method names are intended to be short and explicit, and avoid too much duplication like having 'name' or 'path' in the method name.

I believe the object-oriented approach to manipulate paths is very elegant and useful.  
Paths are naturally the subject of their methods and even if they are simple Strings behind, they carry way much more information and deserve a first-class status.

Also, using a path library like this avoid to remember in which class the functionality is implemented, everything is in one place (if not, please open an issue!).

## API

All the useful methods of `File` (and so `IO`) and `Dir` should be included.  
Most methods of `FileUtils` should be there too.

### creation

``` ruby
Path.new('/usr/bin')
Path['/usr/bin']
Path('/usr/bin') # unless NO_EPATH_GLOBAL_FUNCTION is defined

Path.new('/usr', 'bin')
%w[foo bar].map(&Path) # => [Path('foo'), Path('bar')]
```

``` ruby
Path.file           # == Path(__FILE__).expand
Path.dir            # == Path(File.dirname(__FILE__)).expand
Path.relative(path) # == Path(File.expand_path("../#{path}", __FILE__))
Path.home           # == Path(File.expand_path('~'))
```

### temporary

``` ruby
Path.tmpfile
Path.tmpdir
```

### aliases

* expand => expand\_path
* relative\_to => relative\_path\_from

### parts

* base: basename(extname)
* dir: alias of dirname
* ext: extname without the leading dot
* /: join paths

```ruby
Path('/usr')/'bin'
```

* add\_ext / add\_extension
* rm\_ext / without\_extension
* sub\_ext(new\_ext) / replace\_extension(new\_ext)

### glob

* entries: files under self, without . and ..
* glob: relative glob to self, yield absolute paths

### structure

* ascend, ancestors: self and all the parent directories
* descend: in the reverse order
* backfind: ascends the parents until it finds the given path

``` ruby
# Path.backfind is Path.here.backfind
Path.backfind('lib') # => Path's lib folder

# It accepts XPath-like context
Path.backfind('.[.git]') # => the root of this repository
```

### IO

* read
* write(contents)
* append(contents)

### management

* mkdir
* mkdir\_p
* rm\_rf

### require

* Path.require\_tree: require all .rb files recursively (in alphabetic order)

## Status

This is still in the early development stage, you should expect many additions and some changes.

## Author

Benoit Daloze - eregon

## Contributors

Bernard Lambeau - blambeau  
Ravil Bayramgalin - brainopia
