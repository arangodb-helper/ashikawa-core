# -*- encoding : utf-8 -*-
require 'unit/spec_helper'
require 'ashikawa-core/cursor'

describe Ashikawa::Core::Cursor do
  subject { Ashikawa::Core::Cursor }
  let(:database) { double }

  describe 'cursor for a non-complete batch' do
    let(:response) { server_response('cursor/26011191') }
    let(:cursor_containing_string) do
      {
        'hasMore' => false,
        'error' => false,
        'result' => [
          'test'
        ],
        'code' => 200,
        'count' => 1
      }
    end
    subject { Ashikawa::Core::Cursor.new(database, response) }

    its(:id) { should eq('26011191') }
    its(:length) { should eq(5) }

    it 'should be deletable' do
      expect(database).to receive(:send_request).with('cursor/26011191', delete: {})
      subject.delete
    end

    it 'should iterate over all documents of a cursor when given a block' do
      first = true

      allow(database).to receive(:send_request).with('cursor/26011191', put: {}) do
        if first
          first = false
          server_response('cursor/26011191-2')
        else
          server_response('cursor/26011191-3')
        end
      end
      expect(database).to receive(:send_request)
        .twice
      expect(Ashikawa::Core::Document).to receive(:new)
        .exactly(5).times

      subject.each {}
    end

    it 'should return the raw string when the response consists of strings' do
      allow(database).to receive(:send_request)
        .with('cursor/26011191', put: {})
        .and_return(cursor_containing_string)

      expect(subject.to_a).to include 'test'
    end

    it 'should return an enumerator to go over all documents of a cursor when given no block' do
      first = true

      allow(database).to receive(:send_request).with('cursor/26011191', put: {}) do
        if first
          first = false
          server_response('cursor/26011191-2')
        else
          server_response('cursor/26011191-3')
        end
      end
      expect(database).to receive(:send_request)
        .twice
      expect(Ashikawa::Core::Document).to receive(:new)
        .exactly(5).times

      enumerator = subject.each
      enumerator.next
      enumerator.next
      enumerator.next
      enumerator.next
      enumerator.next
      expect { enumerator.next }.to raise_exception(StopIteration)
    end

    it 'should be enumerable' do
      first = true
      result = double

      expect(database).to receive(:send_request)
        .twice
        .with('cursor/26011191', put: {}) do
          if first
            first = false
            server_response('cursor/26011191-2')
          else
            server_response('cursor/26011191-3')
          end
        end

      expect(Ashikawa::Core::Document).to receive(:new)
        .exactly(5).times
        .and_return(result)

      expect(subject.map { |i| i }[0]).to eq(result)
    end

    it 'should return edge objects when recieving data from an edge collection' do
      expect(database).to receive(:send_request)
        .once
        .with('cursor/26011191', put: {})
        .and_return(server_response('cursor/edges'))

      expect(Ashikawa::Core::Edge).to receive(:new)
        .exactly(2).times

      subject.each {}
    end
  end

  describe 'cursor for the last batch' do
    let(:response) { server_response('cursor/26011191-3') }
    subject { Ashikawa::Core::Cursor.new(database, response) }

    its(:id) { should be_nil }
    its(:length) { should eq(5) }
  end
end
