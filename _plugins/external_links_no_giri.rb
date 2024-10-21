# frozen_string_literal: true

# TODO add to still make use of the aliase from the wiki style if present

# Register a post-conversion hook for all collections and pages
Jekyll::Hooks.register [:documents, :notes, :pages], :post_convert do |doc|
    # Convert wiki-style links in the document content
    convert_wiki_links(doc)
  
    # Optionally open external links in new tabs and add the 'external-link' CSS class
    add_target_blank_and_class_to_external_links(doc)
  end
  
  # Converts wiki-style links to HTML anchor tags for internal links
  def convert_wiki_links(doc)
    all_docs = doc.site.collections.values.flat_map(&:docs) + doc.site.pages
    link_extension = !!doc.site.config["use_html_extension"] ? '.html' : ''
  
    all_docs.each do |linked_doc|
      doc_title = linked_doc.data['title'] || linked_doc.basename
      doc_url = "#{doc.site.baseurl}#{linked_doc.url}#{link_extension}"
  
      # Convert [[Link|Alias]] style links to internal anchor tags
      anchor_tag = "<a class='internal-link' href='#{doc_url}'>\\1</a>"
      doc.content.gsub!(/\[\[#{Regexp.escape(doc_title)}\|(.+?)\]\]/i, anchor_tag)
  
      # Convert [[Link]] style links to internal anchor tags
      doc.content.gsub!(/\[\[(#{Regexp.escape(doc_title)})\]\]/i, "<a class='internal-link' href='#{doc_url}'>\\1</a>")
    end
  
    # Replace any remaining [[Link]] with an invalid link notice
    doc.content.gsub!(/\[\[(.+?)\]\]/i, <<~HTML.delete("\n"))
      <span title='There is no document that matches this link.' class='invalid-link'>
        <span class='invalid-link-brackets'>[[</span>
        \\1
        <span class='invalid-link-brackets'>]]</span>
      </span>
    HTML
  end
  
  # Adds `target=_blank` and the 'external-link' CSS class to external links
  def add_target_blank_and_class_to_external_links(doc)
    open_external_links_in_new_tab = !!doc.site.config["open_external_links_in_new_tab"]
  
    if open_external_links_in_new_tab
      # This regex will match anchor tags that do not have the 'internal-link' class
      # and add `target="_blank"` and 'external-link' class to them
      doc.content.gsub!(/<a(?!.*?class=['"].*?internal-link.*?['"])(.*?)href=['"](http.*?|www\..*?)['"](.*?)>/i) do |match|
        new_match = match
  
        # Add target="_blank" if it's not already present
        unless match.include?('target="_blank"')
          new_match = new_match.gsub('>', ' target="_blank">')
        end
  
        # Add class="external-link" if it's not already present
        if match.include?('class="')
          new_match = new_match.gsub('class="', 'class="external-link ')
        else
          new_match = new_match.gsub('>', ' class="external-link">')
        end
  
        new_match
      end
    end
  end
  