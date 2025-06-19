class IndexerCommon

  @custom_restriction_resolves = [
    'ancestors',
    'ancestors::instances::top_container',
    'ancestors::instances::top_container::container_locations',
    'digital_object',
    'top_container',
    'top_container::container_locations'
  ]
  @@resolved_attributes += @custom_restriction_resolves
  AppConfig[:record_inheritance_resolves] += @custom_restriction_resolves

  add_indexer_initialize_hook do |indexer|
    indexer.add_document_prepare_hook {|doc, record|
      doc['custom_restrictions_u_sbool'] = nil
      case doc['primary_type']
      when 'accession'
        location = AspaceCustomRestrictionsContextHelper.get_location(record_data)
        unless location.nil? || location.empty?
          doc['custom_restrictions_locations_u_sstr'] = ASUtils.to_json(location)
        end
        doc['custom_restrictions_u_sstr'] = ASUtils.to_json(toplevel_restriction(record_data))
      when 'archival_object'
        record_data = check_ancestors_are_resolved(record)
        location = AspaceCustomRestrictionsContextHelper.get_ao_location(record_data)
        unless location.nil? || location.empty?
          doc['custom_restrictions_locations_u_sstr'] = ASUtils.to_json(location)
        end
        doc['custom_restrictions_context_u_sstr'] = ASUtils.to_json(extract_hierarchy(record_data))
        doc['custom_restrictions_u_sstr'] = ASUtils.to_json(get_restrictions(record_data))
      when 'digital_object'
        doc['custom_restrictions_u_sstr'] = ASUtils.to_json(toplevel_restriction(record_data))
      when 'digital_object_component'
        record_data = check_ancestors_are_resolved(record)
        doc['custom_restrictions_context_u_sstr'] = ASUtils.to_json(extract_hierarchy(record_data))
        doc['custom_restrictions_u_sstr'] = ASUtils.to_json(get_restrictions(record_data))
      when 'resource'
        location = AspaceCustomRestrictionsContextHelper.get_location(record_data)
        unless location.nil? || location.empty?
          doc['custom_restrictions_locations_u_sstr'] = ASUtils.to_json(location)
        end
        doc['custom_restrictions_u_sstr'] = ASUtils.to_json(toplevel_restriction(record_data))
      end
      if doc['custom_restrictions_u_sstr'] && ASUtils.json_parse(doc['custom_restrictions_u_sstr']).length > 0
        doc['custom_restrictions_u_sbool'] = true
      end
    }
  end

  # do we really need to be this paranoid?
  def self.check_ancestors_are_resolved(record)
    record_data = record['record']

    if record_data['ancestors'].nil?
      record_data = resolve_ancestors(record)
    else
      record_data['ancestors'].each do |anc|
        if anc['_resolved'].nil?
          record_data = resolve_ancestors(record)
          break
        end
      end
    end

    record_data

  end

  def self.resolve_ancestors(record)
    JSONModel::HTTP.get_json(record['uri'], 'resolve[]' => @custom_restriction_resolves)
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
