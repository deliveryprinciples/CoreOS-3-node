#!/usr/bin/env bash

curl -X DELETE -H "Content-Type: application/json" \
  -H "Authorization: Bearer "$(cat ../DOToken) \
  "https://api.digitalocean.com/v2/droplets?tag_name=master_services"
