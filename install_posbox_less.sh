# INSTALACIÓN DE POSBOXLESS EN UBUNTU 16.04 // ODOO V 9.0

#!/usr/bin/env bash

DEPENDENCIAS="cups adduser postgresql-client python python-dateutil python-decorator python-docutils python-feedparser python-imaging python-jinja2 python-ldap python-libxslt1 python-lxml python-mako python-mock python-openid python-passlib python-psutil python-psycopg2 python-babel python-pychart python-pydot python-pyparsing python-pypdf2 python-reportlab python-requests python-tz python-vatnumber python-vobject python-werkzeug python-xlwt python-yaml postgresql python-gevent python-serial python-pip python-dev localepurge vim mc mg screen iw hostapd isc-dhcp-server git rsync console-data"
apt-get -y install ${DEPENDENCIAS}

adduser --system --disabled-login pi #adduser pi -s /sbin/nologin -p 'raspberry'
mkdir /home/pi
cd /home/pi
git clone -b 9.0 --no-checkout --depth 1 https://github.com/odoo/odoo.git 
cd odoo
git config core.sparsecheckout true
echo "addons/web
addons/web_kanban
addons/hw_*
addons/point_of_sale/tools/posbox/configuration
openerp/
odoo.py" | tee --append .git/info/sparse-checkout > /dev/null
git read-tree -mu HEAD


pip install pyserial pyusb==1.0.0b1 qrcode evdev babel pypdf

groupadd usbusers
usermod -a -G usbusers pi
usermod -a -G lp pi
usermod -a -G lpadmin pi 

#Usuario de Postgress no funciona con pi
sudo -u postgres createuser -s root #sudo -u postgres createuser -s pi
mkdir /var/log/odoo
chown pi:pi /var/log/odoo

echo 'SUBSYSTEM=="usb", GROUP="usbusers", MODE="0660"
SUBSYSTEMS=="usb", GROUP="usbusers", MODE="0660"' > /etc/udev/rules.d/99-usbusers.rules

echo '[Unit]
Description=Odoo PosBoxLess
After=network.target

[Service]
Type=simple
User=pi
Group=pi
ExecStart=/home/pi/odoo/odoo.py --load=web,hw_proxy,hw_posbox_homepage,hw_posbox_upgrade,hw_scale,hw_scanner,hw_escpos
KillMode=mixed

[Install]
WantedBy=multi-user.target

' > /etc/systemd/system/posboxless.service

systemctl enable posboxless.service
systemctl start posboxless.service

echo -e "

 ******* SI EL POS NO SE ENCUENTRA DENTRO DE LA RED ******
 Identificar la red con ifconfig

 EDITAR  /home/pi/odoo/addons/point_of_sale/tools/posbox/configuration/wireless_ap.sh
 BUSCAR:
 WIRED_IP=$(ifconfig enp2s0 | grep "inet" | awk -F: '{print $2}' | awk '{print $1}';) 
 REEMPLAZAR "enp2s0" por el nombre de tu red, ej: wlo1

 EDITAR /home/pi/odoo/addons/hw_escpos/controllers/main.py
 BUSCAR:
 mac = subprocess.check_output('ifconfig | grep -B 1 \' inet addr \' | grep -o \'HWaddr .*\' | sed \'s/HWaddr //\'', shell=True).rstrip()
 ips =  [ c.split(':')[1].split(' ')[0] for c in commands.getoutput("/sbin/ifconfig").split('\n') if ' inet addr ' in c ]
 REEMPLAZAR: "inet addr" por "inet"


 CAMBIAR EL PUERTO DE LA INSTANCIA DE POSBOXLESS A 8070
 Editar el archivo /home/pi/odoo/openerp/tools/config.py     

 group.add_option("--xmlrpc-port", dest="xmlrpc_port", my_default=8069, 
       help="specify the TCP port for the XML-RPC protocol", type="int")


 ARRANCAR CON 
 sudo ./odoo.py --load=web,hw_proxy,hw_posbox_homepage,hw_posbox_upgrade,hw_scale,hw_scanner,hw_escpos

 Chequear que la impresora este encendida y conectada. 

 ********************************************************
 "