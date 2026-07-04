# Odysseus Portable — Windows Scripts

Self-hosted AI workspace (Odysseus) — портативная Windows-сборка без Docker.
Оригинальный проект на [Odysseus](https://github.com/pewdiepie-archdaemon/odysseus).

## 🚀 Быстрый старт

1. Склонируйте этот репозиторий в `D:\Odysseus` например:
```text
     cd D:/
     git clone https://github.com/MRafStudio/Odysseus-Portable-Scripts.git Odysseus
     cd Odysseus
```

## 📁 Структура

```
D:\Odysseus
├── Start.bat                    # Главное меню
├── scripts\                      # Скрипты установки и запуска
│   ├── Config.ini                 # Файл настроек (генерируется)
│   ├── CreateConfig.bat           # Создание Config.ini
│   ├── InstallOrUpdate.bat        # Меню установки/обновления
│   ├── InstallOrUpdate-All.bat    # Установка всех компонентов
│   ├── InstallOrUpdate-Python.bat # Portable Python 3.12.10
│   ├── InstallOrUpdate-NodeJS.bat # Portable Node.js 20.11.0
│   ├── InstallOrUpdate-Repo.bat   # Клонирование/обновление repo
│   ├── InstallOrUpdate-Deps.bat  # Python зависимости
│   ├── Start-Odysseus.bat        # Запуск Odysseus + ChromaDB
│   ├── Settings.bat              # Настройки (LLM, порт, auth)
│   ├── DevTools.bat              # Инструменты разработчика
│   └── SmartPause.bat            # Авто-продолжение с остановкой
├── repo\                         # Клон репозитория Odysseus (dev-ветка)
├── python-3.12.10\               # Portable Python (ставится автоматически)
├── node-dist\                    # Portable Node.js (ставится автоматически)
└── data\                         # Изоляция данных (AppData, TEMP, HOME, БД, логи)
    ├── temp\                     # TEMP / TMP
    ├── appdata\                  # APPDATA
    ├── localappdata\             # LOCALAPPDATA
    ├── home\                     # HOME / USERPROFILE
    ├── huggingface\              # HF_HOME (кэш моделей)
    ├── fastembed\                # Кэш FastEmbed
    ├── chromadb\                 # Данные ChromaDB
    ├── logs\                     # Логи приложения
    └── app.db                    # SQLite база данных
```

## ⚙️ Требования

- **Windows 10/11** (x64)
- **Git for Windows** (глобальный, обязательно) — [https://git-scm.com/download/win](https://git-scm.com/download/win)
- **Microsoft C++ Build Tools** или **Visual Studio 2022 Build Tools** — для компиляции C-расширений (bcrypt, cryptography, lxml)
- **Ollama** (опционально, но рекомендуется) — [https://ollama.com/download](https://ollama.com/download)

## Установка

1. Установите **Git for Windows** и **Microsoft C++ Build Tools** (если ещё не установлены)
2. Запустите `Start.bat`
3. Выберите пункт **[1] Установка / Обновление компонентов**
4. Дождитесь окончания установки (5-15 минут)
5. Убедитесь, что Ollama запущена (если используете)
6. Запустите Odysseus через пункт **[*]** или **[Enter]**

## Настройка

- **LLM Backend**: Ollama (по умолчанию), LM Studio, OpenAI, или custom endpoint
- **Порт**: 7000 (по умолчанию)
- **Auth**: включён по умолчанию (admin / admin)
- **Web Search**: Brave API, Tavily, Serper, Google Custom Search, или none
- **ChromaDB**: запускается автоматически на порту 8100

## Что отличается от Docker-версии

| Docker | Portable |
|--------|----------|
| `python:3.14-slim` | Python 3.12.10 |
| ChromaDB контейнер | ChromaDB через `chroma.exe run` |
| SearXNG контейнер | Не используется (заменяется API-ключами) |
| ntfy контейнер | Не используется |
| PUID/PGID | Не нужно (Windows) |
| Linux-пути | Windows-пути |

## Примечания

- **Python 3.12** — оптимальный выбор. Python 3.13+ ломает `basicsr/gfpgan/facexlib` (PEP 667).
- **Node.js 20.11.0** — portable, устанавливается автоматически через `InstallOrUpdate-NodeJS.bat`.
- `requirements.txt` автоматически фиксится при установке: удаляется `httpx2`, `chromadb-client` → `chromadb`, добавляется `python-magic-bin`.
- Все данные изолированы в `data\` — ничего не пишется в систему.

## Устранение неполадок

### "Не удалось установить зависимости"
- Установите **Microsoft C++ Build Tools** с компонентом "Desktop development with C++"
- Проверьте лог: `data	emp\pip-install.log`

### "ChromaDB не запустилась"
- Проверьте, не занят ли порт 8100: `netstat -ano | findstr 8100`
- Попробуйте запустить вручную: `python-3.12.10\Scripts\chroma.exe run --path D:\Odysseus\data\chromadb --port 8100 --host 127.0.0.1`

### "Ollama не отвечает"
- Убедитесь, что Ollama запущена и доступна на `http://127.0.0.1:11434`
- Или измените LLM backend в настройках на LM Studio / OpenAI

### "ModuleNotFoundError: No module named '...'"
- Запустите переустановку зависимостей через DevTools → [2]

## 📝 Лицензия

Odysseus: AGPL-3.0-or-later
Скрипты: MIT (RafStudio)
