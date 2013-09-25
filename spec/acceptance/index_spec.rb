# -*- encoding : utf-8 -*-
require 'acceptance/spec_helper'

describe "Indices" do
  let(:database) { DATABASE }
  subject { database["documenttest"] }
  let(:index) { subject.add_index(:skiplist, on: [:identifier]) }

  it "should be possible to set indices" do
    index.delete

    expect {
      subject.add_index :skiplist, on: [:identifier]
    }.to change { subject.indices.length }.by(1)
  end

  it "should be possible to get an index by ID" do
    # This is temporary until Index has a key
    index_key = index.id.split('/')[1]

    expect(subject.index(index_key).id).to eq(index.id)
    expect(subject.indices[0].class).to eq(Ashikawa::Core::Index)
  end

  it "should be possible to remove indices" do
    pending "See Bug #34"

    expect {
      index.delete
      sleep(1) # from time to time it may fail because of threading
    }.to change { subject.indices.length }.by(-1)
  end
end
