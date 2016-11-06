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

    #ARGV.each

     # Initialise the Digital Ocean token into a global variable.
    getDOToken()

    # Set up the default configuration specification for the droplets
    sshKey = "7e:0c:0f:08:04:d4:4d:c2:ec:c5:90:d4:8b:d8:f3:db"
    region = "lon1"
    size = "512mb"
    tag = "test-tag"
    name = "test-node"
    cloudConfig = getCloudConfig(".")

    #dropletCreate(name, tag, region, size, sshKey, cloudConfig)
    dropletDeleteByTag(tag)



  # Catch expetions, and print out a stack trace of what went wrong.
  rescue => exception
    puts "Exception caught in method main(): " + exception.message
    print exception.backtrace.join("\n")
  end
end


#
# Cluster configuration scripts
#

# To be developed



#
# Oigital Ocean API helper functions
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
  http, req = initReq("tags/#{tag}/resources", "POST")
  req.body = {"resources" => [{"resource_id" => id, "resource_type" => "droplet"}]}.to_json
  http.request(req).body
end

# Send the request to DigitalOcean using HTTPS and our personal auth token.
# Returns a JSON object containing the list of droplets provided by DO.
def dropletList()
  http, req = initReq("droplets/")
  JSON.parse(http.request(req).body)
end

# Retrieves the list of droplets, and returns the ID of the one that matches the provided name.
# Optionally, if the caller supplies this list of droplets the method will use that instead of issuing a HTTP request (faster!).
# Returns a string containing the droplet's DO identifier.
def dropletIDbyName(name, list = nil)
  list = dropletList() if list == nil
  list["droplets"].each do |l|
  return l["id"].to_s if l["name"] == name
  end
end

# Deletes all the droplets with a given tag.
def dropletDeleteByTag(tag)
  http, req = initReq("droplets?tag_name=#{tag}", "DELETE")
  http.request(req).body
  tagCleanUp()
end

# Creates a new Digital Ocean droplet. All agrgs are mandatory.
def dropletCreate(name, tag, region, size, sshKey, cloudConfig)
  # Create the tag using the spec provided... note that we cannot add the tag during creation due to DO API limitations.
  http, req = initReq("droplets", "POST")
  req.body = { "region" => region,
               "image" => "coreos-stable",
               "size" => size,
               "private_networking" => true,
               "ssh_keys" => [sshKey],
               "name" => name,
               "user_data" => cloudConfig }.to_json
  http.request(req).body

  # Once the droplet is created - tag it with our custom tag.
  tagAdd(tag)   # This ensures that DO knows about the tag we want to use.
  tagDroplet(dropletIDbyName(name), tag)  # Add the tag to the droplet (after we've looked up the ID using the name)
end

# Retrieve our Digital Ocean token from the local file system
# Store the token in a global const variable
def getDOToken()
  tokenFile = File.new(ENV['HOME'] + "/DOToken", "r")
  $Token = tokenFile.gets.chomp
  tokenFile.close
end

# Method to open the open the cloud config file from the given location, and load return it as a string.
def getCloudConfig(path)
  cloudFile = File.new(path + "/cloud-config.yaml", "r")
  fileContents = cloudFile.read
  cloudFile.close
  fileContents
end

# Trigger the main function if this file is executed directly.
if __FILE__ == $0
  main()
end
