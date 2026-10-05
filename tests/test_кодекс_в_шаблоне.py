"""Свежая установка не начинает знакомство с жалобы на кодекс.

**Почему это всплыло.** 05.10.2026 вторую копию коуча поставили из `brain-template/`,
и первым же сообщением коуч передал человеку «техническую строку для того, кто правит
код»: копии кодекса нет в файле правил. Шаблон писался 02.08 со строкой «копия
приезжает с плагином, здесь не дублируется», сторож свежести появился 13.08 и требует
обратного (`core.md` § 9.3 п. 5) — шаблон за ним не обновили. Мозг владельца жалобы
не давал: копию туда перенесли руками, и разлад жил только у новых установок.

**Почему запуск сторожа, а не поиск строки.** Тест зовёт тот самый хук, что работает
у бота на старте, и требует тишины. Сверка строки повторяла бы правила хука своими
словами и разошлась бы с ним при первой его правке.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

ПЛАГИН = Path(__file__).resolve().parents[1]
ШАБЛОН = ПЛАГИН / "brain-template"
СТОРОЖ = ПЛАГИН / "hooks" / "codex-freshness.py"


def слова_сторожа(проект: Path) -> str:
    окружение = dict(os.environ, CLAUDE_PROJECT_DIR=str(проект), CLAUDE_PLUGIN_ROOT=str(ПЛАГИН))
    итог = subprocess.run(
        [sys.executable, str(СТОРОЖ)], input="{}", capture_output=True, text=True,
        env=окружение, timeout=30,
    )
    assert итог.returncode == 0, итог.stderr
    return итог.stdout.strip()


def test_на_шаблоне_мозга_сторож_кодекса_молчит():
    сказано = слова_сторожа(ШАБЛОН)
    assert сказано == "", (
        "Сторож свежести кодекса жалуется на шаблон мозга — свежая установка "
        "начнёт знакомство с этой жалобы:\n"
        + json.loads(сказано)["hookSpecificOutput"]["additionalContext"]
    )


def test_сторож_не_молчит_без_копии(tmp_path):
    """Обратная сторона: тишина выше что-то значит, только если без копии сторож говорит."""
    for файл in (".loreground", "CLAUDE.md"):
        (tmp_path / файл).write_text((ШАБЛОН / файл).read_text(encoding="utf-8"), encoding="utf-8")
    правила = tmp_path / "CLAUDE.md"
    текст = правила.read_text(encoding="utf-8")
    без_копии = "\n".join(с for с in текст.splitlines() if "codex.md" not in с)
    правила.write_text(без_копии, encoding="utf-8")
    assert "кодекса нет" in слова_сторожа(tmp_path)
