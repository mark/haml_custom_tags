module HamlCustomTags

  CONTEXT_TAGS = {

    # What are the contextual tags within a given tag?
    # key = outside tag
    # value = hash for $container, $title, and $body
    #   [ arg1, arg2..argN, true/false ]
    #   arg1 = default tag interpretation (if any)
    #   arg2..argN = other allowed tag interpretations (if any)
    #   true = user can define it to be any tag they want in a style guide
    #   false = user can't define it to be anything other than arg1..argN
    
    'table' => {
      'container' => [ 'tr', false ],
      'title'     => [ 'th', false ],
      'body'      => [ 'td', false ]
    },
    'tr' => {
      'container' => [ 'td', 'th', false ],
      'title'     => [ true ],
      'body'      => [ 'div', true ]
    }
  }

end
