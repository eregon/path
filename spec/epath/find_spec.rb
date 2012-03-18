require 'spec_helper'

describe 'Path : Find' do
  it 'find', :tmpchdir do
    a, b = Path('a').touch, Path('b').touch
    d = Path('d').mkdir
    x, y = Path('d/x').touch, Path('d/y').touch
    here = Path('.')

    r = []
    here.find { |f| r << f }
    r.sort.should == [here, a, b, d, x, y]

    d.find.sort.should == [d, x, y]
  end
end
