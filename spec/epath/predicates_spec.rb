require File.expand_path('../../spec_helper', __FILE__)

describe 'Path predicates' do
  it 'absolute?' do
    Path('/').should be_absolute
    Path('a').should_not be_absolute
  end

  it 'relative?' do
    Path('/').should_not be_relative
    Path('/a').should_not be_relative
    Path('/..').should_not be_relative
    Path('a').should be_relative
    Path('a/b').should be_relative
  end

  it 'relative? (dosish_drive)', :dosish_drive do
    Path('A:').should_not be_relative
    Path('A:/').should_not be_relative
    Path('A:/a').should_not be_relative
  end

  it 'relative? (unc)', :unc do
    [
      '//',
      '//a',
      '//a/',
      '//a/b',
      '//a/b/',
      '//a/b/c',
    ].each { |path| Path(path).should_not be_relative }
  end

  it 'root?' do
    Path('/').should be_root
    Path('//').should be_root
    Path('///').should be_root
    Path('').should_not be_root
    Path('a').should_not be_root
  end

  it 'mountpoint?' do
    [true, false].should include Path('/').mountpoint?
  end
end
