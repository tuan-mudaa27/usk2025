#!/bin/bash

echo "===================================================="
echo " INSTALL DNS, LAMP, SAMBA, MAIL, dan CACTI SERVER DEBAIN 12"
echo "===================================================="

# Input domain
echo "----------------------------------------------------"
echo " DOMAIN 1 dan DOMAIN 2"
echo "----------------------------------------------------"
read -p "Masukkan Domain 1 - usk-smk[NIS] (contoh: usk-smk13930.net): " DOMAIN1
read -p "Masukkan Domain 2 - linux[NIS] (contoh: linux13930.my.id): " DOMAIN2

# Input subdomain mail server
echo "----------------------------------------------------"
echo " SUBDOMAIN"
echo "----------------------------------------------------"
read -p "Masukkan Subdomain CCTV - cctv, ipcamera, atau lainnya (contoh: cctv): " SUBDOMAINCCTV
read -p "Masukkan Subdomain Cacti Server - cacti, monitoring, atau lainnya (contoh: cacti): " SUBDOMAINCACTI
read -p "Masukkan Subdomain Mail Server - mail, webmail, atau lainnya (contoh: webmail): " SUBDOMAINMAIL
read -p "Masukkan Subdomain VoIP Server - voip, briker, atau lainnya (contoh: voip): " SUBDOMAINVOIP

# Input subdomain
echo "----------------------------------------------------"
echo " PILIH SUBDOMAIN UNTUK DOMAIN 1 ATAU DOMAIN 2"
echo "----------------------------------------------------"
read -p "Pilih subdomain $SUBDOMAINCCTV ingin dimasukkan ke $DOMAIN1 (domain 1) atau $DOMAIN2 (domain 2), (contoh: 1): " SUBCCTV
read -p "Pilih subdomain $SUBDOMAINCACTI ingin dimasukkan ke $DOMAIN1 (domain 1) atau $DOMAIN2 (domain 2), (contoh: 1): " SUBCACTI
read -p "Pilih subdomain $SUBDOMAINMAIL ingin dimasukkan ke $DOMAIN1 (domain 1) atau $DOMAIN2 (domain 2), (contoh: 2): " SUBWEBMAIL
read -p "Pilih subdomain $SUBDOMAINVOIP ingin dimasukkan ke $DOMAIN1  (domain 1) atau $DOMAIN2 (domain 2), (contoh: 1): " SUBVOIP

# Input ip address dan subnet mask
echo "----------------------------------------------------"
echo " IP ADDRESS dan NETWORK"
echo "----------------------------------------------------"
read -p "Masukkan IP Address (contoh: 172.16.33.133): " IPADDR
read -p "Masukkan Network (contoh: 172.16.33.128/25): " NETWORK

# Membalikkan IP
IFS='.' read -r i1 i2 i3 i4 <<< "$IPADDR"
REVERSED_IP="$i3.$i2.$i1"

# Update package lists
echo "----------------------------------------------------"
echo "Update package lists"
echo "----------------------------------------------------"
apt update

# Install BIND9 and DNS utilities
echo "----------------------------------------------------"
echo "Install BIND9 dan DNS utilities"
echo "----------------------------------------------------"
apt install bind9 dnsutils -y

DO1=$(echo "$DOMAIN1" | cut -d '.' -f 1)
DO2=$(echo "$DOMAIN2" | cut -d '.' -f 1)

# Konfigurasi db.IP
cat > /etc/bind/db.$i1 <<EOF
\$TTL    604800
;
; BIND reverse data file for local loopback interface
;
@       IN      SOA     $DOMAIN1. root.$DOMAIN1. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      $DOMAIN1.
$i4       IN      PTR     $DOMAIN1.
$i4       IN      PTR     $DOMAIN2.
$i4       IN      PTR     www.$DOMAIN1.
$i4       IN      PTR     www.$DOMAIN2.
EOF

# Tambahkan PTR untuk subdomain berdasarkan pilihan pengguna
if [ "$SUBCCTV" == "1" ]; then
    echo "$i4       IN      PTR     $SUBDOMAINCCTV.$DOMAIN1." >> /etc/bind/db.$i1
