#!/bin/bash
set -e
# Most code taken from https://www.vultr.com/docs/add-brotli-support-to-nginx-on-ubuntu-18-04

# Install required dependencies
sudo apt install -y libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev build-essential

# Download NGINX
NGINX_VERSION="$(nginx -v 2>&1 | grep -o -E -e '[0-9]+.[0-9]+.[0-9]+')"
wget "https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz"
tar zxvf "nginx-$NGINX_VERSION.tar.gz"

# Download Brotli and install sub-modules
cd ~
git clone https://github.com/google/ngx_brotli
cd ngx_brotli
git submodule update --init

# Compile brotli as dynamic module for nginx
cd ../nginx-"$NGINX_VERSION"
./configure --with-compat --add-dynamic-module=../ngx_brotli
make modules

# Copy compiled module to nginx modules and update permissions
sudo cp objs/*.so /etc/nginx/modules
sudo chmod 644 /etc/nginx/modules/*.so

# Update nginx config
echo "
# Brotli modules
load_module modules/ngx_http_brotli_filter_module.so;
load_module modules/ngx_http_brotli_static_module.so;

$(cat /etc/nginx/nginx.conf)
" | sudo tee /etc/nginx/nginx.conf

# Test config and restart nginx
sudo nginx -t
sudo systemctl restart nginx

# Cleanup
sudo rm -rf ~/nginx-"$NGINX_VERSION" \
	~/nginx-"$NGINX_VERSION".tar.gz  \
	~/ngx_brotli

echo "
Done!
Add this to your server block:

	# Brotli
	brotli on;
	brotli_static on;
	brotli_comp_level 6;
	brotli_types text/plain text/css text/javascript application/javascript text/xml application/xml image/svg+xml application/json;
"
