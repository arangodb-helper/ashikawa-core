# -*- encoding : utf-8 -*-
require 'unit/spec_helper'
require 'ashikawa-core/edge'

describe Ashikawa::Core::Edge do
  let(:database) { double }
  let(:id) { 412 }
  let(:path) { 'edge/412' }
  let(:key) { double }
  let(:revision) { double }
  let(:from_id) { double }
  let(:to_id) { double }
  let(:first_name) { double }
  let(:last_name) { double }
  let(:raw_data) do
    {
      '_id' => id,
      '_key' => key,
      '_rev' => revision,
      '_from' => from_id,
      '_to' => to_id,
      'first_name' => first_name,
      'last_name' => last_name
    }
  end
  let(:new_last_name) { double }
  let(:raw_data_without_meta_data_and_new_last_name) do
    {
      'first_name' => first_name,
      'last_name' => new_last_name
    }
  end

  describe 'initialized edge' do
    subject { Ashikawa::Core::Edge.new(database, raw_data) }

    its(:id) { should be(id) }
    its(:key) { should be(key) }
    its(:revision) { should be(revision) }
    its(:from_id) { should eq(from_id) }
    its(:to_id) { should eq(to_id) }

    it 'should be deletable' do
      expect(database).to receive(:send_request)
        .with(path, { delete: {} })

      subject.delete
    end

    it 'should store changes to the database' do
      expect(database).to receive(:send_request)
        .with(path, { put: raw_data_without_meta_data_and_new_last_name })

      subject['last_name'] = new_last_name
      subject.save
    end
  end

  describe 'initializing edge with additional data' do
    let(:more_info) { double }
    let(:additional_data) { { more_info: more_info } }
    subject { Ashikawa::Core::Edge.new(database, raw_data, additional_data) }

    its(['more_info']) { should eq(more_info) }
  end
end
