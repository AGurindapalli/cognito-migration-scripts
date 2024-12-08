#!/bin/bash

# Variables
USER_POOL_ID="your-source-user-pool-id" # Replace with your Cognito User Pool ID
AWS_PROFILE="source-account-profile"    # Replace with your AWS CLI profile name
AWS_REGION="your-region"                # Replace with your AWS region              
INPUT_FILE="part_01.json"                    # Replace with your Input file  
THREADS=10                              # Config the threads based on your system configuration

# Export variables for parallel
export USER_POOL_ID AWS_PROFILE AWS_REGION

# Function to import a user into Cognito
import_user() {
  local email="$1"
  local email_verified="$2"
  local name="$3"
  local preferred_username="$4"

  # Ensure email and email_verified are valid before proceeding
  if [ -z "$email" ] || [ -z "$email_verified" ]; then
    echo "ERROR: Missing email or email_verified for user $email. Skipping."
    return
  fi

  # Prepare user attributes for Cognito
  user_attributes=("Name=email,Value=$email" "Name=email_verified,Value=$email_verified")

  # Only add 'name' if it is non-null and non-empty
  if [ -n "$name" ] && [ "$name" != "null" ]; then
    user_attributes+=("Name=name,Value=$name")
  fi

  # Only add 'preferred_username' if it is non-null and non-empty
  if [ -n "$preferred_username" ] && [ "$preferred_username" != "null" ]; then
    user_attributes+=("Name=preferred_username,Value=$preferred_username")
  fi

  # Create user in Cognito
  echo "Creating user: $email"
  aws cognito-idp admin-create-user \
    --user-pool-id "$USER_POOL_ID" \
    --username "$email" \
    --user-attributes "${user_attributes[@]}" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --message-action "SUPPRESS" || echo "Failed to create user: $email"
}

# Export the function for parallel
export -f import_user

# Process JSON and pass data to the function using parallel
jq -c '.[] | select(.Attributes != null) | {
  email: (.Attributes[] | select(.Name == "email") | .Value),
  email_verified: (.Attributes[] | select(.Name == "email_verified") | .Value),
  name: ((.Attributes[] | select(.Name == "name") | .Value) // null),
  preferred_username: ((.Attributes[] | select(.Name == "preferred_username") | .Value) // null),
}' "$INPUT_FILE" | \
parallel -j "$THREADS" --pipe bash -c '
  while IFS= read -r data; do
    email=$(echo "$data" | jq -r .email)
    email_verified=$(echo "$data" | jq -r .email_verified)
    name=$(echo "$data" | jq -r .name)
    preferred_username=$(echo "$data" | jq -r .preferred_username)
    # Call the import_user function with appropriate arguments
    import_user "$email" "$email_verified" "$name" "$preferred_username"
  done
'

echo "User import complete!"
