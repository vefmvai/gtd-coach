#!/bin/bash
# Запуск MCP-сервера Google Календаря для Claude Code.
#
# Доступ берётся по цепочке: сначала переменные окружения, потом связка ключей
# macOS. Так один скрипт работает и на машине, где секреты в связке, и там,
# где они приходят из окружения — и ни в одном случае не попадает в конфиг.
#
# Где взять сам сервер (по порядку):
#   GCAL_MCP_PYTHON — путь к python, которому доступен пакет gcal-mcp;
#   GCAL_MCP_SOURCE — источник для uvx, например git+https://…/gcal-mcp;
#   иначе           — python3 из PATH.
#
# Что нужно для доступа: GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET,
# GOOGLE_REFRESH_TOKEN. Как их получить — в README пакета gcal-mcp.

set -euo pipefail

from_keychain() {  # $1 — имя записи; пусто, если записи нет или это не macOS
  command -v security >/dev/null 2>&1 || return 0
  security find-generic-password -s "$1" -w 2>/dev/null || true
}

: "${GOOGLE_CLIENT_ID:=$(from_keychain "${GOOGLE_KEYCHAIN_CLIENT_ID:-google-oauth-client-id}")}"
: "${GOOGLE_CLIENT_SECRET:=$(from_keychain "${GOOGLE_KEYCHAIN_CLIENT_SECRET:-google-oauth-client-secret}")}"
: "${GOOGLE_REFRESH_TOKEN:=$(from_keychain "${GOOGLE_KEYCHAIN_REFRESH_TOKEN:-google-oauth-refresh-token}")}"

if [ -z "${GOOGLE_CLIENT_ID}" ] || [ -z "${GOOGLE_CLIENT_SECRET}" ] || [ -z "${GOOGLE_REFRESH_TOKEN}" ]; then
  echo "Нет доступа к Календарю. Задайте GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET" >&2
  echo "и GOOGLE_REFRESH_TOKEN — переменными окружения или записями в связке ключей." >&2
  echo "Как их получить — README пакета gcal-mcp." >&2
  exit 1
fi
export GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET GOOGLE_REFRESH_TOKEN
export GOOGLE_CALENDAR_ID="${GOOGLE_CALENDAR_ID:-primary}"
export COACH_TZ="${COACH_TZ:-Europe/Moscow}"

if [ -n "${GCAL_MCP_PYTHON:-}" ]; then
  exec "${GCAL_MCP_PYTHON}" -m gcal_mcp.server
fi

if [ -n "${GCAL_MCP_SOURCE:-}" ] && command -v uvx >/dev/null 2>&1; then
  exec uvx --quiet --from "${GCAL_MCP_SOURCE}" gcal-mcp
fi

exec python3 -m gcal_mcp.server
