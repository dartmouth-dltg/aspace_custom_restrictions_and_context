require 'db/migrations/utils'

Sequel.migration do

  up do
    $stderr.puts("Adding Custom Restrictions to Digital Object Components")

    alter_table(:custom_restriction) do
      add_column(:digital_object_component_id, Integer)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
    end

  end

end