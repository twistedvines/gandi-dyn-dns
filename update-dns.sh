#!/bin/bash

get_zones() {
  local api_key="$1"
  curl -s -H "X-Api-Key: $api_key" https://dns.api.gandi.net/api/v5/zones
}

get_zone() {
  local name="$1"
  local zones="$2"
  echo "$zones" | jq ".[] | select(name == $name)"
}

get_zone_uuid() {
  local zone="$1"
  echo "$zone" | jq '.uuid'
}

create_dns_record() {
  local api_key="$1"
  local domain="$2"
  local ip_address="$3"
  local zone_file_uuid="$4"

  local payload="$( \
    jq ".rrset_name = \"$domain\" |"`
      `'.rrset_type = "A" |'`
      `'.rrset_ttl = 3600 |'`
      `"rrset_values = [\"$ip_address\"]"
  )"

  local result="$(curl -s \
    -X PUT \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $api_key" \
    -d "$payload" \
    "https://dns.api.gandi.net/api/v5/zones/${zone_file_uuid}/records")"
}

get_external_ip_address() {
  curl -s https://api.ipify.org
}
