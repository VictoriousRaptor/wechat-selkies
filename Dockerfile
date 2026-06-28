# WeChat for Linux using Selkies baseimage
FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

# Metadata labels
LABEL org.opencontainers.image.title="WeChat Selkies"
LABEL org.opencontainers.image.description="WeChat Linux client in browser via Selkies WebRTC"
LABEL org.opencontainers.image.authors="nickrunning"
LABEL org.opencontainers.image.source="https://github.com/nickrunning/wechat-selkies"
LABEL org.opencontainers.image.documentation="https://github.com/nickrunning/wechat-selkies#readme"
LABEL org.opencontainers.image.vendor="WeChat Selkies Project"
LABEL org.opencontainers.image.licenses="GPL-3.0-only"

# Build arguments for multi-arch support
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "🏗️ Building WeChat-Selkies on $BUILDPLATFORM, targeting $TARGETPLATFORM"

# Install required packages (Debian Trixie)
# Note: libgcc1 → libgcc-s1, libcups2 → libcups2t64, libgtk-3-0 → libgtk-3-0t64 (t64 ABI transition)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    chromium \
    chromium-l10n \
    desktop-file-utils \
    pcmanfm \
    fonts-noto-cjk \
    inotify-tools \
    tint2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcairo2 \
    libcups2t64 \
    libdbus-1-3 \
    libfontconfig1 \
    libgbm1 \
    libgcc-s1 \
    libgdk-pixbuf-2.0-0 \
    libglib2.0-0 \
    libgtk-3-0t64 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb-glx0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-render0 \
    libxcb-shape0 \
    libxcb-shm0 \
    libxcb-sync1 \
    libxcb-util1 \
    libxcb-xfixes0 \
    libxcb-xinerama0 \
    libxcb-xkb1 \
    libxcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxkbcommon-x11-0 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    shared-mime-info && \
    rm -rf /var/lib/apt/lists/*

# Install VA-API drivers for hardware video acceleration
# Debian Trixie non-free is already enabled in the base image
# intel-media-va-driver-non-free is amd64-only; vainfo is installed on all arches
RUN ARCH=$(dpkg --print-architecture) && \
    apt-get update && \
    if [ "$ARCH" = "amd64" ]; then \
        apt-get install -y --no-install-recommends intel-media-va-driver-non-free vainfo; \
    else \
        apt-get install -y --no-install-recommends vainfo; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# Install WeChat based on target architecture
RUN case "$TARGETPLATFORM" in \
    "linux/amd64") \
        WECHAT_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb"; \
        WECHAT_ARCH="x86_64" ;; \
    "linux/arm64") \
        WECHAT_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_arm64.deb"; \
        WECHAT_ARCH="arm64" ;; \
    *) \
        echo "❌ Unsupported platform: $TARGETPLATFORM" >&2; \
        echo "Supported platforms: linux/amd64, linux/arm64" >&2; \
        exit 1 ;; \
    esac && \
    echo "📦 Downloading WeChat for $WECHAT_ARCH architecture..." && \
    curl -fsSL --retry 3 --retry-delay 10 --retry-all-errors -o wechat.deb "$WECHAT_URL" && \
    echo "🔧 Installing WeChat..." && \
    (dpkg -i wechat.deb || (apt-get update && apt-get install -f -y && dpkg -i wechat.deb)) && \
    rm -f wechat.deb && \
    echo "✅ WeChat installation completed for $WECHAT_ARCH"

# Rename system chromium and set wrapper script as the new /usr/bin/chromium
RUN mv /usr/bin/chromium /usr/bin/chromium-real

# Install QQ based on target architecture (optional)
ARG INSTALL_QQ
RUN if [ "$INSTALL_QQ" = "true" ]; then \
        case "$TARGETPLATFORM" in \
        "linux/amd64") \
            QQ_URL="https://qqdl.gtimg.cn/qqfile/QQNT/9.9.31/release/00e6a3e7/QQ_3.2.29_260528_amd64_01.deb"; \
            QQ_ARCH="x86_64" ;; \
        "linux/arm64") \
            QQ_URL="https://qqdl.gtimg.cn/qqfile/QQNT/9.9.31/release/00e6a3e7/QQ_3.2.29_260528_arm64_01.deb"; \
            QQ_ARCH="arm64" ;; \
        *) \
            echo "❌ Unsupported platform: $TARGETPLATFORM" >&2; \
            exit 1 ;; \
        esac && \
        echo "📦 Downloading QQ for $QQ_ARCH architecture..." && \
        curl -fsSL --retry 3 --retry-delay 10 --retry-all-errors -o qq.deb "$QQ_URL" && \
        echo "🔧 Installing QQ..." && \
        (dpkg -i qq.deb || (apt-get update && apt-get install -f -y && dpkg -i qq.deb)) && \
        rm -f qq.deb && \
        echo "✅ QQ installation completed for $QQ_ARCH"; \
    else \
        echo "⏭️ Skipping QQ installation (INSTALL_QQ=$INSTALL_QQ)"; \
    fi

# Clean up
RUN apt-get purge -y --autoremove
RUN apt-get autoclean && \
    rm -rf \
        /config/.cache \
        /config/.npm \
        /usr/share/applications/tint2.desktop \
        /usr/share/applications/tint2conf.desktop \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*

# set app name and environment
ENV TITLE="WeChat-Selkies"
ENV TZ="Asia/Shanghai"
ENV LC_ALL="zh_CN.UTF-8"
ENV AUTO_START_WECHAT="true"
ENV AUTO_START_QQ="false"
# Prevent auto-fullscreen in both X11 (Openbox) and Wayland (Labwc) modes
ENV NO_FULL="true"

# update favicon
RUN cp /usr/share/icons/hicolor/128x128/apps/wechat.png /usr/share/selkies/www/icon.png

# patch qq.desktop: add --no-sandbox so desktop icon click works
RUN if [ -f /usr/share/applications/qq.desktop ]; then \
        sed -i 's|^Exec=/opt/QQ/qq |Exec=/opt/QQ/qq --no-sandbox |' /usr/share/applications/qq.desktop; \
    fi

# add local files
COPY /root /

# ensure wrapper scripts are executable (Windows build hosts don't preserve execute bits)
RUN chmod +x /usr/bin/chromium
