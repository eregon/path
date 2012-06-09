require 'spec_helper'

describe 'Path : Dir', :tmpchdir do
  it 'glob' do
    f = Path('f')
    f.write 'abc'
    d = Path('d').mkdir
    Path.glob('*').sort.should == [d,f]

    Path.glob('*', &accumulator)
    accumulator.sort.should == [d,f]

    a = Path('a.rb').touch
    b = Path('b.rb').touch

    Path.getwd.glob('*.rb').sort.should == [a,b].map(&:expand)
    Path.glob('*.rb').sort.should == [a,b]
  end

  it 'getwd, pwd', :tmpchdir => false do
    Path.method(:getwd).should == Path.method(:pwd)
    Path.getwd.should be_kind_of Path
  end

  it 'entries' do
    a, b = Path('a').touch, Path('b').touch
    Path('.').entries.sort.should == [Path('.'), Path('..'), a, b]
  end

  it 'each_entry' do
    a, b = Path('a').touch, Path('b').touch
    Path('.').each_entry(&accumulator)
    accumulator.sort.should == [Path('.'), Path('..'), a, b]
  end

  it 'mkdir' do
    Path('d').mkdir.should be_a_directory
    Path('e').mkdir(0770).should be_a_directory
  end

  it 'rmdir' do
    d = Path('d').mkdir
    d.should be_a_directory
    d.rmdir
    d.should_not exist
  end

  it 'opendir' do
    Path('a').touch
    Path('b').touch
    Path('.').opendir { |d|
      d.each(&accumulator)
    }
    accumulator.sort.should == ['.', '..', 'a', 'b']
  end

  it 'chdir', :tmpchdir => false do
    called = false
    spec = Path(__FILE__).expand.dir.parent
    root = spec.parent
    Path.getwd.should == root
    spec.chdir do
      called = true
      Path.getwd.should == spec
    end
    Path.getwd.should == root
    called.should be_true
  end

  it 'children' do
    a = Path('a').touch
    b = Path('b').touch
    d = Path('d').mkdir
    x = Path('d/x').touch
    y = Path('d/y').touch

    Path('.').children.sort.should == [a, b, d]
    d.children.sort.should == [x, y]
    d.children(false).sort.should == [Path('x'), Path('y')]
  end

  it 'each_child' do
    a = Path('a').touch
    b = Path('b').touch
    d = Path('d').mkdir
    x = Path('d/x').touch
    y = Path('d/y').touch

    Path('.').each_child(&accumulator)
    accumulator.sort.should == [a, b, d]

    d.each_child(&accumulator)
    accumulator.sort.should == [x, y]

    d.each_child(false, &accumulator)
    accumulator.sort.should == [Path('x'), Path('y')]
  end
end
