#!/bin/bash

set -e

get_zones() {
  local api_key="$1"
  local result="$(
    curl -s -H "X-Api-Key: $api_key" \
      https://dns.api.gandi.net/api/v5/zones
  )"

  local code="$(echo "$result" | jq -r '.code?')"

  [[ "$code" == 'null' ]] && code=

  if [[ -n "$code" ]] && [[ "$code" != '200' ]]; then
    echo "An error occurred getting zones: $(echo "$result" | jq -r '.message')" \
      1>&2
    return 1
  fi

  echo "$result"
}

get_zone() {
  local name="$1"
  local zones="$2"
  echo "$zones" | jq ".[] | select(.name == \"$name\")"
}

get_records() {
  local api_key="$1"
  local zone_uuid="$2"

  local result="$(
    curl -s -H "X-Api-Key: $api_key" \
      "https://dns.api.gandi.net/api/v5/zones/$zone_uuid/records"
  )"

  local code="$(echo "$result" | jq -r '.code?')"

  [[ "$code" == 'null' ]] && code=

  if [[ -n "$code" ]] && [[ "$code" != '200' ]]; then
    echo "An error occurred getting zones: $(echo "$result" | \
      jq -r '.message')" 1>&2
    return 1
  fi

  echo "$result"
}

get_record() {
  local name="$1"
  local records="$2"
  echo "$records" | jq ".[] | select(.rrset_name == \"$name\")"
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

update_dns_record() {
  local api_key="$1"
  local domain="$2"
  local ip_address="$3"
  local zone_file_uuid="$4"

  local payload="$(echo '{}' | jq ".rrset_values = [\"$ip_address\"]")"

  local result="$(curl -s \
    -X PUT \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $api_key" \
    -d "$payload" \
    "https://dns.api.gandi.net/api/v5/zones/"`
    `"${zone_file_uuid}/records/${domain}/A"
  )"

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

parse_opts() {
  local opts=$@
  while getopts 'k:d:n:u:' opt; do
    case "$opt" in
      k)
        GANDI_API_KEY="$OPTARG"
        ;;
      d)
        SUBDOMAIN="$OPTARG"
        ;;
      n)
        ZONE_FILE_NAME="$OPTARG"
        ;;
      u)
        ZONE_FILE_UUID="$OPTARG"
    esac
  done
}

if ! [[ "$0" == '-bash' ]]; then
  parse_opts $@
  if [ -z "$GANDI_API_KEY" ]; then
    # assuming no args were passed
    source_dot_env_file
  fi

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

  records="$(get_records "$GANDI_API_KEY" "$ZONE_FILE_UUID")"
  target_record="$(get_record "$SUBDOMAIN" "$records")"
  if [ -z "$target_record" ]; then
    create_dns_record \
      "$GANDI_API_KEY" \
      "$SUBDOMAIN" \
      "$ip_address" \
      "$ZONE_FILE_UUID"
  else
    update_dns_record \
      "$GANDI_API_KEY" \
      "$SUBDOMAIN" \
      "$ip_address" \
      "$ZONE_FILE_UUID"
  fi
fi
