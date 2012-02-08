require File.expand_path('../../spec_helper', __FILE__)

describe 'Path : File and Dir' do
  it 'unlink', :tmpchdir do
    f = Path('f')
    f.write 'abc'
    f.unlink
    f.exist?.should be_false

    d = Path('d').mkdir
    d.unlink
    d.exist?.should be_false
  end
end
