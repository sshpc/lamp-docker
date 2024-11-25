# 使用 PHP  和 Apache 的基础镜像
#FROM php:7.4.33-apache
FROM php:5.6.36-apache

# 安装必要的 PHP 扩展
RUN docker-php-ext-install mysqli pdo pdo_mysql

# 安装redis
#RUN pecl install -y redis
#RUN docker-php-ext-enable redis

# 启用 Apache 模块
RUN a2enmod rewrite

# 设置工作目录
WORKDIR /var/www

# 复制本地的 PHP 配置文件（如果需要）
# COPY ./php.ini /usr/local/etc/php/
