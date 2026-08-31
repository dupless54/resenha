# frozen_string_literal: true

require "rails_helper"
require "syntax_tree"

RSpec.describe "room bans Syntax Tree probe" do
  it "prints canonical formatting" do
    source = File.read(File.join(__dir__, "room_bans_controller_spec.rb"))
    options =
      SyntaxTree::Formatter::Options.new(
        trailing_comma: true,
        disable_auto_ternary: true,
      )

    warn "STREE_PROBE_BEGIN"
    warn SyntaxTree.format(source, 100, options: options)
    warn "STREE_PROBE_END"
  end
end