else
    echo "$i4       IN      PTR     $SUBDOMAINCCTV.$DOMAIN2." >> /etc/bind/db.$i1
fi

if [ "$SUBCACTI" == "1" ]; then
    echo "$i4       IN      PTR     $SUBDOMAINCACTI.$DOMAIN1." >> /etc/bind/db.$i1
else
    echo "$i4       IN      PTR     $SUBDOMAINCACTI.$DOMAIN2." >> /etc/bind/db.$i1
fi

if [ "$SUBWEBMAIL" == "1" ]; then
    echo "$i4       IN      PTR     $SUBDOMAINMAIL.$DOMAIN1." >> /etc/bind/db.$i1
else
    echo "$i4       IN      PTR     $SUBDOMAINMAIL.$DOMAIN2." >> /etc/bind/db.$i1
fi

if [ "$SUBVOIP" == "1" ]; then
    echo "$i4       IN      PTR     $SUBDOMAINVOIP.$DOMAIN1." >> /etc/bind/db.$i1
else
    echo "$i4       IN      PTR     $SUBDOMAINVOIP.$DOMAIN2." >> /etc/bind/db.$i1
fi

# Konfigurasi db.domain 1
cat > /etc/bind/db.$DO1 <<EOF
\$TTL    604800
;
; BIND data file for local loopback interface
;
@       IN      SOA     $DOMAIN1. root.$DOMAIN1. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      $DOMAIN1.
@       IN      A       $IPADDR
www     IN      A       $IPADDR
EOF

# Tambahkan subdomain ke domain 1 atau domain 2 berdasarkan pilihan pengguna
if [ "$SUBCCTV" == "1" ]; then
    echo "$SUBDOMAINCCTV     IN      A       $IPADDR" >> /etc/bind/db.$DO1
fi

if [ "$SUBCACTI" == "1" ]; then
    echo "$SUBDOMAINCACTI    IN      A       $IPADDR" >> /etc/bind/db.$DO1
fi

if [ "$SUBWEBMAIL" == "1" ]; then
    echo "$SUBDOMAINMAIL  IN      A       $IPADDR" >> /etc/bind/db.$DO1
    echo "$DOMAIN1. IN      MX      10      $SUBDOMAINMAIL.$DOMAIN1." >> /etc/bind/db.$DO1
fi

if [ "$SUBVOIP" == "1" ]; then
    echo "$SUBDOMAINVOIP     IN      A       $IPADDR" >> /etc/bind/db.$DO1
    echo "_sip._udp.$SUBDOMAINVOIP.$DOMAIN1.     86400       IN      SRV     10      5       5060        $SUBDOMAINVOIP.$DOMAIN1." >> /etc/bind/db.$DO1
fi

# Konfigurasi db.domain 2
cat > /etc/bind/db.$DO2 <<EOF
\$TTL    604800
;
; BIND data file for local loopback interface
;
@       IN      SOA     $DOMAIN2. root.$DOMAIN2. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      $DOMAIN2.
@       IN      A       $IPADDR
www     IN      A       $IPADDR
EOF

# Tambahkan subdomain ke domain 1 atau domain 2 berdasarkan pilihan pengguna
if [ "$SUBCCTV" == "2" ]; then
    echo "$SUBDOMAINCCTV     IN      A       $IPADDR" >> /etc/bind/db.$DO2
fi

if [ "$SUBCACTI" == "2" ]; then
    echo "$SUBDOMAINCACTI    IN      A       $IPADDR" >> /etc/bind/db.$DO2
fi

if [ "$SUBWEBMAIL" == "2" ]; then
    echo "$SUBDOMAINMAIL  IN      A       $IPADDR" >> /etc/bind/db.$DO2
    echo "$DOMAIN2. IN      MX      10      $SUBDOMAINMAIL.$DOMAIN2." >> /etc/bind/db.$DO2
fi

if [ "$SUBVOIP" == "2" ]; then
    echo "$SUBDOMAINVOIP     IN      A       $IPADDR" >> /etc/bind/db.$DO2
    echo "_sip._udp.$SUBDOMAINVOIP.$DOMAIN2.     86400       IN      SRV     10      5       5060        $SUBDOMAINVOIP.$DOMAIN2." >> /etc/bind/db.$DO2
