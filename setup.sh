#!/bin/bash
set -e

# Ask user about the domain
echo 'Which domain should be used for the nginx config?'
read -r DOMAIN

# Update system
sudo apt update
sudo apt upgrade -y

# Install and configure nginx
# See https://www.techrepublic.com/article/how-to-install-the-latest-version-of-nginx-on-ubuntu-server-18-04/
cd ~

# Add repo
echo "deb [arch=amd64] http://nginx.org/packages/mainline/ubuntu/ bionic nginx
deb-src http://nginx.org/packages/mainline/ubuntu/ bionic nginx
" | sudo tee /etc/apt/sources.list.d/nginx.list

# Add nginx public key
wget https://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key
rm nginx_signing.key

# Update and install nginx
sudo apt update
sudo apt install nginx -y

# Install and launch certbot
sudo apt install software-properties-common -y
sudo add-apt-repository universe
sudo add-apt-repository ppa:certbot/certbot
sudo apt update
sudo apt install certbot python-certbot-nginx -y
sudo certbot certonly --nginx --cert-name "$DOMAIN"

# Nginx configuration
echo "$(cat <<EOL
server {
	listen 443 ssl http2 default_server;
	listen [::]:443 ssl http2 default_server;
	server_name $DOMAIN;
	client_max_body_size 0;

	location /ws {
		proxy_pass http://localhost:8080;
		proxy_http_version 1.1;
		proxy_set_header Host \$host;
		proxy_set_header Upgrade \$http_upgrade;
		proxy_set_header Connection "upgrade";
		proxy_read_timeout 86400;
	}

	location ~ ^/(file|stream|d) {
		proxy_buffering off;
		proxy_request_buffering off;
		proxy_pass http://localhost:8080\$request_uri;
	}

	location ~ (precache-manifest.*|service-worker|sw)\.js {
		add_header Cache-Control 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0';
		expires off;
		access_log off;
		root /home/ubuntu/beam.cafe.www;
	}

	location / {
		sendfile on;
		sendfile_max_chunk 1m;
		tcp_nopush on;
		autoindex off;
		index index.html;
		root /home/ubuntu/beam.cafe.www;
	}

	# Redirect on not-found / no-access
	location @400 {
		return 301 https://$host;
	}

	# Custom error pages
	error_page 404 403 = @400;

	# Restrict ssl protocols, ciphers
	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	ssl_ecdh_curve secp521r1:secp384r1;
	ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
	ssl_session_cache shared:SSL:5m;
	ssl_session_timeout 1h;

	# Hide upstream proxy headers
	proxy_hide_header X-Powered-By;
	proxy_hide_header X-AspNetMvc-Version;
	proxy_hide_header X-AspNet-Version;
	proxy_hide_header X-Drupal-Cache;

	# Custom headers
	add_header Strict-Transport-Security "max-age=63072000; includeSubdomains" always;
	add_header Referrer-Policy "no-referrer";
	add_header Feature-Policy "geolocation none; midi none; notifications none; push none; sync-xhr none; microphone none; camera none; magnetometer none; gyroscope none; speaker none; vibrate none; fullscreen self; payment none; usb none;";
	add_header X-XSS-Protection "1; mode=block" always;
	add_header X-Content-Type-Options "nosniff" always;
	add_header X-Frame-Options "SAMEORIGIN" always;
	add_header Content-Security-Policy "default-src wss://$DOMAIN 'self' data:;; script-src 'self' 'unsafe-eval'; style-src 'self' 'unsafe-inline' fonts.googleapis.com; base-uri 'self'; font-src 'self' fonts.gstatic.com; form-action 'none'; object-src 'none'; upgrade-insecure-requests; block-all-mixed-content;" always;

	# Close slow connections (in case of a slow loris attack)
	client_body_timeout 10s;
	client_header_timeout 10s;
	keepalive_timeout 5s 5s;
	send_timeout 10s;

	# SSL
	ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
	ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

	# Gzip fallback
	gzip on;
	gzip_vary on;
	gzip_min_length 10240;
	gzip_proxied expired no-cache no-store private auth;
	gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml;
}

server {
	listen 80;
	server_name $DOMAIN;

	if (\$host = $DOMAIN) {
		return 301 https://\$host\$request_uri;
	}

	return 404;
}
EOL
)" | sudo tee /etc/nginx/conf.d/"$DOMAIN".conf

# Enable and start nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Setup and enable firewall
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
echo "y" | sudo ufw enable

# Install node
cd ~
curl -sL https://deb.nodesource.com/setup_13.x | sudo bash
sudo apt install nodejs -y

# We're using pm2 as process manager
sudo npm install -g pm2

# Download both front / backend and install them
for path in 'beam.cafe' 'beam.cafe.backend'; do
	cd ~
	git clone "git@github.com:dot-cafe/${path}.git" --depth 1
	cd "$path"
	npm install
	npm run build
done

# Create www directory and copy frontend
cd ~
mkdir beam.cafe.www
mv beam.cafe/dist/* beam.cafe.www/

# Start api as pm2 process
pm2 start beam.cafe.backend/dist/src/app.js --name beam.cafe.backend

# Download utility scripts
echo 'Download utility scripts...'
curl -sS -o update.backend.sh https://raw.githubusercontent.com/dot-cafe/beam.cafe.sh/master/utils/update.backend.sh
curl -sS -o update.frontend.sh https://raw.githubusercontent.com/dot-cafe/beam.cafe.sh/master/utils/update.frontend.sh
echo 'Done!'
