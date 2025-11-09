#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "Image Path Verification Script"
echo "================================================"
echo ""

# 1. Check for remaining /img/ references in markdown files
echo "1. Checking for old /img/ references..."
OLD_REFS=$(grep -r "/img/" --include="*.md" --include="*.mdx" docs/ versioned_docs/ 2>/dev/null | grep -v "node_modules" | grep -v ".git" || true)

if [ -z "$OLD_REFS" ]; then
    echo -e "${GREEN}✓ No old /img/ references found${NC}"
else
    echo -e "${RED}✗ Found old /img/ references:${NC}"
    echo "$OLD_REFS"
    echo ""
fi

# 2. Check for relative image paths and verify files exist
echo ""
echo "2. Verifying relative image paths..."
BROKEN_IMAGES=0
VALID_IMAGES=0

# Find all image references with relative paths
while IFS= read -r line; do
    # Extract file path and line content
    FILE=$(echo "$line" | cut -d: -f1)
    CONTENT=$(echo "$line" | cut -d: -f2-)

    # Extract image path from markdown ![](path) or <img src="path"
    IMAGE_PATH=$(echo "$CONTENT" | grep -oP '(?<=\()\./images/[^)]+(?=\))' || echo "$CONTENT" | grep -oP '(?<=src=")[^"]+(?=")' || true)

    if [ -n "$IMAGE_PATH" ]; then
        # Resolve relative path
        DIR=$(dirname "$FILE")
        FULL_PATH="$DIR/$IMAGE_PATH"

        if [ -f "$FULL_PATH" ]; then
            ((VALID_IMAGES++))
        else
            echo -e "${RED}✗ Broken image reference:${NC}"
            echo "  File: $FILE"
            echo "  References: $IMAGE_PATH"
            echo "  Expected at: $FULL_PATH"
            echo ""
            ((BROKEN_IMAGES++))
        fi
    fi
done < <(grep -r "\./images/" --include="*.md" --include="*.mdx" docs/ versioned_docs/ 2>/dev/null | grep -v "node_modules" | grep -v ".git" || true)

echo -e "${GREEN}✓ Valid image references: $VALID_IMAGES${NC}"
if [ $BROKEN_IMAGES -gt 0 ]; then
    echo -e "${RED}✗ Broken image references: $BROKEN_IMAGES${NC}"
else
    echo -e "${GREEN}✓ No broken image references${NC}"
fi

# 3. List all images in version directories
echo ""
echo "3. Image inventory:"
for dir in docs/images versioned_docs/*/images; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -type f | wc -l)
        echo "  $dir: $count files"
    fi
done

# Summary
echo ""
echo "================================================"
echo "Summary:"
echo "================================================"

EXIT_CODE=0
if [ -n "$OLD_REFS" ]; then
    echo -e "${RED}⚠ Action required: Old /img/ references found${NC}"
    EXIT_CODE=1
fi

if [ $BROKEN_IMAGES -gt 0 ]; then
    echo -e "${RED}⚠ Action required: Broken image references found${NC}"
    EXIT_CODE=1
fi

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ All image paths are valid!${NC}"
fi

echo ""
exit $EXIT_CODE
