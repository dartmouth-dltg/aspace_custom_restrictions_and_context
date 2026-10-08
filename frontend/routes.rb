ArchivesSpace::Application.routes.draw do
  [AppConfig[:frontend_proxy_prefix], AppConfig[:frontend_prefix]].uniq.each do |prefix|
    scope prefix do
      get '/plugins/aspace_custom_restrictions_and_context/mini_tree', to: 'custom_restrictions#mini_tree'
      get '/plugins/aspace_custom_restrictions_and_context/restrictions', to: 'custom_restrictions#restrictions'
    end
  end
end