fi

# Konfigurasi named.conf.local
cat > /etc/bind/named.conf.local <<EOF
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
// include "/etc/bind/zones.rfc1918";

zone "$DOMAIN1" {
        type master;
        file "/etc/bind/db.$DO1";
};

zone "$DOMAIN2" {
        type master;
        file "/etc/bind/db.$DO2";
};

zone "$REVERSED_IP.in-addr.arpa" {
        type master;
        file "/etc/bind/db.$i1";
};
EOF

# Konfigurasi named.conf.options
cat > /etc/bind/named.conf.options <<EOF
options {
        directory "/var/cache/bind";

        // If there is a firewall between you and nameservers you want
        // to talk to, you may need to fix the firewall to allow multiple
        // ports to talk. See http://www.kb.cert.org/vuls/id/800113

        // If your ISP provided one or more IP addresses for stable
        // nameservers, you probably want to use them as forwarders.
        // Uncomment the following block, and insert the addresses replacing
        // the all-0's placeholder.

        allow-query { 127.0.0.1; $NETWORK; };

        forwarders {
                8.8.8.8;
                8.8.4.4;
        };

        recursion yes;
        forward only;

        //========================================================================
        // If BIND logs error messages about the root key being expired,
        // you will need to update your keys.  See https://www.isc.org/bind-keys
        //========================================================================

        dnssec-validation no;

        listen-on-v6 { none; };
};
EOF

# Konfigurasi resolv.conf
sed -i 's/^nameserver/#nameserver/g' /etc/resolv.conf
echo "nameserver $IPADDR" >> /etc/resolv.conf

# Restart dan cek status BIND9
echo "----------------------------------------------------"
echo "Restart dan cek status BIND9"
echo "----------------------------------------------------"
systemctl restart bind9
systemctl status bind9

# Uji konfigurasi dengan nslookup
echo "----------------------------------------------------"
echo "Uji konfigurasi dengan nslookup"
echo "----------------------------------------------------"
nslookup www.$DOMAIN1
nslookup www.$DOMAIN2

# Install LAMP Stack
echo "----------------------------------------------------"
echo "Install LAMP Stack"
echo "----------------------------------------------------"
apt install apache2 php php-json php-mysql mariadb-server wget unzip expect -y

# Otomatis mysql_secure_installation menggunakan expect
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation

expect \"Enter current password for root (enter for none):\"
send \"\r\"

expect \"Switch to unix_socket authentication\"
send \"Y\r\"

expect \"Change the root password?\"
send \"Y\r\"

expect \"New password:\"
send \"antix\r\"

expect \"Re-enter new password:\"
send \"antix\r\"

expect \"Remove anonymous users?\"
send \"Y\r\"

expect \"Disallow root login remotely?\"
send \"Y\r\"

expect \"Remove test database and access to it?\"
send \"Y\r\"

expect \"Reload privilege tables now?\"
send \"Y\r\"

expect eof
")

echo "$SECURE_MYSQL"

DB1=$(echo "$DOMAIN1" | sed 's/-/_/g' | cut -d '.' -f 1)
DB2=$(echo "$DOMAIN2" | sed 's/-/_/g' | cut -d '.' -f 1)

# Buat database untuk domain 1
mysql -u root -pantix -e "CREATE DATABASE $DB1;"

# Buat database untuk domain 2
mysql -u root -pantix -e "CREATE DATABASE $DB2;"

# Download dan Install WordPress untuk domain 1
wget https://wordpress.org/latest.zip
unzip latest.zip
chmod -R 777 wordpress
mkdir /var/www/$DO1
mv wordpress/ /var/www/$DO1/

# Download dan Install WordPress untuk domain 2
unzip latest.zip
chmod -R 777 wordpress
mkdir /var/www/$DO2
mv wordpress/ /var/www/$DO2/

# Konfigurasi Apache untuk domain 1
cat > /etc/apache2/sites-available/www$DO1.conf <<EOF
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        ServerName www.$DOMAIN1

        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/$DO1/wordpress

        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        # LogLevel info ssl:warn

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined

        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        # Include conf-available/serve-cgi-bin.conf
