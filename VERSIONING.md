# ServerlessLLM Documentation Versioning Guide

## Overview

The ServerlessLLM documentation now supports versioning with two documentation tracks:

1. **Stable versions** (0.7.0, 0.8.0, etc.) - Released, tested documentation for production use
2. **Latest (dev)** - Bleeding-edge documentation synced from the main branch

## URL Structure

- `/docs/` or `/docs/intro` → **0.7.0 (stable)** - Default for users
- `/docs/latest/` or `/docs/latest/intro` → **Latest (dev)** - For developers
- `/docs/0.7.0/` → Specific stable version
- `/docs/api/` → API documentation (same for all versions)

## Version Dropdown

Users can switch between versions using the dropdown in the navigation bar:
- **0.7.0 (stable)** - Current stable release (default)
- **Latest (dev)** - Development documentation with unreleased features
- Older versions (0.6.0, 0.5.0, etc.) as they are added

## Directory Structure

```
serverlessllm.github.io/
├── docs/                           # Latest (dev) - synced from main branch
│   ├── intro.md
│   ├── getting_started.md
│   ├── deployment/
│   ├── features/
│   ├── store/
│   ├── api/                        # API docs (shared across versions)
│   └── ...
├── versioned_docs/                 # Stable version snapshots
│   └── version-0.7.0/              # 0.7.0 stable release
│       ├── intro.md
│       ├── getting_started.md
│       └── ...
├── versioned_sidebars/             # Sidebar configs for each version
│   └── version-0.7.0-sidebars.json
└── versions.json                   # List of all versions: ["0.7.0"]
```

## How Versioning Works

### For Latest (Dev) Documentation

1. Developer commits to `main` branch in ServerlessLLM repository
2. Sync workflow triggers
3. Documentation in `docs/` folder is updated
4. Users accessing `/docs/latest/` see the new content

### For Stable Version Documentation

1. New release is published (e.g., v0.8.0)
2. Version snapshot workflow triggers
3. Creates `versioned_docs/version-0.8.0/` with frozen documentation
4. Updates `versions.json` to include 0.8.0
5. Updates config to make 0.8.0 the new default
6. Users accessing `/docs/` now see 0.8.0 by default

## Sync Workflows

### 1. Sync Latest Docs (Continuous)

**Location:** `.github/workflows/sync-latest-docs.yml`

**Trigger:** Repository dispatch event `sync-latest-docs`

**Purpose:** Updates the "Latest (dev)" documentation from main branch

**Testing:**
```bash
gh workflow run sync-latest-docs.yml
```

### 2. Create Version Snapshot (On Release)

**Location:** `.github/workflows/create-version-snapshot.yml`

**Trigger:** Repository dispatch event `create-version-snapshot` or manual dispatch

**Purpose:** Creates a versioned snapshot when a new release is published

**Testing:**
```bash
gh workflow run create-version-snapshot.yml \
  -f version=0.8.0 \
  -f tag=v0.8.0
```

## Main Repository Setup

The main ServerlessLLM repository needs workflow files to trigger documentation syncing.

See `.github/MAIN_REPO_WORKFLOWS.md` for detailed instructions on:
- Setting up sync workflows in the main repo
- Creating GitHub tokens
- Configuring repository dispatch events

## Creating a New Version

### Manual Process

When releasing a new version (e.g., 0.8.0):

1. **Sync docs from the release tag:**
```bash
# Clone the main repo at the specific tag
git clone --depth 1 --branch v0.8.0 https://github.com/ServerlessLLM/ServerlessLLM.git temp_repo

# Remove current docs (keep api/)
find docs/ -mindepth 1 -maxdepth 1 ! -name 'api' ! -name 'images' ! -name 'README.md' -exec rm -rf {} +

# Copy docs from release
cp -r temp_repo/docs/* docs/

# Clean up
rm -rf temp_repo
```

2. **Create version snapshot:**
```bash
npm run docusaurus docs:version 0.8.0
```

