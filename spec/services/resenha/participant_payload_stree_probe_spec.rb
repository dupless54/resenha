# frozen_string_literal: true

require "rails_helper"
require "syntax_tree"

RSpec.describe "participant payload Syntax Tree probe" do
  it "prints the canonical participant payload spec" do
    path = File.expand_path("participant_payload_spec.rb", __dir__)
    puts "STREE_CANONICAL_BEGIN"
    puts SyntaxTree.format(File.read(path))
    puts "STREE_CANONICAL_END"

    expect(true).to eq(true)
  end
end
