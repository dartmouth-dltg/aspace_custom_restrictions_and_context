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
    resolve = ['ancestors:id']

    if allowed_types.include?(record_type)

      begin
        results = ArchivesSpaceClient.instance.search_records([uri])
      rescue
        record = false
      end

      unless results.raw.fetch('results', []).empty?
        record = results.raw.fetch('results').fetch(0)
      end

      if record
        restrictions = record['custom_restrictions_u_sstr'].nil? ? {} : ASUtils.json_parse(record['custom_restrictions_u_sstr'].fetch(0))
        restrictions = AspaceCustomRestrictionsContextHelper.restriction_applies_to_object?(record, restrictions)

        # restrictions is in form {level => restriction_type}
        if restrictions.empty?
          render :json => {}
        else
          begin
            restriction_type = I18n.t('enumerations.custom_restriction_type.' + restrictions.values.first, :raise => I18n::MissingTranslationData)
          rescue I18n::MissingTranslationData
            restriction_type = I18n.t('enumerations.custom_restriction_type.default')
          end
          restriction_message = I18n.t('custom_restrictions_and_context.restriction_label', 
                            {
                              :level => restrictions.keys.first.titleize,
                              :restriction => restriction_type
                            }
                          )
          render :json => ASUtils.to_json(restriction_message)
        end

      else
        render :json => {}
      end

    else
      render :json => {}
    end
  end

end
