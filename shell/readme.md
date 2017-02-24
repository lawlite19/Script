搭建自己的VPN
===========

### 一、首先租一个服务器
- 1、租一个香港的服务器，这里我选的按量付费，如果不使用了释放就可以了，按小时收费的，不过要求你账户上要多于`100`块钱。

- 2、操作系统选择的64位`CentOS6.5`，`CentOS7`以上下面的命令会有所不同。  
![enter description here][1]
- 3、创建成功后管理控制台会有公网和私网两个`ip`地址    
![enter description here][2]

### 二、配置VPN

- 1、安装`ppp`和`pptpd`:
```
    yum install ppp pptpd
```
- 2、配置`DNS`
`/etc/ppp/options.pptpd`文件中`的ms-dns`配置为：
```
    ms-dns 8.8.8.8
    ms-dns 8.8.4.4
```
- 3、配置`IP`
`/etc/pptpd.conf`文件中最后加入：
```
    localip 192.168.0.1
    remoteip 192.168.0.2-254
```
- 4、配置`VPN`用户名和密码
`/etc/ppp/chap-secrets`文件中加入：
```
    userName  pptpd  password  *
```
就是`userName`位置写上你的用户名`，password`位置写上你的密码
- 5、配置IP转发
`/etc/sysctl.conf`文件中`net.ipv4.ip_forward = 0`改为
```
    net.ipv4.ip_forward = 1
```
然后执行：`sysctl -p`使其生效

### 三、配置防火墙

- 1、加入防火墙规则
```
iptables -A INPUT -p TCP -i eth1 --dport  1723  --sport 1024:65534 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth1 -s 192.168.0.0/24 -j MASQUERADE
iptables -I FORWARD -p tcp --syn -i ppp+ -j TCPMSS --set-mss 1356
```

 - 注意这里指定的网卡是`eth1`，其对应外网的网卡，否则能够连上`VPN`，但是是访问不了外网的。
 - `VPN`默认的端口是`1723` 

- 2、保存防火墙配置，启动`pptpd`，让其开机自启动
```
service iptables save
service iptables restart
service pptpd start 
chkconfig pptpd on
```

### 四、测试

1、`window`或手机等连接

- 对应外网`IP`，设置的用户名和密码 

- 速度是可以的，   
![enter description here][3]

- 我也测试了一下国外的服务器，速度非常慢，还不如免费的`VPN`软件，

### 五、`shell`脚本

- 1、我写了一个简单的`shell`脚本放在了`github`上，`github`地址：https://github.com/lawlite19/Script

- 2、运行步骤如下：

 - 下载脚本：`wget https://raw.githubusercontent.com/lawlite19/Script/master/shell/vpn_setup.sh`
 - 添加执行权限：`chmod +x vpn_setup.sh`
 - 执行即可：`./vpn_setup.sh`
3、完整代码：
```
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
iptables -A INPUT -p TCP -i eth1 --dport  1723  --sport 1024:65534 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth1 -s 192.168.0.0/24 -j MASQUERADE
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
```

### 六、总结

- 最初是在租了一个国外的服务器测试的，没有问题，但是后来租用香港的服务器就出现的了错误，同样的系统、同样的配置，后来查看内网绑定的是网卡eth0,外网绑定的是网卡`eth1`，而我防火墙里设置的是内网的网卡`eth0`。而国外的那个服务器只要一个网卡，所以没有问题。另外练练`shell`脚本。 


  [1]: ./images/vpn_setup_02.png "vpn_setup_02.png"
  [2]: ./images/vpn_setup_03.png "vpn_setup_03.png"
  [3]: ./images/vpn_setup_04.png "vpn_setup_04.png"