require 'haml_custom_tags'

require 'minitest/autorun'
# require 'mocha/setup'

require 'helpers/xml_to_hash'

def render(template)
  engine = Haml::Engine.new(template)
  # puts engine.render
  Hash.from_xml(engine.render)
end

def assert_structure(expected_html, actual_html)
  expected_structure = Hash.from_xml(expected_html)
  actual_structure   = render(actual_html)

  actual_structure.must_equal(expected_structure)
end
