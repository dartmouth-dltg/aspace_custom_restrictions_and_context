class CustomRestrictionsPuiController < ApplicationController

  ALLOWED_TYPES = [
    'accessions',
    'archival_objects',
    'digital_objects',
    'digital_object_components',
    'resources'
  ]

  MAX_BATCH = 100

  # batch lookup of restriction labels for tree nodes
  # params[:uris] => ['/repositories/2/archival_objects/1', ...]
  # returns { uri => label } where label is '' if there is no restriction
  def custom_pui_restrictions
    uri_pattern = %r{\A/repositories/\d+/(#{ALLOWED_TYPES.join('|')})/\d+\z}

    # tolerate a trailing fragment (e.g. #pui) but key the response by what was sent
    requested = Array(params[:uris]).map(&:to_s).uniq.first(MAX_BATCH)
    lookup = requested.each_with_object({}) do |uri, h|
      bare = uri.sub(/#.*\z/, '')
      h[uri] = bare if bare =~ uri_pattern
    end

    return render(:json => {}) if lookup.empty?

    records = begin
      ArchivesSpaceClient.instance.search_records(lookup.values.uniq, 'page_size' => lookup.size).raw.fetch('results', [])
    rescue StandardError => e
      Rails.logger.error("custom restrictions: search failed: #{e.message}")
      []
    end
    records_by_uri = records.each_with_object({}) {|record, h| h[record['uri']] = record}

    labels = lookup.each_with_object({}) do |(uri, bare), h|
      h[uri] = restriction_label(records_by_uri[bare])
    end

    render :json => ASUtils.to_json(labels)
  end

  private

  def restriction_label(record)
    return '' if record.nil?

    restrictions = record['custom_restrictions_u_sstr'].nil? ? {} : ASUtils.json_parse(record['custom_restrictions_u_sstr'].fetch(0))
    restrictions = AspaceCustomRestrictionsContextHelper.restriction_applies_to_object?(record, restrictions)
    return '' if restrictions.empty?

    I18n.t('custom_restrictions_and_context.restriction_label',
           level: restrictions.keys.first.titleize,
           restriction: I18n.t('enumerations.custom_restriction_type.' + restrictions.values.first,
                               default: I18n.t('enumerations.custom_restriction_type.default')))
  end

end
