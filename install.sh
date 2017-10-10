## Server Setup

apt-get install build-essential flex bison git
git clone https://github.com/VrayoSystems/vtrunkd.git
cd vtrunkd
./configure --prefix=
make
make install

## create a basic configuration file
cp ./vtrunkd.conf /etc/
nano /etc/vtrunkd.conf

## leave everything as is, just replace the default password "testpasswd" and save

## add the following lines to /etc/rc.local
iptables -t nat -A POSTROUTING -j MASQUERADE
vtrunkd -s -f /etc/vtrunkd.conf -P 6000

## and the following lines at the end of /etc/sysctl.conf
net.ipv4.ip_forward=1
kernel.shmmax = 300000000
kernel.shmall = 300000000

## restart to launch vtrunkd at port 6000 and enable packet forwarding
reboot


## Client Setup

##Compile vtrunkd

apt-get install build-essential flex bison git
git clone https://github.com/VrayoSystems/vtrunkd.git
cd vtrunkd
./configure --prefix=
make
make install

## add the following lines at the end of /etc/sysctl.conf
net.ipv4.ip_forward=1
kernel.shmmax = 300000000
kernel.shmall = 300000000


## add the following lines to /etc/rc.local
iptables -t nat -A POSTROUTING -j MASQUERADE

## add packet mark
ip rule add fwmark 0x1 lookup 101
ip rule add fwmark 0x2 lookup 102
ip rule add fwmark 0x3 lookup 103

## add routing rules
ip route add default dev lo table 101 metric 200
ip route add default dev lo table 102 metric 200
ip route add default dev lo table 103 metric 200

## Configure the interfaces

## add the following script to /opt/modem.sh
#!/bin/sh

while true; do
for IF in `ifconfig -a | grep rename | cut -d' ' -f1`; do
        WWID=`/devname2.sh`
        NAME=wwan$WWID
        ifconfig $IF down
        ip link set $IF name $NAME
        ifconfig $NAME 192.168.8.2 netmask 255.255.255.0
        ip route add default via 192.168.8.1 dev $NAME table 10$WWID metric 100
done
for IF in `ifconfig -a | grep eth | grep -v eth0 | cut -d' ' -f1`; do
        WWID=`/devname2.sh`
        NAME=wwan$WWID
        ifconfig $IF down
        ip link set $IF name $NAME
        ifconfig $NAME 192.168.8.2 netmask 255.255.255.0
        ip route add default via 192.168.8.1 dev $NAME table 10$WWID metric 100
done
if ! route -n | head -n1 | grep 10.0.0.1; then
route del default
fi
route add default gw 10.0.0.1 dev tun1
sleep 30
done

##and save

##use these commands to check if the modems are properly configured
ping -m 1 8.8.8.8 # will check modem 1
ping -m 2 8.8.8.8 # 2
ping -m 3 8.8.8.8 # 3

## Copy client vtrunkd config and change the password
cp ./vtrunkd_client.conf /etc/vtrunkd.conf
nano /etc/vtrunkd.conf

## Start vtrunkd for each modem 
vtrunkd -P 6000 -f /etc/vtrunkd.conf 000000_1 [server address]
vtrunkd -P 6000 -f /etc/vtrunkd.conf 000000_2 [server address]
vtrunkd -P 6000 -f /etc/vtrunkd.conf 000000_3 [server address]


## If you can see the interface tun1 appeared and can ping 10.0.0.1 then everyhing's ok
## Checkout http://www.yourownlinux.com/2013/07/how-to-configure-ubuntu-as-router.html if you want to use your board as actual router
## Make the rules permamnent by putting these following lines to /etc/rc.local

#!/bin/sh -e
iptables -t nat -A POSTROUTING -j MASQUERADE
ip rule add fwmark 0x1 lookup 101
ip rule add fwmark 0x2 lookup 102
ip rule add fwmark 0x3 lookup 103

ip route add default dev lo table 101 metric 200
ip route add default dev lo table 102 metric 200
ip route add default dev lo table 103 metric 200

# these lines are required for Raspberry Pi to run at full CPU clock
echo 1200000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo 1200000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

vtrunkd -P 6000 -f /etc/vtrunkd.conf 000000_1 [server address]
vtrunkd -P 6000 -f /etc/vtrunkd.conf 000000_2 [server address]
vtrunkd -P 6000 -f /etc/vtrunkd.conf 000000_3 [server address]

bash /opt/modem.sh &
exit 0


