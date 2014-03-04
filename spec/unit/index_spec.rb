# -*- encoding : utf-8 -*-
require 'unit/spec_helper'
require 'ashikawa-core/index'

describe Ashikawa::Core::Index do
  let(:collection) { double }
  let(:id) { '167137465/168054969' }
  let(:path) { 'index/167137465/168054969' }
  let(:delete_payload) { { delete: {} } }
  let(:type_as_sym) { double }
  let(:type) { double(to_sym: type_as_sym) }
  let(:field_as_sym) { double }
  let(:field) { double(to_sym: field_as_sym) }
  let(:unique) { double }
  let(:raw_data) do
    {
      'code' => 201,
      'fields' => [field],
      'id' => id,
      'type' => type,
      'isNewlyCreated' => true,
      'unique' => unique,
      'error' => false
    }
  end

  describe 'initialized index' do
    subject { Ashikawa::Core::Index.new(collection, raw_data) }

    its(:id) { should be(id) }
    its(:type) { should be(type_as_sym) }
    its(:on) { should include(field_as_sym) }
    its(:unique) { should be(unique) }

    it 'should be deletable' do
      expect(collection).to receive(:send_request)
        .with(path, delete_payload)

      subject.delete
    end
  end
end
