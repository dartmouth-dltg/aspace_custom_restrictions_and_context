ArchivesSpace::Application.routes.draw do
  [AppConfig[:frontend_proxy_prefix], AppConfig[:frontend_prefix]].uniq.each do |prefix|
    scope prefix do
      match('/plugins/aspace_custom_restrictions_and_context/mini_tree' => 'custom_restrictions#mini_tree', :via => [:post])
    end
  end
end
