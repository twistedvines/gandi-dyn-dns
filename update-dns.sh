#!/bin/bash

get_zones() {
  local api_key="$1"
  curl -s -H "X-Api-Key: $api_key" https://dns.api.gandi.net/api/v5/zones
}
