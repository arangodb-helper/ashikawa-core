# -*- encoding : utf-8 -*-
require 'unit/spec_helper'
require 'ashikawa-core/configuration'

describe Ashikawa::Core::Configuration do
  let(:url) { double }
  let(:logger) { double }
  let(:adapter) { double }
  let(:connection) { double }
  let(:username) { double }
  let(:password) { double }

  its(:url) { should be_nil }
  its(:logger) { should be_nil }
  its(:adapter) { should be_nil }

  it 'should raise an Argument error if the URL is missing' do
    expect do
      subject.connection
    end.to raise_error(ArgumentError, /either an url or a connection/)
  end

  context 'provided with connection' do
    before { subject.connection = connection }
    its(:connection) { should be connection }
  end

  context 'provided with url, logger and adapter' do
    before do
      subject.url = url
      subject.logger = logger
      subject.adapter = adapter
    end

    its(:url) { should be url }
    its(:logger) { should be logger }
    its(:adapter) { should be adapter }

    it 'should construct a connection' do
      expect(Ashikawa::Core::Connection).to receive(:new)
        .with(url, { logger: logger, adapter: adapter })
        .and_return(connection)
      expect(subject.connection).to be connection
    end
  end

  context 'provided with url' do
    before do
      subject.url = url
    end

    its(:url) { should be url }
    its(:logger) { should be nil }
    its(:adapter) { should be nil }

    it 'should construct a connection' do
      expect(Ashikawa::Core::Connection).to receive(:new)
        .with(url, {})
        .and_return(connection)
      expect(subject.connection).to be connection
    end
  end

  describe 'set up authentication' do
    before do
      subject.url = url
      allow(Ashikawa::Core::Connection).to receive(:new)
        .and_return(connection)
    end

    it 'should setup authentication when username and password were provided' do
      expect(connection).to receive(:authenticate_with)
        .with({ username: username, password: password })
        .and_return(connection)

      subject.username = username
      subject.password = password
      subject.connection
    end

    it 'should not setup authentication when only username was provided' do
      expect(connection).to_not receive(:authenticate_with)

      subject.username = username
      subject.connection
    end

    it 'should not setup authentication when only password was provided' do
      expect(connection).to_not receive(:authenticate_with)

      subject.password = password
      subject.connection
    end
  end
end
