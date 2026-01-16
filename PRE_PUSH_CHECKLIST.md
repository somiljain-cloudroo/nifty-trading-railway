# Pre-Push Checklist for GitHub

Before pushing to GitHub, verify these critical items:

## 🔒 Security Check (CRITICAL)

- [ ] Run: `git status` and verify NO sensitive files listed
- [ ] Verify `.env` files are NOT staged (should be in .gitignore)
- [ ] Verify `*.db` files are NOT staged
- [ ] Verify `logs/` directory is NOT staged
- [ ] Check for hardcoded API keys in code:
  ```bash
  grep -r "OPENALGO_API_KEY.*=" baseline_v1_live/ | grep -v ".env"
  grep -r "api_key.*=.*['\"]" baseline_v1_live/ | grep -v ".env"
  ```

## 📝 Code Quality

- [ ] All imports working locally
- [ ] No syntax errors: `python -m py_compile baseline_v1_live/*.py`
- [ ] Remove debug print statements
- [ ] Remove commented-out code blocks (or document why kept)
- [ ] Update docstrings if functions changed

## 🐳 Docker Specific

- [ ] Test Docker build locally:
  ```bash
  docker build -t baseline_v1_live:test .
  ```
- [ ] Test docker-compose syntax:
  ```bash
  docker compose config
  ```
- [ ] Verify `.dockerignore` excludes .env and .db files
- [ ] Test with minimal .env (from .env.sample)

## 📚 Documentation

- [ ] Update README if features changed
- [ ] Update DOCKER_DEPLOY.md if deployment steps changed
- [ ] Add comments to complex logic
- [ ] Update version/date in commit message

## ✅ Final Verification

```bash
# 1. Check what will be committed
git status
git diff --cached

# 2. Verify no secrets
git grep -i "api_key.*=.*['\"]" -- baseline_v1_live/

# 3. Check .gitignore coverage
cat .gitignore | grep -E "\.env|\.db|logs"

# 4. Test Docker build
docker build -t test:latest .

# 5. If all clear, commit
git add .
git commit -m "Descriptive message"
git push origin main
```

## 🚨 Emergency - Pushed Secrets by Mistake

If you accidentally pushed .env or API keys:

```bash
# 1. Immediately revoke the API key in OpenAlgo
# 2. Remove from git history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch baseline_v1_live/.env" \
  --prune-empty --tag-name-filter cat -- --all

# 3. Force push
git push origin --force --all

# 4. Generate new API key
# 5. Update .env locally (never commit again)
```

## 📋 Deployment After Push

On EC2 instance:

```bash
# 1. Pull changes
cd ~/nifty_options_agent
git pull origin main

# 2. Rebuild (if Dockerfile or requirements changed)
docker compose build

# 3. Restart
docker compose up -d

# 4. Verify
docker compose logs --tail=50 trading_agent
```

## 🧪 Testing Workflow

**Local (Windows)**:
```powershell
# Test changes locally first
python baseline_v1_live/baseline_v1_live.py --expiry 30JAN26 --atm 23500
```

**Docker (EC2)**:
```bash
# After git push, on EC2:
git pull
docker compose up -d --build
docker compose logs -f trading_agent
```

---

**Remember**: 
- **NEVER** commit .env files
- **ALWAYS** test locally before pushing
- **VERIFY** PAPER_TRADING=true in production .env
- **MONITOR** first hour after deployment closely
