ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

require_relative '../lib/aspace_custom_restrictions_and_context_helper'
require_relative '../lib/css_js_compile'

Rails.application.config.after_initialize do

  if AppConfig[:plugins].include?('aspace_custom_restrictions_and_context') &&
      AppConfig.has_key?(:aspace_custom_restrictions_faceting) &&
      AppConfig[:aspace_custom_restrictions_faceting]
    Plugins::add_search_base_facets('custom_restrictions_u_sbool')
  end

  ActionView::PartialRenderer.class_eval do
    alias_method :render_custom_restrictions, :render
    def render(context, options, block)
      result = render_custom_restrictions(context, options, block);

      # Add our location-specific templates to shared/templates
      if options[:partial] == "shared/templates"
        result += render(context, options.merge(:partial => "js_templates/templates"), nil)
      end

      result
    end
  end

  # aggregate css & js on each restart - assume it will mean some css or js changes to local files
  plugin_directory = File.expand_path(File.dirname(__FILE__))

  css_files = Dir[File.join(plugin_directory,"assets","custom_restrictions_context.css")]
  js_files = Dir[
      File.join(plugin_directory,"assets","custom_restrictions_context.js"),
      File.join(plugin_directory,"assets","custom_restrictions_tree_additions.js")
    ]

  AppConfig[:aspace_custom_restrictions_sui_assets_filename] = CssJsCompile.reaggregate_files(css_files, js_files, plugin_directory)

end