3. **Update docusaurus.config.js:**
```javascript
docs: {
  lastVersion: '0.8.0', // Update to new stable version
  versions: {
    current: {
      label: 'Latest (dev)',
      path: 'latest',
      banner: 'unreleased',
    },
    '0.8.0': {
      label: '0.8.0 (stable)',
      path: '/',
      banner: 'none',
    },
    '0.7.0': {
      label: '0.7.0',
      // Older version, no longer default
    },
  },
}
```

4. **Commit and push:**
```bash
git add .
git commit -m "docs: create version 0.8.0 snapshot"
git push
```

### Automated Process (Recommended)

Use the `create-version-snapshot.yml` workflow:

```bash
# Trigger from main ServerlessLLM repo on release
# OR manually trigger from this repo:
gh workflow run create-version-snapshot.yml \
  -f version=0.8.0 \
  -f tag=v0.8.0
```

## Version Configuration

### versions.json

Lists all stable versions:
```json
[
  "0.8.0",
  "0.7.0",
  "0.6.0"
]
```

### docusaurus.config.js

Configure version behavior:

```javascript
docs: {
  lastVersion: '0.8.0', // Default version for /docs/
  versions: {
    current: {
      label: 'Latest (dev)',      // Label in dropdown
      path: 'latest',              // URL path
      banner: 'unreleased',        // Warning banner
      badge: true,                 // Show badge
    },
    '0.8.0': {
      label: '0.8.0 (stable)',
      path: '/',                   // Root path (default)
      banner: 'none',
    },
    '0.7.0': {
      label: '0.7.0',
      // Uses default path: /docs/0.7.0/
    },
  },
}
```

## Migration Summary

The migration from the old structure involved:

1. ✅ Moved `docs/stable/*` → `docs/*`
2. ✅ Updated `sidebars.js` to use root directory
3. ✅ Created initial version 0.7.0 snapshot
4. ✅ Configured versioning in `docusaurus.config.js`
5. ✅ Fixed broken internal links
6. ✅ Updated homepage link
7. ✅ Created sync workflows

## Breaking Changes

### URL Changes

Old URL structure:
- `/docs/stable/intro` → Documentation

New URL structure:
- `/docs/intro` → Stable documentation (0.7.0)
- `/docs/latest/intro` → Latest development docs
- `/docs/0.7.0/intro` → Specific version

**Impact:** External links to `/docs/stable/*` will break and need updating.

### Recommendation

Set up redirects for old URLs:
```javascript
// In docusaurus.config.js
plugins: [
  [
    '@docusaurus/plugin-client-redirects',
    {
      redirects: [
        {
          from: '/docs/stable/:path',
          to: '/docs/:path',
        },
      ],
    },
  ],
],
```

## Troubleshooting

### Build Errors

**Issue:** Broken links after restructuring

**Solution:** Update all internal links:
- `../stable/path.md` → `../path.md`
- Ensure cross-references between `docs/` and `docs/api/` use correct relative paths

### Version Not Showing in Dropdown

**Issue:** New version not visible

**Solution:**
1. Check `versions.json` includes the version
2. Verify `versioned_docs/version-X.X.X/` exists
3. Rebuild: `npm run build`

### Wrong Default Version

**Issue:** Latest (dev) shows by default instead of stable

**Solution:** Ensure `lastVersion` in config points to stable version:
```javascript
docs: {
  lastVersion: '0.7.0', // Should be stable, not 'current'
}
```

## Best Practices

1. **Always sync from tagged releases** for stable versions, not from branches
2. **Test versioned docs locally** before deploying
3. **Update version labels** in config when creating new versions
4. **Keep version history** - don't delete old versions unless necessary
5. **Document breaking changes** between versions in release notes

## Future Enhancements

Potential improvements to consider:

1. **Automatic version creation** on GitHub releases
2. **Version deprecation banners** for outdated versions
3. **Version-specific search** to filter results by version
4. **Changelog integration** linking versions to release notes
5. **Version comparison tools** to see changes between versions

## Support

For issues or questions about versioning:
- Check Docusaurus versioning docs: https://docusaurus.io/docs/versioning
- Report issues: https://github.com/ServerlessLLM/serverlessllm.github.io/issues
