def compile_tag
  t = @node.value

  # Get rid of whitespace outside of the tag if we need to
  rstrip_buffer! if t[:nuke_outer_whitespace]

  dont_indent_next_line =
    (t[:nuke_outer_whitespace] && !block_given?) ||
    (t[:nuke_inner_whitespace] && block_given?)

  if @options[:suppress_eval]
    object_ref = "nil"
    parse = false
    value = t[:parse] ? nil : t[:value]
    attributes_hashes = {}
    preserve_script = false
  else
    object_ref = t[:object_ref]
    parse = t[:parse]
    value = t[:value]
    attributes_hashes = t[:attributes_hashes]
    preserve_script = t[:preserve_script]
  end

  # Check if we can render the tag directly to text and not process it in the buffer
  if object_ref == "nil" && attributes_hashes.empty? && !preserve_script
    tag_closed = !block_given? && !t[:self_closing] && !parse

    open_tag = prerender_tag(t[:name], t[:self_closing], t[:attributes])
    if tag_closed
      open_tag << "#{value}</#{t[:name]}>"
      open_tag << "\n" unless t[:nuke_outer_whitespace]
    elsif !(parse || t[:nuke_inner_whitespace] ||
        (t[:self_closing] && t[:nuke_outer_whitespace]))
      open_tag << "\n"
    end

    push_merged_text(open_tag,
      tag_closed || t[:self_closing] || t[:nuke_inner_whitespace] ? 0 : 1,
      !t[:nuke_outer_whitespace])

    @dont_indent_next_line = dont_indent_next_line
    return if tag_closed
  else
    if attributes_hashes.empty?
      attributes_hashes = ''
    elsif attributes_hashes.size == 1
      attributes_hashes = ", #{attributes_hashes.first}"
    else
      attributes_hashes = ", (#{attributes_hashes.join(").merge(")})"
    end

    push_merged_text "<#{t[:name]}", 0, !t[:nuke_outer_whitespace]
    push_generated_script(
      "_hamlout.attributes(#{inspect_obj(t[:attributes])}, #{object_ref}#{attributes_hashes})")
    concat_merged_text(
      if t[:self_closing] && xhtml?
        " />" + (t[:nuke_outer_whitespace] ? "" : "\n")
      else
        ">" + ((if t[:self_closing] && html?
                  t[:nuke_outer_whitespace]
                else
                  !block_given? || t[:preserve_tag] || t[:nuke_inner_whitespace]
                end) ? "" : "\n")
      end)

    if value && !parse
      concat_merged_text("#{value}</#{t[:name]}>#{t[:nuke_outer_whitespace] ? "" : "\n"}")
    elsif !t[:nuke_inner_whitespace] && !t[:self_closing]
      @to_merge << [:text, '', 1]
    end

    @dont_indent_next_line = dont_indent_next_line
  end

  return if t[:self_closing]

  if value.nil?
    @output_tabs += 1 unless t[:nuke_inner_whitespace]
    yield if block_given?
    @output_tabs -= 1 unless t[:nuke_inner_whitespace]
    rstrip_buffer! if t[:nuke_inner_whitespace]
    push_merged_text("</#{t[:name]}>" + (t[:nuke_outer_whitespace] ? "" : "\n"),
      t[:nuke_inner_whitespace] ? 0 : -1, !t[:nuke_inner_whitespace])
    @dont_indent_next_line = t[:nuke_outer_whitespace]
    return
  end

  if parse
    push_script(value, t.merge(:in_tag => true))
    concat_merged_text("</#{t[:name]}>" + (t[:nuke_outer_whitespace] ? "" : "\n"))
  end
end
