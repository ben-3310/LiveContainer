# Быстрый старт сборки LiveContainer+SideStore.ipa

## Шаг 1: Настройка Xcode (выполнить один раз)

Откройте терминал и выполните:

```bash
cd "/Users/ben/Library/Mobile Documents/com~apple~CloudDocs/Repo/LiveContainer"

# Переключение на Xcode
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Принятие лицензии Xcode
sudo xcodebuild -license accept
```

Вам потребуется ввести пароль администратора.

## Шаг 2: Запуск сборки

После настройки Xcode выполните:

```bash
export TEAM_ID=972MD5K36E
./build_sidestore.sh
```

Скрипт автоматически:
- ✅ Соберет архив проекта
- ✅ Создаст `LiveContainer.ipa`
- ✅ Интегрирует SideStore
- ✅ Создаст `LiveContainer+SideStore.ipa`

## Альтернатива: Использование setup_xcode.sh

Или используйте скрипт настройки:

```bash
./setup_xcode.sh
export TEAM_ID=972MD5K36E
./build_sidestore.sh
```

## Результат

После успешной сборки вы получите:
- `LiveContainer.ipa` - базовая версия
- `LiveContainer+SideStore.ipa` - версия с интеграцией SideStore

## Текущий статус

✅ Team ID настроен: `972MD5K36E`  
✅ Скрипт сборки готов  
⏳ Требуется принять лицензию Xcode (см. Шаг 1)
