class SearchResolverCustomRestrictions

  FIELDS_TO_KEEP = ['id_0', 'id_1', 'id_2', 'id_3', 'jsonmodel_type', 'level', 'other_level', 'title', 'uri', 'publish', 'restrictions', 'restrictions_apply', 'instances', 'user_defined', 'custom_restrictions_u_sstr', 'digital_object']

  # Really just including this as a demo.  Let's parse the JSON and extract a few fields.
  def resolve(record)
    resource = ASUtils.json_parse(record['json'])
    resource.select {|key, _| FIELDS_TO_KEEP.include?(key)}
  end

  SearchResolver.add_custom_resolver('custom_restrictions_compact_resource', self)

end
