#!/bin/bash

# Variables
USER_POOL_ID="your-source-user-pool-id"  # Replace with your Cognito User Pool ID
AWS_PROFILE="source-account-profile"    # Replace with your AWS CLI profile name
AWS_REGION="your-region"                # Replace with your AWS region
OUTPUT_FILE="users.json"                # Output file for user data

# Initialize
echo "[" > $OUTPUT_FILE
TOKEN=""

# Function to fetch users
fetch_users() {
  local token=$1
  if [ -z "$token" ]; then
    # Initial request
    aws cognito-idp list-users \
      --user-pool-id "$USER_POOL_ID" \
      --profile "$AWS_PROFILE" \
      --region "$AWS_REGION"
  else
    # Paginated request
    aws cognito-idp list-users \
      --user-pool-id "$USER_POOL_ID" \
      --profile "$AWS_PROFILE" \
      --region "$AWS_REGION" \
      --pagination-token "$token"
  fi
}

# Fetch users with pagination
while :; do
  echo "Fetching users..."
  
  RESPONSE=$(fetch_users "$TOKEN")
  USERS=$(echo "$RESPONSE" | jq '.Users')
  
  # Append users to the output file
  echo "$USERS" | jq -c '.[]' >> $OUTPUT_FILE.tmp
  
  # Check for the next token
  TOKEN=$(echo "$RESPONSE" | jq -r '.PaginationToken // empty')
  
  # Break loop if no more tokens
  if [ -z "$TOKEN" ]; then
    break
  fi
done

# Combine users into a JSON array
sed -i '$!s/$/,/' $OUTPUT_FILE.tmp
cat $OUTPUT_FILE.tmp >> $OUTPUT_FILE
echo "]" >> $OUTPUT_FILE

# Clean up
rm -f $OUTPUT_FILE.tmp

echo "Export complete. Users saved to $OUTPUT_FILE"
