# - source it
# - set parameters once with setKcParameters
# - inspect parameters with getKcParameters
#
# tested with zsh
#

setKcParameters() {
  [[ "$1" ]] && KC_API_URL=$1 || read "KC_API_URL?Base URL:"
  [[ "$2" ]] && KC_API_REALM=$2 || read "KC_API_REALM?Realm:"
  [[ "$3" ]] && KC_API_CLIENT_ID=$3 || read "KC_API_CLIENT_ID?Client ID:"
  read -s "clientSecret?Client secret:"
}

getKcParameters() {
  echo $KC_API_URL
  echo $KC_API_REALM
  echo $KC_API_CLIENT_ID
}

accessToken() {
  curl -s \
    --request POST \
    --url $KC_API_URL/realms/$KC_API_REALM/protocol/openid-connect/token \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data grant_type=client_credentials \
    --data client_id=$KC_API_CLIENT_ID \
    --data client_secret=$clientSecret \
  | jq -r .access_token
}

refreshToken() {
  accessToken=$(accessToken)
}

# getUsers | jq -c '.[] | {username, id}'
getUsers() {
  refreshToken
  curl -s \
    --request GET \
    --url $KC_API_URL/admin/realms/$KC_API_REALM/users \
    --header "Authorization: Bearer $accessToken"
}

createUser() {
  local username
  [[ "$1" ]] && username=$1 || read "username?Username:"
  refreshToken
  curl -s \
    --request POST \
    --url $KC_API_URL/admin/realms/$KC_API_REALM/users \
    --header "Authorization: Bearer $accessToken" \
    --header "Content-Type: application/json" \
    -d "{\"username\":\"$username\", \"enabled\": true}"
}

resetPassword() {
  local userId password
  [[ "$1" ]] && userId=$1 || read "userId?User ID (not name!):"
  [[ "$2" ]] && password=$2 || read -s "password?Password:"
  refreshToken
  curl -s \
  --request PUT \
  --url $KC_API_URL/admin/realms/$KC_API_REALM/users/$userId/reset-password \
  --header "Authorization: Bearer $accessToken" \
  --header 'Content-Type: application/json' \
  --data "{\"value\":\"$password\"}"
}

getUserToken() {
  local username password
  [[ "$1" ]] && username=$1 || read "username?Username:"
  [[ "$2" ]] && password=$2 || read -s "password?Password:"
  curl -s \
  --request POST \
  --url $KC_API_URL/realms/$KC_API_REALM/protocol/openid-connect/token \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data grant_type=password \
  --data client_id=$KC_API_CLIENT_ID \
  --data client_secret=$clientSecret \
  --data username=$username \
  --data password=$password
}
