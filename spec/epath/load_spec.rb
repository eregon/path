require File.expand_path('../../spec_helper', __FILE__)

fixtures = Path(File.expand_path('../../fixtures',__FILE__))

describe 'Path#load' do
  it 'knows how to load yaml and json' do
    (fixtures/'data.yml').load.should == {'kind' => 'yml'}
    (fixtures/'data.yaml').load.should == {'kind' => 'yaml'}
    (fixtures/'data.json').load.should == {'kind' => 'json'}

    lambda {
      (fixtures/'no-such-one.yml').load
    }.should raise_error(Errno::ENOENT)

    lambda {
      Path(__FILE__).load
    }.should raise_error(RuntimeError, /Unable to load .*unrecognized extension/)
  end

  it 'loads new extensions with Path.register_loader' do
    Path.register_loader('test_ext1') { |file| eval file.read }
    (fixtures/'data.test_ext1').load.should == 42

    Path.register_loader('.test_ext2') { |file| eval file.read }
    (fixtures/'data.test_ext2').load.should == 24
  end
end
