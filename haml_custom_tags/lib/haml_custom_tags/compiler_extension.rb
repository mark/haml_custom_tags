module Haml

  module Compiler

    # Telling Haml how to render our new tag types:

    def compile_context_tag
      t = @node.value
      # p = node.parent
      
      push_text("<h2>#{t[:name]}</h2>")
      
      # push_text("<ol>", 1)

      # while p
      #   if p.value
      #     push_text("<li>#{p.value[:name]}</li>")
      #   else
      #     push_text("<li>#{ p.inspect }</li>")
      #   end
      #   p = (p == p.parent) ? nil : p.parent
      # end

      # push_text("</ol>", -1)
    end

  end

end