</VirtualHost>
EOF

cat > /etc/apache2/sites-available/$DO1.conf <<EOF
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that  
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        ServerName $DOMAIN1

        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/$DO1/wordpress

        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        # LogLevel info ssl:warn

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined

        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        # Include conf-available/serve-cgi-bin.conf
</VirtualHost>
EOF

# Konfigurasi Apache untuk domain 2
cat > /etc/apache2/sites-available/www$DO2.conf <<EOF
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that  
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        ServerName www.$DOMAIN2

        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/$DO2/wordpress

        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        # LogLevel info ssl:warn

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined

        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        # Include conf-available/serve-cgi-bin.conf
</VirtualHost>
EOF

cat > /etc/apache2/sites-available/$DO2.conf <<EOF
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that  
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        ServerName $DOMAIN2

        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/$DO2/wordpress

        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        # LogLevel info ssl:warn

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined

        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        # Include conf-available/serve-cgi-bin.conf
</VirtualHost>
EOF

# Aktifkan konfigurasi situs
a2ensite www$DO1.conf
a2ensite $DO1.conf
a2ensite www$DO2.conf
a2ensite $DO2.conf

# Nonaktifkan situs default
a2dissite 000-default.conf

# Set konfigurasi otomatis untuk phpMyAdmin
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password antix" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password antix" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password antix" | debconf-set-selections

# Install phpMyAdmin
echo "----------------------------------------------------"
echo "Install phpMyAdmin"
echo "----------------------------------------------------"
apt install phpmyadmin -y

# Restart dan cek status Apache
echo "----------------------------------------------------"
echo "Restart dan cek status Apache"
echo "----------------------------------------------------"
systemctl restart apache2
systemctl status apache2

# Install Samba Server
echo "----------------------------------------------------"
echo "Install Samba Server"
echo "----------------------------------------------------"
apt install samba samba-client -y

# Input user dan nama folder
echo "----------------------------------------------------"
echo "Konfigurasi User dan Folder Samba"
echo "----------------------------------------------------"
read -p "Masukkan user untuk akses folder samba (contoh: samba-public): " USER_SAMBA
read -p "Masukkan nama folder untuk akses full sharing (baca dan tulis) (contoh: PUBLIC): " SHARING_FOLDER
read -p "Masukkan nama folder untuk akses read-only (hanya baca) (contoh: REPORT-PROJCET): " READONLY_FOLDER

# Buat user untuk akses folder Samba
/usr/sbin/useradd -rs /bin/false $USER_SAMBA

# Buat folder untuk user samba
mkdir /$SHARING_FOLDER
mkdir /$READONLY_FOLDER

# Set permission untuk folder samba
chown $USER_SAMBA /$SHARING_FOLDER
chown $USER_SAMBA /$READONLY_FOLDER
chmod u+rwx /$SHARING_FOLDER
chmod u+rx /$READONLY_FOLDER

# Konfigurasi Samba Server
cat >> /etc/samba/smb.conf <<EOF
[$SHARING_FOLDER]
    path = /$SHARING_FOLDER
    available = yes
    browsable = yes
    public = yes
    writable = yes
    force user = $USER_SAMBA

[$READONLY_FOLDER]
    path = /$READONLY_FOLDER
    available = yes
    browsable = yes
    public = yes
    writable = no
    force user = $USER_SAMBA
EOF

# Restart dan cek status Samba Server
echo "----------------------------------------------------"
echo "Restart dan cek status Samba Server"
echo "----------------------------------------------------"
systemctl restart smbd
systemctl status smbd

# Install Mail Server Postfix dan Dovecot
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "Install Mail Server Postfix dan dovecot"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
if [ "$SUBWEBMAIL" == "1" ]; then
    echo -e "\e[1;34mSaat ditanya System Mail Name, Masukkan $DOMAIN1\e[0m"
    echo -e "\e[1;34mSaat ditanya Other Destinations, Masukkan $DOMAIN1, $SUBDOMAINMAIL.$DOMAIN1, localhost\e[0m"
