#!/usr/bin/ruby

=begin

This script can be used to control Digital Ocean droplets via their v2 RESt API.

In order for this to work, the we must have access to 'Personal Token' generaged though their website. This is stord
in the file 'DOToken' located in the home directory. Do not hard code the token in here, or publish it via version control.

=end

require "net/http"
require "uri"
require "json"

#
# Main function - triggered but the function call at the bottom of the file.
#

def main()
  begin

    getDOToken()          # Initialise the Digital Ocean token into a global variable.
    tags = tagList()     # Get the list of all tags that DO currently knows about.
    tagPrint(tags)

    puts "-----"
    tagAdd("test_tag")
    tagCleanUp()
    puts "-----"

    tags = tagList()
    tagPrint(tags)

  # Catch expetions, and print out a stack trace of what went wrong.
  rescue => exception
    puts "Exception caught in method main(): " + exception.message
    print exception.backtrace.join("\n")
  end
end




=begin
res = getListOfDroplets()

# Iterate through the JSON responce, and set the custom tags for each item.
data = JSON.parse(res.body)
#data["droplets"].each do |droplet|
#  puts addTagToDroplet(droplet["id"], "custom_tag")
#end

tagsList = listExistingTags()
tagsList["tags"].each do |t|
  puts t["name"]
end
=end


#
# Function definitions
#

# Initialise the http request, returning the res object to the caller (which must then sent using http.requeste(req) after customisation)
# This function's arg is the REST path to use of the call. Can be used for GET or POST, as specified as an arg (the default is GET).
def initReq(service, method = "GET")
  url = URI.parse("https://api.digitalocean.com/v2/#{service}")
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  case method
  when "GET"
    req = Net::HTTP::Get.new(url.request_uri)
  when "POST"
    req = Net::HTTP::Post.new(url.request_uri)
  when "DELETE"
    req = Net::HTTP::Delete.new(url.request_uri)
  else
    raise "Unknown HTTP method specified in method initReq. Valid options are GET and POST"
  end
  req["Content-Type"] = "application/json"
  req["Authorization"] = "Bearer " + $Token
  [http, req]
end

# Send the request to DigitalOcean using HTTPS and our personal auth token.
# Returns a JSON object containing the list of droplets provided by DO.
def dropletList()
  http, req = initReq("droplets/")
  JSON.parse(http.request(req).body)
end

# Simple method pull back the list of tags that currently exist (that Digital Ocean knows about)
# Returns a JSON object containing the listof tags provided by DO.
def tagList()
  http, req = initReq("tags/")
  JSON.parse(http.request(req).body)
end

# Method to tell Digal Ocean abobout a new tag... useful as tags currently need to be created before resources can use them.
# Returns a JSON object containing the result of the API call.
def tagAdd(tag)
  http, req = initReq("tags/", "POST")
  req.body = {"name" => tag.to_s}.to_json
  JSON.parse(http.request(req).body)
end

# Deletes a custom tag to en existing Digital Ocean droplet - no error checking here... so should only be used by our tagCleanUp() method.
# Does not return anything useful.
def tagDelete(tag)
  http, req = initReq("tags/#{tag}", "DELETE")
  http.request(req).body
end

# Removes all of the DO tags that are not currently used.
# Does not return anything useful.
def tagCleanUp()
  tags = tagList()
  tags["tags"].each do |t|
  tagDelete(t["name"]) if t["resources"]["droplets"]["count"].to_s == "0"
  end
end

# Print out the tags that exist, plus the number of resources that are tagged with each tag.
def tagPrint(tags)
  tags["tags"].each do |t|
    puts t["name"].to_s + ": " + t["resources"]["droplets"]["count"].to_s
  end
end

# Add a custom tag to en existing Digital Ocean droplet
# Returns a JSON object containing the result of the API call.
def tagDroplet(id, tag)
  http, req = initReq("tags/" + tag.to_s + "/resource", "POST")
  req.body = {"resources" => [{"resource_id" => id.to_s, "resource_type" => "droplet"}]}.to_json
  JSON.parse(http.request(req).body)
end

# Retrieve our Digital Ocean token from the local file system
# Store the token in a global const variable
def getDOToken()
  tokenFile = File.new(ENV['HOME'] + "/DOToken", "r")
  $Token = tokenFile.gets.chomp
  tokenFile.close
end

# Trigger the main function if this file is executed directly.
if __FILE__ == $0
  main()
end
