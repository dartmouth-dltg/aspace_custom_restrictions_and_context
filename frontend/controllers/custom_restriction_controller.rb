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
      'digital_object_components',
      'resources'
    ]
    return unless allowed_types.include?(record_type)

    resolve = ['top_container', 'top_container::container_locations', 'ancestors', 'ancestors::instances::top_container', 'ancestors::instances::top_container::container_locations', 'digital_object']
    uri = '/repositories/' + repo_id + '/' + record_type + '/' + id
    @tree = ''
    @location = ''
    @restrictions = {}

    unless id.empty?
      record = JSONModel::HTTP.get_json(uri, 'resolve[]' => resolve)
      unless record.nil?
        case record_type
        when 'accessions'
          @location = AspaceCustomRestrictionsContextHelper.get_location(record)
          @restrictions = toplevel_restriction(record)
        when 'archival_objects'
          @location = AspaceCustomRestrictionsContextHelper.get_ao_location(record)
          @tree = extract_hierarchy(record)
          @restrictions = get_restrictions(record)
        when 'digital_objects'
          @restrictions = toplevel_restriction(record)
        when 'digital_object_components'
          @tree = extract_hierarchy(record)
          @restrictions = get_digital_object_component_restrictions(record)
        when 'resources'
          @location = AspaceCustomRestrictionsContextHelper.get_location(record)
          @restrictions = toplevel_restriction(record)
        end
      end
    end

    @restrictions = AspaceCustomRestrictionsContextHelper.restriction_applies_to_object?(record, @restrictions)
    
    render_aspace_partial :partial => "mini_tree/context"
  end

  private

  def get_digital_object_component_restrictions(record)
    restrictions = AspaceCustomRestrictionsContextHelper.is_restricted?(record)
    if restrictions.empty?
      restrictions = AspaceCustomRestrictionsContextHelper.is_restricted?(record['digital_object']['_resolved'])
    end

    restrictions
  end

  def get_restrictions(record)
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

  def toplevel_restriction(record)
    AspaceCustomRestrictionsContextHelper.is_restricted?(record)
  end

  def extract_hierarchy(record)
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
