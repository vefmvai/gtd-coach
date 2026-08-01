#!/bin/bash
# Запуск MCP-сервера Todoist для Claude Code.
#
# Секрет берётся по цепочке, а не одним способом: сначала переменная окружения,
# потом связка ключей macOS. Так один и тот же скрипт работает и там, где
# токен лежит в связке, и там, где он приходит из окружения (Linux, контейнер,
# сервер) — и ни в одном из случаев не попадает ни в конфиг, ни в репозиторий.
#
# Где взять сам сервер (по порядку):
#   TODOIST_MCP_PYTHON — путь к python, которому доступен пакет. Самый прямой
#                        способ: указать python из окружения, куда пакет
#                        установлен через `uv pip install -e .`.
#   TODOIST_MCP_SOURCE — источник для uvx, например git+https://…/todoist-mcp
#                        Тогда ничего ставить заранее не нужно.
#   иначе              — python3 из PATH; пакет должен быть ему виден.
#
# Ошибка «нет токена» означает: задайте TODOIST_API_TOKEN или положите токен
# в связку ключей под именем, указанным в TODOIST_KEYCHAIN_ITEM.

set -euo pipefail

# ── токен ─────────────────────────────────────────────────────────────────────
if [ -z "${TODOIST_API_TOKEN:-}" ] && command -v security >/dev/null 2>&1; then
  ITEM="${TODOIST_KEYCHAIN_ITEM:-todoist-api}"
  TODOIST_API_TOKEN="$(security find-generic-password -s "${ITEM}" -w 2>/dev/null || true)"
fi

if [ -z "${TODOIST_API_TOKEN:-}" ]; then
  echo "Нет токена Todoist. Задайте переменную TODOIST_API_TOKEN" >&2
  echo "или положите токен в связку ключей (по умолчанию имя записи: todoist-api)." >&2
  exit 1
fi
export TODOIST_API_TOKEN

# Часовой пояс, в котором показывать время задач. Переехали — поменяли,
# код при этом не трогается.
export COACH_TZ="${COACH_TZ:-Europe/Moscow}"

# ── запуск ────────────────────────────────────────────────────────────────────
if [ -n "${TODOIST_MCP_PYTHON:-}" ]; then
  exec "${TODOIST_MCP_PYTHON}" -m coach_todoist_mcp.server
fi

if [ -n "${TODOIST_MCP_SOURCE:-}" ] && command -v uvx >/dev/null 2>&1; then
  exec uvx --quiet --from "${TODOIST_MCP_SOURCE}" todoist-mcp
fi

exec python3 -m coach_todoist_mcp.server
