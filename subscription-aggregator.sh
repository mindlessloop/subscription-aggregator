#!/bin/bash

echo "="
echo "==="
echo "==="
echo "==="
echo "==="
echo "=== Hello Community :) ==="
echo "==="
echo "=== 1. Consider you are in \"server-1\" ==="
echo "==="
echo "=== 2. Keep default port of subscription link as it is: ==="
echo "=== Panel -> Panel Settings -> Subscriptions -> General -> Listen Port :: 2096 ==="
echo "==="
echo "=== 3. Also \"URI Path\" should be the same you entered in panel: ==="
echo "=== Panel -> Panel Settings -> Subscriptions -> General -> URI PATH ==="
echo "==="
echo "=== LETS BEGIN! ==="
echo "==="
echo "==="
echo "==="
echo "==="
echo "="
# === Ask user input ===
read -p "Enter main domain (e.g. server-1-domain.ir): " DOMAIN
read -p "Enter second domain (e.g. server-2-domain.ir): " SUBDOMAIN
read -p "Enter full path to ssl_certificate (e.g. /root/cert/server-1-domain.ir/fullchain.pem): " SSLCERT
read -p "Enter full path to ssl_certificate_key (e.g. /root/cert/server-1-domain.ir/privkey.pem): " SSLKEY
read -p "Enter URI path to rewrite (e.g. sub): " URIPATH
read -p "Enter subscription port (default 2096): " SUBPORT
read -p "Enter the port for client link (e.g. 2097): " PORT

# =========================================
# nginx setup
# =========================================
echo "="
echo "==="
echo "=== Updating and installing nginx ==="
echo "==="
echo "="
sudo apt update
sudo apt install nginx -y

echo "="
echo "==="
echo "=== Enabling and starting nginx ==="
echo "==="
echo "="
sudo systemctl enable nginx
sudo systemctl start nginx

echo "="
echo "==="
echo "=== Creating nginx config for $DOMAIN ==="
echo "==="
echo "="
sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null <<EOF
server {
    listen $PORT ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    root /var/www/html;
    index index.php index.html index.htm;

    ssl_certificate     $SSLCERT;
    ssl_certificate_key $SSLKEY;

    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ ^/$URIPATH/([a-zA-Z0-9]+)$ {
        # internally rewrite to sub.php with query parameter 'key'
        rewrite ^/$URIPATH/([a-zA-Z0-9]+)$ /sub.php?key=\$1 last;
    }

    location ~ /\.ht {
        deny all;
    }
}

server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$host\$request_uri;
}
EOF

echo "="
echo "==="
echo "=== Enabling site and reloading nginx ==="
echo "==="
echo "="
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

echo "="
echo "==="
echo "=== Adjusting certificate file permissions ==="
echo "==="
echo "="
chmod 644 $SSLCERT $SSLKEY
CERTDIR="/etc/ssl/$DOMAIN"
sudo mkdir -p \$CERTDIR
sudo cp $SSLCERT $SSLKEY \$CERTDIR/
sudo chmod 644 \$CERTDIR/*.pem

# =========================================
# PHP setup
# =========================================
echo "="
echo "==="
echo "=== Installing PHP 8.3 and extensions ==="
echo "==="
echo "="
sudo apt update
sudo apt install -y php8.3 php8.3-fpm php8.3-cli php8.3-mbstring php8.3-xml php8.3-curl php8.3-mysql php8.3-zip php8.3-gd

echo "="
echo "==="
echo "=== Enabling and starting PHP-FPM ==="
echo "==="
echo "="
sudo systemctl start php8.3-fpm
sudo systemctl enable php8.3-fpm

echo "="
echo "==="
echo "=== Preparing web root ==="
echo "==="
echo "="
sudo mkdir -p /var/www/html
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

echo "="
echo "==="
echo "=== Creating sub.php with embedded domain values ==="
echo "==="
echo "="
sudo tee /var/www/html/sub.php > /dev/null <<EOF
<?php
// Get the subscription key either from query parameter or path info
\$key = '';

// Try to get from query string first
if (!empty(\$_GET['key'])) {
    \$key = preg_replace('/[^a-zA-Z0-9]+/', '', \$_GET['key']); // sanitize key
} else {
    // Try to get from PATH_INFO (like /sub.php/juwhi2zs8qii2391)
    if (!empty(\$_SERVER['PATH_INFO'])) {
        \$pathInfo = trim(\$_SERVER['PATH_INFO'], '/');
        \$key = preg_replace('/[^a-zA-Z0-9]+/', '', \$pathInfo); // sanitize key
    }
}

if (empty(\$key)) {
    header("HTTP/1.1 400 Bad Request");
    echo "Missing or invalid subscription key.";
    exit;
}

\$url1 = "https://$DOMAIN:$SUBPORT/$URIPATH/{\$key}";
\$url2 = "https://$SUBDOMAIN:$SUBPORT/$URIPATH/{\$key}";

function fetchContent(\$url) {
    \$ch = curl_init();

    curl_setopt(\$ch, CURLOPT_URL, \$url);
    curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt(\$ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt(\$ch, CURLOPT_SSL_VERIFYHOST, false);
    curl_setopt(\$ch, CURLOPT_TIMEOUT, 10);

    \$result = curl_exec(\$ch);
    if (curl_errno(\$ch)) {
        \$result = false;
    }
    curl_close(\$ch);

    return \$result;
}

\$content1 = fetchContent(\$url1);
\$content2 = fetchContent(\$url2);

if (\$content1 === false) \$content1 = '';
if (\$content2 === false) \$content2 = '';

// Decode base64
\$decoded1 = base64_decode(\$content1);
\$decoded2 = base64_decode(\$content2);

// Split into lines (trim to avoid empty lines)
\$lines1 = array_filter(array_map('trim', explode("\n", \$decoded1)));
\$lines2 = array_filter(array_map('trim', explode("\n", \$decoded2)));

// Merge arrays, remove duplicates
\$mergedLines = array_unique(array_merge(\$lines1, \$lines2));

// Join lines with newline
\$mergedString = implode("\n", \$mergedLines);

// Encode merged string back to base64
\$mergedBase64 = base64_encode(\$mergedString);

// Output the base64 subscription
header('Content-Type: text/plain; charset=utf-8');
echo \$mergedBase64;
?>
EOF

echo "="
echo "==="
echo "=== Setting permissions ==="
echo "==="
echo "="
sudo chown www-data:www-data /var/www/html/sub.php
sudo chmod 644 /var/www/html/sub.php

echo "="
echo "==="
echo "=== Restarting services ==="
echo "==="
echo "="
systemctl restart nginx php*-fpm

echo "="
echo "==="
echo "==="
echo "==="
echo "==="
echo "=== You can check services by below command: ==="
echo "=== systemctl status nginx php8.3-fpm ==="
echo "==="
echo "=== How to test: ==="
echo "=== 1. set both configs SAME SUBSCRIPTION LINK in both servers ==="
echo "=== 2. Open a subscription link in your browser (it should show a config in base64) ==="
echo "=== 3. Only change the port to what you entered earlier. ==="
echo "=== Now if you open, it brings both configs of both servers ==="
echo "=== From now on if you want to provide a subscription link ==="
echo "=== just change the port and give the new link ==="
echo "=== enjoy ;) ==="
echo "==="
echo "==="
echo "==="
echo "==="
echo "="