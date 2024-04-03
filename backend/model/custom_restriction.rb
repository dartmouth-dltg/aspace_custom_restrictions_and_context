class CustomRestriction < Sequel::Model(:custom_restriction)
  include ASModel
  
  corresponds_to JSONModel(:custom_restriction)

  set_model_scope :global
  
end
