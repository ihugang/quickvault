# QuickVault Support Page

## 部署说明 / Deployment Instructions

### 上传到服务器 / Upload to Server

将所有文件上传到你的服务器：

```bash
# 使用 scp 上传（根据你的服务器配置修改）
scp index.html center-logo.png app-icon-180.png user@timehound.vip:/path/to/quickhold/support/

# 或使用 FTP/SFTP 工具上传
# 需要上传的文件：
# - index.html (主页面)
# - center-logo.png (页面 logo，透明背景)
# - app-icon-180.png (favicon 图标)
```

### 访问地址 / Access URL

部署后可通过以下地址访问：
- https://timehound.vip/quickhold/support

### Nginx 配置示例 / Nginx Configuration Example

如果你使用 Nginx，确保配置正确：

```nginx
server {
    listen 443 ssl;
    server_name timehound.vip;

    location /quickhold/support {
        alias /path/to/quickhold/support;
        index index.html;
        try_files $uri $uri/ /quickhold/support/index.html;
    }
}
```

### 功能特性 / Features

- ✅ 响应式设计 - 支持手机、平板、电脑
- ✅ 深色模式 - 自动适配系统主题
- ✅ 中英双语 - 一键切换语言
- ✅ 纯静态页面 - 无需后端支持
- ✅ SEO 优化 - 包含完整 meta 标签

### 自定义修改 / Customization

如需修改内容，直接编辑 `index.html` 文件：

1. **修改联系邮箱**：搜索 `ihugang@gmail.com` 并替换
2. **添加 App Store 链接**：在页面顶部 hero 区域添加下载按钮
3. **修改 FAQ**：在 FAQ Section 中添加或修改问题
4. **更新功能说明**：在 Features Section 中修改功能卡片

### 测试 / Testing

在上传前，可以在本地测试：

```bash
# 在 support 目录下启动简单服务器
cd support
python3 -m http.server 8000

# 然后访问 http://localhost:8000
```

### App Store 提交 / App Store Submission

在 App Store Connect 中填写 Support URL：
```
https://timehound.vip/quickhold/support
```

### 维护建议 / Maintenance Recommendations

- 定期更新 FAQ 内容
- 根据用户反馈添加新的常见问题
- 在应用重大更新时同步更新页面内容
- 保持联系邮箱可用并及时回复用户
