require File.expand_path('../../spec_helper', __FILE__)

describe 'Path : Dir' do
  it 'glob', :tmpchdir do
    f = Path('f')
    f.write 'abc'
    d = Path('d').mkdir
    Path.glob('*').sort.should == [d,f]

    r = []
    Path.glob('*') { |path| r << path }
    r.sort.should == [d,f]

    a = Path('a.rb').touch
    b = Path('b.rb').touch

    Path.getwd.glob('*.rb').sort.should == [a,b].map(&:expand)
    Path.glob('*.rb').sort.should == [a,b]
  end

  it 'getwd, pwd' do
    Path.getwd.should be_kind_of Path
    Path.pwd.should be_kind_of Path
  end

  it 'entries', :tmpchdir do
    a, b = Path('a').touch, Path('b').touch
    Path('.').entries.sort.should == [Path('.'), Path('..'), a, b]
  end

  it 'each_entry', :tmpchdir do
    a, b = Path('a').touch, Path('b').touch
    r = []
    Path('.').each_entry { |entry| r << entry }
    r.sort.should == [Path('.'), Path('..'), a, b]
  end

  it 'mkdir', :tmpchdir do
    Path('d').mkdir.should be_a_directory
    Path('e').mkdir(0770).should be_a_directory
  end

  it 'rmdir', :tmpchdir do
    d = Path('d').mkdir
    d.should be_a_directory
    d.rmdir
    d.exist?.should be_false
  end

  it 'opendir', :tmpchdir do
    Path('a').touch
    Path('b').touch
    r = []
    Path('.').opendir { |d|
      d.each { |e| r << e }
    }
    r.sort.should == ['.', '..', 'a', 'b']
  end

  it 'chdir' do
    called = false
    spec = Path(__FILE__).expand.dir.dir
    spec.chdir do
      called = true
      Path.getwd.should == spec
    end
    called.should be_true
  end
end
