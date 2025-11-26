#!/usr/bin/env bash
set -euo pipefail

# 构建并推送 new-api 镜像到阿里云镜像仓库。

REGISTRY="${REGISTRY:-registry.cn-hangzhou.aliyuncs.com/qidao778}"
IMAGE_NAME="${IMAGE_NAME:-new-api}"
VERSION_FILE="${VERSION_FILE:-VERSION}"
PLATFORMS="${PLATFORMS:-linux/amd64}"
USE_BUILDX="${USE_BUILDX:-1}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker 未安装，无法继续" >&2
  exit 1
fi

REPO="${REGISTRY}/${IMAGE_NAME}"

if [[ $# -gt 0 ]]; then
  TAG="$1"
elif [[ -f "${VERSION_FILE}" ]] && [[ -s "${VERSION_FILE}" ]]; then
  TAG="$(tr -d '\r\n ' < "${VERSION_FILE}")"
elif git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  TAG="$(git rev-parse --short HEAD)"
else
  TAG=""
fi

if [[ -z "${TAG}" ]]; then
  TAG="latest"
  echo "未检测到 VERSION 或 Git 信息，使用默认标签：${TAG}"
fi

TARGET_TAG="${REPO}:${TAG}"
LATEST_TAG="${REPO}:latest"

echo "即将构建镜像：${TARGET_TAG} (以及 ${LATEST_TAG})"
echo "确保已经执行过 docker login ${REGISTRY}"

if [[ "${USE_BUILDX}" == "1" ]] && docker buildx version >/dev/null 2>&1; then
  echo "使用 docker buildx 构建并推送 (${PLATFORMS})"
  docker buildx build \
    --platform "${PLATFORMS}" \
    -t "${TARGET_TAG}" \
    -t "${LATEST_TAG}" \
    --push \
    .
else
  echo "使用常规 docker build (仅本地平台)"
  docker build \
    -t "${TARGET_TAG}" \
    -t "${LATEST_TAG}" \
    .
  docker push "${TARGET_TAG}"
  docker push "${LATEST_TAG}"
fi

echo "镜像推送完成：${TARGET_TAG}"
