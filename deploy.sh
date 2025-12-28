#!/bin/bash

# 1. Ask for a commit message
echo "Enter your update message:"
read MESSAGE

# 2. Add all changes
git add .

# 3. Commit with your message
git commit -m "$MESSAGE"

# 4. Push to GitHub (This triggers the Action)
git push origin master
