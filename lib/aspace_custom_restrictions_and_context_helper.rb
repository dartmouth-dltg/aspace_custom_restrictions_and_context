class AspaceCustomRestrictionsContextHelper

  def self.is_restricted?(record)
    restrictions = {}
    level = record['level'] == 'otherlevel' ? record['other_level'] : record['level']

    if level.nil?
      level = record['jsonmodel_type'].gsub('_', ' ').capitalize
    end

    if record['custom_restriction'] && record['custom_restriction']['custom_restriction_type']
      restrictions[level] = record['custom_restriction']['custom_restriction_type']
    elsif record['restrictions_apply'] || record['restrictions']
      restrictions[level] = 'default'
    end

    restrictions
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
      if inst['sub_container']['top_container'] && inst['sub_container']['top_container']['_resolved']
        indicator = inst['sub_container']['top_container']['_resolved']['indicator']
        type = inst['sub_container']['top_container']['_resolved']['type']
        locations = parse_container_locations(inst['sub_container']['top_container']['_resolved']['container_locations'])
        containers << {
          "indicator" => indicator, 
          "type" => type, 
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

  def self.get_resource_location(record)
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

end
