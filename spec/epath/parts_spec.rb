require 'spec_helper'

describe 'Path : parts' do
  it 'base, basename' do
    Path('dir/file.ext').basename.should == Path('file.ext')
    Path('file.ext').basename.should == Path('file.ext')
    Path('file.ext').basename('xt').should == Path('file.e')
    Path('file.ext').basename('.ext').should == Path('file')

    Path('file.ext').base.should == Path('file')
    Path('dir/file.ext').base.should == Path('file')
  end

  it 'dir, dirname' do
    :dir.should be_an_alias_of :dirname
    Path('dirname/basename').dir.should == Path('dirname')
  end

  it 'ext, extname' do
    Path('file.rb').extname.should == '.rb'
    Path('file.rb').ext.should == 'rb'
    Path('.hidden').extname.should == ''
    Path('.hidden').ext.should == ''
  end

  it 'split' do
    Path('dirname/basename').split.should == [Path('dirname'), Path('basename')]
  end

  it '/, +' do
    (Path('a')/'b').should == Path('a/b')
    (Path('a')/:b).should == Path('a/b')
    (Path('a')/nil).should == Path('a')
    (Path('')/'a').should == Path('a')
    (Path('')/:a).should == Path('a')
  end

  it 'add_ext, add_extension' do
    :add_ext.should be_an_alias_of :add_extension
    path = Path('file')
    path = path.add_extension('.txt')
    path.ext.should == 'txt'
    path = path.add_extension(:mkv)
    path.ext.should == 'mkv'
    path = path.add_ext('tar.gz')
    path.ext.should == 'gz'
    path.to_s.should == 'file.txt.mkv.tar.gz'
  end

  it 'rm_ext, without_extension' do
    :rm_ext.should be_an_alias_of :without_extension
    Path('/usr/bin/ls').without_extension.should == Path('/usr/bin/ls')
    Path('/usr/bin/ls.rb').rm_ext.should == Path('/usr/bin/ls')
  end

  it 'sub_ext, replace_extension' do
    :sub_ext.should be_an_alias_of :replace_extension
    Path('hello/world.rb').replace_extension('.ext').should == Path('hello/world.ext')
    Path('hello/world.rb').replace_extension( :ext ).should == Path('hello/world.ext')
    Path('hello/world').replace_extension('.ext').should == Path('hello/world.ext')

    # should add a '.' if missing (consistent with #ext)
    Path('hello/world').replace_extension('ext').should == Path('hello/world.ext')

    Path('a.c').sub_ext('.o').should == Path('a.o')
    Path('a.c++').sub_ext('.o').should == Path('a.o')
    Path('a.gif').sub_ext('.png').should == Path('a.png')
    Path('ruby.tar.gz').sub_ext('.bz2').should == Path('ruby.tar.bz2')
    Path('d/a.c').sub_ext('.o').should == Path('d/a.o')
    Path('foo.exe').sub_ext('').should == Path('foo')
    Path('lex.yy.c').sub_ext('.o').should == Path('lex.yy.o')
    Path('fooaa').sub_ext('.o').should == Path('fooaa.o')
    Path('d.e/aa').sub_ext('.o').should == Path('d.e/aa.o')
    Path('long_enough.not_to_be_embeded[ruby-core-31640]').
      sub_ext('.bug-3664').should == Path('long_enough.bug-3664')
  end

  it 'each_filename' do
    Path('/usr/bin/ruby').each_filename(&accumulator)
    accumulator.should == %w[usr bin ruby]
    Path('/usr/bin/ruby').each_filename.to_a.should == %w[usr bin ruby]
  end

  it 'descend' do
    Path('/a/b/c').descend.map(&:to_s).should == %w[/ /a /a/b /a/b/c]
    Path('a/b/c').descend.map(&:to_s).should == %w[a a/b a/b/c]
    Path('./a/b/c').descend.map(&:to_s).should == %w[. ./a ./a/b ./a/b/c]
    Path('a/').descend.map(&:to_s).should == %w[a/]
  end

  it 'ascend, ancestors' do
    :ascend.should be_an_alias_of :ancestors
    Path('/a/b/c').ascend.map(&:to_s).should == %w[/a/b/c /a/b /a /]
    Path('a/b/c').ascend.map(&:to_s).should == %w[a/b/c a/b a]
    Path('./a/b/c').ascend.map(&:to_s).should == %w[./a/b/c ./a/b ./a .]
    Path('a/').ascend.map(&:to_s).should == %w[a/]

    r = Path.new(File.dirname('C:') != '.' ? 'C:/' : '/')
    (r/'usr/bin/ls').ancestors.to_a.should == [r/'usr/bin/ls', r/'usr/bin', r/'usr', r]
  end
end
