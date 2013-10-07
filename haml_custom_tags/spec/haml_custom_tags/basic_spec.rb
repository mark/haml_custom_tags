require 'spec_helper'

describe "Basic HAML checks" do

  let(:html) { <<-HTML }
  <div id="outer">
    <div class="inner">
      <strong>Hello</strong> World
    </div>
  </div>
HTML

  let(:haml) { <<-HAML }
#outer
  .inner
    %strong Hello
    World
HAML

  it "should render a basic template" do
    assert_structure(html, haml)
  end

end