else
    echo -e "\e[1;34mSaat ditanya System Mail Name, Masukkan $DOMAIN2\e[0m"
    echo -e "\e[1;34mSaat ditanya Other Destinations, Masukkan $DOMAIN2, $SUBDOMAINMAIL.$DOMAIN2, localhost\e[0m"
fi
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
sleep 5
apt install postfix dovecot-imapd dovecot-pop3d -y

# Konfigurasi Postfix

# Edit /etc/postfix/main.cf
if [ "$SUBWEBMAIL" == "1" ]; then
    sed -i "s/^mydestination.*/mydestination = $DOMAIN1, $SUBDOMAINMAIL.$DOMAIN1, localhost/" /etc/postfix/main.cf
    sed -i "s/^myhostname.*/myhostname = $SUBDOMAINMAIL.$DOMAIN1/" /etc/postfix/main.cf
else
    sed -i "s/^mydestination.*/mydestination = $DOMAIN2, $SUBDOMAINMAIL.$DOMAIN2, localhost/" /etc/postfix/main.cf
    sed -i "s/^myhostname.*/myhostname = $SUBDOMAINMAIL.$DOMAIN2/" /etc/postfix/main.cf
fi
sed -i "s/^mynetworks.*/mynetworks = 127.0.0.0\/8 [::ffff:127.0.0.0]\/104 [::1]\/128 0.0.0.0\/0/" /etc/postfix/main.cf
sed -i "s/^inet_protocols.*/inet_protocols = ipv4/" /etc/postfix/main.cf

#tambahkan home_mailbox
echo "home_mailbox = Maildir/" >> /etc/postfix/main.cf

# Buat mail directory di /etc/skel
maildirmake.dovecot /etc/skel/Maildir

dpkg-reconfigure postfix

# Konfigurasi Dovecot

# Edit /etc/dovecot/dovecot.conf
sed -i 's/^#listen = .*/listen = */' /etc/dovecot/dovecot.conf

# Edit /etc/dovecot/conf.d/10-auth.conf
sed -i 's/^#disable_plaintext_auth = .*/disable_plaintext_auth = no/' /etc/dovecot/conf.d/10-auth.conf

# Edit /etc/dovecot/conf.d/10-mail.conf
sed -i '/^# *mail_location = maildir:~\/Maildir/s/^# *//' /etc/dovecot/conf.d/10-mail.conf
sed -i '/^mail_location = mbox:~\/mail:INBOX=\/var\/mail\/%u/s/^/#/' /etc/dovecot/conf.d/10-mail.conf

# Buat user untuk mail server
echo "----------------------------------------------------"
echo " User untuk Mail Sever"
echo "----------------------------------------------------"
read -p "Masukkan username 1 (contoh: vinic): " USER1_MAIL
read -p "Masukkan password 1 (contoh: vinic): " USER1_PASS
read -p "Masukkan username 2 (contoh: slamet): " USER2_MAIL
read -p "Masukkan password 2 (contoh: slamet): " USER2_PASS

adduser --disabled-password --gecos "" $USER1_MAIL
echo "$USER1_MAIL:$USER1_PASS" | chpasswd

adduser --disabled-password --gecos "" $USER2_MAIL
echo "$USER2_MAIL:$USER2_PASS" | chpasswd

# Restart dan cek status Postfix dan Dovecot
echo "----------------------------------------------------"
echo "Restart dan cek status Postfix dan Dovecot"
echo "----------------------------------------------------"
systemctl restart postfix dovecot
systemctl status postfix
systemctl status dovecot

# Install Roundcube
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "Install Roundcube"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "\e[1;34mSaat ditanya password MYSQL, Masukkan antix\e[0m"
echo -e "\e[1;34mSaat ditanya IMAP Server, Masukkan localhost:143\e[0m"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
sleep 5
apt install roundcube -y

# Konfigurasi Roundcube

# Edit /etc/roundcube/config.inc.php
if [ "$SUBWEBMAIL" == "1" ]; then
    sed -i "s/\$config\['imap_host'\].*/\$config\['imap_host'\] = \['$DOMAIN1:143'\];/" /etc/roundcube/config.inc.php
    sed -i "s/\$config\['smtp_host'\].*/\$config\['smtp_host'\] = '$DOMAIN1:25';/" /etc/roundcube/config.inc.php
