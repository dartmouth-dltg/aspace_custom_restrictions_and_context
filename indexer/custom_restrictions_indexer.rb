class IndexerCommon

  @custom_restriction_resolves = [
    'top_container',
    'top_container::container_locations',
    'ancestors',
    'ancestors::instances::top_container',
    'ancestors::instances::top_container::container_locations',
    'digital_object'
  ]
  @@resolved_attributes += @custom_restriction_resolves

  add_indexer_initialize_hook do |indexer|
    indexer.add_document_prepare_hook {|doc, record|
      record_data = record['record']
      case doc['primary_type']
      when 'accession'
        unless AspaceCustomRestrictionsContextHelper.get_location(record_data).nil?
          doc['custom_restrictions_locations_u_sstr'] = ASUtils.to_json(AspaceCustomRestrictionsContextHelper.get_location(record_data))
        end
        doc['custom_restrictions_u_sstr'] = ASUtils.to_json(toplevel_restriction(record_data))
      when 'archival_object'
        if record_data['ancestors'].nil?
          record_data = resolve_ancestors_for_pui(record)
        end
        unless AspaceCustomRestrictionsContextHelper.get_ao_location(record_data).nil?
          doc['custom_restrictions_locations_u_sstr'] = ASUtils.to_json(AspaceCustomRestrictionsContextHelper.get_ao_location(record_data))
        end
        doc['custom_restrictions_context_u_sstr'] = ASUtils.to_json(extract_hierarchy(record_data))
        doc['custom_restrictions_u_sstr'] = ASUtils.to_json(get_restrictions(record_data))
      when 'digital_object'
        doc['custom_restrictions_u_sstr'] = ASUtils.to_json(toplevel_restriction(record_data))
      when 'digital_object_component'
        if record_data['ancestors'].nil?
          record = resolve_ancestors_for_pui(record)
        end
        doc['custom_restrictions_context_u_sstr'] = ASUtils.to_json(extract_hierarchy(record_data))
        doc['custom_restrictions_u_sstr'] = ASUtils.to_json(get_restrictions(record_data))
      when 'resource'
        unless AspaceCustomRestrictionsContextHelper.get_location(record_data).nil?
          doc['custom_restrictions_locations_u_sstr'] = ASUtils.to_json(AspaceCustomRestrictionsContextHelper.get_location(record_data))
        end
          doc['custom_restrictions_u_sstr'] = ASUtils.to_json(toplevel_restriction(record_data))
      end
    }
  end

  def self.resolve_ancestors_for_pui(record)
    enhanced_record = JSONModel::HTTP.get_json(record['uri'], 'resolve[]' => @custom_restriction_resolves)

    enhanced_record
  end

  def self.get_restrictions(record)
    restrictions = AspaceCustomRestrictionsContextHelper.is_restricted?(record)
    if restrictions.empty?
      if record['ancestors'] && record['ancestors'].length > 0
        record['ancestors'].each do |anc|
          break if restrictions.length > 0 
          restrictions = AspaceCustomRestrictionsContextHelper.is_restricted?(anc['_resolved'])
        end
      end
    end

    restrictions
  end

  def self.toplevel_restriction(record)
    AspaceCustomRestrictionsContextHelper.is_restricted?(record)
  end

  def self.extract_hierarchy(record)
    hierarchy = {}
    if record['ancestors']
      record['ancestors'].reverse.each do |anc|
        level = anc['level'].nil? ? anc['_resolved']['jsonmodel_type'].sub('_',' '): anc['level']
        display_string = anc['_resolved']['display_string']
        title = display_string.nil? || display_string.empty? ? anc['_resolved']['title'] : display_string
        hierarchy[level] = title
      end
    end

    hierarchy
  end

end
