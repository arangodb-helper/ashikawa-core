# -*- encoding : utf-8 -*-
require "ashikawa-core/status"

describe Ashikawa::Core::Status do
  subject { Ashikawa::Core::Status }

  describe "a new born collection" do
    subject { Ashikawa::Core::Status.new(1) }
    its(:new_born?) { should be_true }
    its(:unloaded?) { should be_false }
    its(:loaded?) { should be_false }
    its(:being_unloaded?) { should be_false }
    its(:corrupted?) { should be_false }
  end

  describe "an unloaded collection" do
    subject { Ashikawa::Core::Status.new(2) }
    its(:new_born?) { should be_false }
    its(:unloaded?) { should be_true }
    its(:loaded?) { should be_false }
    its(:being_unloaded?) { should be_false }
    its(:corrupted?) { should be_false }
  end

  describe "a loaded collection" do
    subject { Ashikawa::Core::Status.new(3) }
    its(:new_born?) { should be_false }
    its(:unloaded?) { should be_false }
    its(:loaded?) { should be_true }
    its(:being_unloaded?) { should be_false }
    its(:corrupted?) { should be_false }
  end

  describe "a collection being unloaded" do
    subject { Ashikawa::Core::Status.new(4) }
    its(:new_born?) { should be_false }
    its(:unloaded?) { should be_false }
    its(:loaded?) { should be_false }
    its(:being_unloaded?) { should be_true }
    its(:corrupted?) { should be_false }
  end

  describe "a corrupted collection" do
    subject { Ashikawa::Core::Status.new(6) }
    its(:new_born?) { should be_false }
    its(:unloaded?) { should be_false }
    its(:loaded?) { should be_false }
    its(:being_unloaded?) { should be_false }
    its(:corrupted?) { should be_true }
  end
end
