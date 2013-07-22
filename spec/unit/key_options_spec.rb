require 'unit/spec_helper'
require 'ashikawa-core/key_options'

describe Ashikawa::Core::KeyOptions do
  subject { Ashikawa::Core::KeyOptions }

  it "should parse the key options" do
    type = double
    offset = double
    increment = double
    allow_user_keys = double

    key_options = subject.new({
      "type" => type,
      "offset" => offset,
      "increment" => increment,
      "allowUserKeys" => allow_user_keys
    })

    key_options.type.should == type
    key_options.offset.should == offset
    key_options.increment.should == increment
    key_options.allow_user_keys.should == allow_user_keys
  end
end
