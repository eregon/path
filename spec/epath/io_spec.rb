require File.expand_path('../../spec_helper', __FILE__)

describe 'Path : IO', :tmpchdir do
  it 'open' do
    path = Path('a')
    path.write 'abc'

    path.open { |f| f.read.should == 'abc' }
    path.open('r') { |f| f.read.should == 'abc' }

    b = Path('b')
    b.open('w', 0444) { |f| f.write 'def' }
    (b.stat.mode & 0777).should == 0444
    b.read.should == 'def'

    g = path.open
    g.read.should == 'abc'
    g.close
  end

  it 'open 1.9', :ruby => 1.9, :fails_on => [:rbx19, :jruby19] do
    c = Path('c')
    c.open('w', 0444, {}) { |f| f.write "ghi" }
    (c.stat.mode & 0777).should == 0444
    c.read.should == 'ghi'
  end

  it 'each_line' do
    a = Path('a')

    a.open('w') { |f| f.puts 1, 2 }
    r = []
    a.each_line { |line| r << line }
    r.should == ["1\n", "2\n"]

    a.each_line('2').to_a.should == ["1\n2", "\n"]

    a.each_line.to_a.should == ["1\n", "2\n"]
  end

  it 'each_line 1.9', :ruby => 1.9, :fails_on => [:rbx19, :jruby19] do
    a = Path('a')
    a.open('w') { |f| f.puts 1, 2 }
    a.each_line(1).to_a.should == ['1', "\n", '2', "\n"]
    a.each_line('2', 1).to_a.should == ['1', "\n", '2', "\n"]
  end

  it 'readlines' do
    Path('a').open('w') { |f| f.puts 1, 2 }
    Path('a').readlines.should == ["1\n", "2\n"]
  end

  it 'read' do
    Path('a').open('w') { |f| f.puts 1, 2 }
    Path('a').read.should == "1\n2\n"
  end

  it 'binread' do
    Path('a').write 'abc'
    Path('a').binread.should == 'abc'
  end

  it 'sysopen' do
    Path('a').write 'abc'
    fd = Path('a').sysopen
    io = IO.new(fd)
    begin
      io.read.should == 'abc'
    ensure
      io.close
    end
  end

  it 'write' do
    Path('a').write "abc\ndef"
    Path('a').read.should == "abc\ndef"
  end

  it 'append' do
    f = Path('f')
    f.write "hello\n"
    f.append "world\n"
    f.read.should == "hello\nworld\n"
  end
end
