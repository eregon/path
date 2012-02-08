require File.expand_path('../../spec_helper', __FILE__)

describe 'Path : File and Dir' do
  it 'unlink', :tmpchdir do
    f = Path('f')
    f.write 'abc'
    f.unlink
    f.should_not exist

    d = Path('d').mkdir
    d.unlink
    d.should_not exist
  end
end
