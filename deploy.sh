#!/usr/bin/env bash
# ============================================================
# deploy.sh — 同步两份 HTML 并提交推送到 GitHub Pages
# 用法:
#   ./deploy.sh                  # 提交说明用默认时间戳
#   ./deploy.sh "更新角色卡"      # 自定义提交说明
# 说明:
#   - 自动把较新的那份 HTML 覆盖较旧的（双向同步）
#   - 没有改动时安全退出，不会产生空提交
#   - 仅依赖 git；remote 须为 HTTPS 且 gh 以有写权限的账号登录
# ============================================================
set -uo pipefail

# 切到脚本所在目录（= 仓库根），这样从任何地方调用都对
cd "$(dirname "$0")" || { echo "✗ 无法进入脚本目录"; exit 1; }

# ---- 可按项目修改的配置 ----
SRC_A="卡卡利科夜未眠.html"   # 常编辑的中文工作文件
SRC_B="index.html"            # GitHub Pages 入口文件
BRANCH="main"
PAGES_URL="https://boomlulu.github.io/Blood-on-the-Clocktower/"
REPO_URL="https://github.com/boomlulu/Blood-on-the-Clocktower.git"

# ---- 1. 同步两份 HTML（较新覆盖较旧） ----
if [[ -f "$SRC_A" && -f "$SRC_B" ]]; then
  if cmp -s "$SRC_A" "$SRC_B"; then
    echo "✓ 两份 HTML 已一致，无需同步"
  elif [[ "$SRC_A" -nt "$SRC_B" ]]; then
    cp "$SRC_A" "$SRC_B"; echo "↻ 同步: $SRC_A → $SRC_B"
  else
    cp "$SRC_B" "$SRC_A"; echo "↻ 同步: $SRC_B → $SRC_A"
  fi
elif [[ -f "$SRC_A" ]]; then
  cp "$SRC_A" "$SRC_B"; echo "↻ 仅有 $SRC_A，复制为 $SRC_B"
elif [[ -f "$SRC_B" ]]; then
  cp "$SRC_B" "$SRC_A"; echo "↻ 仅有 $SRC_B，复制为 $SRC_A"
else
  echo "✗ 找不到任何 HTML 文件，终止"; exit 1
fi

# ---- 2. 暂存改动 ----
git add -A

if git diff --cached --quiet; then
  echo "✓ 没有需要提交的改动，结束"
  exit 0
fi

# 让你先看一眼这次都改了啥
echo "── 本次改动 ──"
git diff --cached --stat

# ---- 3. 提交 ----
MSG="${1:-更新内容 $(date '+%Y-%m-%d %H:%M')}"
git commit -q -m "$MSG

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
echo "✓ 已提交: $MSG"

# ---- 4. 推送 ----
echo "→ 推送到 origin/$BRANCH ..."
if GIT_TERMINAL_PROMPT=0 git push -q origin "$BRANCH"; then
  echo "✓ 推送成功"
  echo ""
  echo "🌐 约 1 分钟后线上生效:"
  echo "   $PAGES_URL"
else
  echo "✗ 推送失败。常见原因是 SSH 认证成了别的账号，请确认 remote 是 HTTPS："
  echo "    git remote -v          # 应为 https://github.com/...."
  echo "    gh auth status         # 应为有写权限的账号"
  echo "  如需切回 HTTPS: git remote set-url origin $REPO_URL"
  exit 1
fi
