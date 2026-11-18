# 开发指南

## 结构

| 文件 | 职责 |
| --- | --- |
| `Models.swift` | 动画清单、提醒、偏好与文件撤销记录 |
| `Actions.swift` | 动作标签、默认事件名称、16 方向计算 |
| `PetPanel.swift` | 可悬浮的透明 NSPanel |
| `AppController.swift` | 生命周期、动画状态、菜单、提醒与文件操作 |
| `PetView.swift` | 绘制、泡泡、点击、拖动和文件接收 |
| `Diagnostics.swift` | 显式调用的运行检查与预览导出 |
| `main.swift` | AppKit 程序入口 |

此项目不依赖第三方 Swift 包，不需要 Xcode 工程。构建脚本使用 `swiftc` 编译整个目录，再组装标准 `.app`，复制资源与 Info.plist，最后进行本地临时签名。

## 常用命令

```sh
python3 scripts/check-resources.py
bash scripts/build.sh
bash scripts/package.sh
bash scripts/smoke-test.sh
```

素材检查验证清单、帧数、PNG 的 CRC、384×416 尺寸与 RGBA 通道。运行检查需要有图形登录会话的 Mac，会短暂打开透明窗口；CI 仅做素材检查、编译和打包，不运行桌面交互。

`smoke-test.sh` 使用独立临时偏好文件，不改动日常设置。

## 集成检查：废纸篓与提醒

下面的检查会创建一个可丢弃的测试文本文件，把它移入废纸篓，然后还原并核对内容；也会弹出一个自动关闭的测试提醒。请只在本机图形会话中显式执行：

```sh
bash scripts/build.sh
mkdir -p .build/integration
build/猫咪老师.app/Contents/MacOS/NyankoCompanion \
  --integration-test \
  --test-data "$PWD/.build/integration/preferences.json" \
  --report "$PWD/.build/integration/report.json"
cat .build/integration/report.json
```

诊断标志总是与 `--test-data` 一起使用，避免影响正常使用时的偏好。报告中的 `ok` 必须为 `true`；正常运行不会自动执行这些诊断。

## 动画素材

`Resources/animations.json` 描述每组的 `count` 和 `duration`（毫秒）。帧名从 `0.png` 开始，画布为 384×416、透明 RGBA。新增动作时同步修改清单、标签及相应检查。`lookA` / `lookB` 按顺时针保存 16 个方向：从向上开始，每步 22.5 度。

满足时的泡泡由 AppKit 实时绘制，不包含在 PNG 中。绘制没有背景矩形，静态表情与多帧动作共用同一套播放器。

## 打包与发布

`bash scripts/package.sh` 会生成 `dist/nyanko-sensei-macos-<架构>.zip`，适合手动添加到 GitHub Release。源码树不提交 `.app`、zip、构建缓存和个人状态。若以后用于广泛分发，可另行配置 Developer ID 签名和公证；当前脚本没有签名证书或发布凭据。

修改代码后须重新构建；已运行的旧进程不会自动热更新。提交前至少执行素材检查和编译。交互或文件操作发生变化时，在本机执行相应运行检查并记录结果。
