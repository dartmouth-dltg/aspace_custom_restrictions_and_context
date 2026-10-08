class CustomRestrictionsPuiController < ApplicationController

  skip_before_action  :verify_authenticity_token

  def custom_pui_restrictions
    record_type = params[:type]
    uri = params[:uri]

    allowed_types = [
      'accessions',
      'archival_objects',
      'digital_objects',
      'digital_object_components',
      'resources'
    ]

    unless allowed_types.include?(record_type)
      render :json => {}
      return
    end

    record = begin
      ArchivesSpaceClient.instance.search_records([uri]).raw.fetch('results', []).first
    rescue StandardError => e
      Rails.logger.error("custom restrictions: search failed for #{uri}: #{e.message}")
      nil
    end

    restrictions = {}
    if record
      restrictions = record['custom_restrictions_u_sstr'].nil? ? {} : ASUtils.json_parse(record['custom_restrictions_u_sstr'].fetch(0))
      restrictions = AspaceCustomRestrictionsContextHelper.restriction_applies_to_object?(record, restrictions)
    end

    # restrictions is in form {level => restriction_type}
    if restrictions.empty?
      render :json => {}
    else
      restriction_type = I18n.t('enumerations.custom_restriction_type.' + restrictions.values.first, default: I18n.t('enumerations.custom_restriction_type.default'))
      restriction_message = I18n.t('custom_restrictions_and_context.restriction_label',
                                   level: restrictions.keys.first.titleize,
                                   restriction: restriction_type)
      render :json => ASUtils.to_json(restriction_message)
    end
  end

end
