loop do
  uri = URI("http://web:3000/heavy_file_object_upload?uuid=#{SecureRandom.uuid}")
  ap "GET RESPONSE: #{Net::HTTP.get(uri)}"

  sleep(rand(5..20))
end
