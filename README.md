# Gandi Dynamic DNS Updater
This bash script utilises [jq](https://stedolan.github.io/jq/) and
[ipify](https://www.ipify.org/) to manage dynamic DNS via Gandi's LiveDNS API.

## Dependencies
- [jq](https://stedolan.github.io/jq/);
- bash;
- curl.

## Parameters
- `-k (API Key)`: your API key for accessing Gandi LiveDNS;
- `-d (Domain/Subdomain)`: the domain you want to associate with your IP address;
- `-n (Zone File Name)`: the zone file name, if you don't know your Zone's UUID;
- `-u (Zone File UUID)`: the zone file UUID. This saves the script from making
an extra request to fetch your zone to get the UUID.

Alternatively, these parameters can be set in the provided `.env` file.

## Assumptions
- You have created a zone file;
- You have generated your API key.
