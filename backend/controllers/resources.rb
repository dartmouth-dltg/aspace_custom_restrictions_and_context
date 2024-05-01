require_relative '../model/custom_large_tree_resource'

class ArchivesSpaceService < Sinatra::Base
  alias_method :custom_restrictions_large_tree_for_resource, :large_tree_for_resource

  def large_tree_for_resource(largetree_opts = {})
    puts "custom large tree"
    custom_large_tree = custom_restrictions_large_tree_for_resource(largetree_opts = {})
    #custom_large_tree.add_decorator(CustomLargeTreeResource.new)

    custom_large_tree
  end
end
