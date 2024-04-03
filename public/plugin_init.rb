Plugins::extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Plugins::add_record_page_action_erb(['accession', 'archival_object', 'digital_object', 'resource'], 
  'custom_restrictions/custom_restrictions_action')
