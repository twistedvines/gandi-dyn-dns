#!/bin/bash

set -e

get_zones() {
  local api_key="$1"
  curl -s -H "X-Api-Key: $api_key" https://dns.api.gandi.net/api/v5/zones
}

get_zone() {
  local name="$1"
  local zones="$2"
  echo "$zones" | jq ".[] | select(.name == \"$name\")"
}

get_zone_uuid() {
  local zone="$1"
  echo "$zone" | jq -r '.uuid'
}

create_dns_record() {
  local api_key="$1"
  local domain="$2"
  local ip_address="$3"
  local zone_file_uuid="$4"

  local payload="$( \
    echo '{}' | jq ".rrset_name = \"$domain\" |"`
      `'.rrset_type = "A" |'`
      `'.rrset_ttl = 3600 |'`
      `".rrset_values = [\"$ip_address\"]"
  )"

  local result="$(curl -s \
    -X POST \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $api_key" \
    -d "$payload" \
    "https://dns.api.gandi.net/api/v5/zones/${zone_file_uuid}/records")"
  echo "$result"
}

get_external_ip_address() {
  curl -s https://api.ipify.org
}

source_dot_env_file() {
  if [ -f '.env.local' ]; then
    source '.env.local'
  else
    source '.env'
  fi
}

source_dot_env_file

if [ -z "$ZONE_FILE_UUID" ]; then
  if [ -z "$ZONE_FILE_NAME" ]; then
    echo "neither ZONE_FILE_UUID or ZONE_FILE_NAME is set: quitting." \
      1>&2
    exit 1
  fi
  zones="$(get_zones "$GANDI_API_KEY")"
  zone="$(get_zone "$ZONE_FILE_NAME" "$zones")"
  ZONE_FILE_UUID="$(get_zone_uuid "$zone")"
fi

ip_address="$(get_external_ip_address)"
create_dns_record \
  "$GANDI_API_KEY" \
  "$SUBDOMAIN" \
  "$ip_address" \
  "$ZONE_FILE_UUID"
