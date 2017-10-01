# frozen_string_literal: true

require 'jekyll'
require 'jekyll/utils'

require 'jekyll/antex/alias'
require 'jekyll/antex/dealiaser'

module Jekyll
  module Antex
    class Generator < Jekyll::Generator
      def generate(site)
        site.pages.each do |page|
          dealiaser = build_dealiaser site: site, resource: page
          page.content = dealiaser.parse page.content
        end

        # site.documents.each do |document|
        #   TODO
        # end

        # site.posts.docs.each do |post|
        #   TODO
        # end
      end

      private

      def build_dealiaser(site:, resource:)
        options = build_options(site: site, resource: resource)
        dealiaser = Jekyll::Antex::Dealiaser.new
        dealiaser.add_aliases build_aliases(options['aliases'])
        dealiaser
      end

      def build_options(site:, resource:)
        Jekyll::Antex::Options.build Jekyll::Antex::Options::DEFAULTS,
                                     site.config['antex'] || {},
                                     resource.data['antex'] || {}
      end

      def build_aliases(options_hash)
        options_hash.values.map do |args|
          Alias.new Jekyll::Utils.symbolize_hash_keys(args)
        end
      end
    end
  end
end
