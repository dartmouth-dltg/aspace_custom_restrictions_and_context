require 'db/migrations/utils'

Sequel.migration do

  up do
    $stderr.puts("Adding Custom Restrictions Module plugin tables")

    create_table(:custom_restriction) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :accession_id
      Integer :resource_id
      Integer :archival_object_id
      Integer :digital_object_id

      DynamicEnum :custom_restriction_type_id

      apply_mtime_columns
    end

    alter_table(:custom_restriction) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
    end

    create_editable_enum("custom_restriction_type", ["access_restricted", "may_be_restricted", "some_materials_restricted"])

  end

end