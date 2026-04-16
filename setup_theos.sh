#!/bin/bash

# 设置Theos环境
export THEOS=${THEOS:-~/theos}

# 克隆Theos（如果不存在）
if [ ! -d "$THEOS" ]; then
    echo "Cloning Theos..."
    git clone --recursive https://github.com/theos/theos.git "$THEOS"
fi

# 下载SDK
if [ ! -d "$THEOS/sdks" ]; then
    echo "Downloading iPhone SDK..."
    mkdir -p "$THEOS/sdks"
    # 下载iPhoneOS SDK
    curl -L -o "$THEOS/sdks/iPhoneOS13.5.sdk.tar.xz" "https://github.com/theos/sdks/raw/master/iPhoneOS13.5.sdk.tar.xz"
    cd "$THEOS/sdks" && tar -xf iPhoneOS13.5.sdk.tar.xz && rm iPhoneOS13.5.sdk.tar.xz
fi

echo "Theos setup complete"