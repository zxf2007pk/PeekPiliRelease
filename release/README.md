# Release 文件夹说明

此文件夹用于存放应用安装包，发布到 GitHub Release 时，这些文件会自动上传。

## 📦 文件命名规范

建议按照以下格式命名安装包：

- **Android**: `app-android-v1.0.0.apk` 或 `app-android-v1.0.0-arm64.apk`
- **iOS**: `app-ios-v1.0.0.ipa`
- **Windows**: `app-windows-v1.0.0.exe` 或 `app-windows-v1.0.0-x64.zip`
- **macOS**: `app-macos-v1.0.0.dmg` 或 `app-macos-v1.0.0.zip`

## 🚀 快速发布方法

### 方法一：使用 GitHub Actions（推荐）

1. **准备安装包**
   - 将编译好的安装包放入 `release/` 文件夹
   - 确保文件名清晰易懂

2. **创建 Git 标签并推送**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
   - GitHub Actions 会自动检测标签并创建 Release

3. **或使用手动触发**
   - 在 GitHub 仓库页面，进入 Actions
   - 选择 "自动发布 Release" 工作流
   - 点击 "Run workflow"
   - 填写版本号和发布说明
   - 点击运行

### 方法二：使用 GitHub CLI（快速）

1. **安装 GitHub CLI**
   ```bash
   # Windows (使用 Chocolatey)
   choco install gh
   
   # 或下载安装包
   # https://cli.github.com/
   ```

2. **登录 GitHub**
   ```bash
   gh auth login
   ```

3. **创建 Release**
   ```bash
   # 进入项目目录
   cd d:\pydemo\tvbox_config-master
   
   # 创建 Release（会自动上传 release 文件夹中的所有文件）
   gh release create v1.0.0 release/* \
     --title "Release v1.0.0" \
     --notes "新版本发布说明"
   ```

### 方法三：使用脚本（最简单）

1. **使用提供的发布脚本**
   ```bash
   # Windows PowerShell
   .\scripts\release.ps1 -Version v1.0.0 -Notes "新版本发布"
   ```

2. **脚本会自动：**
   - 检查 release 文件夹中的文件
   - 创建 Git 标签
   - 推送到 GitHub
   - 创建 Release 并上传文件

## 📝 发布检查清单

- [ ] 所有安装包已放入 `release/` 文件夹
- [ ] 文件命名规范清晰
- [ ] 已测试安装包可以正常安装和运行
- [ ] 已更新版本号
- [ ] 已准备发布说明
- [ ] 已提交所有代码更改

## ⚠️ 注意事项

1. **文件大小限制**
   - GitHub 单个文件限制：100MB（免费账户）
   - 如果文件超过 50MB，建议使用 Git LFS

2. **敏感信息**
   - 不要上传包含密钥、密码等敏感信息的文件
   - 检查 `.gitignore` 确保敏感文件不会被提交

3. **版本号规范**
   - 建议使用语义化版本：`v主版本号.次版本号.修订号`
   - 例如：`v1.0.0`, `v1.1.0`, `v2.0.0`

## 🔗 相关链接

- [GitHub Releases 文档](https://docs.github.com/cn/repositories/releasing-projects-on-github)
- [GitHub CLI 文档](https://cli.github.com/manual/)
- [语义化版本规范](https://semver.org/lang/zh-CN/)