else
    sed -i "s/\$config\['imap_host'\].*/\$config\['imap_host'\] = \['$DOMAIN2:143'\];/" /etc/roundcube/config.inc.php
    sed -i "s/\$config\['smtp_host'\].*/\$config\['smtp_host'\] = '$DOMAIN2:25';/" /etc/roundcube/config.inc.php
fi
sed -i "s/\$config\['smtp_user'\] = '%u';/\$config\['smtp_user'\] = '';/" /etc/roundcube/config.inc.php
sed -i "s/\$config\['smtp_pass'\] = '%p';/\$config\['smtp_pass'\] = '';/" /etc/roundcube/config.inc.php
if [ "$SUBWEBMAIL" == "1" ]; then
    sed -i "s/\$config\['product_name'\] = 'Roundcube Webmail';/\$config\['product_name'\] = 'Selamat datang di Webmail $DO1';/" /etc/roundcube/config.inc.php
else
    sed -i "s/\$config\['product_name'\] = 'Roundcube Webmail';/\$config\['product_name'\] = 'Selamat datang di Webmail $DO2';/" /etc/roundcube/config.inc.php
fi

dpkg-reconfigure roundcube-core

# Konfigurasi Apache untuk Mail Server
if [ "$SUBWEBMAIL" == "1" ]; then
cat > /etc/apache2/sites-available/$SUBDOMAINMAIL$DO1.conf <<EOF
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that  
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        ServerName $SUBDOMAINMAIL.$DOMAIN1

        ServerAdmin webmaster@localhost
        DocumentRoot /usr/share/roundcube

        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        # LogLevel info ssl:warn

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined

        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        # Include conf-available/serve-cgi-bin.conf
</VirtualHost>
EOF
else
cat > /etc/apache2/sites-available/$SUBDOMAINMAIL$DO2.conf <<EOF
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that  
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        ServerName $SUBDOMAINMAIL.$DOMAIN2

        ServerAdmin webmaster@localhost
        DocumentRoot /usr/share/roundcube

        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        # LogLevel info ssl:warn

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined

        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        # Include conf-available/serve-cgi-bin.conf
</VirtualHost>
EOF
fi

# Aktifkan konfigurasi situs
if [ "$SUBWEBMAIL" == "1" ]; then
    a2ensite $SUBDOMAINMAIL$DO1.conf
else
    a2ensite $SUBDOMAINMAIL$DO2.conf
fi

# Restart dan cek status Apache
echo "----------------------------------------------------"
echo "Restart dan cek status Apache"
echo "----------------------------------------------------"
systemctl restart apache2 
systemctl status apache2

# Limit attachment file 20 MB
echo "----------------------------------------------------"
echo "Limit attachment file"
echo "----------------------------------------------------"
read -p "Limit attachment file MB (contoh: 20): " LIMIT_FILE

# Edit /etc/php/8.2/apache2/php.ini
sed -i "s/^upload_max_filesize = .*/upload_max_filesize = ${LIMIT_FILE}M/" /etc/php/8.2/apache2/php.ini
sed -i "s/^post_max_size = .*/post_max_size = ${LIMIT_FILE}M/" /etc/php/8.2/apache2/php.ini

# tambahkan message_size_limit
echo "message_size_limit = ${LIMIT_FILE}480000" >> /etc/postfix/main.cf

# Restart dan cek status Apache, Postfix, dan Dovecot
echo "----------------------------------------------------"
echo "Restart dan cek status Apache, Postfix, dan Dovecot"
echo "----------------------------------------------------"
systemctl restart apache2 postfix dovecot
systemctl status apache2
systemctl status postfix
systemctl status dovecot

########## CACTI ########## CACTI ########## CACTI ########## CACTI ########## CACTI ########## 
########## CACTI ########## CACTI ########## CACTI ########## CACTI ########## CACTI ########## 
########## CACTI ########## CACTI ########## CACTI ########## CACTI ########## CACTI ##########

timedatectl set-timezone Asia/Jakarta
echo "----------------------------------------------------"
echo " update dan upgrade "
echo "----------------------------------------------------"
apt update && apt upgrade -y

