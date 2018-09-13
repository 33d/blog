require 'fileutils'
require 'yaml'

require 'jekyll'
require 'rmagick'

require 'jekyll-responsive-image/version'
require 'jekyll-responsive-image/config'
require 'jekyll-responsive-image/utils'
require 'jekyll-responsive-image/render_cache'
require 'jekyll-responsive-image/image_processor'
require 'jekyll-responsive-image/resize_handler'
require 'jekyll-responsive-image/renderer'
require 'jekyll-responsive-image/tag'
require 'jekyll-responsive-image/block'
require 'jekyll-responsive-image/extra_image_generator'

module Jekyll
  module ResponsiveImage

    class CustomTag < Liquid::Tag

      def initialize(tag_name, markup, tokens)
        super

        @attributes = {}

        markup.scan(Liquid::TagAttributes) do |key, value|
          value = value || ''
          # Strip quotes from around attribute values
          @attributes[key] = value.gsub(/^['"]|['"]$/, '')
        end

      end

      def render(context)
        site = context.registers[:site]
        puts @attributes.to_yaml
        if @attributes['wp']
          dirname = context.registers[:page]['path'].scan(/.*\/(.*)\.[A-Za-z0-9]*/)[0][0]
          @attributes['path'] = 'images/wp/' + dirname + '/' +  @attributes['path'] 
        else
          @attributes['path'] = 'images/' + @attributes['path'] 
        end
        Renderer.new(site, @attributes).render_responsive_image
      end
    end
  end
end

Liquid::Template.register_tag('responsive_image', Jekyll::ResponsiveImage::CustomTag)
Liquid::Template.register_tag('image', Jekyll::ResponsiveImage::CustomTag)
Liquid::Template.register_tag('responsive_image_block', Jekyll::ResponsiveImage::Block)
