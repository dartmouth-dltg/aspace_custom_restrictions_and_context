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
        record = ArchivesSpaceClient.instance.get_record(uri, 'resolve[]' => resolve)
      rescue
        record = false
      end

      if record

        case record_type
        when 'accessions'
          restrictions = toplevel_restriction(record.raw)
        when 'archival_objects'
          restrictions = get_restrictions(record.raw)
        when 'digital_objects'
          restrictions = toplevel_restriction(record.raw)
        when 'digital_object_components'
          restrictions = get_restrictions(record.raw)
        when 'resources'
          restrictions = toplevel_restriction(record.raw)
        end

        restrictions = AspaceCustomRestrictionsContextHelper.restriction_applies_to_object?(ASUtils.json_parse(record.raw['json']), restrictions)

        # restrictions is in form {level => restriction_type}
        if restrictions.empty?
          render :json => {}
        else
          restriction_message = I18n.t('enumerations.custom_restriction_type.' + restrictions.values.first, I18n.t('enumerations.custom_restriction_type.default'))
          render :json => ASUtils.to_json(restriction_message)
        end

      else
        render :json => {}
      end

    else
      render :json => {}
    end
  end

  private

  def get_restrictions(record)
    restrictions = AspaceCustomRestrictionsContextHelper.is_restricted?(ASUtils.json_parse(record['json']))
    if restrictions.empty?
      if record['_resolved_ancestors'] && record['_resolved_ancestors'].length > 0
        # uggghhh! resolved ancestors are stored as a hash....ugly
        record['_resolved_ancestors'].to_a.reverse.to_h.each do |anc|
          break if restrictions.length > 0 
          # resolved ancestors are in form [uri, [record]]
          restrictions = AspaceCustomRestrictionsContextHelper.is_restricted?(ASUtils.json_parse(anc.last.first['json']))
        end
      end
    end

    restrictions
  end

  def toplevel_restriction(record)
    AspaceCustomRestrictionsContextHelper.is_restricted?(ASUtils.json_parse(record['json']))
  end

end
