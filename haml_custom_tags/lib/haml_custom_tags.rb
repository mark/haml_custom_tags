require 'bundler'
Bundler.require(:default)

module HamlCustomTags; end

require 'haml_custom_tags/parser_extension'
require 'haml_custom_tags/compiler_extension'