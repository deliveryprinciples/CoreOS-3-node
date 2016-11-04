#!/usr/bin/env bash

export DO_SSH_KEY_FINGERPRINT="7e:0c:0f:08:04:d4:4d:c2:ec:c5:90:d4:8b:d8:f3:db"
export TOKEN="DOToken"

# A basic Droplet create request.
curl -X POST "https://api.digitalocean.com/v2/droplets" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d'{"name":["coreos-01","coreos-02","coreos-03"]","region":"lon1","size":"512mb","private_networking":true,"image":"coreos-stable","user_data":"'"$(cat cloud-config.yml)"'", "ssh_keys":[ "'$DO_SSH_KEY_FINGERPRINT'" ]}'
