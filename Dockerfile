﻿# syntax = docker/dockerfile:experimental

FROM mcr.microsoft.com/dotnet/sdk:6.0-alpine AS build
ARG RID=x64

WORKDIR /src
COPY ["JSDXTS.csproj", "./"]
RUN dotnet restore "JSDXTS.csproj"
COPY . .
WORKDIR "/src/"
RUN dotnet build "JSDXTS.csproj" -c Release -o /app/build
    
FROM build AS publish
RUN dotnet publish "JSDXTS.csproj" -c Release -o /app/publish \
    --arch $RID \
    --os alpine \
    --self-contained true \
    /p:PublishTrimmed=true \
    /p:PublishSingleFile=true

#https://m.imooc.com/article/316499
#https://docs.microsoft.com/zh-cn/dotnet/core/rid-catalog
#https://hub.docker.com/_/microsoft-dotnet-runtime-deps

ARG TARGETARCH
ARG TARGETVARIANT

FROM ${TARGETARCH}${TARGETVARIANT}/alpine:3 AS final
ARG version=0.0.0

LABEL version=${version}
LABEL name="js.189.cn-speedup"
LABEL url="https://hub.docker.com/repository/docker/lpyedge/js.189.cn-speedup"
LABEL email="lpyedge#163.com"

ENV TZ=Asia/Shanghai \
    # Configure web servers to bind to port 80 when present
    ASPNETCORE_URLS=http://+:80 \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Set the invariant mode since icu-libs isn't included (see https://github.com/dotnet/announcements/issues/20)
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true

#包安装源切换到阿里云
#修复alpine时区设置的问题
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories; \
    apk add --no-cache \
            ca-certificates \
            tzdata \
            # .NET Core dependencies
            krb5-libs \
            libgcc \
            libintl \
            libssl1.1 \
            libstdc++ \
            zlib

#复制编译完毕的程序
WORKDIR /app
COPY --from=publish /app/publish .

#进程状态检查
COPY healthcheck.sh .
RUN chmod -R 777 /app/healthcheck.sh
HEALTHCHECK --interval=15m --timeout=5s --start-period=30s CMD /app/healthcheck.sh JSDXTS

ENTRYPOINT ["/app/JSDXTS"]