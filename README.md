# Subscription Link Aggregator Setup Script

This script automates the installation and configuration of NGINX and PHP 8.3-FPM to serve a subscription link aggregator endpoint.
It merges subscription data fetched from two servers and returns a unified Base64-encoded subscription configuration.

## What This Script Does

- Installs and configures NGINX with SSL support and HTTP/2.
- Configures PHP 8.3 and PHP-FPM with necessary extensions.
- Creates an NGINX site config for your domain, handling SSL certificates and URI path rewriting.
- Creates a PHP endpoint (`sub.php`) that:
  - Accepts a subscription key parameter.
  - Fetches subscription data from two configured servers.
  - Merges and deduplicates the subscription data.
  - Returns the merged subscription as a Base64 string.

## Input Parameters Explained

During execution, the script will ask you for:

- **Main Domain**: The primary server domain (e.g., server-1-domain.ir).
- **Second Domain**: The secondary server domain to fetch subscriptions from (e.g., server-2-domain.ir).
- **Full Path to SSL Certificate**: The full path to your SSL certificate file (e.g., /root/cert/server-1-domain.ir/fullchain.pem).
- **Full Path to SSL Certificate Key**: The full path to your SSL private key (e.g., /root/cert/server-1-domain.ir/privkey.pem).
- **URI Path to Rewrite**: The URI path configured in your subscription panel (e.g., sub).
- **Subscription Port**: The port used by the subscription service internally (default is 2096).
- **Client Link Port**: The port exposed for clients to access the subscription aggregator (e.g., 2097).

## Important Notes (PLEASE READ CAREFULLY)

**If you have configurations on multiple servers, the subscription links must use the SAME URI path and subscription port across all servers.**

- The "Listen Port" (usually 2096) must be identical on both servers.
- The URI path (e.g., "sub") must be the same on both servers.
- This ensures the aggregator script can successfully fetch, merge, and serve combined subscription data.

Failure to keep these settings consistent will cause the aggregation to fail or return incomplete data.

## How to Use

1. Run this script on your main server.
2. Provide all requested input values correctly.
3. After completion, test your setup by accessing:

https://your-main-domain:CLIENT_LINK_PORT/URI_PATH/SUBSCRIPTION_KEY


Replace the placeholders with your values.

4. The PHP endpoint will fetch subscription data from both your main and secondary server subscription URLs, merge them, remove duplicates, and return a combined Base64-encoded subscription.

## Services Modified / Installed

- **NGINX**: Installed (if needed), enabled, and configured with SSL certificates and site configuration.
- **PHP 8.3 and PHP-FPM**: Installed and configured with required PHP extensions.
- The script also creates and sets permissions on `/var/www/html/sub.php`, the PHP endpoint handling subscription merges.

## Example

- Main domain: `server-1-domain.ir`
- Secondary domain: `server-2-domain.ir`
- URI Path: `sub`
- Subscription port: `2096`
- Client link port: `2097`
- Subscription key: `abc123`

Access the merged subscription at:

https://server-1-domain.ir:2097/sub/abc123

This will internally fetch and combine subscription data from:

https://server-1-domain.ir:2096/sub/abc123
https://server-2-domain.ir:2096/sub/abc123

and return the combined Base64 subscription to the client.

## Verification & Troubleshooting

- Check nginx and php-fpm services status:

systemctl status nginx php8.3-fpm


- Confirm SSL certificate and key paths are correct.
- Verify ports and URI paths are consistent across servers.
- Ensure firewall rules allow traffic on the ports you configured.
- Logs can help diagnose nginx or PHP errors.

---

Thank you for using this subscription aggregator setup script. If you encounter issues or have questions, please review your inputs carefully and ensure consistency across all involved servers.

---

*Enjoy a seamless and unified subscription management experience!*
