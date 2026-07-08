# 轻院课表 (QYClass)

> 面向华北理工大学轻工学院学生的课程表 App

## 项目概述

- **目标平台**: Android（后续可扩展 iOS）
- **技术栈**: Flutter + Python FastAPI 爬虫微服务
- **核心功能**: 课表查看、教务系统导入课表、空教室查询
- **目标用户**: 华北理工大学轻工学院在校学生
- **教务系统**: jws.qgxy.cn（Spring Security 新版系统，非旧版正方 ASP.NET）

## 教务系统分析结果（2026-07-06 实测）

| 项目 | 实际值 |
|------|--------|
| 系统类型 | **Spring Security + Java**（不是旧版正方！） |
| 登录地址 | `https://jws.qgxy.cn/login` |
| 登录接口 | `POST /j_spring_security_check` |
| 学号字段 | `j_username` |
| 密码字段 | `j_password`（**MD5 加密后提交**） |
| 验证码字段 | `j_captcha`（4位） |
| 验证码地址 | `/img/captcha.jpg`（加随机参数防缓存） |
| 隐藏字段 | `tokenValue`（从登录页提取）, `schoolCode=100059` |
| 密码加密 | 标准 JavaScript hex_md5 → Python `hashlib.md5` 兼容 |

## 架构

```
Flutter App (客户端)
  ├── 课表页面: 周视图网格展示，左右滑动切换周次
  ├── 空教室页面: 按教学楼/星期/节次筛选
  └── 我的页面: 导入课表、设置

Python FastAPI 爬虫微服务 (scraper/)
  ├── /api/v1/captcha — 获取验证码
  ├── /api/v1/login — 登录教务系统
  ├── /api/v1/schedule — 获取课表
  └── /api/v1/classrooms/free — 查询空教室
```

## 技术栈

| 层 | 技术 |
|----|------|
| 框架 | Flutter 3.x (Dart) |
| 状态管理 | Provider |
| 本地数据库 | sqflite (SQLite) |
| 网络请求 | dio |
| 爬虫 | Python FastAPI + requests + BeautifulSoup + ddddocr |

## 目录结构

```
qyclass/
├── lib/                    # Flutter 源码
│   ├── main.dart           # 入口
│   ├── app.dart            # MaterialApp 配置
│   ├── models/             # 数据模型
│   ├── providers/          # Provider 状态管理
│   ├── services/           # 业务逻辑 (API, 数据库)
│   ├── screens/            # 页面
│   ├── widgets/            # 可复用组件
│   └── utils/              # 工具函数
├── scraper/                # Python 爬虫微服务
│   ├── main.py             # FastAPI 入口
│   └── zhengfang/          # 正方教务系统爬虫模块
└── assets/                 # 图片资源
```

## 数据模型

- **Course**: 课程元数据（名称、教师、学分、颜色）
- **CourseSchedule**: 排课记录（课程ID、星期几、节次、教室、周次范围、单双周）
- **Semester**: 学期（名称、起止日期、总周数）
- **Classroom**: 教室（教学楼、教室号、容量）

所有数据存本地 SQLite，保证离线可用。

## 开发约定

- 命名: Dart 用 lowerCamelCase，Python 用 snake_case
- 状态管理: 统一用 Provider (ChangeNotifier + Consumer)
- 每个功能先写 Python 脚本验证，再集成到 Flutter
- 每个小功能完成后 git commit

## 当前状态

- [x] 产品设计完成
- [x] 第0阶段：环境搭建（Flutter 3.42 + Python 3.14 已就绪）
- [x] 第1阶段：爬虫开发 — **已根据实际系统重写**（Spring Security + MD5）
- [x] 第2阶段：Flutter 前端 — 20 个 .dart 文件，0 编译错误
- [x] 教务系统已分析：jws.qgxy.cn = Spring Security 新版系统
- [ ] 第3阶段：安装 Python 依赖 + 测试爬虫 + 真机运行

## 下一步操作（简化！）

爬虫代码已经适配了实际系统，现在只需要 2 步：

1. **安装 Python 依赖**（用 Python 3.12 避免编译问题）：
   ```bash
   pip install fastapi uvicorn requests beautifulsoup4 pydantic python-multipart
   # ddddocr 可选（自动识别验证码用，先跳过也可以）
   ```

2. **启动爬虫并测试**：
   ```bash
   cd scraper
   python main.py
   # 访问 http://localhost:8000/docs 可以看到 API 文档
   ```
   然后用 curl 或 Postman 测试：
   ```bash
   # 1. 获取验证码
   curl -X POST http://localhost:8000/api/v1/captcha
   
   # 2. 登录（替换成你的学号和验证码）
   curl -X POST http://localhost:8000/api/v1/login \
     -H "Content-Type: application/json" \
     -d '{"student_id":"你的学号","password":"你的密码","captcha_id":"上一步返回的id","captcha_code":"验证码"}'
   
   # 3. 获取课表
   curl http://localhost:8000/api/v1/schedule -H "Authorization: Bearer 登录返回的token"
   ```

3. **运行 Flutter App**：
   ```bash
   flutter run
   ```

## 关键待完成

- [ ] `lib/screens/login_screen.dart`：TODO 标记处接入真实的 ApiService
- [ ] 爬虫需要实际登录一次验证（课表页面 URL 需要登录后才能确认）
- [ ] ddddocr 验证码识别（可选，手动输入也能用）
- [ ] 爬虫部署到 Railway 或 ngrok（App 需要访问）
