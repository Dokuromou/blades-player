#!/usr/bin/env bash
# Provisions a JDK 17 + Android SDK + Gradle distribution inside the sandbox so the
# project can be compiled for real. Not part of the app repo.
set -euo pipefail

ROOT=/home/user/tools
mkdir -p "$ROOT/downloads" "$ROOT/jdk" "$ROOT/android-sdk" "$ROOT/gradle"

echo "==> JDK 17 (Temurin)"
if [ ! -x "$ROOT/jdk/bin/javac" ]; then
  curl -sSL -o "$ROOT/downloads/jdk17.tar.gz" \
    "https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse"
  tar xzf "$ROOT/downloads/jdk17.tar.gz" -C "$ROOT/jdk" --strip-components=1
fi
"$ROOT/jdk/bin/java" -version

echo "==> Android command-line tools"
if [ ! -x "$ROOT/android-sdk/cmdline-tools/latest/bin/sdkmanager" ]; then
  curl -sSL -o "$ROOT/downloads/cmdline-tools.zip" \
    "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
  mkdir -p "$ROOT/android-sdk/cmdline-tools"
  unzip -q -o "$ROOT/downloads/cmdline-tools.zip" -d "$ROOT/android-sdk/cmdline-tools"
  mv "$ROOT/android-sdk/cmdline-tools/cmdline-tools" "$ROOT/android-sdk/cmdline-tools/latest"
fi

export JAVA_HOME="$ROOT/jdk"
export PATH="$JAVA_HOME/bin:$PATH"
SDKM="$ROOT/android-sdk/cmdline-tools/latest/bin/sdkmanager"

echo "==> SDK packages"
yes | "$SDKM" --sdk_root="$ROOT/android-sdk" --licenses >/dev/null 2>&1 || true
"$SDKM" --sdk_root="$ROOT/android-sdk" \
  "platform-tools" "platforms;android-34" "platforms;android-35" \
  "build-tools;34.0.0" 2>&1 | tail -5

echo "==> Gradle 8.9 distribution"
if [ ! -d "$ROOT/gradle/gradle-8.9" ]; then
  curl -sSL -o "$ROOT/downloads/gradle.zip" "https://services.gradle.org/distributions/gradle-8.9-bin.zip"
  unzip -q -o "$ROOT/downloads/gradle.zip" -d "$ROOT/gradle"
fi

echo "==> DONE"
