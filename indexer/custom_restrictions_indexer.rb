class IndexerCommon

  @custom_restriction_resolves = [
    'ancestors',
    'ancestors::instances::top_container',
    'ancestors::instances::top_container::container_locations',
    'digital_object',
    'top_container',
    'top_container::container_locations'
  ]
  @custom_restriction_resolves.each {|attr| add_attribute_to_resolve(attr)}

  add_indexer_initialize_hook do |indexer|
    hook = proc {|doc, record|
      doc['custom_restrictions_u_sbool'] = nil
      record_data = record['record']
      restrictions = nil
      case doc['primary_type']
      when 'accession', 'resource'
        location = AspaceCustomRestrictionsContextHelper.get_location(record_data)
        unless location.nil? || location.empty?
          doc['custom_restrictions_locations_u_sstr'] = ASUtils.to_json(location)
        end
        restrictions = toplevel_restriction(record_data)
      when 'archival_object'
        record_data = check_ancestors_are_resolved(record)
        location = AspaceCustomRestrictionsContextHelper.get_ao_location(record_data)
        unless location.nil? || location.empty?
          doc['custom_restrictions_locations_u_sstr'] = ASUtils.to_json(location)
        end
        doc['custom_restrictions_context_u_sstr'] = ASUtils.to_json(extract_hierarchy(record_data))
        restrictions = get_restrictions(record_data)
      when 'digital_object'
        restrictions = toplevel_restriction(record_data)
      when 'digital_object_component'
        record_data = check_ancestors_are_resolved(record)
        doc['custom_restrictions_context_u_sstr'] = ASUtils.to_json(extract_hierarchy(record_data))
        restrictions = get_restrictions(record_data)
      end
      if restrictions
        doc['custom_restrictions_u_sstr'] = ASUtils.to_json(restrictions)
        doc['custom_restrictions_u_sbool'] = true unless restrictions.empty?
      end
    }

    # PUIIndexer's own prepare hook deletes record['record']['ancestors']. Before
    # final_doc_rules (archivesspace #3667) it ran ahead of plugin hooks, so go
    # first there or every AO costs a backend GET
    if indexer.respond_to?(:final_doc_rules, true)
      indexer.add_document_prepare_hook(&hook)
    else
      indexer.instance_variable_get(:@document_prepare_hooks).unshift(hook)
    end
  end

  # fall back to fetching the record if ancestors somehow arrived unresolved
  def self.check_ancestors_are_resolved(record)
    ancestors = record['record']['ancestors']
    return record['record'] unless ancestors.nil? || ancestors.any? {|anc| anc['_resolved'].nil?}

    JSONModel::HTTP.get_json(record['uri'], 'resolve[]' => @custom_restriction_resolves)
  end

  def self.get_restrictions(record)
    restrictions = AspaceCustomRestrictionsContextHelper.is_restricted?(record)
    if restrictions.empty?
      if record['ancestors'] && record['ancestors'].length > 0
        record['ancestors'].each do |anc|
          break unless restrictions.empty?
          next unless anc['_resolved']
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
        next unless anc['_resolved']
        level = AspaceCustomRestrictionsContextHelper.record_level(anc['_resolved']).downcase
        display_string = anc['_resolved']['display_string']
        title = display_string.nil? || display_string.empty? ? anc['_resolved']['title'] : display_string
        hierarchy[level] = title
      end
    end

    hierarchy
  end

end
