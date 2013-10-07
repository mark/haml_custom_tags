module Haml

  module Parser

    # Telling Haml it has to parse our new tag types:

    CONTEXT_TAG = ?$

    SPECIAL_CHARACTERS << CONTEXT_TAG

    # Telling Haml what to do with our new tag types:

    alias_method :haml_process_line, :process_line

    def process_line(text, index)
      @index = index + 1

      case text[0]
      when CONTEXT_TAG
        push context_tag(text)
      else
        haml_process_line(text, index)
      end
    end

    # Defining behavior for our new tags types:

    def context_tag(text)
      ParseNode.new(:context_tag, @index, name: text, :attributes => {},
        :attributes_hashes => {}, :self_closing => true,
        :nuke_inner_whitespace => false,
        :nuke_outer_whitespace => true, :object_ref => "nil",
        :escape_html => false, :preserve_tag => false,
        :preserve_script => true, :parse => false, :value => "Foo bar baz")
    end

  end

end
