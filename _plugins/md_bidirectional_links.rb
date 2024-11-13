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
        # Get the basename and title (if available) for each document
        note_basename = File.basename(doc_potentially_linked_to.basename, File.extname(doc_potentially_linked_to.basename))
        title_from_data = doc_potentially_linked_to.data['title']
        link_title = doc_potentially_linked_to.data['linkTitle'] # Get linkTitle from front matter

        # Create regex patterns for the basename and title (case-insensitive)
        note_title_regexp_pattern = Regexp.escape(note_basename).gsub('\_', '[ _]').gsub('\-', '[ -]').capitalize
        title_from_data_regexp_pattern = Regexp.escape(title_from_data || '').gsub('\_', '[ _]').gsub('\-', '[ -]').capitalize

        # Handle wiki-style links with an alias (e.g., [[filename|alias]] or [[title|alias]])
        current_doc.content.gsub!(/\[\[#{note_title_regexp_pattern}\|(.+?)(?=\])\]\]/i) do |match|
          alias_name = Regexp.last_match(1)
          display_text = alias_name || link_title || title_from_data || note_basename
          new_href = "#{site.baseurl}#{doc_potentially_linked_to.url}#{link_extension}"
          "<a class='internal-link' href='#{new_href}'>#{display_text}</a>"
        end

        current_doc.content.gsub!(/\[\[#{title_from_data_regexp_pattern}\|(.+?)(?=\])\]\]/i) do |match|
          alias_name = Regexp.last_match(1)
          display_text = alias_name || link_title || title_from_data || note_basename
          new_href = "#{site.baseurl}#{doc_potentially_linked_to.url}#{link_extension}"
          "<a class='internal-link' href='#{new_href}'>#{display_text}</a>"
        end

        # Handle wiki-style links without an alias (e.g., [[filename]] or [[title]])
        current_doc.content.gsub!(/\[\[(#{note_title_regexp_pattern})\]\]/i) do |match|
          display_text = link_title || title_from_data || note_basename
          new_href = "#{site.baseurl}#{doc_potentially_linked_to.url}#{link_extension}"
          "<a class='internal-link' href='#{new_href}'>#{display_text}</a>"
        end

        current_doc.content.gsub!(/\[\[(#{title_from_data_regexp_pattern})\]\]/i) do |match|
          display_text = link_title || title_from_data || note_basename
          new_href = "#{site.baseurl}#{doc_potentially_linked_to.url}#{link_extension}"
          "<a class='internal-link' href='#{new_href}'>#{display_text}</a>"
        end
      end

      # Turn remaining double-bracket-wrapped words into disabled links
      current_doc.content = current_doc.content.gsub(
        /\[\[([^\]]+)\]\]/i,
        <<~HTML.delete("\n")
          <span title='This link doesnot yet exist or has been made private.' class='invalid-link'>
            \\1
          </span>
        HTML
      )
    end

    # Identify document backlinks and add them to each document
    all_docs.each do |current_doc|
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
