# 荧光检测 App - 完整项目文档

## 📱 项目概述

这是一个现代化的荧光检测移动应用，采用 Flutter 跨平台框架开发，支持 Android、iOS、Web 等多个平台。应用采用简洁优雅的卡片式设计，提供直观的用户体验。

## 🎨 设计特点

- **现代化 UI**：采用柔和的渐变色和圆角卡片设计
- **流畅动画**：页面切换和数据展示都有精心设计的动画效果
- **数据可视化**：使用专业图表库展示荧光强度趋势
- **响应式布局**：适配不同屏幕尺寸

## 📂 项目结构

```
frontend/
├── lib/
│   ├── main.dart                    # 应用入口 + 底部导航
│   ├── app_theme.dart               # 全局主题配置
│   │
│   ├── models/                      # 数据模型
│   │   └── intensity_data.dart      # 荧光强度数据模型
│   │
│   ├── services/                    # 服务层
│   │   └── api_service.dart         # API 接口服务
│   │
│   ├── screens/                     # 页面
│   │   ├── home_screen.dart         # 首页 - 拍照上传
│   │   ├── analysis_screen.dart     # 分析结果页
│   │   ├── history_screen.dart      # 历史记录页
│   │   ├── dashboard_screen.dart    # 数据统计页
│   │   └── profile_screen.dart      # 个人中心页
│   │
│   └── widgets/                     # 通用组件
│       ├── soft_card.dart           # 卡片组件
│       └── trend_chart.dart         # 图表组件
│
├── android/                         # Android 平台配置
├── ios/                             # iOS 平台配置
├── web/                             # Web 平台配置
├── pubspec.yaml                     # 依赖配置
└── README.md                        # 项目说明
```

## 🎯 核心功能

### 1. 首页 (HomeScreen)
- **拍照功能**：调用相机拍摄荧光图片
- **相册选择**：支持从相册选择多张图片
- **图片预览**：网格展示已选择的图片
- **连接状态**：实时显示后端连接状态
- **使用提示**：友好的操作指引

### 2. 分析结果页 (AnalysisScreen)
- **统计卡片**：展示平均值、最大值、最小值、样本数
- **趋势图表**：可视化展示荧光强度变化趋势
- **详细列表**：每张图片的详细数据和强度等级
- **动画效果**：页面加载时的淡入和滑动动画
- **操作按钮**：分享、保存、返回首页、查看历史

### 3. 历史记录页 (HistoryScreen)
- **记录列表**：展示所有历史检测记录
- **迷你图表**：每条记录都有小型趋势图
- **详情弹窗**：点击查看完整的分析详情
- **操作菜单**：分享、添加备注、删除记录
- **清空功能**：批量清空历史记录

### 4. 数据统计页 (DashboardScreen)
- **总览卡片**：显示总检测次数和增长趋势
- **时间筛选**：支持按日/周/月/年查看数据
- **趋势图表**：展示一段时间内的检测趋势
- **分布图表**：柱状图展示强度分布情况
- **最近活动**：快速查看最近的检测记录

### 5. 个人中心页 (ProfileScreen)
- **用户信息**：头像、用户名、邮箱
- **统计数据**：检测次数、使用天数
- **功能设置**：通知、数据同步、导出数据
- **系统功能**：设置、帮助、关于、退出登录

## 🎨 设计系统

### 颜色方案
```dart
// 主色调 - 蓝紫渐变
primaryGradient: [#667eea, #764ba2]

// 强调色 - 粉红渐变
accentGradient: [#f093fb, #f5576c]

// 成功色 - 蓝青渐变
successGradient: [#4facfe, #00f2fe]

// 背景色
backgroundColor: #F8F9FA

// 文字颜色
textPrimary: #2D3436
textSecondary: #636E72
```

### 组件设计
- **SoftCard**：带柔和阴影的白色卡片
- **GradientCard**：渐变色背景卡片
- **TrendChart**：完整的趋势折线图
- **MiniTrendChart**：迷你趋势图

## 🔧 技术栈

### 核心框架
- **Flutter 3.0+**：跨平台 UI 框架
- **Dart**：编程语言

### 主要依赖
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 网络请求
  dio: ^5.4.1
  
  # 图片选择
  image_picker: ^1.0.7
  
  # 图表绘制
  fl_chart: ^0.66.0
  
  # UI 组件
  cupertino_icons: ^1.0.8
```

## 🚀 快速开始

### 1. 环境准备
```bash
# 确保已安装 Flutter SDK
flutter --version

# 检查环境
flutter doctor
```

### 2. 安装依赖
```bash
cd frontend
flutter pub get
```

### 3. 运行应用

#### Android
```bash
# 启动 ADB 端口转发（连接后端）
adb reverse tcp:8000 tcp:8000

# 运行应用
flutter run
```

#### iOS
```bash
flutter run
```

#### Web
```bash
flutter run -d chrome
```

### 4. 构建发布版本

#### Android APK
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## 📡 后端集成

### API 接口

#### 1. 健康检查
```
GET /health
Response: 200 OK
```

#### 2. 图片上传分析
```
POST /process_images/
Content-Type: multipart/form-data

Body:
  files: [File, File, ...]

Response:
{
  "results": [
    {
      "image_path": "path/to/image1.jpg",
      "intensity": 75.5
    },
    {
      "image_path": "path/to/image2.jpg",
      "intensity": 82.3
    }
  ]
}
```

### 连接配置

在 `lib/services/api_service.dart` 中配置后端地址：

```dart
static const String baseUrl = "http://127.0.0.1:8000";
```

## 📱 使用流程

1. **启动应用**：打开应用，检查后端连接状态
2. **选择图片**：点击"拍照"或"相册"选择荧光图片
3. **开始分析**：点击"开始分析"上传图片到后端
4. **查看结果**：查看分析结果、趋势图和详细数据
5. **保存记录**：结果自动保存到历史记录
6. **数据统计**：在统计页面查看整体趋势和分布

## 🎯 待实现功能

- [ ] 本地数据持久化（SharedPreferences / SQLite）
- [ ] 用户登录注册系统
- [ ] 数据云端同步
- [ ] 导出 PDF 报告
- [ ] 分享功能
- [ ] 推送通知
- [ ] 多语言支持
- [ ] 深色模式

## 🐛 常见问题

### 1. 后端连接失败
- 检查 ADB 端口转发是否正常：`adb reverse tcp:8000 tcp:8000`
- 确认后端服务已启动
- 检查防火墙设置

### 2. 图片上传失败
- 检查图片格式是否支持（JPG、PNG）
- 确认图片大小不超过限制
- 查看后端日志排查问题

### 3. 图表不显示
- 确认 fl_chart 依赖已正确安装
- 检查数据格式是否正确
- 查看控制台错误信息

## 📄 许可证

MIT License

## 👥 贡献

欢迎提交 Issue 和 Pull Request！

---

**开发完成时间**：2026-03-09
**版本**：1.0.0
