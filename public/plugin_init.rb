Plugins::extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

unless AppConfig.has_key?(:aspace_custom_restrictions_pui_enhance) && AppConfig[:aspace_custom_restrictions_pui_enhance] == false
  Plugins::add_record_page_action_erb(['accession', 'archival_object', 'digital_object', 'resource'], 
    'custom_restrictions/custom_restrictions_action')
end

require_relative '../lib/aspace_custom_restrictions_and_context_helper'
