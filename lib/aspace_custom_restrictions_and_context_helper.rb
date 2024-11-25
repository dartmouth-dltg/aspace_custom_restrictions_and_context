class AspaceCustomRestrictionsContextHelper

  def self.use_accessrestrict?
   AppConfig.has_key?(:aspace_custom_restrictions_use_accessrestrict) && AppConfig[:aspace_custom_restrictions_use_accessrestrict] == false ? false : true
  end

  def self.record_level(record)
    level = record['level'] == 'otherlevel' ? record['other_level'] : record['level']

    if level.nil?
      level = record['jsonmodel_type'].gsub('_', ' ').capitalize
    end

    level
  end

  def self.restriction_applies_to_object?(record, restrictions)
    # list the level that a restriction applies to
    # default is all restriction types apply to all levels
    # uses config option specified like:
    # AppConfig[:aspace_custom_restriction_type_mapping] = {
    #  'some_materials_restricted' => [
    #    'otherlevel',
    #    'box',
    #    'collection',
    #    'series',
    #    'subseries'
    #  ]
    # }
    result_level = record_level(record).downcase
    aos_for_res_type = AppConfig.has_key?(:aspace_custom_restriction_type_mapping) ? AppConfig[:aspace_custom_restriction_type_mapping] : nil

    # check if we have a restriction type that only applies to certain levels
    unless aos_for_res_type.nil?
      restrictions.each do |restriction_level, restriction|
        if aos_for_res_type.keys.include?(restriction)
          aos_for_res_type.each do |restriction_type, ao_types|
            unless ao_types.include?(result_level)
              restrictions = {}
            end
          end
        end
      end
    end

    restrictions

  end

  def self.is_restricted?(record)
    restrictions = {}
    level = record_level(record)

    if record['custom_restriction'] && record['custom_restriction']['custom_restriction_type']
      restrictions[level] = record['custom_restriction']['custom_restriction_type']
    end

    if restrictions.empty? && record['notes'] && use_accessrestrict? && has_local_access_note?(record['notes'])
      # If you want to tailor the restriction by access note type
      # you'll want to map the access type to a restriction message.
      # Since access notes can have multiple types, you'll also need
      # to decide what the priority of the access note types is for display.
      # For now, we just use the default.
      restrictions[level] = 'default'
    end

    if restrictions.empty? && (record['restrictions_apply'] || record['restrictions'])
      restrictions[level] = 'default'
    end

    restrictions
  end

  def self.has_local_access_note?(notes_json)
    has_local_access_restriction = false
    notes_json.each do |note|
      if note['type'] == 'accessrestrict'
        has_local_access_restriction = true
        if AppConfig.has_key?(:aspace_custom_restrictions_access_note_skip_phrases) && AppConfig[:aspace_custom_restrictions_access_note_skip_phrases].kind_of?(Array)
          unless note['subnotes'].nil?
            note['subnotes'].each do |subnote|
              break unless has_local_access_restriction
              AppConfig[:aspace_custom_restrictions_access_note_skip_phrases].each do |skip_phrase|
                break unless has_local_access_restriction
                unless subnote['content'].nil?
                  if subnote['content'].downcase.include?(skip_phrase.downcase)
                    has_local_access_restriction = false
                  end
                end
              end
            end
          end
        end
      end
    end

    has_local_access_restriction
  end
  
  def self.check_for_subcontainers(instances)
    has_sub_containers = false
    instances.each do |inst|
      if inst['sub_container']
        has_sub_containers = true
      end
    end
    has_sub_containers
  end

  def self.parse_container_locations(container_locations)
    locations = []
    unless container_locations.nil?
      container_locations.each do |cloc|
        if cloc['status'] == 'current'
          locations << cloc['_resolved']['title']
        end
      end
    end

    locations
  end

  def self.parse_containers(instances)
    containers = []
    instances.each do |inst|
      if inst['sub_container'] && inst['sub_container']['top_container'] && inst['sub_container']['top_container']['_resolved']
        display_string = inst['sub_container']['top_container']['_resolved']['display_string']
        type = inst['sub_container']['top_container']['_resolved']['type']

        if type.nil?
          display_string = "Container: " + display_string
        end

        locations = parse_container_locations(inst['sub_container']['top_container']['_resolved']['container_locations'])
        containers << {
          "display_string" => display_string,
          "locations" => locations
        }
      end
    end

    containers
  end

  def self.check_ancestor_instances(record)
    if record['ancestors']
      record['ancestors'].each do |anc|
        if anc['_resolved']
          get_ao_location(anc['_resolved'])
        end
      end
    end
  end

  def self.get_location(record)
    indicator_and_location = nil
    if check_for_subcontainers(record['instances'])
      indicator_and_location = parse_containers(record['instances'])
    end

    indicator_and_location
  end

  def self.get_ao_location(record)
    indicator_and_location = nil
    if record['instances'].empty?
      check_ancestor_instances(record)
    else
      if check_for_subcontainers(record['instances'])
        indicator_and_location = parse_containers(record['instances'])
      else
        check_ancestor_instances(record)
      end
    end

    return indicator_and_location
  end

  def self.view_content(uri)
    restrictions = {}
    locations = {} 
    context_tree = ''

    params = {"filter_term[]" => [{"uri" => uri}.to_json], "q" => "*", "resolve[]" => ["ancestors:id@dartmouth_compact_resource"]}
    repo = JSONModel.parse_reference(uri)[:repository]
    repo_id = JSONModel.parse_reference(repo)[:id]

    obj_data = Search.all(repo_id, params)["results"]

    unless obj_data.empty?
      record = obj_data.first
    end

    unless record.nil?
      restrictions = record['custom_restrictions_u_sstr'].nil? ? {} : ASUtils.json_parse(record['custom_restrictions_u_sstr'].first)
      locations = record['custom_restrictions_locations_u_sstr'].nil? ? {} : ASUtils.json_parse(record['custom_restrictions_locations_u_sstr'].first)
      context_tree = record['custom_restrictions_context_u_sstr'].nil? ? {} : ASUtils.json_parse(record['custom_restrictions_context_u_sstr'].first)
    end
    
    return restrictions, locations, context_tree
  end

end
