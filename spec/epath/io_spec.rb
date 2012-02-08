require File.expand_path('../../spec_helper', __FILE__)

describe 'Path : IO' do
  it 'each_line', :tmpchdir do
    a = Path('a')

    a.open('w') { |f| f.puts 1, 2 }
    r = []
    a.each_line { |line| r << line }
    r.should == ["1\n", "2\n"]

    a.each_line('2').to_a.should == ["1\n2", "\n"]

    a.each_line.to_a.should == ["1\n", "2\n"]
  end

  it 'each_line 1.9', :tmpchdir, :ruby => 19, :fails_on => [:rbx19] do
    a = Path('a')
    a.open('w') { |f| f.puts 1, 2 }
    a.each_line(1).to_a.should == ['1', "\n", '2', "\n"]
    a.each_line('2', 1).to_a.should == ['1', "\n", '2', "\n"]
  end

  it 'readlines', :tmpchdir do
    Path('a').open('w') { |f| f.puts 1, 2 }
    Path('a').readlines.should == ["1\n", "2\n"]
  end

  it 'read', :tmpchdir do
    Path('a').open('w') { |f| f.puts 1, 2 }
    Path('a').read.should == "1\n2\n"
  end

  it 'binread', :tmpchdir do
    Path('a').write 'abc'
    Path('a').binread.should == 'abc'
  end

  it 'sysopen', :tmpchdir do
    Path('a').write 'abc'
    fd = Path('a').sysopen
    io = IO.new(fd)
    begin
      io.read.should == 'abc'
    ensure
      io.close
    end
  end

  it 'write', :tmpchdir do
    Path('a').write "abc\ndef"
    Path('a').read.should == "abc\ndef"
  end

  it 'append', :tmpchdir do
    f = Path('f')
    f.write "hello\n"
    f.append "world\n"
    f.read.should == "hello\nworld\n"
  end
end
