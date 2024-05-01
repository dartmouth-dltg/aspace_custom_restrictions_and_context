class CustomLargeTreeResource

  def root(response, root_record)
    puts "ROOT RECORD: #{root_record.inspect}"

    response
  end
end
