# -*- encoding : utf-8 -*-
require "ashikawa-core/figure"

describe Ashikawa::Core::Figure do
  let(:alive_size) { double }
  let(:alive_count) { double }
  let(:dead_size) { double }
  let(:dead_count) { double }
  let(:dead_deletion) { double }
  let(:datafiles_count) { double }
  let(:datafiles_file_size) { double }
  let(:journals_count) { double }
  let(:journals_file_size) { double }
  let(:shapes_count) { double }
  let(:attributes_count) { double }

  let(:raw_figures) {
    {
      "alive" => {
        "size" => alive_size,
        "count" => alive_count
      },
      "dead" => {
        "size" => dead_size,
        "count" => dead_count,
        "deletion" => dead_deletion
      },
      "datafiles" => {
        "count" => datafiles_count,
        "fileSize" => datafiles_file_size
      },
      "journals" => {
        "count" => journals_count,
        "fileSize" => journals_file_size
      },
      "shapes" => {
        "count" => shapes_count
      },
      "attributes" => {
        "count" => attributes_count
      }
    }
  }

  subject { Ashikawa::Core::Figure.new(raw_figures) }

  its(:alive_size)          { should be(alive_size) }
  its(:alive_count)         { should be(alive_count) }
  its(:dead_size)           { should be(dead_size) }
  its(:dead_count)          { should be(dead_count) }
  its(:dead_deletion)       { should be(dead_deletion) }
  its(:datafiles_count)     { should be(datafiles_count) }
  its(:datafiles_file_size) { should be(datafiles_file_size) }
  its(:journals_count)      { should be(journals_count) }
  its(:journals_file_size)  { should be(journals_file_size) }
  its(:shapes_count)        { should be(shapes_count) }
  its(:attributes_count)    { should be(attributes_count) }
end
