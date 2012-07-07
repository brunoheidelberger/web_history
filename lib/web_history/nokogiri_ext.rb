require 'nokogiri'
require 'digest/sha1'

module Nokogiri
  module XML
    class Node
      attr_accessor :digest
      attr_accessor :accumulated_digest
    end

    module NodeHelpers

      VOID_ELEMENTS = %w{ area base br col command embed hr img input keygen link meta param source track wbr }

      def self.stripify(str)
        str.gsub(/[[:space:]]+/u, ' ').strip
      end

      def self.traverse(node, level = 0, &block)
        block.call(node, :before, level)
        node.children.each { |child| traverse(child, level + 1, &block) }
        block.call(node, :after, level)
      end

      def self.normalize(node)
        case node.type
        when Nokogiri::XML::Node::CDATA_SECTION_NODE,
             Nokogiri::XML::Node::COMMENT_NODE
          node.unlink
        when Nokogiri::XML::Node::ELEMENT_NODE
          attribute_nodes = node.attribute_nodes.sort { |attribute_node_1, attribute_node_2| attribute_node_1.name <=> attribute_node_2.name }
          node.keys.each { |key| node.delete(key) }
          attribute_nodes.each { |attribute_node| node[attribute_node.name] = attribute_node.value }
        when Nokogiri::XML::Node::TEXT_NODE
          node.content = stripify(node.content)
          node.unlink if node.blank?
        else
          raise "Unknown node type: #{node.type} #{node.name}"
        end
      end

      def self.digest(node)
        case node.type
        when Nokogiri::XML::Node::CDATA_SECTION_NODE,
             Nokogiri::XML::Node::COMMENT_NODE
          raise "Non-normalized document"
        when Nokogiri::XML::Node::ELEMENT_NODE,
             Nokogiri::XML::Node::TEXT_NODE
          digest = Digest::SHA1.new
          digest << node.name
          node.keys.each { |key| digest << "#{key}=\"#{node[key]}\"" }
          digest << node.content unless node.element?
          node.digest = digest.hexdigest.encode('utf-8')
          node.children.each { |child| digest << child.accumulated_digest }
          node.accumulated_digest = digest.hexdigest.encode('utf-8')
        else
          raise "Unknown node type: #{node.type} #{node.name}"
        end
      end

      def self.to_str(node, type)
        str = nil
        if type == :before
          case node.type
          when Nokogiri::XML::Node::CDATA_SECTION_NODE,
               Nokogiri::XML::Node::COMMENT_NODE
            raise "Non-normalized document"
          when Nokogiri::XML::Node::ELEMENT_NODE
            str = "<#{node.name}"
            node.attribute_nodes.each do |attribute_node|
              prefix = attribute_node.namespace.nil? ? '' : "#{attribute_node.namespace.prefix}:"
              str << " #{prefix}#{attribute_node.name}=\"#{node.encode_special_chars(attribute_node.value)}\""
            end
            str << ((node.children.empty? && !VOID_ELEMENTS.include?(node.name)) ? "></#{node.name}>" : ">")
          when Nokogiri::XML::Node::TEXT_NODE
            str = node.content
          else
            raise "Unknown node type: #{node.type} #{node.name}"
          end
        else
          case node.type
          when Nokogiri::XML::Node::CDATA_SECTION_NODE,
               Nokogiri::XML::Node::COMMENT_NODE
            raise "Non-normalized document"
          when Nokogiri::XML::Node::ELEMENT_NODE
            str = "</#{node.name}>" unless VOID_ELEMENTS.include?(node.name) || node.children.empty?
          when Nokogiri::XML::Node::TEXT_NODE
          else
            raise "Unknown node type: #{node.type} #{node.name}"
          end
        end
        str
      end
    end
  end
end

