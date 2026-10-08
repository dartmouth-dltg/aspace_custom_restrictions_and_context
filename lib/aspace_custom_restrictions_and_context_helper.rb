class AspaceCustomRestrictionsContextHelper

  # AppConfig[] raises on unset keys
  def self.config(key, default = nil)
    AppConfig.has_key?(key) ? AppConfig[key] : default
  end

  def self.use_accessrestrict?
    config(:aspace_custom_restrictions_use_accessrestrict) != false
  end

  # accepts both JSONModel hashes (jsonmodel_type) and solr docs (primary_type)
  def self.record_level(record)
    level = record['level'] == 'otherlevel' ? record['other_level'] : record['level']
    level = (record['jsonmodel_type'] || record['primary_type']).to_s.tr('_', ' ').capitalize if level.nil? || level.empty?

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
    type_mapping = config(:aspace_custom_restriction_type_mapping)
    return restrictions unless type_mapping.is_a?(Hash)

    result_level = record_level(record).downcase

    restrictions.each_value do |restriction|
      levels = type_mapping[restriction]
      return {} if levels && !levels.include?(result_level)
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

  # true if any accessrestrict note is not neutralised by a configured skip phrase
  def self.has_local_access_note?(notes_json)
    skip_phrases = config(:aspace_custom_restrictions_access_note_skip_phrases)
    skip_phrases = [] unless skip_phrases.is_a?(Array)

    notes_json.any? do |note|
      next false unless note['type'] == 'accessrestrict'

      (note['subnotes'] || []).none? do |subnote|
        content = subnote['content']
        !content.nil? && skip_phrases.any? {|phrase| content.downcase.include?(phrase.downcase)}
      end
    end
  end

  def self.check_for_subcontainers(instances)
    (instances || []).any? {|inst| inst['sub_container']}
  end

  def self.parse_container_locations(container_locations)
    locations = []
    unless container_locations.nil?
      container_locations.each do |cloc|
        if cloc['status'] == 'current'
          if cloc['_resolved'] && cloc['_resolved']['title']
            locations << cloc['_resolved']['title']
          else
            res_cloc = JSONModel::HTTP.get_json(cloc['ref'])
            locations << res_cloc['title'] if res_cloc && res_cloc['title']
          end
        end
      end
    end

    locations
  end

  def self.parse_containers(instances)
    containers = []
    (instances || []).each do |inst|
      if inst['sub_container'] && inst['sub_container']['top_container'] && inst['sub_container']['top_container']['_resolved']
        display_string = inst['sub_container']['top_container']['_resolved']['display_string']
        type = inst['sub_container']['top_container']['_resolved']['type']

        if type.nil?
          display_string = "Container: #{display_string}"
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
          if check_for_subcontainers(anc['_resolved']['instances'])
            return parse_containers(anc['_resolved']['instances'])
          end
        end
      end
    end

    # If we get here, we didn't find any subcontainers in the ancestors
    nil
  end

  def self.get_location(record)
    indicator_and_location = nil
    if check_for_subcontainers(record['instances'])
      indicator_and_location = parse_containers(record['instances'])
    end

    indicator_and_location
  end

  def self.get_ao_location(record)
    get_location(record) || check_ancestor_instances(record)
  end

  def self.view_content(uri)
    restrictions = {}
    locations = {} 
    context_tree = ''

    params = {"filter_term[]" => [{"uri" => uri}.to_json], "q" => "*", "resolve[]" => ["ancestors:id@custom_restrictions_compact_resource"]}
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
