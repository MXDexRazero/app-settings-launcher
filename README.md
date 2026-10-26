简体中文 | [English](./README_EN.md)

# App Settings Launcher（应用设置跳板）

一个极小的 Android 跳板 APK：打开它就**直接跳转到小米的「应用设置」页面**，
随后自动关闭自己，不残留后台、不出现在最近任务里。

跳转目标：

```
包名     com.miui.securitycenter
Activity com.miui.appmanager.AppManagerMainActivity
```

它的用途是给系统「自动任务」当跳板——自动任务通常只能"启动某个应用"，
无法直接拉起指定 Activity。装上它之后，自动任务只要"启动 App Settings Launcher"
等价于打开了「设置 → 应用设置」。

---

## 下载

前往 [Releases 页面](https://github.com/MXDexRazero/app-settings-launcher/releases/latest)
下载最新的 `AppSettingsLauncher.apk`，在手机上点击安装即可。

安装包体积约 **9 KB**，不含任何权限、不含网络访问、不收集任何数据。

> **关于签名**：Releases 里的 APK 由 GitHub Actions 自动构建。若仓库未配置正式签名密钥，
> 每次构建会使用临时自签证书，**签名不一致会导致无法覆盖安装**，请先卸载旧版再安装。
> 若希望各版本签名一致，请在仓库 Settings → Secrets 中配置：
> `SIGNING_KEYSTORE_BASE64`、`SIGNING_KEYSTORE_PASSWORD`、`SIGNING_KEY_ALIAS`、`SIGNING_KEY_PASSWORD`。

## 典型用法：定时自动卸载「安全服务」更新

配合 **[gkd_subscription](https://github.com/MXDexRazero/gkd_subscription)** 订阅，
可以实现在特定时间段自动完成整条流程：

```
自动任务定时启动本 APK
      ↓
自动打开「设置 → 应用设置」
      ↓
GKD 订阅接管：点安全服务 → 卸载更新 → 确定 → 退出设置
```

配置步骤见订阅仓库的 README。

## 小米 / 澎湃 OS 必做配置

否则 GKD 会「时灵时不灵」：

1. 长按 GKD 的最近任务卡片 → **加锁**
2. 设置 → 应用设置 → GKD → 省电策略「**无限制**」+ 打开「**自启动**」
3. 省电与电池 → 应用配置 → GKD → 无限制
4. HyperOS 会回收闲置的第三方无障碍服务；失效时去
   **更多设置 → 无障碍 → 已下载的服务** 重新点开 GKD

## 自行构建

**方式一：本机构建**（需 JDK 21 与 Android SDK 的 `platforms;android-34`、`build-tools;34.0.0`）

```shell
bash build.sh
```

产物在 `out/AppSettingsLauncher.apk`。脚本会自动探测 `ANDROID_HOME` 与已安装的 build-tools 版本。

**方式二：GitHub Actions 自动构建并发布**

推送一个 `v` 开头的标签即可自动打包并发布到 Releases：

```shell
git tag v1
git push origin v1
```

也可以在仓库的 Actions 页面手动触发 `Build and Release APK`。

> 编译注意：JDK 21 默认产出 class major version 65，d8 无法处理，
> 脚本中已固定使用 `javac --release 8`，请勿移除该参数。

## 项目结构

```
.
├── AndroidManifest.xml                       # 清单，透明无标题主题
├── java/com/mxd/launcher/MainActivity.java   # 唯一源文件，跳转逻辑
├── build.sh                                  # 跨平台打包脚本
└── .github/workflows/release.yml             # 自动构建并发布 Release
```

## 相关项目

- **[gkd_subscription](https://github.com/MXDexRazero/gkd_subscription)**
  —— 配套的 GKD 订阅，负责「应用设置」页面打开之后的所有点击操作

---

[→ 前往 gkd_subscription（GKD 订阅仓库）](https://github.com/MXDexRazero/gkd_subscription)
