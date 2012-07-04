# Changelog

## 0.4.0

* huge refactoring of internal code for clarity and efficiency
* improve Path.require_tree with a good default order and an :except option
* add a Path.like? predicate and a Path.like matcher for path-like objects
* be consistent and try #to_path, then #path, #to_str and #to_s in constructor
* CHANGE: #unlink (and the alias #delete) is now File.unlink,
  and will not remove directories (use #rmdir or #rm_r)
* fix #glob to yield when a block is given, as documented and as Path.glob
* Path() is now in Kernel, no more in Object (as Integer, String, Array, ...)
* reorganize implementation.rb so that it contains almost only internal methods
* more testing on Windows
* improve documentation and specs

## 0.3.0

* Path#relocate: allows to easily relocate a path
  in another hierarchy tree, with optional and easy renaming
* Path.+: configures Path#+ to help the transition to Path coming from String/Pathname
* Path#path: an alias of #to_s to improve readability
* Path#{head,tail} and Path#binwrite
* Run coverage across OS and >= 1.9 versions (maybe 1.8 soon?)
* JSON dumping/loading (never two without three)
* Improve specs, by using better matchers, an automatic accumulator block and sharing them

## 0.2.0

* Every public method is now documented (although some basically), and methods grouped
  - Further improvements in this area: link to File,Dir,... documentation with a real link
* All interesting methods from FileUtils have been added
* Implementation bug squashing has started!
* Begin to deprecate Path#+
  - Next step: make it configurable
* Path.~, which is Path.home(user = myself)
* RSpec filters have been fixed with my suggestion, so no more nil checking in filters

## 0.1.1

* YAML and Marshal dumping/loading
* Path#{cp,copy,cp_r}

## 0.1.0

Was "about time" to get a release, next ones should be much *much* faster

Done:

* Decent and well-organized tests with maximum coverage
* Full compatibility with MRI 1.8/1.9 on Windows/Linux/OSX
* Internal design
* Most important changes like real immutable Path (freeze at #initialize)

TODO:

* Documentation
* Improve compatibility with JRuby/Rubinius by patching them myself
* Add some interesting methods from FileUtils
* < What you would expect for Path 1.0 >

## 0.0.1

Initial release
