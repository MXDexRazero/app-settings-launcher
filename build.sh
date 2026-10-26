#!/usr/bin/env bash
# 极简 Android 打包：javac -> d8 -> aapt2 -> zipalign -> apksigner
# 不依赖 Gradle / Android Studio，Windows(Git Bash) 与 Linux(macOS) 均可运行。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# ---- 定位 Android SDK ----
ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"

# Git Bash / MSYS 下把 /c/... 转成 C:\...
# 否则 javac / aapt2 这类原生程序认不出 MSYS 路径，导致找不到 android.jar
if command -v cygpath >/dev/null 2>&1; then
  ANDROID_HOME="$(cygpath -w "$ANDROID_HOME")"
fi
export ANDROID_HOME

pick_latest() {
  # 按版本号排序取最后一个（sort -V 自然序）
  ls -1d "$@" 2>/dev/null | sort -V | tail -1 || true
}

BT_DIR="$(pick_latest "$ANDROID_HOME"/build-tools/*)"
PLAT_JAR="$(pick_latest "$ANDROID_HOME"/platforms/android-*/android.jar)"

if [ -z "${BT_DIR:-}" ] || [ ! -f "${PLAT_JAR:-}" ]; then
  echo "[!] 未找到 Android SDK 组件。" >&2
  echo "    请先安装：sdkmanager \"platforms;android-34\" \"build-tools;34.0.0\"" >&2
  echo "    或设置环境变量 ANDROID_HOME。" >&2
  exit 1
fi

# Windows 下工具带 .exe 后缀
AAPT2="$BT_DIR/aapt2";   [ -f "$BT_DIR/aapt2.exe" ]   && AAPT2="$BT_DIR/aapt2.exe"
ZIPALIGN="$BT_DIR/zipalign"; [ -f "$BT_DIR/zipalign.exe" ] && ZIPALIGN="$BT_DIR/zipalign.exe"

echo "[i] ANDROID_HOME = $ANDROID_HOME"
echo "[i] build-tools  = $(basename "$BT_DIR")"
echo "[i] platform     = $(basename "$(dirname "$PLAT_JAR")")"

rm -rf build out
mkdir -p build/obj build/dex out

# ---- 1. 编译 ----
# 必须 --release 8：JDK 21 默认产出 class major version 65，d8 无法处理
echo "[1/5] javac"
javac -nowarn -encoding UTF-8 \
  --release 8 \
  -classpath "$PLAT_JAR" \
  -d build/obj \
  java/com/mxd/launcher/MainActivity.java

# ---- 2. class -> dex ----
echo "[2/5] d8 -> classes.dex"
java -cp "$BT_DIR/lib/d8.jar" com.android.tools.r8.D8 \
  --lib "$PLAT_JAR" \
  --output build/dex \
  build/obj/com/mxd/launcher/*.class

# ---- 3. 打包资源与清单 ----
echo "[3/5] aapt2 link"
"$AAPT2" link \
  -I "$PLAT_JAR" \
  --manifest AndroidManifest.xml \
  --auto-add-overlay \
  -o build/unaligned.apk

# ---- 4. 塞入 dex 并对齐 ----
echo "[4/5] 追加 classes.dex + zipalign"
cp build/unaligned.apk build/withdex.apk
if command -v python3 >/dev/null 2>&1; then PY=python3; else PY=python; fi
"$PY" - <<'PY'
import zipfile
with zipfile.ZipFile('build/withdex.apk', 'a', zipfile.ZIP_DEFLATED) as z:
    z.write('build/dex/classes.dex', 'classes.dex')
PY
"$ZIPALIGN" -f 4 build/withdex.apk build/aligned.apk

# ---- 5. 签名 ----
# 优先使用仓库 Secrets 提供的正式签名：
#   SIGNING_KEYSTORE_BASE64 / SIGNING_KEYSTORE_PASSWORD / SIGNING_KEY_ALIAS / SIGNING_KEY_PASSWORD
# 未配置时自动生成一个临时自签 keystore（注意：每次构建的签名都不同，
# 覆盖安装前需要先卸载旧版）。
echo "[5/5] 签名"
KS_FILE="${KS_FILE:-launcher.keystore}"
KS_ALIAS="${KS_ALIAS:-launcher}"
KS_STORE_PASS="${KS_STORE_PASS:-123456}"
KS_KEY_PASS="${KS_KEY_PASS:-123456}"

if [ ! -f "$KS_FILE" ]; then
  echo "    未检测到 keystore，生成临时自签: $KS_FILE"
  keytool -genkeypair -v \
    -keystore "$KS_FILE" \
    -alias "$KS_ALIAS" \
    -keyalg RSA -keysize 2048 -validity 10950 \
    -storepass "$KS_STORE_PASS" -keypass "$KS_KEY_PASS" \
    -dname "CN=AppSettingsLauncher, OU=Dev, O=MXD, C=CN" >/dev/null
fi

java -jar "$BT_DIR/lib/apksigner.jar" sign \
  --ks "$KS_FILE" \
  --ks-key-alias "$KS_ALIAS" \
  --ks-pass "pass:$KS_STORE_PASS" \
  --key-pass "pass:$KS_KEY_PASS" \
  --out out/AppSettingsLauncher.apk \
  build/aligned.apk

java -jar "$BT_DIR/lib/apksigner.jar" verify --print-certs out/AppSettingsLauncher.apk

echo
echo "[✓] 完成: $ROOT/out/AppSettingsLauncher.apk"
