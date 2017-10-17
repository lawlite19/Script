#!/bin/bash

# Author: Wang Yongzhi(bob)
# Date:   2016.11.16
echo -e "-----------------------------------------------"
echo -e "|                   Setup VPN...              |"
echo -e "-----------------------------------------------\n"

# Step 1:install ppp and pptpd

yum install -y ppp
yum install -y pptpd

if [ $? -eq 0 ]
then
	echo -e "install ppp and pptpd Success!\n"
else
	echo -e "Sorry! install ppp and pptpd Failed!\n"
	exit 0
fi

# Step 2:configure pptpd DNS
sed -i -e '/#ms-dns 10.0.0.1/a\ms-dns 8.8.8.8' /etc/ppp/options.pptpd
sed -i -e '/#ms-dns 10.0.0.2/a\ms-dns 8.8.4.4' /etc/ppp/options.pptpd

if [ $? -eq 0 ]
then
	echo -e "Configure DNS Success!\n"
else
	echo -e "Configure DNS Failed!\n"
	exit 0
fi


# Step 3:configure pptpd IP

echo  localip 192.168.0.1 >> /etc/pptpd.conf
echo  remoteip 192.168.0.2-254 >> /etc/pptpd.conf

if [ $? -eq 0 ]
then
	echo -e "Configure pptpd IP Success!\n"
else
	echo -e "Configure pptpd IP Failed!\n"
	exit 0
fi

# Step 4: configure VPN userName and password

while true
do
	read -p "Please input userName:" userName
	read -p "Please input passwd:  " Passwd
	echo $userName	pptpd	$Passwd \* >> /etc/ppp/chap-secrets
	read -p "continue?y/N:         " flag
	if [ $flag = "n" -o $flag = "N" ]
	then
		break
	fi
done


# Step 5: configure forwarding

sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf

if [ $? -eq 0 ]
then
	echo -e "Configure forwarding Success!\n"
else
	echo -e "Configure forwarding Failed\n"
	exit 0
fi

sysctl -p

# Step 6: configure iptables

#EXTIF=$(ifconfig | head -n 1 | grep -v lo | cut -d ' ' -f 1)
iptables -A INPUT -p TCP -i eth0 --dport  1723  --sport 1024:65534 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.0.0/24 -j MASQUERADE
iptables -I FORWARD -p tcp --syn -i ppp+ -j TCPMSS --set-mss 1356

# Step 7: configure when start server to start pptpd and iptables

service iptables save
service iptables restart
service pptpd start 
chkconfig pptpd on

echo -e "Complete! Now you can connect the VPN throuth your computer or phone!\n"

echo "                *****         *****"
echo "              *********     *********"
echo "            ************* *************"
echo "           *****************************"
echo "           *****************************"
echo "           *****************************"
echo "            ***************************"
echo "              ***********************"
echo "                *******************"
echo "                  ***************"
echo "                    ***********"
echo "                      *******"
echo "                        ***"
echo "                         *"

