Plugins::extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

unless AppConfig.has_key?(:aspace_custom_restrictions_pui_enhance) && AppConfig[:aspace_custom_restrictions_pui_enhance] == false
  Plugins::add_record_page_action_erb(['accession', 'archival_object', 'digital_object', 'digital_object_component', 'resource'], 
    'custom_restrictions/custom_restrictions_action')
end

require_relative '../lib/aspace_custom_restrictions_and_context_helper'
require_relative '../lib/css_js_compile'

Rails.application.config.after_initialize do

  # aggregate css & js on each restart - assume it will mean some css or js changes to local files
  plugin_directory = File.expand_path(File.dirname(__FILE__))

  css_files = Dir[File.join(plugin_directory,"assets","custom_restrictions_pui.css")]
  js_files = Dir[
      File.join(plugin_directory,"assets","custom_restrictions_pui.js"),
      File.join(plugin_directory,"assets","custom_restrictions_tree_base.js"),
      File.join(plugin_directory,"assets","custom_restrictions_tree_additions_pui.js"),
      File.join(plugin_directory,"assets","custom_restrictions_infinite_tree.js"),
      File.join(plugin_directory,"assets","custom_restrictions_infinite_records.js"),
      File.join(plugin_directory,"assets","custom_restrictions_infinite_scroll.js")
    ]
  
  AppConfig[:aspace_custom_restrictions_pui_assets_filename] = CssJsCompile.reaggregate_files(css_files, js_files, plugin_directory)

  as_version_file = File.read(File.join(ASUtils.find_base_directory, 'ARCHIVESSPACE_VERSION'))
  AppConfig[:custom_restrict_app_version] = as_version_file.gsub('v','').split('-')[0].to_f

  ApplicationController.class_eval do
    helper_method :is_search?, :should_add_custom_restrictions?, :safe_json_script

    def should_add_custom_restrictions?(controller)
      is_search?(controller) || is_accession_idx?(controller) || is_digital_object_idx?(controller) || is_resource_idx?(controller)
    end

    def safe_json_script(data)
      ASUtils.to_json(data).gsub('</', '<\/')
    end

    def is_search?(controller)
      controller.controller_name == "search"
    end
    def is_resource_idx?(controller)
      controller.controller_name == "resources"
    end
    def is_accession_idx?(controller)
      controller.controller_name == "accessions"
    end
    def is_digital_object_idx?(controller)
      controller.controller_name == "objects"
    end
  
  end

end
