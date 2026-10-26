简体中文 | [English](./README_EN.md)

# App Settings Launcher（应用设置跳板）

一个极小的 Android 跳板 APK：打开它就**直接跳转到小米的「应用设置」页面**，
随后自动关闭自己，不残留后台、不出现在最近任务里。

跳转目标：

```
包名     com.miui.securitycenter
Activity com.miui.appmanager.AppManagerMainActivity
```

它存在的意义是给系统「自动任务」当跳板 —— 自动任务通常只能"启动某个应用"，
无法直接拉起指定 Activity。装上它之后，自动任务只要"启动 App Settings Launcher"
就等价于打开了「设置 → 应用设置」。

---

## 下载

前往 **[Releases 页面](https://github.com/MXDexRazero/app-settings-launcher/releases/latest)**
下载最新的 `AppSettingsLauncher.apk`，在手机上安装即可。

安装包约 **9 KB**，不申请任何权限、不联网、不收集数据。

---

## 使用教程

### 第 1 步：安装并验证

1. 下载 `AppSettingsLauncher.apk` 并安装
2. 桌面会出现名为 **「应用设置」** 的图标
3. 点一下它 —— 应该**直接打开「应用设置」列表页**，而没有中间界面

如果点击后停在某个空白页或无反应，说明该 Activity 在你的系统上不可从外部启动。

### 第 2 步：配置自动任务

打开系统「**自动任务**」（在安全中心里）→ 新建任务：

![小米自动任务配置示例](./docs/autotask-screenshot.png)

| 区域 | 设置 |
|---|---|
| 任务名称 | 自动卸载 |
| 如果（条件） | 指定时间，例如 `05:30` / 每天 |
| 就执行（结果） | 开启应用 → 选择 **应用设置** |

保存即可。到点后系统会自动拉起「应用设置」，随后由 GKD 订阅接管剩余操作。

### 第 3 步：配合 GKD 订阅

本 APK 只负责"打开应用设置"。之后的点击动作由
**[gkd_subscription](https://github.com/MXDexRazero/gkd_subscription)** 订阅完成：

```
自动任务（定时）→ 本 APK 打开「应用设置」→ GKD 订阅：点安全服务 → 卸载更新 → 确定 → 退出设置
```

两个仓库都配置好后整条链路才能跑通。订阅链接：

```
https://raw.githubusercontent.com/MXDexRazero/gkd_subscription/main/dist/gkd.json5
```

---

## 规则做了什么

进入应用列表后，三条规则按界面特征依次触发（不使用 `preKeys`，避免与延迟参数冲突）:

| 步骤 | 匹配依据 | 动作 |
|---|---|---|
| 1 | `TextView[vid="am_label"][text="安全服务"]` 的可点击祖先 | 点击进入详情页 |
| 2 | 详情页标题为「安全服务」 且 底部有「卸载更新」 | 点击卸载更新 |
| 3 | 弹窗标题为「要卸载更新吗？」 | 点击 `android:id/button1`（确定） |

每条规则都配了 `matchDelay` + `actionDelay`，用于避开小米设置界面的入场动画。
规则的 `enable` 默认为 `false`，需手动开启。

### 重要：为什么界面会突然消失

「安全服务」的包名就是 `com.miui.securitycenter，而「应用设置」页面也跑在这个 App 里。
卸载更新会 `forceStop` 掉它自己，界面当场消失、直接回到桌面 —— **这是正常现象**。

---

## 小米 / 澎湃 OS 必做配置

漏掉这些会出现「时灵时不灵」:

1. 长按 GKD 的最近任务卡片 → **加锁**，防止被后台清理
2. 设置 → 应用设置 → 搜索 GKD → 省电策略选「**无限制**」，并打开「**自启动**」
3. 省电与电池 → 应用配置 → GKD → 无限制
4. HyperOS 会在闲置后回收第三方无障碍服务。若发现规则失效，去
   **更多设置 → 无障碍 → 已下载的服务** 重新点开 GKD 一次

---

## 常见问题

**打开应用设置后完全没反应**

- 确认 GKD 首页无障碍服务为「运行中」
- 确认订阅里的规则组已开启（默认关闭）
- 确认页面标题是「应用设置」

**日志显示触发成功，但界面没动**

GKD 的 `preKeys` 与 `matchDelay` / `actionDelay` 同时使用时存在冲突，会导致点击被丢弃。
本订阅已改用特征节点做前置条件规避该问题。若仍遇到，把延迟再加大一档。

**可能被自动更新回来**

小米应用商店可能重新推送系统应用更新。如需保持回滚状态，请在应用商店
关闭该应用的自动更新。

---

## 相关项目

- **[gkd_subscription](https://github.com/MXDexRazero/gkd_subscription)**
  —— 配套的 GKD 订阅，负责「应用设置」打开之后的所有点击操作

---

[→ 前往 gkd_subscription（GKD 订阅仓库）](https://github.com/MXDexRazero/gkd_subscription)
