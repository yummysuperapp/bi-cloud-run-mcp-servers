# GitHub Setup Checklist

## ✅ Pre-Commit Checklist

Before pushing to GitHub, ensure:

### 1. Credentials Removed
- [x] No API tokens in deploy-cloud-run.sh
- [x] No service account JSON files (except .example)
- [x] No dbt Cloud tokens in any scripts
- [x] No GitHub tokens in code

### 2. Files to Verify
Run these commands to check for sensitive data:

```bash
# Check for dbt tokens
grep -r "dbtc_" . --exclude-dir=.git

# Check for GitHub tokens
grep -r "ghp_" . --exclude-dir=.git

# Check for email addresses
grep -r "@.*\.com" . --exclude-dir=.git --exclude="*.md" --exclude="*.example"

# List all JSON files (should only be .example files)
find . -name "*.json" -not -path "./.git/*"
```

Expected results:
- No matches for dbtc_ or ghp_ tokens
- Only .example JSON files present

### 3. Configuration Files
Ensure these files exist:
- [x] config.example.sh (template with placeholders)
- [x] profiles.yml.example (template with placeholders)
- [x] service-account.json.example (template structure)
- [x] .env.example (template with placeholders)

Ensure these files are NOT committed:
- [ ] config.local.sh (user's local config)
- [ ] profiles.yml (user's actual dbt profile)
- [ ] yummy-development.json (service account key)
- [ ] Any other *.json files with actual credentials

### 4. Git Configuration

```bash
# Initialize git repository
git init

# Add all files
git add .

# Check what will be committed
git status

# Verify .gitignore is working
git check-ignore *.json
git check-ignore config.local.sh
```

## 🚀 Initial Commit

```bash
# First commit
git commit -m "Initial commit: dbt MCP Server on Cloud Run

- Complete deployment scripts for Google Cloud Run
- dbt Cloud API integration
- BigQuery connectivity
- MCP protocol support with SSE transport
- Comprehensive documentation
- Example configuration files
- Local testing support"

# Create GitHub repository (via web or CLI)
gh repo create bi-cloud-run-mcp-servers --public --source=. --remote=origin --push
```

Or manually:
1. Create repository on GitHub.com
2. Link and push:
```bash
git remote add origin https://github.com/yourusername/bi-cloud-run-mcp-servers.git
git branch -M main
git push -u origin main
```

## 📝 Post-Upload Checklist

After pushing to GitHub:

1. **Verify on GitHub.com**:
   - [ ] No JSON files with credentials visible
   - [ ] No tokens in deploy-cloud-run.sh
   - [ ] README.md displays correctly
   - [ ] .gitignore is present

2. **Add Repository Details**:
   - [ ] Set repository description
   - [ ] Add topics: `dbt`, `mcp`, `cloud-run`, `bigquery`, `ai`, `claude`
   - [ ] Add website link (if applicable)

3. **Configure Repository**:
   - [ ] Add LICENSE file to repository
   - [ ] Enable Issues (if desired)
   - [ ] Add branch protection rules (optional)

4. **Update README**:
   - [ ] Replace `yourusername` with actual GitHub username
   - [ ] Update clone URL in Quick Start section
   - [ ] Add badges (optional): build status, license, etc.

## 🔒 Security Review

Double-check these before making repository public:

- [ ] No hardcoded credentials anywhere
- [ ] No internal URLs or IP addresses
- [ ] No company-specific information
- [ ] No proprietary code or algorithms
- [ ] All example files use placeholders

## 📋 Optional Enhancements

Consider adding:

- [ ] GitHub Actions for CI/CD
- [ ] Dependabot for dependency updates
- [ ] CONTRIBUTING.md guide
- [ ] Issue templates
- [ ] Pull request template
- [ ] CHANGELOG.md
- [ ] Docker Hub automated builds

## ⚠️ Important Notes

1. **Never commit credentials**: Even if you delete them later, they remain in git history
2. **Review before pushing**: Always review `git diff` before committing
3. **Use .env files**: Keep sensitive data in .env files that are gitignored
4. **Rotate exposed secrets**: If you accidentally commit credentials, rotate them immediately

## 🔄 Regular Maintenance

After initial setup:

```bash
# Keep repository updated
git add .
git commit -m "Description of changes"
git push

# Create releases for major versions
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

## 📚 Additional Resources

- [GitHub Best Practices](https://docs.github.com/en/repositories/creating-and-managing-repositories/best-practices-for-repositories)
- [Securing Your Repository](https://docs.github.com/en/code-security/getting-started/securing-your-repository)
- [.gitignore Templates](https://github.com/github/gitignore)
