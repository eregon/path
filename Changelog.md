# Changelog

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
