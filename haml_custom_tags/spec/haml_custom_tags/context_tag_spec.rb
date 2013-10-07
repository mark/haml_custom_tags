require 'spec_helper'

describe "Custom tags" do

  let(:html) { <<-HTML }
  <div id="outer">
    <div class="inner">
      <strong>Hello</strong>
      <h2>World</h2>
    </div>
  </div>
HTML

  let(:haml) { <<-HAML }
#outer
  .inner
    %strong Hello
    $World
HAML

  it "should render a basic template" do
    assert_structure(html, haml)
  end

end
