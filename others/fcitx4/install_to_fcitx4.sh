#!/usr/bin/env bash
set -euo pipefail

MIN_RIME_VERSION="1.8.5"
LEGACY_NO_LUA="auto"

for arg in "$@"; do
  case "$arg" in
    --legacy-no-lua)
      LEGACY_NO_LUA="true"
      ;;
    --full)
      LEGACY_NO_LUA="false"
      ;;
    *)
      echo "未知参数: ${arg}"
      echo "用法: $0 [--legacy-no-lua|--full]"
      exit 1
      ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET_DIR="${HOME}/.config/fcitx/rime"
BACKUP_BASE="${HOME}/.config/fcitx"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${BACKUP_BASE}/rime.backup.${TIMESTAMP}"

version_ge() {
  local lhs="$1"
  local rhs="$2"
  [[ "$(printf '%s\n%s\n' "${lhs}" "${rhs}" | sort -V | head -n1)" == "${rhs}" ]]
}

detect_librime_version() {
  local ver=""
  if command -v pkg-config >/dev/null 2>&1; then
    ver="$(pkg-config --modversion rime 2>/dev/null || true)"
  fi
  if [[ -z "${ver}" ]] && command -v dpkg-query >/dev/null 2>&1; then
    ver="$(dpkg-query -W -f='${Version}' librime1 2>/dev/null || true)"
  fi
  echo "${ver}" | grep -Eo '[0-9]+(\.[0-9]+)+' | head -n1 || true
}

has_librime_lua() {
  if command -v ldconfig >/dev/null 2>&1; then
    if ldconfig -p 2>/dev/null | grep -Eiq 'librime-lua|rime[-_.]?lua'; then
      return 0
    fi
  fi
  find /usr/lib /lib -type f \( -name '*librime-lua*' -o -name '*rime*lua*' \) 2>/dev/null | head -n1 | grep -q .
}

echo "[1/4] 检查环境..."
command -v rsync >/dev/null 2>&1 || {
  echo "未找到 rsync，请先安装 rsync。"
  exit 1
}

if [[ "${LEGACY_NO_LUA}" == "auto" ]]; then
  RIME_VERSION="$(detect_librime_version)"
  LUA_OK=false
  if has_librime_lua; then
    LUA_OK=true
  fi

  if [[ -z "${RIME_VERSION}" ]]; then
    LEGACY_NO_LUA="true"
    echo "检测不到 librime 版本，默认启用 legacy 无 Lua 兼容模式。"
  elif ! version_ge "${RIME_VERSION}" "${MIN_RIME_VERSION}"; then
    LEGACY_NO_LUA="true"
    echo "检测到 librime ${RIME_VERSION} (< ${MIN_RIME_VERSION})，默认启用 legacy 无 Lua 兼容模式。"
  elif [[ "${LUA_OK}" != "true" ]]; then
    LEGACY_NO_LUA="true"
    echo "未检测到 librime-lua，默认启用 legacy 无 Lua 兼容模式。"
  else
    LEGACY_NO_LUA="false"
    echo "环境满足完整模式要求（librime ${RIME_VERSION}，且检测到 librime-lua）。"
  fi
fi

mkdir -p "${TARGET_DIR}"

if [[ -d "${TARGET_DIR}" ]] && [[ "$(ls -A "${TARGET_DIR}")" != "" ]]; then
  echo "[2/4] 备份现有配置到 ${BACKUP_DIR} ..."
  mkdir -p "${BACKUP_BASE}"
  cp -a "${TARGET_DIR}" "${BACKUP_DIR}"
else
  echo "[2/4] 未检测到现有配置，跳过备份。"
fi

echo "[3/4] 同步配置到 ${TARGET_DIR} ..."
rsync -a --delete \
  --exclude='.git/' \
  --exclude='.github/' \
  --exclude='others/pages/' \
  --exclude='others/fcitx4/' \
  --exclude='build/' \
  --exclude='sync/' \
  --exclude='*.userdb/' \
  --exclude='*.userdb/**' \
  --exclude='user.yaml' \
  --exclude='installation.yaml' \
  --exclude='.place_holder' \
  "${REPO_DIR}/" "${TARGET_DIR}/"

if [[ "${LEGACY_NO_LUA}" == "true" ]]; then
  echo "[3.5/4] 应用 legacy 无 Lua 兼容补丁 ..."
  for name in default.custom.yaml rime_ice.custom.yaml; do
    if [[ -f "${TARGET_DIR}/${name}" ]]; then
      cp -a "${TARGET_DIR}/${name}" "${TARGET_DIR}/${name}.bak.${TIMESTAMP}"
    fi
    cp -a "${REPO_DIR}/others/fcitx4/legacy_no_lua/${name}" "${TARGET_DIR}/${name}"
  done
fi

echo "[4/4] 尝试重载 fcitx4 ..."
if command -v fcitx-remote >/dev/null 2>&1; then
  fcitx-remote -r || true
  echo "已执行：fcitx-remote -r"
else
  echo "未找到 fcitx-remote，请手动重启 fcitx4 后生效。"
fi

if [[ "${LEGACY_NO_LUA}" == "true" ]]; then
  echo "完成。已启用 legacy 无 Lua 模式：仅保留基础拼音/词库能力，Lua 扩展功能已关闭。"
else
  echo "完成。若出现兼容性问题，请确认系统安装的是 fcitx-rime，且 librime 版本与 librime-lua 满足要求。"
  echo "如系统较旧（例如 librime < 1.8.5 或缺少 librime-lua），请改用：bash others/fcitx4/install_to_fcitx4.sh --legacy-no-lua"
fi