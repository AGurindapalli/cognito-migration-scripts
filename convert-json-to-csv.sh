#!/bin/bash

# Input JSON file
input_file="part_01.json"
output_file="part_01_output.csv"

# Write CSV header
echo "profile,address,birthdate,gender,preferred_username,updated_at,website,picture,phone_number,phone_number_verified,zoneinfo,locale,email,email_verified,given_name,family_name,middle_name,name,nickname,cognito:mfa_enabled,cognito:username" > "$output_file"

# Parse JSON and extract data for each user
jq -r '.[] | 
  [
    "",
    "",
    "",
    "",
    (.Attributes[]? | select(.Name == "preferred_username") | .Value // ""),
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    (.Attributes[]? | select(.Name == "email") | .Value // ""),
    (.Attributes[]? | select(.Name == "email_verified") | .Value // ""),
    "",
    "",
    "",
    "",
    "",
    "",
    (.Attributes[]? | select(.Name == "email") | .Value // "")
  ] | @csv' "$input_file" >> "$output_file"

# Replace double quotes with empty values
sed -i 's/""//g' "$output_file"

echo "CSV conversion complete. Output file: $output_file"