echo "----------------------------------------------------"
echo "Install Paket pendukung Cacti"
echo "----------------------------------------------------"
apt install cron snmp snmpd php-snmp rrdtool librrds-perl unzip curl git gnupg2 -y

echo "----------------------------------------------------"
echo "Install LAMP Server"
echo "----------------------------------------------------"
apt install apache2 mariadb-server php php-mysql libapache2-mod-php php-xml php-ldap php-mbstring php-gd php-gmp php-intl -y

sed -i 's/memory_limit = 128M/memory_limit = 1024M/g' /etc/php/8.2/apache2/php.ini

sed -i 's/max_execution_time = 30/max_execution_time = 60/g' /etc/php/8.2/apache2/php.ini

sed -i 's/;date.timezone =/date.timezone = Asia\/Jakarta/g' /etc/php/8.2/apache2/php.ini

sed -i 's/memory_limit = 128M/memory_limit = 1024M/g' /etc/php/8.2/cli/php.ini

sed -i 's/max_execution_time = 30/max_execution_time = 60/g' /etc/php/8.2/cli/php.ini

sed -i 's/;date.timezone =/date.timezone = Asia\/Jakarta/g' /etc/php/8.2/cli/php.ini

systemctl restart apache2

sed -i 's/collation-server      = utf8mb4_general_ci/collation-server      = utf8mb4_unicode_ci/g' /etc/mysql/mariadb.conf.d/50-server.cnf

cat >> /etc/mysql/mariadb.conf.d/50-server.cnf << EOF
max_heap_table_size = 128M
tmp_table_size = 128M
join_buffer_size = 1M
innodb_file_format = Barracuda
innodb_large_prefix = 1
innodb_buffer_pool_size = 2048M
innodb_flush_log_at_timeout = 3
innodb_read_io_threads = 32
innodb_write_io_threads = 16
innodb_io_capacity = 5000
innodb_io_capacity_max = 10000
innodb_doublewrite = OFF
sort_buffer_size = 1M
EOF

systemctl restart mariadb

echo "----------------------------------------------------"
echo "  Nama Database  "
echo "----------------------------------------------------"

read -p "contoh cactidb: " namadb

mysqladmin -uroot create $namadb

echo "----------------------------------------------------"
echo "  Password Database  "
echo "----------------------------------------------------"

read -p "masukkan password untuk database, contoh cactidb: " passdb

mysql -uroot -e "grant all on $namadb.* to 'cactiuser'@'localhost' identified by '$passdb'"

mysql -uroot -e "flush privileges"

mysql mysql < /usr/share/mysql/mysql_test_data_timezone.sql

mysql -uroot -e "GRANT SELECT ON mysql.time_zone_name TO 'cactiuser'@'localhost'"

mysql -uroot -e "flush privileges"

rm -rf /var/www/html/index.html

wget http://repo.antix.or.id/other/cacti-latest.tar.gz --no-check-certificate

tar -zxvf cacti-latest.tar.gz

cp -a cacti-1*/. /var/www/html

chown -R www-data:www-data /var/www/html/

chmod -R 775 /var/www/html/

mysql $namadb < /var/www/html/cacti.sql

cp /var/www/html/include/config.php.dist /var/www/html/include/config.php

sed -i 's/database_default  = '\''cacti/database_default  = '\'''$namadb'/g' /var/www/html/include/config.php

sed -i 's/database_password = '\''cactiuser/database_password = '\'''$passdb'/g' /var/www/html/include/config.php

sed -i 's/url_path = '\''\/cacti/url_path = '\''/g' /var/www/html/include/config.php

touch /etc/cron.d/cacti
cat >> /etc/cron.d/cacti << EOF
*/5 * * * * www-data php /var/www/html/poller.php > /dev/null 2>&1
EOF

chmod +x /etc/cron.d/cacti

# Buat nama string untuk SNMP
echo "----------------------------------------------------"
echo " Buat nama string untuk SNMP"
echo "----------------------------------------------------"
read -p "Masukkan Community String (contoh: tkj): " COSTRING

