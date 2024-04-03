Rails.application.routes.draw do
  [AppConfig[:public_proxy_prefix], AppConfig[:public_prefix]].uniq.each do |prefix|
    scope prefix do
      post 'aspace_custom_restrictions_and_context/pui_restrictions', to: 'custom_restrictions_pui#custom_pui_restrictions'
    end
  end
end
