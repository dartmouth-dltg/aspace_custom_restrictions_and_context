{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "custom_restriction_type" => {
        "type" => "string",
        "dynamic_enum" => "custom_restriction_type",
        "ifmissing" => "error"
      }
    }
  }
}
