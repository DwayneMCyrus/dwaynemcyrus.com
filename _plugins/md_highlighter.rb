# _plugins/highlighter.rb

# Turns ==something== in Markdown to <mark>something</mark> in output HTML

Jekyll::Hooks.register [:documents, :pages], :pre_render do |doc|
    apply_highlight(doc)
  end
  
  def apply_highlight(doc)
    # Replace text between `==` with <mark>...</mark>
    doc.content.gsub!(/==+([^ ](.*?)?[^ .=])==+/, "<mark>\\1</mark>")
  end
  