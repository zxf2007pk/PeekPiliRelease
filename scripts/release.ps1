# TVBox Config 发布脚本
# 用于快速创建 GitHub Release 并上传安装包

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$Notes = "新版本发布",
    
    [Parameter(Mandatory=$false)]
    [string]$Repo = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Draft = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Prerelease = $false
)

# 设置错误处理
$ErrorActionPreference = "Stop"

Write-Host "🚀 开始发布流程..." -ForegroundColor Green

# 检查 GitHub CLI 是否安装
try {
    $ghVersion = gh --version 2>&1
    Write-Host "✅ GitHub CLI 已安装" -ForegroundColor Green
} catch {
    Write-Host "❌ 未检测到 GitHub CLI，请先安装：" -ForegroundColor Red
    Write-Host "   https://cli.github.com/" -ForegroundColor Yellow
    Write-Host "   或使用: choco install gh" -ForegroundColor Yellow
    exit 1
}

# 检查是否在 Git 仓库中
try {
    $gitRoot = git rev-parse --show-toplevel 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "不在 Git 仓库中"
    }
    Write-Host "✅ Git 仓库检测成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 当前目录不是 Git 仓库" -ForegroundColor Red
    Write-Host "   请先初始化 Git 仓库: git init" -ForegroundColor Yellow
    exit 1
}

# 检查 release 文件夹
$releasePath = Join-Path $gitRoot "release"
if (-not (Test-Path $releasePath)) {
    Write-Host "⚠️  release 文件夹不存在，正在创建..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $releasePath | Out-Null
}

# 检查 release 文件夹中的文件
$releaseFiles = Get-ChildItem -Path $releasePath -File
if ($releaseFiles.Count -eq 0) {
    Write-Host "⚠️  release 文件夹为空" -ForegroundColor Yellow
    Write-Host "   请将安装包放入 release 文件夹后重试" -ForegroundColor Yellow
    $continue = Read-Host "是否继续创建 Release? (y/n)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 0
    }
} else {
    Write-Host "✅ 找到 $($releaseFiles.Count) 个文件：" -ForegroundColor Green
    foreach ($file in $releaseFiles) {
        Write-Host "   - $($file.Name) ($([math]::Round($file.Length / 1MB, 2)) MB)" -ForegroundColor Cyan
    }
}

# 检查是否已登录 GitHub
try {
    $ghAuth = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "未登录"
    }
    Write-Host "✅ GitHub 登录状态正常" -ForegroundColor Green
} catch {
    Write-Host "❌ 未登录 GitHub，正在打开登录页面..." -ForegroundColor Red
    gh auth login
}

# 获取仓库信息
if ([string]::IsNullOrEmpty($Repo)) {
    try {
        $remoteUrl = git remote get-url origin 2>&1
        if ($remoteUrl -match "github\.com[:/](.+?)/(.+?)(?:\.git)?$") {
            $Repo = "$($matches[1])/$($matches[2])"
            Write-Host "✅ 检测到仓库: $Repo" -ForegroundColor Green
        } else {
            throw "无法解析仓库地址"
        }
    } catch {
        Write-Host "❌ 无法自动检测仓库，请手动指定 -Repo 参数" -ForegroundColor Red
        exit 1
    }
}

# 检查标签是否已存在
try {
    $existingTag = git tag -l $Version 2>&1
    if ($existingTag) {
        Write-Host "⚠️  标签 $Version 已存在" -ForegroundColor Yellow
        $overwrite = Read-Host "是否删除并重新创建? (y/n)"
        if ($overwrite -eq "y" -or $overwrite -eq "Y") {
            git tag -d $Version 2>&1 | Out-Null
            git push origin :refs/tags/$Version 2>&1 | Out-Null
            Write-Host "✅ 已删除旧标签" -ForegroundColor Green
        } else {
            Write-Host "❌ 取消发布" -ForegroundColor Red
            exit 0
        }
    }
} catch {
    # 标签不存在，继续
}

# 创建 Git 标签
Write-Host "📝 创建 Git 标签: $Version" -ForegroundColor Cyan
git tag -a $Version -m "Release $Version" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 创建标签失败" -ForegroundColor Red
    exit 1
}

# 推送标签
Write-Host "📤 推送标签到远程仓库..." -ForegroundColor Cyan
git push origin $Version 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 推送标签失败" -ForegroundColor Red
    exit 1
}
Write-Host "✅ 标签推送成功" -ForegroundColor Green

# 构建 Release 说明
$releaseBody = @"
## 🎉 新版本发布

$Notes

## 📦 下载安装包

请从下方 Assets 中下载对应平台的安装包。

## 📝 更新内容

- 查看更新日志了解详细内容

## ⚠️ 注意事项

- 请根据您的设备平台选择合适的安装包
- 安装前请备份重要数据
"@

# 创建 Release
Write-Host "🚀 创建 GitHub Release..." -ForegroundColor Cyan
$releaseParams = @(
    "release", "create", $Version,
    "--repo", $Repo,
    "--title", "Release $Version",
    "--notes", $releaseBody
)

if ($Draft) {
    $releaseParams += "--draft"
}

if ($Prerelease) {
    $releaseParams += "--prerelease"
}

# 添加文件
foreach ($file in $releaseFiles) {
    $filePath = Join-Path $releasePath $file.Name
    $releaseParams += $filePath
}

gh $releaseParams 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 创建 Release 失败" -ForegroundColor Red
    Write-Host "   请检查 GitHub CLI 权限和网络连接" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Release 创建成功！" -ForegroundColor Green
Write-Host "🔗 查看 Release: https://github.com/$Repo/releases/tag/$Version" -ForegroundColor Cyan

