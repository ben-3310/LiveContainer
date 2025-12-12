#!/bin/bash

# Скрипт для настройки Xcode перед сборкой

echo "=== Настройка Xcode для сборки ==="

# Переключение на Xcode
if [ -d "/Applications/Xcode.app" ]; then
    echo "Переключение xcode-select на Xcode..."
    sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
    
    if [ $? -eq 0 ]; then
        echo "✓ xcode-select настроен"
    else
        echo "✗ Ошибка при переключении xcode-select"
        exit 1
    fi
else
    echo "✗ Xcode.app не найден в /Applications"
    exit 1
fi

# Принятие лицензии
echo "Принятие лицензии Xcode..."
sudo xcodebuild -license accept

if [ $? -eq 0 ]; then
    echo "✓ Лицензия принята"
else
    echo "✗ Ошибка при принятии лицензии"
    exit 1
fi

# Проверка версии
echo ""
echo "Версия Xcode:"
xcodebuild -version

echo ""
echo "✓ Xcode настроен и готов к использованию"
