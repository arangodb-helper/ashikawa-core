# -*- encoding : utf-8 -*-
require 'acceptance/spec_helper'

describe 'Graphs' do
  subject { DATABASE.graph 'ponyville' }

  let(:ponies) { subject.add_vertex_collection(:ponies) }
  let(:places) { subject.add_vertex_collection(:places) }

  let(:pinkie_pie) { ponies.create_document(name: 'Pinkie Pie', color: 'pink') }
  let(:rainbow_dash) { ponies.create_document(name: 'Rainbow Dash', color: 'blue') }

  let(:crystal_empire) { places.create_document(name: 'Crystal Empire') }
  let(:cloudsdale) { places.create_document(name: 'Cloudsdale') }
  let(:manehatten) { places.create_document(name: 'Manehatten') }

  let(:friends_with) { subject.add_edge_definition(:friends_with, from: [:ponies], to: [:ponies]) }
  let(:visited)      { subject.add_edge_definition(:visited, from: [:ponies], to: [:places]) }

  before do
    # required to create the required collections
    ponies
    places
    friends_with
    visited
  end

  after do
    subject.delete(drop_collections: true)
  end

  it 'should have some basic information about the graph' do
    edge_definitions = [
      {
        'collection' => 'visited',
        'from'       => ['ponies'],
        'to'         => ['places']
      },
      {
        'collection' => 'friends_with',
        'from'       => ['ponies'],
        'to'         => ['ponies']
      }
    ]

    expect(subject.name).to eq 'ponyville'
    expect(subject.revision).not_to be_nil
    expect(subject.edge_definitions).to match_array edge_definitions
  end

  it 'should know the vertex collections' do
    expect(subject.vertex_collections).to include ponies
    expect(subject.vertex_collections).to include places
  end

  it 'should know the edge collections' do
    expect(subject.edge_collections).to include friends_with
    expect(subject.edge_collections).to include visited
  end

  it 'adding the same vertex collection should be idempotent' do
    expect { subject.add_vertex_collection(:ponies) }.not_to raise_error
  end

  context 'connected vertices' do
    before :each do
      # There are only directed graphs
      subject.edge_collection(:friends_with).add(from: pinkie_pie, to: rainbow_dash)
      subject.edge_collection(:friends_with).add(from: rainbow_dash, to: pinkie_pie)

      subject.edge_collection(:visited).add(from: pinkie_pie, to: crystal_empire)
      subject.edge_collection(:visited).add(from: rainbow_dash, to: cloudsdale)
      subject.edge_collection(:visited).add(from: rainbow_dash, to: crystal_empire)
      subject.edge_collection(:visited).add(from: rainbow_dash, to: manehatten)
    end

    it 'should know all their neighbors' do
      neighbors = ['Pinkie Pie', 'Pinkie Pie', 'Cloudsdale', 'Manehatten', 'Crystal Empire']
      expect(subject.neighbors(rainbow_dash).map { |d| d['name'] }).to eq neighbors
    end

    it 'should know neighbors by type' do
      neighbors = ['Cloudsdale', 'Manehatten', 'Crystal Empire']
      expect(subject.neighbors(rainbow_dash, edges: :visited).map { |d| d['name'] }).to eq neighbors
    end

    it 'should remove edges between vertices' do
      neighbors = ['Cloudsdale', 'Crystal Empire']
      subject.edge_collection(:visited).remove(from: rainbow_dash, to: manehatten)
      expect(subject.neighbors(rainbow_dash, edges: :visited).map { |d| d['name'] }).to eq neighbors
    end
  end
end
