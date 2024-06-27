# 使用基础镜像，这里选择ubuntu:20.04，因为它支持多平台
FROM --platform=$BUILDPLATFORM ubuntu:20.04

# 维护者信息
LABEL maintainer="chenjh <842761733@qq.com>"

# 设置工作目录
WORKDIR /app

# 复制字体文件到容器中
COPY fonts/* /usr/share/fonts/chinese/

# 使用多阶段构建来安装Java，以适应不同平台
# 使用托管在不同平台上的Java JDK下载链接
ARG JAVA_URL_LINUX_X64="https://example.com/path/to/server-jre-8u251-linux-x64.tar.gz"
ARG JAVA_URL_LINUX_ARM="https://example.com/path/to/server-jre-8u251-linux-arm.tar.gz"
ARG JAVA_URL_LINUX_ARM64="https://example.com/path/to/server-jre-8u251-linux-aarch64.tar.gz"

# 根据构建平台选择正确的Java JDK下载链接
RUN echo "deb [arch=amd64] https://mirrors.aliyun.com/ubuntu $(lsb_release -cs) main restricted" > /etc/apt/sources.list.d/aliyun.list && \
    echo "deb [arch=armhf] https://mirrors.aliyun.com/ubuntu $(lsb_release -cs) main restricted" >> /etc/apt/sources.list.d/aliyun.list && \
    echo "deb [arch=arm64] https://mirrors.aliyun.com/ubuntu $(lsb_release -cs) main restricted" >> /etc/apt/sources.list.d/aliyun.com.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends wget ca-certificates && \
    wget -O /tmp/server-jre.tar.gz $(case $BUILDPLATFORM in \
        "linux/amd64") echo "${JAVA_URL_LINUX_X64}" ;; \
        "linux/arm/v7") echo "${JAVA_URL_LINUX_ARM}" ;; \
        "linux/arm64") echo "${JAVA_URL_LINUX_ARM64}" ;; \
        *) echo "Unsupported platform"; exit 1 ;; esac) && \
    tar -xzf /tmp/server-jre.tar.gz -C /usr/local && \
    rm /tmp/server-jre.tar.gz && \
    apt-get purge -y --auto-remove wget ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 安装中文语言包和设置时区
RUN apt-get update && \
    apt-get install -y locales tzdata && \
    sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    export LANG=zh_CN.UTF-8 && \
    export LC_ALL=zh_CN.UTF-8 && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 安装字体和字体工具
RUN apt-get update && \
    apt-get install -y fontconfig && \
    fc-cache -f -v && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 将字体复制到字体目录并更新字体缓存
COPY --from=0 /usr/share/fonts/chinese/* /usr/share/fonts/chinese/
RUN mkfontscale && \
    mkfontdir && \
    fc-cache -fv

# 定义环境变量
ENV JAVA_HOME /usr/local/jdk1.8.0_251
ENV CLASSPATH "$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar"
ENV PATH "$PATH:$JAVA_HOME/bin"

# 定义默认命令
CMD ["/bin/bash"]
