module HamlExtensions

  class MyParseNode < Struct.new(:type, :line, :value, :parent, :children)
    def initialize(*args)
      super
      self.children ||= []
    end

    def inspect
      text = "(#{type} #{value.inspect}"
      children.each {|c| text << "\n" << c.inspect.gsub(/^/, "  ")}
      text + ")"
    end
  end
    
  class ContextTagParser

    def self.parse(line)
      MyParseNode.new(:context_tag, @index, name: 'h3', :attributes => {},
        :attributes_hashes => {}, :self_closing => true,
        :nuke_inner_whitespace => false,
        :nuke_outer_whitespace => true, :object_ref => "nil",
        :escape_html => false, :preserve_tag => false,
        :preserve_script => true, :parse => false, :value => "Foo bar baz")
    end
    
  end
  
  class ContextTagCompiler
    
    attr_reader :compiler, :node
    
    ###############
    #             #
    # Constructor #
    #             #
    ###############
    
    def initialize(compiler, node)
      @compiler = compiler
      @node     = node
    end
    
    #################
    #               #
    # Class Methods #
    #               #
    #################
    
    def self.compile(compiler, node)
      self.new(compiler, node).compile
    end
    
    ####################
    #                  #
    # Instance Methods #
    #                  #
    ####################
    
    def compile
      t = node.value
      p = node.parent
      
      push_text("<h4>#{t[:value]}</h4>")
      
      push_text("<ol>", 1)

      while p
        if p.value
          push_text("<li>#{p.value[:name]}</li>")
        else
          push_text("<li>#{ p.inspect }</li>")
        end
        p = (p == p.parent) ? nil : p.parent
      end

      push_text("</ol>", -1)
    end
    
    def push_text(*args)
      compiler.send(:push_text, *args)
    end
    
  end
  
end
