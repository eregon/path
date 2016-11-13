require 'spec_helper'

describe 'Path : Dir', :tmpchdir do
  let(:a) { Path('a').touch }
  let(:b) { Path('b').touch }
  let(:d) { Path('d').mkdir }
  let(:x) { (d/'x').touch }
  let(:y) { (d/'y').touch }

  def create_files
    a; b
  end

  def create_hierarchy
    a; b; d; x; y
  end

  it 'glob' do
    f = Path('f')
    f.write 'abc'
    d = Path('d').mkdir

    Path.glob('*').sort.should == [d,f]
    Path.glob('*', &accumulator)
    accumulator.sort.should == [d,f]

    a = Path('a.rb').touch
    b = Path('b.rb').touch

    Path.glob('*.rb').sort.should == [a,b]
    Path.getwd.glob('*.rb').sort.should == [a,b].map(&:expand)
    Path.getwd.glob('*.rb', &accumulator)
    accumulator.sort.should == [a,b].map(&:expand)
  end

  context 'glob with directories having globbing characters' do
    %w"a[b ] [a-c] {a,b} { } * ** ?".each do |dir|
      it dir, :fails_on => [:rbx, :jruby] do
        dir = Path(dir).mkdir
        dir.should be_a_directory
        files = %w[a e].map { |name| (dir/name).touch }
        dir.glob('*').sort.should == files
      end
    end
  end

  it 'getwd, cwd, pwd', :tmpchdir => false do
    Path.method(:getwd).should == Path.method(:cwd)
    Path.method(:getwd).should == Path.method(:pwd)
    Path.getwd.should be_kind_of Path
  end

  it 'entries' do
    create_files
    Path('.').entries.sort.should == [Path('.'), Path('..'), a, b]
  end

  it 'each_entry' do
    create_files
    Path('.').each_entry(&accumulator)
    accumulator.sort.should == [Path('.'), Path('..'), a, b]
  end

  it 'mkdir' do
    d.should be_a_directory
    Path('e').mkdir(0770).should be_a_directory
  end

  it 'rmdir' do
    d.should be_a_directory
    d.rmdir
    d.should_not exist
  end

  it 'opendir' do
    create_files
    Path('.').opendir { |dir|
      dir.each(&accumulator)
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
    called.should be true
  end

  it 'children' do
    create_hierarchy
    Path('.').children.sort.should == [a, b, d]
    d.children.sort.should == [x, y]
    d.children(false).sort.should == [Path('x'), Path('y')]
  end

  it 'each_child' do
    create_hierarchy
    Path('.').each_child(&accumulator)
    accumulator.sort.should == [a, b, d]

    d.each_child(&accumulator)
    accumulator.sort.should == [x, y]

    d.each_child(false, &accumulator)
    accumulator.sort.should == [Path('x'), Path('y')]
  end

  it 'siblings' do
    create_hierarchy
    d.siblings.sort.should == [a, b]
    x.siblings.sort.should == [y]
    x.siblings(false).sort.should == [Path('y')]
  end
end
