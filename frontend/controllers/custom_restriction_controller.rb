class CustomRestrictionsController < ApplicationController

  set_access_control  "view_repository" => [:mini_tree, :restrictions]

  ALLOWED_TYPES = [
    'accessions',
    'archival_objects',
    'digital_objects',
    'digital_object_components',
    'resources'
  ]

  MAX_BATCH = 100

  def mini_tree
    record_type = params[:type]

    return head :bad_request unless ALLOWED_TYPES.include?(record_type) && params[:id].to_s =~ /\A\d+\z/

    uri = "/repositories/#{session[:repo_id]}/#{record_type}/#{params[:id]}"
    search_params = {"filter_term[]" => [{"uri" => uri}.to_json], "q" => "*", "resolve[]" => ["ancestors:id@custom_restrictions_compact_resource"]}
    record = Search.all(session[:repo_id], search_params)["results"].first

    return head :not_found if record.nil?

    @tree = []
    @location = []
    @restrictions = applicable_restrictions(record)

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

  # batch lookup of restriction labels for tree nodes
  # params[:uris] => ['/repositories/2/archival_objects/1', ...]
  # returns { uri => [label, ...] }
  def restrictions
    uri_pattern = %r{\A/repositories/#{session[:repo_id].to_i}/(#{ALLOWED_TYPES.join('|')})/\d+\z}
    uris = Array(params[:uris]).map(&:to_s).select {|uri| uri =~ uri_pattern}.uniq.first(MAX_BATCH)

    return render(:json => {}) if uris.empty?

    query = {
      'query' => {
        'jsonmodel_type' => 'boolean_query',
        'op' => 'OR',
        'subqueries' => uris.map {|uri| {'jsonmodel_type' => 'field_query', 'field' => 'uri', 'value' => uri, 'literal' => true}}
      }
    }
    results = Search.all(session[:repo_id], {'aq' => ASUtils.to_json(query), 'page_size' => uris.length})['results']

    labels = {}
    results.each do |record|
      labels[record['uri']] = applicable_restrictions(record).map do |level, restriction|
        I18n.t('custom_restrictions_and_context.restriction_label',
               :level => level.titleize,
               :restriction => I18n.t('enumerations.custom_restriction_type.' + restriction, default: I18n.t('enumerations.custom_restriction_type.default')))
      end
    end

    render :json => ASUtils.to_json(labels)
  end

  private

  # {level => restriction_type} filtered by any configured type to level mapping
  def applicable_restrictions(record)
    restrictions = record['custom_restrictions_u_sstr'].nil? ? {} : ASUtils.json_parse(record['custom_restrictions_u_sstr'].fetch(0))
    AspaceCustomRestrictionsContextHelper.restriction_applies_to_object?(record, restrictions)
  end

end
