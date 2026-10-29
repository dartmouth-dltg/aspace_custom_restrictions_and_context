Plugins::extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

unless AppConfig.has_key?(:aspace_custom_restrictions_pui_enhance) && AppConfig[:aspace_custom_restrictions_pui_enhance] == false
  Plugins::add_record_page_action_erb(['accession', 'archival_object', 'digital_object', 'digital_object_component', 'resource'], 
    'custom_restrictions/custom_restrictions_action')
end

require_relative '../lib/aspace_custom_restrictions_and_context_helper'

Rails.application.config.after_initialize do

  AppConfig[:aspace_custom_restrictions_pui_asset_version] =
    AspaceCustomRestrictionsContextHelper.asset_version(File.join(File.dirname(__FILE__), "assets"))

  # major.minor as a float for the tree js (note: a future 4.10 would read as 4.1).
  # Unparseable versions (dev branch names, 'NO VERSION') assume the newest markup.
  as_version = ASConstants.VERSION.to_s[/\d+\.\d+/]
  AppConfig[:custom_restrict_app_version] = as_version ? as_version.to_f : 99.0

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
