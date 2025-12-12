#!/bin/bash

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== LiveContainer+SideStore Build Script ===${NC}"

# Параметры
SCHEME="LiveContainer"
ARCHIVE_PATH="archive"
BUILD_CONFIG="Release"

# Проверка наличия необходимых инструментов
echo -e "${YELLOW}Проверка инструментов...${NC}"

# Определение пути к xcodebuild
XCODEBUILD=""
if [ -f "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild" ]; then
    XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
elif command -v xcodebuild &> /dev/null; then
    XCODEBUILD="xcodebuild"
else
    echo -e "${RED}Ошибка: xcodebuild не найден. Установите Xcode.${NC}"
    exit 1
fi

# Проверка лицензии Xcode
if ! $XCODEBUILD -version &> /dev/null; then
    echo -e "${YELLOW}Внимание: Необходимо принять лицензию Xcode.${NC}"
    echo -e "${YELLOW}Выполните: sudo xcodebuild -license accept${NC}"
    echo -e "${YELLOW}Или запустите: sudo $XCODEBUILD -license accept${NC}"
    read -p "Продолжить сборку? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Проверка Team ID
if [ -z "$TEAM_ID" ]; then
    echo -e "${YELLOW}Team ID не указан. Попытка получить из Xcode...${NC}"
    
    # Попытка получить Team ID из настроек проекта
    TEAM_ID=$($XCODEBUILD -showBuildSettings -project LiveContainer.xcodeproj -scheme "$SCHEME" -configuration "$BUILD_CONFIG" 2>/dev/null | grep "DEVELOPMENT_TEAM" | head -1 | sed 's/.*= *//' | xargs)
    
    if [ -z "$TEAM_ID" ] || [ "$TEAM_ID" = "AAAAA11111" ]; then
        echo -e "${YELLOW}Team ID не найден в настройках проекта.${NC}"
        echo -e "${YELLOW}Пожалуйста, введите ваш Team ID (10 символов):${NC}"
        read -p "Team ID: " TEAM_ID
        
        if [ -z "$TEAM_ID" ]; then
            echo -e "${RED}Ошибка: Team ID не указан.${NC}"
            echo -e "${YELLOW}Вы можете указать Team ID одним из способов:${NC}"
            echo "  1. Установите переменную окружения: export TEAM_ID=YOUR_TEAM_ID"
            echo "  2. Или отредактируйте xcconfigs/Global.xcconfig"
            echo "  3. Или введите его при запуске скрипта"
            exit 1
        fi
    fi
fi

echo -e "${GREEN}Используется Team ID: $TEAM_ID${NC}"

# Обновление Global.xcconfig если нужно
if [ ! -z "$TEAM_ID" ]; then
    echo -e "${YELLOW}Обновление Global.xcconfig...${NC}"
    sed -i '' "s/DEVELOPMENT_TEAM\[config=Debug\] = .*/DEVELOPMENT_TEAM[config=Debug] = $TEAM_ID/" xcconfigs/Global.xcconfig
    sed -i '' "s/DEVELOPMENT_TEAM\[config=Release\] = .*/DEVELOPMENT_TEAM[config=Release] = $TEAM_ID/" xcconfigs/Global.xcconfig
fi

# Очистка предыдущих сборок
echo -e "${YELLOW}Очистка предыдущих сборок...${NC}"
rm -rf "$ARCHIVE_PATH.xcarchive" Payload tmp "$SCHEME.ipa" "$SCHEME+SideStore.ipa"

# Сборка архива
echo -e "${YELLOW}Сборка архива...${NC}"

# Попытка найти доступный destination для iOS устройства
AVAILABLE_DEST=$($XCODEBUILD -showdestinations -project LiveContainer.xcodeproj -scheme "$SCHEME" 2>/dev/null | grep -E "platform:iOS.*arch:arm64.*id:" | grep -v "Simulator" | head -1)

if [ -z "$AVAILABLE_DEST" ]; then
    # Попытка использовать generic destination
    echo -e "${YELLOW}Устройство не найдено, используем generic destination...${NC}"
    DEST_PARAM="-destination 'generic/platform=iOS'"
else
    # Извлекаем id из destination
    DEST_ID=$(echo "$AVAILABLE_DEST" | grep -o "id:[^,}]*" | cut -d: -f2 | tr -d ' ')
    if [ ! -z "$DEST_ID" ]; then
        echo -e "${GREEN}Найдено устройство: $DEST_ID${NC}"
        DEST_PARAM="-destination 'id=$DEST_ID'"
    else
        echo -e "${YELLOW}Используем generic destination...${NC}"
        DEST_PARAM="-destination 'generic/platform=iOS'"
    fi
fi

# Сборка архива
$XCODEBUILD archive \
    -archivePath "$ARCHIVE_PATH" \
    -scheme "$SCHEME" \
    -project LiveContainer.xcodeproj \
    -configuration "$BUILD_CONFIG" \
    -destination "generic/platform=iOS" \
    CODE_SIGN_IDENTITY="Apple Development" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    -allowProvisioningUpdates \
    2>&1 | tee build.log || {
        echo -e "${RED}Ошибка при сборке. Проверьте build.log${NC}"
        if grep -q "not installed" build.log; then
            echo -e "${YELLOW}Требуется установить платформу iOS через Xcode > Settings > Components${NC}"
        fi
        exit 1
    }

