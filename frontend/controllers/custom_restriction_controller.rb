class CustomRestrictionsController < ApplicationController

  set_access_control  "view_repository" => [:mini_tree]

  ALLOWED_TYPES = [
    'accessions',
    'archival_objects',
    'digital_objects',
    'digital_object_components',
    'resources'
  ]

  def mini_tree
    record_type = params[:type]
    restrictions_only = params[:restrictions_only] ? true : false

    return head :bad_request unless ALLOWED_TYPES.include?(record_type) && params[:id].to_s =~ /\A\d+\z/

    uri = "/repositories/#{session[:repo_id]}/#{record_type}/#{params[:id]}"
    search_params = {"filter_term[]" => [{"uri" => uri}.to_json], "q" => "*", "resolve[]" => ["ancestors:id@custom_restrictions_compact_resource"]}
    record = Search.all(session[:repo_id], search_params)["results"].first

    return render(:json => ASUtils.to_json([])) if record.nil? && restrictions_only
    return head :not_found if record.nil?

    @tree = []
    @location = []
    @restrictions = record['custom_restrictions_u_sstr'].nil? ? {} : ASUtils.json_parse(record['custom_restrictions_u_sstr'].fetch(0))
    @restrictions = AspaceCustomRestrictionsContextHelper.restriction_applies_to_object?(record, @restrictions)

    if restrictions_only
      translated_restrictions = @restrictions.map do |level, restriction|
        I18n.t('custom_restrictions_and_context.restriction_label',
               :level => level.titleize,
               :restriction => I18n.t('enumerations.custom_restriction_type.' + restriction, default: I18n.t('enumerations.custom_restriction_type.default')))
      end

      render :json => ASUtils.to_json(translated_restrictions)
    else
      unless record['custom_restrictions_context_u_sstr'].nil?
        @tree = record['custom_restrictions_context_u_sstr'].reject(&:empty?).map {|ctx| ASUtils.json_parse(ctx)}.first || []
      end
      unless record['custom_restrictions_locations_u_sstr'].nil?
        record['custom_restrictions_locations_u_sstr'].each do |loc|
          next if loc.nil? || loc.empty?
          @location << ASUtils.json_parse(loc).fetch(0)
        end
      end

      render_aspace_partial :partial => "mini_tree/context"
    end
  end

end
