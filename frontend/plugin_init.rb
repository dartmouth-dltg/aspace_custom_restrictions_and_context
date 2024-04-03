ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do

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

end
