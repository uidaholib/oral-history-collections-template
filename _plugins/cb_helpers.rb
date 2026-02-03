# frozen_string_literal: true

#########
#
# CollectionBuilder Helpers Generator, v1.1-csv
#
# Jekyll plugin to generate theme variables for the template.
# 
# Helper functions work with settings in "theme.yml" to add variables to site.data.
# This optimizes setting defaults and calculating some values,
# to avoid slow Liquid routines.
# (c) 2021 CollectionBuilder, evanwill, https://github.com/CollectionBuilder/
# Distributed under the conditions of the MIT license
#
#########

module CollectionBuilderHelperGenerator
  class Generator < Jekyll::Generator
    safe true

    def generate(site)

      #####
      #
      # Featured Item 
      # find featured image as configured in "theme.yml"
      # return new varible --> site.data.featured_item with .src, .alt, .link
      #
      #####

      # get featured image config from "theme.yml"
      if site.data["theme"]
        featured_image = site.data['theme']['featured-image'] || "/assets/img/collectionbuilder-logo.png"
      else 
        featured_image = "/assets/img/collectionbuilder-logo.png"
        puts color_text("Error cb_helpers: your project does not contain a '_data/theme.yml'. The template will use default values.", :yellow)
      end
      if featured_image.include? "/"
        # if featured image is a link
        featured_item_src = featured_image
        featured_item_alt = site.config['title']
        featured_item_link = featured_item_src
      else
        # if featured image is an objectid
        # check configured metadata exists
        if site.data[site.config['metadata']]
          # find item in site metadata
          featured_record = site.data[site.config['metadata']].select { |item| item['objectid'] == featured_image }
          # provide error message if no matching item
          if featured_record.empty?
            puts color_text("Error cb_helpers: Item for featured image with objectid '#{featured_image}' not found in configured metadata '#{site.config['metadata']}'. Please check 'featured-image' in '_data/theme.yml'", :yellow)
          else
            # use object_location for image items, image_small for others
            if featured_record[0]['format'] and featured_record[0]['format'].include? 'image'
              featured_item_src = featured_record[0]['object_location'] || featured_record[0]['image_small']
            elsif featured_record[0]['display_template'] and featured_record[0]['display_template'].include? 'image'
              featured_item_src = featured_record[0]['object_location'] || featured_record[0]['image_small']
            else
              featured_item_src = featured_record[0]['image_small']
            end
            # provide error message if no matching image src
            if featured_item_src.nil? 
              puts color_text("Error cb_helpers: Item for featured image with objectid '#{featured_image}' does not have an image url in metadata. Please check 'featured-image' in '_data/theme.yml' and choose an item that has 'object_location' or 'image_small'", :yellow)
            end
            # use item title as alt
            featured_item_alt = featured_record[0]['title'] || site.config['title']
            # figure out item link
            if featured_record[0]['parentid']
              featured_item_link = "/items/" + featured_record[0]['parentid'] + ".html#" + featured_image
            else
              featured_item_link = "/items/" + featured_image + ".html"
            end
          end
        else
          puts color_text("Error cb_helpers: configured metadata '#{site.config['metadata']}' not found in '_data'.", :yellow)
        end

      end

      # add site.data.featured_item object with src, alt, and link 
      site.data['featured_item'] = { "src" => featured_item_src, "alt" => featured_item_alt, "link" => featured_item_link }

      #####
      #
      # Theme Icons
      # find icons configured in "theme.yml" or set defaults
      # return new variable --> site.data.theme_icons
      # containing keys for each icon, each with key for inline or symbol markup
      #
      #####

      # get list of existing icons in assets
      lib_icons = site.static_files.select { |file| file.path.include? '/assets/lib/icons/' }
      lib_icon_names = lib_icons.map { |i| i.basename }
      # get icons configured in theme.yml
      if site.data["theme"]
        theme_icons = site.data['theme']['icons'] || { }
      else
        theme_icons = { } 
      end
      # set built in svg options using bootstrap icons
      # this ensures default icons are available even if assets/lib/icons/ is missing
      builtin_icons = { }
      builtin_icons['image'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-image" viewBox="0 0 16 16"> <path d="M6.002 5.5a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0z"/> <path d="M2.002 1a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V3a2 2 0 0 0-2-2h-12zm12 1a1 1 0 0 1 1 1v6.5l-3.777-1.947a.5.5 0 0 0-.577.093l-3.71 3.71-2.66-1.772a.5.5 0 0 0-.63.062L1.002 12V3a1 1 0 0 1 1-1h12z"/> </svg>'
      builtin_icons['soundwave'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-soundwave" viewBox="0 0 16 16"> <path fill-rule="evenodd" d="M8.5 2a.5.5 0 0 1 .5.5v11a.5.5 0 0 1-1 0v-11a.5.5 0 0 1 .5-.5zm-2 2a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-1 0v-7a.5.5 0 0 1 .5-.5zm4 0a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-1 0v-7a.5.5 0 0 1 .5-.5zm-6 1.5A.5.5 0 0 1 5 6v4a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm8 0a.5.5 0 0 1 .5.5v4a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm-10 1A.5.5 0 0 1 3 7v2a.5.5 0 0 1-1 0V7a.5.5 0 0 1 .5-.5zm12 0a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0V7a.5.5 0 0 1 .5-.5z"/> </svg>'
      builtin_icons['film'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-film" viewBox="0 0 16 16"> <path d="M0 1a1 1 0 0 1 1-1h14a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H1a1 1 0 0 1-1-1V1zm4 0v6h8V1H4zm8 8H4v6h8V9zM1 1v2h2V1H1zm2 3H1v2h2V4zM1 7v2h2V7H1zm2 3H1v2h2v-2zm-2 3v2h2v-2H1zM15 1h-2v2h2V1zm-2 3v2h2V4h-2zm2 3h-2v2h2V7zm-2 3v2h2v-2h-2zm2 3h-2v2h2v-2z"/> </svg>'
      builtin_icons['file-richtext'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-file-richtext" viewBox="0 0 16 16"> <path d="M7 4.25a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0zm-.861 1.542 1.33.886 1.854-1.855a.25.25 0 0 1 .289-.047l1.888.974V7.5a.5.5 0 0 1-.5.5H5a.5.5 0 0 1-.5-.5V7s1.54-1.274 1.639-1.208zM5 9a.5.5 0 0 0 0 1h6a.5.5 0 0 0 0-1H5zm0 2a.5.5 0 0 0 0 1h3a.5.5 0 0 0 0-1H5z"/> <path d="M2 2a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2zm10-1H4a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1z"/> </svg>'
      builtin_icons['file-text'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-file-text" viewBox="0 0 16 16"> <path d="M5 4a.5.5 0 0 0 0 1h6a.5.5 0 0 0 0-1H5zm-.5 2.5A.5.5 0 0 1 5 6h6a.5.5 0 0 1 0 1H5a.5.5 0 0 1-.5-.5zM5 8a.5.5 0 0 0 0 1h6a.5.5 0 0 0 0-1H5zm0 2a.5.5 0 0 0 0 1h3a.5.5 0 0 0 0-1H5z"/> <path d="M2 2a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2zm10-1H4a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1z"/> </svg>'
      builtin_icons['image-alt'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-image-alt" viewBox="0 0 16 16"> <path d="M7 2.5a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0zm4.225 4.053a.5.5 0 0 0-.577.093l-3.71 4.71-2.66-2.772a.5.5 0 0 0-.63.062L.002 13v2a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-4.5l-4.777-3.947z"/> </svg>'
      builtin_icons['collection'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-collection" viewBox="0 0 16 16"> <path d="M2.5 3.5a.5.5 0 0 1 0-1h11a.5.5 0 0 1 0 1h-11zm2-2a.5.5 0 0 1 0-1h7a.5.5 0 0 1 0 1h-7zM0 13a1.5 1.5 0 0 0 1.5 1.5h13A1.5 1.5 0 0 0 16 13V6a1.5 1.5 0 0 0-1.5-1.5h-13A1.5 1.5 0 0 0 0 6v7zm1.5.5A.5.5 0 0 1 1 13V6a.5.5 0 0 1 .5-.5h13a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-.5.5h-13z"/> </svg>'
      builtin_icons['postcard'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-postcard" viewBox="0 0 16 16"> <path fill-rule="evenodd" d="M2 2a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H2ZM1 4a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1H2a1 1 0 0 1-1-1V4Zm7.5.5a.5.5 0 0 0-1 0v7a.5.5 0 0 0 1 0v-7ZM2 5.5a.5.5 0 0 1 .5-.5H6a.5.5 0 0 1 0 1H2.5a.5.5 0 0 1-.5-.5Zm0 2a.5.5 0 0 1 .5-.5H6a.5.5 0 0 1 0 1H2.5a.5.5 0 0 1-.5-.5Zm0 2a.5.5 0 0 1 .5-.5H6a.5.5 0 0 1 0 1H2.5a.5.5 0 0 1-.5-.5ZM10.5 5a.5.5 0 0 0-.5.5v3a.5.5 0 0 0 .5.5h3a.5.5 0 0 0 .5-.5v-3a.5.5 0 0 0-.5-.5h-3ZM13 8h-2V6h2v2Z"/> </svg>'
      builtin_icons['file-earmark'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-file-earmark" viewBox="0 0 16 16"> <path d="M14 4.5V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2h5.5L14 4.5zm-3 0A1.5 1.5 0 0 1 9.5 3V1H4a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V4.5h-2z"/> </svg>'
      builtin_icons['arrow-up-square'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-arrow-up-square" viewBox="0 0 16 16"> <path fill-rule="evenodd" d="M15 2a1 1 0 0 0-1-1H2a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V2zM0 2a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V2zm8.5 9.5a.5.5 0 0 1-1 0V5.707L5.354 7.854a.5.5 0 1 1-.708-.708l3-3a.5.5 0 0 1 .708 0l3 3a.5.5 0 0 1-.708.708L8.5 5.707V11.5z"/> </svg>'
      builtin_icons['arrow-left'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-arrow-left" viewBox="0 0 16 16"> <path fill-rule="evenodd" d="M15 8a.5.5 0 0 0-.5-.5H2.707l3.147-3.146a.5.5 0 1 0-.708-.708l-4 4a.5.5 0 0 0 0 .708l4 4a.5.5 0 0 0 .708-.708L2.707 8.5H14.5A.5.5 0 0 0 15 8z"/> </svg>'
      builtin_icons['arrow-right'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-arrow-right" viewBox="0 0 16 16"> <path fill-rule="evenodd" d="M1 8a.5.5 0 0 1 .5-.5h11.793l-3.147-3.146a.5.5 0 0 1 .708-.708l4 4a.5.5 0 0 1 0 .708l-4 4a.5.5 0 0 1-.708-.708L13.293 8.5H1.5A.5.5 0 0 1 1 8z"/> </svg>'
      builtin_icons['arrow-down'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-arrow-down" viewBox="0 0 16 16"> <path fill-rule="evenodd" d="M8 1a.5.5 0 0 1 .5.5v11.793l3.146-3.147a.5.5 0 0 1 .708.708l-4 4a.5.5 0 0 1-.708 0l-4-4a.5.5 0 0 1 .708-.708L7.5 13.293V1.5A.5.5 0 0 1 8 1z"/> </svg>'
      builtin_icons['geo-alt-fill'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-geo-alt-fill" viewBox="0 0 16 16"> <path d="M8 16s6-5.686 6-10A6 6 0 0 0 2 6c0 4.314 6 10 6 10zm0-7a3 3 0 1 1 0-6 3 3 0 0 1 0 6z"/> </svg>'
      builtin_icons['calendar3'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-calendar3" viewBox="0 0 16 16"> <path d="M14 0H2a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2zM1 3.857C1 3.384 1.448 3 2 3h12c.552 0 1 .384 1 .857v10.286c0 .473-.448.857-1 .857H2c-.552 0-1-.384-1-.857V3.857z"/> <path d="M6.5 7a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm-9 3a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm-9 3a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2z"/> </svg>'
      builtin_icons['clock'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-clock" viewBox="0 0 16 16"> <path d="M8 3.5a.5.5 0 0 0-1 0V9a.5.5 0 0 0 .252.434l3.5 2a.5.5 0 0 0 .496-.868L8 8.71V3.5z"/> <path d="M8 16A8 8 0 1 0 8 0a8 8 0 0 0 0 16zm7-8A7 7 0 1 1 1 8a7 7 0 0 1 14 0z"/> </svg>'
      builtin_icons['person'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-person" viewBox="0 0 16 16"> <path d="M8 8a3 3 0 1 0 0-6 3 3 0 0 0 0 6Zm2-3a2 2 0 1 1-4 0 2 2 0 0 1 4 0Zm4 8c0 1-1 1-1 1H3s-1 0-1-1 1-4 6-4 6 3 6 4Zm-1-.004c-.001-.246-.154-.986-.832-1.664C11.516 10.68 10.289 10 8 10c-2.29 0-3.516.68-4.168 1.332-.678.678-.83 1.418-.832 1.664h10Z"/> </svg>'
      builtin_icons['chat-left-text'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-chat-left-text" viewBox="0 0 16 16"> <path d="M14 1a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1H4.414A2 2 0 0 0 3 11.586l-2 2V2a1 1 0 0 1 1-1h12zM2 0a2 2 0 0 0-2 2v12.793a.5.5 0 0 0 .854.353l2.853-2.853A1 1 0 0 1 4.414 12H14a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2H2z"/> <path d="M3 3.5a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9a.5.5 0 0 1-.5-.5zM3 6a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9A.5.5 0 0 1 3 6zm0 2.5a.5.5 0 0 1 .5-.5h5a.5.5 0 0 1 0 1h-5a.5.5 0 0 1-.5-.5z"/> </svg>'
      builtin_icons['person-circle'] = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-person-circle" viewBox="0 0 16 16"> <path d="M11 6a3 3 0 1 1-6 0 3 3 0 0 1 6 0z"/> <path fill-rule="evenodd" d="M0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8zm8-7a7 7 0 0 0-5.468 11.37C3.242 11.226 4.805 10 8 10s4.757 1.225 5.468 2.37A7 7 0 0 0 8 1z"/> </svg>'
      # set default values for icons used in template in case nothing is configured
      if !theme_icons['icon-image']
        theme_icons['icon-image'] = "image"
      end
      if !theme_icons['icon-audio']
        theme_icons['icon-audio'] = "soundwave"
      end
      if !theme_icons['icon-video']
        theme_icons['icon-video'] = "film"
      end
      if !theme_icons['icon-pdf']
        theme_icons['icon-pdf'] = "file-richtext"
      end
      if !theme_icons['icon-record']
        theme_icons['icon-record'] = "file-text"
      end
      if !theme_icons['icon-panorama']
        theme_icons['icon-panorama'] = "image-alt"
      end
      if !theme_icons['icon-compound-object']
        theme_icons['icon-compound-object'] = "collection"
      end
      if !theme_icons['icon-multiple']
        theme_icons['icon-multiple'] = "postcard"
      end
      if !theme_icons['icon-default']
        theme_icons['icon-default'] = "file-earmark"
      end
      if !theme_icons['icon-back-to-top']
        theme_icons['icon-back-to-top'] = "arrow-up-square"
      end
      if !theme_icons['arrow-left']
        theme_icons['arrow-left'] = "arrow-left"
      end
      if !theme_icons['arrow-right']
        theme_icons['arrow-right'] = "arrow-right"
      end
      if !theme_icons['arrow-down']
        theme_icons['arrow-down'] = "arrow-down"
      end
      # process icons
      icon_set = { }
      theme_icons.each do |i|
        # check if icon svg file exists in assets or built in
        if !lib_icon_names.include? i[1] and !builtin_icons[i[1]]
          puts color_text("Error cb_helpers: configured icon '#{i[0]}: #{i[1]}' does not exist. Please check 'theme.yml' and 'assets/lib/icons/'.", :yellow)
        else
          # if not in assets/lib/icons/ then use built in options
          if !lib_icon_names.include? i[1]
            markup = builtin_icons[i[1]]
          else
            # find matching icon
            svg_file = lib_icons.find { |icon| icon.basename == i[1] }
            # open icon svg from assets
            file = File.open(svg_file.path, "rb").read
            # remove whitespace
            markup = normalize_whitespace(file)
          end
          # create symbol style markup
          symbol_start = '<symbol id="' + i[0] + '"'
          symbol = markup.gsub('<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"', symbol_start).gsub('</svg>','</symbol>')
          # add to icon set hash
          icon_set[i[0]] = { "inline" => markup, "symbol" => symbol }
        end
      end
      # add icon set to site data
      site.data['theme_icons'] = icon_set
 
    end

    # normalize whitespace
    # taken from Jekyll Filters
    def normalize_whitespace(input)
      input.to_s.gsub(%r!\s+!, " ").tap(&:strip!)
    end

    # Color helper, to add warning colors to message outputs
    # use like: puts color_text("example", :red)
    def text_colors
      @colors = {
        red: 31,
        yellow: 33,
        green: 32
      }
    end
    def color_text(str, color_code)
      "\e[#{text_colors[color_code]}m#{str}\e[0m"
    end

  end
end
