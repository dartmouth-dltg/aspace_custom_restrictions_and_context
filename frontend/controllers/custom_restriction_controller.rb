require 'aspace_logger'
class CustomRestrictionsController < ApplicationController

  #skip_before_filter :unauthorised_access
  set_access_control  "view_repository" => [:mini_tree]

  def mini_tree
    id = params[:id]
    repo_id = params[:repo_id]
    record_type = params[:type]
    restrictions_only = params[:restrictions_only] ? true : false
    allowed_types = [
      'accessions',
      'archival_objects',
      'digital_objects',
      'digital_object_components',
      'resources'
    ]

    return unless allowed_types.include?(record_type)

    uri = "/repositories/#{session[:repo_id]}/#{record_type}/#{id}"

    @tree = []
    @location = []
    @restrictions = {}

    unless id.empty?

      params = {"filter_term[]" => [{"uri" => uri}.to_json], "q" => "*", "resolve[]" => ["ancestors:id@dartmouth_compact_resource"]}
      repo = JSONModel.parse_reference(uri)[:repository]
      repo_id = JSONModel.parse_reference(repo)[:id]
  
      results = Search.all(repo_id, params)["results"]

      unless results.empty?
        record = results.first
      end

      unless record.nil?
        @restrictions = record['custom_restrictions_u_sstr'].nil? ? {} : ASUtils.json_parse(record['custom_restrictions_u_sstr'].fetch(0))

        unless restrictions_only
          unless record['custom_restrictions_context_u_sstr'].nil?
            record['custom_restrictions_context_u_sstr'].each do |ctx|
              next if ctx.empty?
              @tree << ASUtils.json_parse(ctx)
            end
            @tree = @tree.fetch(0)
          end
          unless record['custom_restrictions_locations_u_sstr'].nil?
            record['custom_restrictions_locations_u_sstr'].each do |loc|
              next if loc.nil? || loc.empty?
              @location << ASUtils.json_parse(loc).fetch(0)
            end
          end
        end

      end
    end

    @restrictions = AspaceCustomRestrictionsContextHelper.restriction_applies_to_object?(record, @restrictions)

    if restrictions_only
      translated_restrictions = []
      @restrictions.each do |level, restriction|
        translated_restrictions << I18n.t('custom_restrictions_and_context.restriction_label', 
          level: level.titleize,
          restriction: I18n.t('enumerations.custom_restriction_type.' + restriction, default: I18n.t('enumerations.custom_restriction_type.default'))
        )
      end
      render :json => ASUtils.to_json(translated_restrictions)
    else
      render_aspace_partial :partial => "mini_tree/context"
    end
  end

end
