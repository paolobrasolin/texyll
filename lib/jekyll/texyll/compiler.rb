# frozen_string_literal: true

module Jekyll
  module TeXyll
    class Compiler
      def initialize(snippet: '', options: {})
        @options = options
        @snippet = snippet
      end

      def compile
        make_dirs
        prepare_code
        Pipeline.new(
          pipeline: @options['pipeline'],
          engines: @options['engines'],
          context: binding
        ).run
        load_metrics
        scale_bounds
        compute_margins
      end

      def make_dirs
        FileUtils.mkdir_p @options['work_dir']
        FileUtils.mkdir_p "#{@options['work_dir']}/#{@options['dest_dir']}"
      end

      def prepare_code
        template = Liquid::Template.parse(@options['template'])
        @code = template.render(
          'preamble' => @options['preamble'],
          'append' => @options['append'],
          'prepend' => @options['prepend'],
          'snippet' => @snippet
        )
        @hash = Digest::MD5.hexdigest(@code)

        File.open(file(:tex), 'w') do |file|
          file.write(@code)
        end unless File.exist?(file(:tex))
      end

      def dir(key)
        {
          work: @options['work_dir'],
          dest: @options['dest_dir']
        }[key]
      end

      def file(key)
        dir(:work) + {
          tex: "/#{@hash}.tex",
          dvi: "/#{@hash}.dvi",
          yml: "/#{@hash}.yml",
          tfm: "/#{@hash}.tfm.svg",
          fit: "/#{@hash}.fit.svg",
          svg: "/#{dir(:dest)}/#{@hash}.svg"
        }[key]
      end

      def load_metrics
        @tex = TeXBox.new(file(:yml))
        @tfm = SVGBox.new(file(:tfm))
        @fit = SVGBox.new(file(:fit))
      end

      def scale_bounds
        r = (@tex.ht + @tex.dp) / @tfm.dy
        @tfm.scale(r)
        @fit.scale(r)
      end

      def compute_margins
        @ml = - @tfm.ox + @fit.ox
        @mt = - @tfm.oy + @fit.oy
        @mr =   @tfm.dx - @fit.dx - @ml
        @mb =   @tfm.dy - @fit.dy - @mt - @tex.dp
      end

      def add_to_static_files(site)
        FileUtils.cp(file(:fit), file(:svg))
        # TODO: minify/compress svg?
        site.static_files << Jekyll::StaticFile.new(
          site, @options['work_dir'], @options['dest_dir'], "#{@hash}.svg"
        )
      end

      def render_html_tag
        "<span class='#{@options['classes'].join(' ')}'>"\
        "<img style='margin:#{@mt.round(3)}ex #{@mr.round(3)}ex "\
        "#{@mb.round(3)}ex #{@ml.round(3)}ex; height:#{@fit.dy.round(3)}ex' "\
        "src='#{@options['dest_dir']}/#{@hash}.svg' />"\
        "</span>"
      end
    end
  end
end
