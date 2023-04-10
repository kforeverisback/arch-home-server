#!/bin/bash

set -e
usage () {
    echo "usage:
export AZURE_CLIENT_SECRET=<SECRET>
export AZURE_CLIENT_ID=<SvcPrincipam-CLIENT-ID>
export AZURE_TENANT_ID=<TenantID>
export AZURE_SUBSCRIPTION_ID=<Azure-Sub-Id>
./$0 [PARAMS]
e.g $0 -g common-infra -s e66504de-2c48-4eba-9332-7ad6761dd6be -z km-neer.net -r \"filebrowser homebox hass\" -i 100.126.84.4

NB: Tenant ID, client/service-principal ID and secret has to be passed via environment variables.

MANDATORY PARAMS
  -g|--resource-group   RG          | Resource Group Name
  -z|--dns-zone         DnsZone     | DNS Zone Name
  -r|--record-names     DnsReords   | One or more DNS Reord names separted by space
  -i|--ip-addr          IPAddress   | IP Address for the Record
"
}

echoerr() { printf "%s\n" "$*" >&2; }

while [[ $# -gt 0 ]]; do
  case $1 in
    -g|--resource-group)
      resource_group="$2"; shift 2;;
    -z|--dns-zone)
      dns_zone_name=$2; shift 2;;
    -r|--record-names)
      record_names=$2; shift 2;;
    -i|--ip-addr)
      record_ip=$2; shift 2;;
    -*)
      echo "Unknown option $1"; usage; exit 1;;
    *)
      POSITIONAL_ARGS+=("$1"); shift;; # save positional arg
  esac
done

if  [[ -z $resource_group ]] || \
    [[ -z $dns_zone_name ]] || \
    [[ -z $record_names ]] || \
    [[ -z $record_ip ]] || \
    [[ -z $AZURE_SUBSCRIPTION_ID ]] || \
    [[ -z $AZURE_TENANT_ID ]] || \
    [[ -z $AZURE_CLIENT_ID ]]|| \
    [[ -z $AZURE_CLIENT_SECRET ]]; then
    echo "Provide all mandatory options and environment varaibles"; usage; exit 2
fi

_auth_cache_file="/tmp/t.azdns.cache"

get_auth_token_from_az() {
    # GET Auth token, write it to cache-dir/token and returns http code
    local token_cache_file=$1
    curl -sL -X POST -w "%{http_code}" --output "$token_cache_file" -d "grant_type=client_credentials&client_id=$AZURE_CLIENT_ID&client_secret=$AZURE_CLIENT_SECRET&scope=https%3A%2F%2Fmanagement.azure.com%2F.default" "https://login.microsoftonline.com/$AZURE_TENANT_ID/oauth2/v2.0/token"
}

get_token_status() {
    # possible status: nocache, error, expired, valid
    local token_cache_file=$1
    local expires_in
    [[ ! -f "$1" ]] && echo 'nocache' && return
    [[ $(jq 'has("error_description")' "$token_cache_file" -r) == true ]] && echo error && return
    [[ $(jq 'has("expires_in")' "$token_cache_file" -r) == true ]] && expires_in=$(jq '.expires_in' "$token_cache_file" -r)
    [[ -n $expires_in ]] && [[ $expires_in > $(date +%s) ]] && echo valid || echo expired
}

get_auth_token () {
  local cache_file=$1
  local token_status
  token_status=$(get_token_status "$cache_file")
  case "$token_status" in
    nocache|expired) # Gets the access token no cache file or expired
      response_code=$(get_auth_token_from_az "$cache_file")
      if [[ $response_code -ne 200 ]];then
        echoerr 'Cannot get Auth Token' # Returns
        /bin/rm "$cache_file"
      else
        jq '.token_type + " " + .access_token' "$cache_file" -r # Returns token
      fi
      return;;
    valid) # Returns cached access token
      jq '.token_type + " " + .access_token' "$cache_file" -r;;
    error) # Prints the error and returns
      echoerr 'Token error:'
      jq '.error_description' "$cache_file" -r >&2;
      return;;
  esac
}

token=$(get_auth_token "$_auth_cache_file")
[[ -z "$token" ]] && echoerr "Cannot get token" && exit 1
header_auth="Authorization: $token"
header_content_type="Content-Type: application/json"
body='{"properties":{"TTL":3600,"ARecords":[{"ipv4Address":"'$record_ip'"}]}}'

records=($record_names)

for record in "${records[@]}"; do
  curl -X PUT -H "$header_auth" -H "$header_content_type" -d "$body" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${resource_group}/providers/Microsoft.Network/dnsZones/${dns_zone_name}/a/${record}?api-version=2018-05-01"
  echo ""
done
