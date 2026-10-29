# Updating a location doesn't touch the top containers housed there, so bump their
# mtimes (and those of their linked records) to get the affected records reindexed.
# Prepended so that core's Location#update_from_json stays in the call chain.
module CustomRestrictionsLocationReindex

  def update_from_json(json, opts = {}, apply_nested_records = true)
    result = super

    tc_ids = db[:top_container_housed_at_rlshp].filter(:location_id => id).select_map(:top_container_id)
    TopContainer.update_mtime_for_ids(tc_ids) unless tc_ids.empty?

    result
  end

end

Location.prepend(CustomRestrictionsLocationReindex)
