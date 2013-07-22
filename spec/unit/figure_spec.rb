require "ashikawa-core/figure"

describe Ashikawa::Core::Figure do
  let(:raw_figures) {
    {
      "alive" => {
        "size" => 0,
        "count" => 0
      },
      "dead" => {
        "size" => 2384,
        "count" => 149,
        "deletion" => 0
      },
      "datafiles" => {
        "count" => 1,
        "fileSize" => 124
      },
      "journals" => {
        "count" => 1,
        "fileSize" => 124
      },
      "shapes" => {
        "count" => 2
      },
      "attributes" => {
        "count" => 12
      }
    }
  }
  subject { Ashikawa::Core::Figure.new(raw_figures) }

  it "should check for the alive figures" do
    subject.alive_size.should == 0
    subject.alive_count.should == 0
  end

  it "should check for the dead figures" do
    subject.dead_size.should == 2384
    subject.dead_count.should == 149
    subject.dead_deletion.should == 0
  end

  it "should check for the datafiles figures" do
    subject.datafiles_count.should == 1
    subject.datafiles_file_size.should == 124
  end

  it "should check for the journal figures" do
    subject.journals_count.should == 1
    subject.journals_file_size.should == 124
  end

  it "should check for the shapes figure" do
    subject.shapes_count.should == 2
  end

  it "should check for the attributes_count figure" do
    subject.attributes_count.should == 12
  end
end
