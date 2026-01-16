# Path - a Path manipulation library

[![Gem Version](https://badge.fury.io/rb/path.svg)](https://rubygems.org/gems/path)
[![CI](https://github.com/eregon/path/actions/workflows/ci.yml/badge.svg)](https://github.com/eregon/path/actions/workflows/ci.yml)

[Path](http://rubydoc.info/github/eregon/path/master/Path) is a library to manage paths.  
It is similar to Pathname, but has some extra goodness, notably more than 50 extra methods.  
Pathname only exposes a subset of `File`, `Dir` and `FileUtils` but Path exposes most of them.
The method names are intended to be short and explicit, and avoid too much duplication like having 'name' or 'path' in the method name.

I believe the object-oriented approach to manipulate paths is very elegant and useful.  
Paths are naturally the subject of their methods and even if they are simple Strings behind, they carry way much more information and deserve a first-class status.

With `Path`, there is no need to remember in which class the functionality is implemented, everything is in one place (if not, please open an issue!).

## Version 2

This is the second version of Path, which tries to respect even more
the standard library names and the principle of least surprise.
For the first version, see the branch [1.3.x](https://github.com/eregon/path/tree/1.3.x).

## Installation

    gem install path

## Links

* [GitHub](https://github.com/eregon/path)
* [YARD Documentation](http://rubydoc.info/github/eregon/path/master/file/README.md)
* [Changelog](https://github.com/eregon/path/blob/master/Changelog.md)

## API

See the [Path](http://rubydoc.info/github/eregon/path/master/Path) class documentation for details.

All the useful methods of `File` (and so `IO`) and `Dir` should be included.  
Most methods of `FileUtils` should be there too.

### creation

``` ruby
Path.new('/usr/bin')
Path['/usr/bin']
Path('/usr/bin')

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
Path.home or Path.~ # == Path(File.expand_path('~'))
Path.~(user)        # == Path(File.expand_path("~#{user}"))
```

### temporary paths

``` ruby
Path.tmpfile
Path.tmpdir
```

### aliases

* expand => expand\_path
* relative\_to => relative\_path\_from

### parts and decomposition

A path can be split in two or three parts:

       dir      base
     _______   ______
    /       \ /      \
    /some/dir/file.ext
    \_______/ \__/\__/
       dir    stem ext

    path = dir "/" base = dir "/" stem ext

All of these are methods of Path:

* dir:  "/some/dir"
* base: "file.ext"
* ext:  ".ext"
* stem: "file"

### join

* join(*parts)
* /: join paths (as Pathname#+)

```ruby
Path('/usr')/'bin'
```

### file extensions

* add\_ext / add\_extension
* rm\_ext / without\_extension
* sub\_ext(new\_ext) / replace\_extension(new\_ext)

### globbing

* children: files under self, without . and ..
* glob: relative glob to self, yield absolute paths

### navigating the structure

* parent: parent directory (don't use #dirname more than once, use #parent instead)
* ascend, ancestors: self and all the parent directories
* descend: in the reverse order
* backfind: ascends the parents until it finds the given path

``` ruby
# Path.backfind is Path.dir.backfind
Path.backfind('lib') # => Path's lib folder

# It accepts XPath-like context
Path.backfind('.[.git]') # => the root of this repository
```

### IO

* read
* write(contents)
* append(contents)

### directory management

* mkdir
* mkdir\_p
* rm\_rf

### require

* Path.require\_tree: require all .rb files recursively (in alphabetic order)

### relocate

``` ruby
from = Path('pictures')
to   = Path('output/public/thumbnails')
earth = Path('pictures/nature/earth.jpg')

earth.relocate(from, to, '.png') { |rel| "#{rel}-200" }
# => #<Path output/public/thumbnails/nature/earth-200.png>
```

## Transition from String/Pathname

One aim of Path is to help the user make the transition coming from
String (not using a path library), Pathname, or another library.

To this intent, [`Path.configure`](http://rubydoc.info/github/eregon/path/master/Path#configure-class_method) allows to configure the behavior of `Path#+`.

Coming from String, one should use `Path.configure(:+ => :string)`, and run ruby with the verbose option (`-w`),
which will show where `+` is used as String concatenation.

Coming from a path library using `+` as #join, one should just use the default (`Path.configure(:+ => :warning)`),
which will show where `+` is used.

## Migration from path 1.x

A couple methods changed since 1.x, all mentioned in the [ChangeLog](Changelog.md).

One of the easiest way is to grep for the changed methods.
Here is a list of each with a direct replacement.

* Path.here => Path.file
* Path#base => Path#stem
* Path#ext => Path#pure_ext (it now returns a leading dot)

## Status

This is still in the early development stage, you should expect many additions and some changes.

## Author

Benoit Daloze - eregon

## Contributors

Bernard Lambeau - blambeau  
Ravil Bayramgalin - brainopia