# Проверка наличия архива
if [ ! -d "$ARCHIVE_PATH.xcarchive" ]; then
    echo -e "${RED}Ошибка: архив не создан${NC}"
    exit 1
fi

echo -e "${GREEN}Архив успешно создан${NC}"

# Подготовка Payload
echo -e "${YELLOW}Подготовка Payload...${NC}"
mv "$ARCHIVE_PATH.xcarchive/Products/Applications" Payload

# Создание временной директории
mkdir -p tmp

# Временно перемещаем SideStore.framework
if [ -d "Payload/LiveContainer.app/Frameworks/SideStore.framework" ]; then
    mv Payload/LiveContainer.app/Frameworks/SideStore.framework ./tmp
fi

# Создание базового IPA
echo -e "${YELLOW}Создание базового IPA...${NC}"
zip -r "$SCHEME.ipa" "Payload" -x "._*" -x ".DS_Store" -x "__MACOSX" > /dev/null

# Возвращаем SideStore.framework
if [ -d "./tmp/SideStore.framework" ]; then
    mv ./tmp/SideStore.framework Payload/LiveContainer.app/Frameworks
fi

# Проверка наличия необходимых инструментов для SideStore интеграции
echo -e "${YELLOW}Проверка инструментов для SideStore...${NC}"

if ! command -v wget &> /dev/null; then
    echo -e "${YELLOW}wget не найден, попытка установить через brew...${NC}"
    if command -v brew &> /dev/null; then
        brew install wget || echo -e "${YELLOW}Не удалось установить wget, пропускаем SideStore интеграцию${NC}"
    fi
fi

if ! command -v ldid &> /dev/null; then
    echo -e "${YELLOW}ldid не найден, попытка установить через brew...${NC}"
    if command -v brew &> /dev/null; then
        brew install ldid || echo -e "${RED}Не удалось установить ldid${NC}"
    fi
fi

# Интеграция SideStore
if command -v wget &> /dev/null && command -v ldid &> /dev/null; then
    echo -e "${YELLOW}Интеграция SideStore...${NC}"
    
    # Скачивание dylibify
    if [ ! -f "dylibify" ]; then
        wget -q https://github.com/LiveContainer/SideStore/releases/download/dylibify/dylibify
        chmod +x dylibify
    fi
    
    # Добавление SideStore ключей в Info.plist
    /usr/libexec/PlistBuddy -c 'Add :ALTAppGroups array' ./Payload/LiveContainer.app/Info.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c 'Add :ALTAppGroups: string group.com.SideStore.SideStore' ./Payload/LiveContainer.app/Info.plist 2>/dev/null || true
    
    # URL схемы
    /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:1 dict" ./Payload/LiveContainer.app/Info.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:1:CFBundleURLName string com.kdt.livecontainer.sidestoreurlscheme" ./Payload/LiveContainer.app/Info.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:1:CFBundleURLSchemes array" ./Payload/LiveContainer.app/Info.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:1:CFBundleURLSchemes:0 string sidestore" ./Payload/LiveContainer.app/Info.plist 2>/dev/null || true
    
    # Скачивание SideStore
    cd tmp
    if [ ! -f "SideStore.ipa" ]; then
        wget -q https://github.com/LiveContainer/SideStore/releases/download/nightly/SideStore.ipa
    fi
    unzip -q -o SideStore.ipa 2>/dev/null || true
    cd ..
    
    # Интеграция SideStore в приложение
    if [ -d "./tmp/Payload/SideStore.app" ]; then
        mkdir -p Payload/LiveContainer.app/Frameworks/SideStoreApp.framework
        mv ./tmp/Payload/SideStore.app/* Payload/LiveContainer.app/Frameworks/SideStoreApp.framework/ 2>/dev/null || true
        
        # Конвертация в dylib
        if [ -f "Payload/LiveContainer.app/Frameworks/SideStoreApp.framework/SideStore" ]; then
            ./dylibify Payload/LiveContainer.app/Frameworks/SideStoreApp.framework/SideStore Payload/LiveContainer.app/Frameworks/SideStoreApp.framework/SideStore.dylib 2>/dev/null || true
            rm -f Payload/LiveContainer.app/Frameworks/SideStoreApp.framework/SideStore
            mv Payload/LiveContainer.app/Frameworks/SideStoreApp.framework/SideStore.dylib Payload/LiveContainer.app/Frameworks/SideStoreApp.framework/SideStore 2>/dev/null || true
            ldid -S"" Payload/LiveContainer.app/Frameworks/SideStoreApp.framework/SideStore 2>/dev/null || true
        fi
    fi
    
    # Создание финального IPA с SideStore
    echo -e "${YELLOW}Создание LiveContainer+SideStore.ipa...${NC}"
    zip -r "$SCHEME+SideStore.ipa" "Payload" -x "._*" -x ".DS_Store" -x "__MACOSX" > /dev/null
    
    echo -e "${GREEN}✓ LiveContainer+SideStore.ipa создан${NC}"
else
    echo -e "${YELLOW}Инструменты для SideStore не найдены, создан только базовый IPA${NC}"
fi

echo -e "${GREEN}=== Сборка завершена ===${NC}"
echo -e "${GREEN}Созданные файлы:${NC}"
ls -lh "$SCHEME.ipa" "$SCHEME+SideStore.ipa" 2>/dev/null || ls -lh "$SCHEME.ipa"
