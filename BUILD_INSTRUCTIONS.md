# Инструкция по сборке LiveContainer+SideStore.ipa

## Текущий статус
✅ Team ID обновлен: `972MD5K36E`  
✅ Скрипт сборки готов: `build_sidestore.sh`  
❌ Xcode не установлен (требуется для сборки)

## Шаги для сборки

### 1. Установка Xcode
1. Откройте App Store
2. Найдите "Xcode" и установите (или скачайте с developer.apple.com/xcode)
3. После установки откройте Xcode
4. Перейдите в **Xcode → Settings → Accounts**
5. Добавьте ваш Apple ID: `i@ben3310.com`
6. Убедитесь, что Team ID `972MD5K36E` отображается

### 2. Настройка командной строки
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### 3. Принятие лицензии Xcode
```bash
sudo xcodebuild -license accept
```

### 4. Запуск сборки
```bash
cd "/Users/ben/Library/Mobile Documents/com~apple~CloudDocs/Repo/LiveContainer"
export TEAM_ID=972MD5K36E
./build_sidestore.sh
```

Скрипт автоматически:
- Соберет архив проекта
- Создаст базовый `LiveContainer.ipa`
- Интегрирует SideStore
- Создаст `LiveContainer+SideStore.ipa`

## Альтернативный способ (через Xcode GUI)

1. Откройте `LiveContainer.xcodeproj` в Xcode
2. Выберите схему **LiveContainer**
3. Выберите конфигурацию **Release**
4. Выберите устройство или **Any iOS Device**
5. **Product → Archive**
6. После создания архива используйте скрипт для создания IPA с SideStore

## Требования

- macOS с установленным Xcode
- Apple Developer аккаунт (Team ID: 972MD5K36E)
- Интернет-соединение (для загрузки SideStore и инструментов)
- Homebrew (для установки `wget` и `ldid`, если не установлены)

## Примечания

- Team ID уже настроен в `xcconfigs/Global.xcconfig`
- Скрипт автоматически установит необходимые инструменты через Homebrew
- Финальный файл: `LiveContainer+SideStore.ipa`

