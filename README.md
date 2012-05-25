# Path - a Path manipulation library

Path is a library to manage paths.  
It is similar to Pathname, but has some extra goodness.  
The method names are intended to be short and explicit, and avoid too much duplication like having 'name' or 'path' in the method name.

I believe the object-oriented approach to manipulate paths is very elegant and useful.  
Paths are naturally the subject of their methods and even if they are simple Strings behind, they carry way much more information and deserve a first-class status.

Also, using a path library like this avoid to remember in which class the functionality is implemented, everything is in one place (if not, please open an issue!).

## Installation

    gem install epath

## Links

* [GitHub](https://github.com/eregon/epath)
* [YARD Documentation](http://rubydoc.info/github/eregon/epath/master/file/README.md)

## API

All the useful methods of `File` (and so `IO`) and `Dir` should be included.  
Most methods of `FileUtils` should be there too.

### creation

``` ruby
Path.new('/usr/bin')
Path['/usr/bin']
Path('/usr/bin') # unless NO_EPATH_GLOBAL_FUNCTION is defined

Path.new('~myuser/path') # expanded if it begins with ~

# Separators are replaced by / on systems having File::ALT_SEPARATOR
Path.new('win\sepa\rator') # => #<Path win/sepa/rator>

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

Path can split a path in two ways:

The first way is the one done by File methods (dirname, basename, extname).  

The second is Path's own way in which the base is given without the extension and the extension is given without the leading dot.  
The rationale behind this is to have a true three-components path, splitting on the / and the . (See [this issue](https://github.com/eregon/epath/pull/8#issuecomment-3499030) for details)

       dirname     basename
     ____________   ______
    /            \ /      \
    /some/path/dir/file.ext
    \____________/ \__/ \_/
          dir      base ext

    path = dirname / basename
    path = dirname / basename(extname) extname
    path = dir / base [. ext]

* dirname: "/some/path/dir"
* basename: "file.ext"
* extname: ".ext"

<!-- -->

* dir: alias of dirname: "/some/paths/dir"
* base: basename(extname), the basename without the extension: "file"
* ext: extname without the leading dot: "ext"

<!-- -->

### join

* join(*parts)
* /: join paths (as Pathname#+)

```ruby
Path('/usr')/'bin'
```

### extensions

* add\_ext / add\_extension
* rm\_ext / without\_extension
* sub\_ext(new\_ext) / replace\_extension(new\_ext)

### glob

* children: files under self, without . and ..
* glob: relative glob to self, yield absolute paths

### structure

* parent: parent directory (don't use #dirname more than once, use #parent instead)
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
