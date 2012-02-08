require File.expand_path('../../spec_helper', __FILE__)

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
    Path('dirname/basename').dirname.should == Path('dirname')
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

  it 'add_ext, add_extension' do
    path = Path('file')
    path = path.add_extension('.txt')
    path.ext.should == 'txt'
    path = path.add_extension('.mkv')
    path.ext.should == 'mkv'
    path = path.add_ext('tar.gz')
    path.ext.should == 'gz'
    path.to_s.should == 'file.txt.mkv.tar.gz'
  end

  it 'rm_ext, without_extension' do
    Path('/usr/bin/ls').without_extension.should == Path('/usr/bin/ls')
    Path('/usr/bin/ls.rb').rm_ext.should == Path('/usr/bin/ls')
  end

  it 'sub_ext, replace_extension' do
    Path('hello/world.rb').replace_extension('.ext').should == Path('hello/world.ext')
    Path('hello/world').replace_extension('.ext').should == Path('hello/world.ext')

    # should add a '.' if missing (consistent with #ext)
    Path('hello/world').replace_extension('ext').should == Path('hello/world.ext')
  end
end
