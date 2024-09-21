# Chat GPT update: 
# frozen_string_literal: true
class BidirectionalLinksGenerator < Jekyll::Generator
  def generate(site)
    graph_nodes = []
    graph_edges = []

    # Collect documents from all collections and pages
    all_collections = site.collections.values.flat_map(&:docs)
    all_pages = site.pages
    all_docs = all_collections + all_pages

    link_extension = !!site.config["use_html_extension"] ? '.html' : ''

    # Convert all Wiki/Roam-style double-bracket link syntax to plain HTML
    # anchor tag elements (<a>) with "internal-link" CSS class
    all_docs.each do |current_doc|
      all_docs.each do |doc_potentially_linked_to|
        note_title_regexp_pattern = Regexp.escape(
          File.basename(
            doc_potentially_linked_to.basename,
            File.extname(doc_potentially_linked_to.basename)
          )
        ).gsub('\_', '[ _]').gsub('\-', '[ -]').capitalize

        title_from_data = doc_potentially_linked_to.data['title']
        if title_from_data
          title_from_data = Regexp.escape(title_from_data)
        end

        new_href = "#{site.baseurl}#{doc_potentially_linked_to.url}#{link_extension}"
        anchor_tag = "<a class='internal-link' href='#{new_href}'>\\1</a>"

        # Replace double-bracketed links with label using document title
        current_doc.content.gsub!(
          /\[\[#{note_title_regexp_pattern}\|(.+?)(?=\])\]\]/i,
          anchor_tag
        )

        current_doc.content.gsub!(
          /\[\[#{title_from_data}\|(.+?)(?=\])\]\]/i,
          anchor_tag
        )

        current_doc.content.gsub!(
          /\[\[(#{title_from_data})\]\]/i,
          anchor_tag
        )

        current_doc.content.gsub!(
          /\[\[(#{note_title_regexp_pattern})\]\]/i,
          anchor_tag
        )
      end

      # Turn remaining double-bracket-wrapped words into disabled links
      current_doc.content = current_doc.content.gsub(
        /\[\[([^\]]+)\]\]/i,
        <<~HTML.delete("\n")
          <span title='There is no document that matches this link.' class='invalid-link'>
            <span class='invalid-link-brackets'>[[</span>
            \\1
            <span class='invalid-link-brackets'>]]</span></span>
        HTML
      )
    end

    # Identify document backlinks and add them to each document
    all_docs.each do |current_doc|
      # Nodes: Jekyll
      docs_linking_to_current_doc = all_docs.filter do |e|
        e.content.include?(current_doc.url)
      end

      # Nodes: Graph
      graph_nodes << {
        id: doc_id_from_doc(current_doc),
        path: "#{site.baseurl}#{current_doc.url}#{link_extension}",
        label: current_doc.data['title'] || current_doc.basename,  # Fallback to basename
      } unless current_doc.path.include?('_collections/index.html')

      # Edges: Jekyll
      current_doc.data['backlinks'] = docs_linking_to_current_doc

      # Edges: Graph
      docs_linking_to_current_doc.each do |doc|
        graph_edges << {
          source: doc_id_from_doc(doc),
          target: doc_id_from_doc(current_doc),
        }
      end
    end

    File.write('_includes/docs_graph.json', JSON.dump({
      edges: graph_edges,
      nodes: graph_nodes,
    }))
  end

  # Update this method to handle cases where the title is missing
  def doc_id_from_doc(doc)
    title = doc.data['title'] || File.basename(doc.path, File.extname(doc.path)) # Fallback to filename if title is missing
    title.bytes.join
  end
end
