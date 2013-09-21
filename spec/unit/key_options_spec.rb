# -*- encoding : utf-8 -*-
require 'unit/spec_helper'
require 'ashikawa-core/key_options'

describe Ashikawa::Core::KeyOptions do
  let(:type) { double }
  let(:offset) { double }
  let(:increment) { double }
  let(:allow_user_keys) { double }
  let(:raw_key_options) {{
    "type" => type,
    "offset" => offset,
    "increment" => increment,
    "allowUserKeys" => allow_user_keys
  }}

  describe "initialized key options" do
    subject { Ashikawa::Core::KeyOptions.new(raw_key_options) }

    its(:type) { should eq(type) }
    its(:offset) { should eq(offset) }
    its(:increment) { should eq(increment) }
    its(:allow_user_keys) { should eq(allow_user_keys) }
  end
end