# Konfigurasi SNMP
sed -i 's/^agentaddress[[:space:]]*127.0.0.1,\[::1\]/#agentaddress 127.0.0.1,[::1]/g' /etc/snmp/snmpd.conf
echo "agentaddress $IPADDR" >> /etc/snmp/snmpd.conf

sed -i 's/^rocommunity[[:space:]]*public[[:space:]]*default[[:space:]]*-V[[:space:]]*systemonly/#rocommunity public default -V systemonly/g' /etc/snmp/snmpd.conf
sed -i 's/^rocommunity6[[:space:]]*public[[:space:]]*default[[:space:]]*-V[[:space:]]*systemonly/#rocommunity6 public default -V systemonly/g' /etc/snmp/snmpd.conf

echo "rocommunity $COSTRING $IPADDR" >> /etc/snmp/snmpd.conf

# Restart dan cek status SNMP
echo "----------------------------------------------------"
echo "Restart dan cek status SNMP"
echo "----------------------------------------------------"
systemctl restart snmpd.service 
systemctl status snmpd.service

# Informasi device
snmpwalk -v2c -c $COSTRING $IPADDR

# Konfigurasi Apache untuk Cacti Server
if [ "$SUBCACTI" == "1" ]; then
cat > /etc/apache2/sites-available/cacti$DO1.conf <<EOF
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that  
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        ServerName $SUBDOMAINCACTI.$DOMAIN1

        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html

        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        # LogLevel info ssl:warn

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined

        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        # Include conf-available/serve-cgi-bin.conf
</VirtualHost>
EOF
else
cat > /etc/apache2/sites-available/cacti$DO2.conf <<EOF
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that  
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        ServerName $SUBDOMAINCACTI.$DOMAIN2

        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html

        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        # LogLevel info ssl:warn

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined

        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        # Include conf-available/serve-cgi-bin.conf
</VirtualHost>
EOF
fi

# Aktifkan konfigurasi situs
if [ "$SUBCACTI" == "1" ]; then
    a2ensite $SUBDOMAINCACTI$DO1.conf
else
    a2ensite $SUBDOMAINCACTI$DO2.conf
fi

# Restart dan cek status Apache
echo "----------------------------------------------------"
echo "Restart dan cek status Apache"
echo "----------------------------------------------------"
systemctl restart apache2 
systemctl status apache2

echo "===================================================="
echo -e "\e[1;31m+++++INFORMASI PENTING+++++\e[0m"
echo -e "\e[1;32mSilakan akses http://www.$DOMAIN1 dan http://www.$DOMAIN2\e[0m"
echo -e "\e[1;34mNama database untuk www.$DOMAIN1: $DB1 dan www.$DOMAIN2: $DB2\e[0m"
echo -e "\e[1;31mUser "root" dan Password "antix"\e[0m"
echo "Untuk Mengakses samba sharing folder di file explorer windows \\\\$IPADDR dan di file explorer MX Linux smb:\\\\$IPADDR"
if [ "$SUBWEBMAIL" == "1" ]; then
    echo -e "\e[1;31mhttp://$SUBDOMAINMAIL.$DOMAIN1 untuk mengakses Roundcube Webmail\e[0m"
else
    echo -e "\e[1;31mhttp://$SUBDOMAINMAIL.$DOMAIN2 untuk mengakses Roundcube Webmail\e[0m"
fi
echo -e "\e[1;32mUser mail 1: $USER1_MAIL dengan Password $USER1_PASS dan User mail 2: $USER2_MAIL dengan Password $USER2_PASS\e[0m"
echo "===================================================="
echo " Cacti terinstall di folder /var/www/html "
if [ "$SUBCACTI" == "1" ]; then
    echo " Silahkan lanjutkan login cacti melalui http://$SUBDOMAINCACTI.$DOMAIN1 "
else
    echo " Silahkan lanjutkan login cacti melalui http://$SUBDOMAINCACTI.$DOMAIN2 "
fi
echo " Username: admin dan password: admin "
echo " Community String: $COSTRING "
echo "===================================================="
echo -e "\e[1;32mJangan Lupa untuk mengganti DNS di PC/Laptop Menjadi $IPADDR\e[0m"
echo "===================================================="
echo -e "\e[1;34m+++++vinic+++++\e[0m"
echo "===================================================="