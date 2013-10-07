def tag(line)
  tag_name, attributes, attributes_hashes, object_ref, nuke_outer_whitespace,
    nuke_inner_whitespace, action, value, last_line = parse_tag(line)

  preserve_tag = @options[:preserve].include?(tag_name)
  nuke_inner_whitespace ||= preserve_tag
  preserve_tag = false if @options[:ugly]
  escape_html = (action == '&' || (action != '!' && @options[:escape_html]))

  case action
  when '/'; self_closing = true
  when '~'; parse = preserve_script = true
  when '='
    parse = true
    if value[0] == ?=
      value = unescape_interpolation(value[1..-1].strip, escape_html)
      escape_html = false
    end
  when '&', '!'
    if value[0] == ?= || value[0] == ?~
      parse = true
      preserve_script = (value[0] == ?~)
      if value[1] == ?=
        value = unescape_interpolation(value[2..-1].strip, escape_html)
        escape_html = false
      else
        value = value[1..-1].strip
      end
    elsif contains_interpolation?(value)
      value = unescape_interpolation(value, escape_html)
      parse = true
      escape_html = false
    end
  else
    if contains_interpolation?(value)
      value = unescape_interpolation(value, escape_html)
      parse = true
      escape_html = false
    end
  end

  attributes = Parser.parse_class_and_id(attributes)
  attributes_list = []

  if attributes_hashes[:new]
    static_attributes, attributes_hash = attributes_hashes[:new]
    Buffer.merge_attrs(attributes, static_attributes) if static_attributes
    attributes_list << attributes_hash
  end

  if attributes_hashes[:old]
    static_attributes = parse_static_hash(attributes_hashes[:old])
    Buffer.merge_attrs(attributes, static_attributes) if static_attributes
    attributes_list << attributes_hashes[:old] unless static_attributes || @options[:suppress_eval]
  end

  attributes_list.compact!

  raise SyntaxError.new("Illegal nesting: nesting within a self-closing tag is illegal.", @next_line.index) if block_opened? && self_closing
  raise SyntaxError.new("There's no Ruby code for #{action} to evaluate.", last_line - 1) if parse && value.empty?
  raise SyntaxError.new("Self-closing tags can't have content.", last_line - 1) if self_closing && !value.empty?

  if block_opened? && !value.empty? && !is_ruby_multiline?(value)
    raise SyntaxError.new("Illegal nesting: content can't be both given on the same line as %#{tag_name} and nested within it.", @next_line.index)
  end

  self_closing ||= !!(!block_opened? && value.empty? && @options[:autoclose].any? {|t| t === tag_name})
  value = nil if value.empty? && (block_opened? || self_closing)
  value = handle_ruby_multiline(value) if parse

  ParseNode.new(:tag, @index, :name => tag_name, :attributes => attributes,
    :attributes_hashes => attributes_list, :self_closing => self_closing,
    :nuke_inner_whitespace => nuke_inner_whitespace,
    :nuke_outer_whitespace => nuke_outer_whitespace, :object_ref => object_ref,
    :escape_html => escape_html, :preserve_tag => preserve_tag,
    :preserve_script => preserve_script, :parse => parse, :value => value)
end

# Parses a line into tag_name, attributes, attributes_hash, object_ref, action, value
def parse_tag(line)
  raise SyntaxError.new("Invalid tag: \"#{line}\".") unless match = line.scan(/%([-:\w]+)([-:\w\.\#]*)(.*)/)[0]

  tag_name, attributes, rest = match
  raise SyntaxError.new("Illegal element: classes and ids must have values.") if attributes =~ /[\.#](\.|#|\z)/

  new_attributes_hash = old_attributes_hash = last_line = nil
  object_ref = "nil"
  attributes_hashes = {}
  while rest
    case rest[0]
    when ?{
      break if old_attributes_hash
      old_attributes_hash, rest, last_line = parse_old_attributes(rest)
      attributes_hashes[:old] = old_attributes_hash
    when ?(
      break if new_attributes_hash
      new_attributes_hash, rest, last_line = parse_new_attributes(rest)
      attributes_hashes[:new] = new_attributes_hash
    when ?[
      break unless object_ref == "nil"
      object_ref, rest = balance(rest, ?[, ?])
    else; break
    end
  end

  if rest
    nuke_whitespace, action, value = rest.scan(/(<>|><|[><])?([=\/\~&!])?(.*)?/)[0]
    nuke_whitespace ||= ''
    nuke_outer_whitespace = nuke_whitespace.include? '>'
    nuke_inner_whitespace = nuke_whitespace.include? '<'
  end

  value = value.to_s.strip
  [tag_name, attributes, attributes_hashes, object_ref, nuke_outer_whitespace,
   nuke_inner_whitespace, action, value, last_line || @index]
end

def parse_old_attributes(line)
  line = line.dup
  last_line = @index

  begin
    attributes_hash, rest = balance(line, ?{, ?})
  rescue SyntaxError => e
    if line.strip[-1] == ?, && e.message == "Unbalanced brackets."
      line << "\n" << @next_line.text
      last_line += 1
      next_line
      retry
    end

    raise e
  end

  attributes_hash = attributes_hash[1...-1] if attributes_hash
  return attributes_hash, rest, last_line
end

def parse_new_attributes(line)
  line = line.dup
  scanner = StringScanner.new(line)
  last_line = @index
  attributes = {}

  scanner.scan(/\(\s*/)
  loop do
    name, value = parse_new_attribute(scanner)
    break if name.nil?

    if name == false
      text = (Haml::Shared.balance(line, ?(, ?)) || [line]).first
      raise Haml::SyntaxError.new("Invalid attribute list: #{text.inspect}.", last_line - 1)
    end
    attributes[name] = value
    scanner.scan(/\s*/)

    if scanner.eos?
      line << " " << @next_line.text
      last_line += 1
      next_line
      scanner.scan(/\s*/)
    end
  end

  static_attributes = {}
  dynamic_attributes = "{"
  attributes.each do |name, (type, val)|
    if type == :static
      static_attributes[name] = val
    else
      dynamic_attributes << inspect_obj(name) << " => " << val << ","
    end
  end
  dynamic_attributes << "}"
  dynamic_attributes = nil if dynamic_attributes == "{}"

  return [static_attributes, dynamic_attributes], scanner.rest, last_line
end

def parse_new_attribute(scanner)
  unless name = scanner.scan(/[-:\w]+/)
    return if scanner.scan(/\)/)
    return false
  end

  scanner.scan(/\s*/)
  return name, [:static, true] unless scanner.scan(/=/) #/end

  scanner.scan(/\s*/)
  unless quote = scanner.scan(/["']/)
    return false unless var = scanner.scan(/(@@?|\$)?\w+/)
    return name, [:dynamic, var]
  end

  re = /((?:\\.|\#(?!\{)|[^#{quote}\\#])*)(#{quote}|#\{)/
  content = []
  loop do
    return false unless scanner.scan(re)
    content << [:str, scanner[1].gsub(/\\(.)/, '\1')]
    break if scanner[2] == quote
    content << [:ruby, balance(scanner, ?{, ?}, 1).first[0...-1]]
  end

  return name, [:static, content.first[1]] if content.size == 1
  return name, [:dynamic,
    '"' + content.map {|(t, v)| t == :str ? inspect_obj(v)[1...-1] : "\#{#{v}}"}.join + '"']
end
