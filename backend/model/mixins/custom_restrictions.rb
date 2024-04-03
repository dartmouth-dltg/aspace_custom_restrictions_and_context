module CustomRestrictions

  def self.included(base)
    base.one_to_many :custom_restriction

    base.def_nested_record(:the_property => :custom_restriction,
                           :contains_records_of_type => :custom_restriction,
                           :corresponding_to_association  => :custom_restriction,
                           :is_array => false)
  end

end
