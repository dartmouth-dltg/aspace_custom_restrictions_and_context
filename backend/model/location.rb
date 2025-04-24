class Location < Sequel::Model(:location)

  def find_related_top_containers(loc_id)
    Location
      .join(:top_container_housed_at_rlshp, :top_container_housed_at_rlshp__location_id => :location__id)
      .join(:top_container, :top_container__id => :top_container_housed_at_rlshp__top_container_id)
      .filter(:location__id => loc_id)
      .select(Sequel.qualify(:top_container, :id)).map {|row| row[:id] }
  end

  def trigger_reindex_of_secondaries(id)
    tc_ids = self.find_related_top_containers(id)
    TopContainer.update_mtime_for_ids(tc_ids)
  end

  # we override this method so that we can trigger reindexing of the 
  # associated archival objects and resources
  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.uniqify_functions(json)
    self.trigger_reindex_of_secondaries(self.values[:id])
    super
  end

end
