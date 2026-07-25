#!/usr/bin/env bash
set -e

echo "Running unit tests for wisecow..."

# Test 1: Bash syntax check
echo "Checking bash syntax of wisecow.sh..."
bash -n wisecow.sh
echo "Syntax OK."

# Test 2: Check dependencies (cowsay and fortune)
echo "Checking dependency commands..."
# Add local game paths to PATH in case of system testing
export PATH="/usr/games:${PATH}"

command -v cowsay >/dev/null 2>&1 || { echo "Error: cowsay is not installed or not in PATH"; exit 1; }
command -v fortune >/dev/null 2>&1 || { echo "Error: fortune is not installed or not in PATH"; exit 1; }
echo "Dependencies OK."

# Test 3: Verify the core commands execute together
echo "Testing cowsay and fortune output generation..."
msg=$(fortune)
cowsay "$msg" > /dev/null
echo "Fortune and Cowsay execution OK."

echo "All tests passed successfully!"
