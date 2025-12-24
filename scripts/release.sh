#!/bin/bash
# TVBox Config 发布脚本 (Linux/macOS)
# 用于快速创建 GitHub Release 并上传安装包

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 参数解析
VERSION=""
NOTES="新版本发布"
REPO=""
DRAFT=false
PRERELEASE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -n|--notes)
            NOTES="$2"
            shift 2
            ;;
        -r|--repo)
            REPO="$2"
            shift 2
            ;;
        --draft)
            DRAFT=true
            shift
            ;;
        --prerelease)
            PRERELEASE=true
            shift
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

if [ -z "$VERSION" ]; then
    echo -e "${RED}❌ 请指定版本号${NC}"
    echo "用法: $0 -v v1.0.0 [-n '发布说明'] [-r 'owner/repo'] [--draft] [--prerelease]"
    exit 1
fi

echo -e "${GREEN}🚀 开始发布流程...${NC}"

# 检查 GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ 未检测到 GitHub CLI${NC}"
    echo "请安装: https://cli.github.com/"
    exit 1
fi
echo -e "${GREEN}✅ GitHub CLI 已安装${NC}"

# 检查 Git 仓库
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ 当前目录不是 Git 仓库${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Git 仓库检测成功${NC}"

# 检查 release 文件夹
GIT_ROOT=$(git rev-parse --show-toplevel)
RELEASE_PATH="$GIT_ROOT/release"

if [ ! -d "$RELEASE_PATH" ]; then
    echo -e "${YELLOW}⚠️  release 文件夹不存在，正在创建...${NC}"
    mkdir -p "$RELEASE_PATH"
fi

# 检查文件
RELEASE_FILES=$(find "$RELEASE_PATH" -maxdepth 1 -type f)
FILE_COUNT=$(echo "$RELEASE_FILES" | grep -v '^$' | wc -l | tr -d ' ')

if [ "$FILE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  release 文件夹为空${NC}"
    read -p "是否继续创建 Release? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
else
    echo -e "${GREEN}✅ 找到 $FILE_COUNT 个文件：${NC}"
    for file in "$RELEASE_PATH"/*; do
        if [ -f "$file" ]; then
            SIZE=$(du -h "$file" | cut -f1)
            echo -e "${CYAN}   - $(basename "$file") ($SIZE)${NC}"
        fi
    done
fi

# 检查 GitHub 登录
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ 未登录 GitHub${NC}"
    gh auth login
fi
echo -e "${GREEN}✅ GitHub 登录状态正常${NC}"

# 获取仓库信息
if [ -z "$REPO" ]; then
    REMOTE_URL=$(git remote get-url origin)
    if [[ $REMOTE_URL =~ github\.com[:/](.+?)/(.+?)(?:\.git)?$ ]]; then
        REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
        echo -e "${GREEN}✅ 检测到仓库: $REPO${NC}"
    else
        echo -e "${RED}❌ 无法自动检测仓库${NC}"
        exit 1
    fi
fi

# 检查标签
if git tag -l | grep -q "^$VERSION$"; then
    echo -e "${YELLOW}⚠️  标签 $VERSION 已存在${NC}"
    read -p "是否删除并重新创建? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -d "$VERSION" 2>/dev/null || true
        git push origin ":refs/tags/$VERSION" 2>/dev/null || true
        echo -e "${GREEN}✅ 已删除旧标签${NC}"
    else
        echo -e "${RED}❌ 取消发布${NC}"
        exit 0
    fi
fi

# 创建标签
echo -e "${CYAN}📝 创建 Git 标签: $VERSION${NC}"
git tag -a "$VERSION" -m "Release $VERSION"

# 推送标签
echo -e "${CYAN}📤 推送标签到远程仓库...${NC}"
git push origin "$VERSION"
echo -e "${GREEN}✅ 标签推送成功${NC}"

# 构建 Release 说明
RELEASE_BODY="## 🎉 新版本发布

$NOTES

## 📦 下载安装包

请从下方 Assets 中下载对应平台的安装包。

## 📝 更新内容

- 查看更新日志了解详细内容

## ⚠️ 注意事项

- 请根据您的设备平台选择合适的安装包
- 安装前请备份重要数据"

# 创建 Release
echo -e "${CYAN}🚀 创建 GitHub Release...${NC}"

RELEASE_CMD="gh release create $VERSION --repo $REPO --title \"Release $VERSION\" --notes \"$RELEASE_BODY\""

if [ "$DRAFT" = true ]; then
    RELEASE_CMD="$RELEASE_CMD --draft"
fi

if [ "$PRERELEASE" = true ]; then
    RELEASE_CMD="$RELEASE_CMD --prerelease"
fi

# 添加文件
for file in "$RELEASE_PATH"/*; do
    if [ -f "$file" ]; then
        RELEASE_CMD="$RELEASE_CMD \"$file\""
    fi
done

eval $RELEASE_CMD

echo -e "${GREEN}✅ Release 创建成功！${NC}"
echo -e "${CYAN}🔗 查看 Release: https://github.com/$REPO/releases/tag/$VERSION${NC}"

