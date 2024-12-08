#!/usr/bin/env bash

# 设置版本号，如果用户提供了参数，则使用用户提供的版本号
version=${1:-'1.20.0'}

# 定义 APPDIR 和 PKGNAME
APPDIR="nginx-$version"
PKGNAME="nginx-$version"

# 获取 CPU 核心数
CPU_NUM=$(lscpu | awk -F: '/socket/{print $2}')

# 定义编译选项
MAKE_OPT="./configure --prefix=${APPDIR} \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_realip_module \
--with-http_stub_status_module \
--with-http_gzip_static_module \
--with-pcre \
--with-stream \
--with-stream_ssl_module \
--with-stream_realip_module"

# 安装依赖
_install_dependencies() {
    echo "安装依赖..."
    apt update
    apt install -y bison bison-dev zlib-dev libcurl-dev libarchive-dev boost-dev gcc gcc-c++ cmake ncurses-dev gnutls-dev libxml2-dev openssl-dev libevent-dev libaio-dev
    apt install -y vim lrzsz tree screen psmisc lsof tcpdump wget ntpdate gcc gcc-c++ glibc glibc-dev pcre pcre-dev openssl openssl-dev systemd-dev net-tools iotop bc zip unzip zlib-dev bash-completion nfs-utils automake libxml2 libxml2-dev libxslt libxslt-dev perl perl-ExtUtils-Embed
}

# 编译和安装 Nginx
_compile_and_install_nginx() {
    echo "编译和安装 Nginx..."
    wget -c "http://nginx.org/download/${PKGNAME}.tar.gz" || { echo "下载失败"; exit 1; }
    tar xf ${PKGNAME}.tar.gz
    cd ${PKGNAME} && eval "${MAKE_OPT}" && make -j${CPU_NUM} && make install && tar Jcvf ${PKGNAME}.tar.xz $APPDIR
}

# 删除旧的发布版本
_delete_old_release() {
    echo "删除旧的发布版本..."
    gh release delete ${PKGNAME} -y || { echo "删除旧发布版本失败"; exit 1; }
}

# 创建新的发布版本
_create_new_release() {
    echo "创建新的发布版本..."
    gh release create ${PKGNAME} ./*.tar.xz --title "${PKGNAME}" --notes "this is a make nginx release" || { echo "创建新发布版本失败"; exit 1; }
}

# 主函数
_main() {
    _install_dependencies
    _compile_and_install_nginx
    _delete_old_release
    _create_new_release
    echo "Nginx ${version} 安装完成。"
}

# 执行主函数
_main "$@"
