ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

require_relative '../lib/aspace_custom_restrictions_and_context_helper'

Rails.application.config.after_initialize do

  if AspaceCustomRestrictionsContextHelper.config(:aspace_custom_restrictions_faceting)
    Plugins::add_search_base_facets('custom_restrictions_u_sbool')
  end

  AppConfig[:aspace_custom_restrictions_sui_asset_version] =
    AspaceCustomRestrictionsContextHelper.asset_version(File.join(File.dirname(__FILE__), "assets"))

end
