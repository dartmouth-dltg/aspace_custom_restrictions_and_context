require 'aspace_logger'
class CustomRestrictionsController < ApplicationController

  #skip_before_filter :unauthorised_access
  set_access_control  "view_repository" => [:mini_tree]

  def mini_tree
    id = params[:id]
    repo_id = params[:repo_id]
    record_type = params[:type]
    allowed_types = [
      'accessions',
      'archival_objects',
      'digital_objects',
      'resources'
    ]
    return unless allowed_types.include?(record_type)

    resolve = ['top_container', 'top_container::container_locations', 'ancestors', 'ancestors::instances::top_container', 'ancestors::instances::top_container::container_locations']
    uri = '/repositories/' + repo_id + '/' + record_type + '/' + id
    @tree = ''
    @location = ''

    unless id.empty?
      record = JSONModel::HTTP.get_json(uri, 'resolve[]' => resolve)
      unless record.nil?
        case record_type
        when 'accessions'
          @restrictions = toplevel_restriction(record)
        when 'archival_objects'
          @location = AspaceCustomRestrictionsContextHelper.get_ao_location(record)
          @tree = extract_hierarchy(record)
          @restrictions = get_restrictions(record)
        when 'digital_objects'
          @restrictions = toplevel_restriction(record)
        when 'resources'
          @location = AspaceCustomRestrictionsContextHelper.get_resource_location(record)
          @restrictions = toplevel_restriction(record)
        end
      end
    end
    
    render_aspace_partial :partial => "mini_tree/context"
  end

  private

  def is_restricted?(record)
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

  def get_restrictions(record)
    restrictions = is_restricted?(record)
    
    if restrictions.empty?
      if record['ancestors'] && record['ancestors'].length > 0
        record['ancestors'].each do |anc|
          break if restrictions.length > 0 
          restrictions = is_restricted?(anc['_resolved'])
        end
      end
    end

    restrictions
  end

  def toplevel_restriction(record)
    is_restricted?(record)
  end

  def extract_hierarchy(record)
    hierarchy = {}
    if record['ancestors']
      record['ancestors'].reverse.each do |anc|
        level = anc['level']
        title = anc['_resolved']['title']
        hierarchy[level] = title
      end
    end

    hierarchy
  end

end
