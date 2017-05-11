#!/bin/bash

# create my ssh key
if [ ! -f /root/ssh-key ]; then
    ssh-keygen -t rsa -N '' -f /root/ssh-key
fi

# add it to authorized_keys
cat /root/ssh-key.pub >> /host/root/.ssh/authorized_keys

# discover my host IP
myHostIP=`awk -f /root/Network-Interfaces-Script/readInterfaces.awk /host/interfaces device=eth0 | awk '{print $1;}'`
echo "i am running on ${myHostIP}"

myNetmask=`awk -f /root/Network-Interfaces-Script/readInterfaces.awk /host/interfaces device=eth0 | awk '{print $2;}'`

# reset host fingerprint
if [ -f /root/.ssh/known_hosts ]; then
    ssh-keygen -R ${myHostIP}
fi

mkdir -p /root/.ssh
touch /root/.ssh/known_hosts
ssh-keyscan -t rsa ${myHostIP} 1>> /root/.ssh/known_hosts

# get my gateway, which is my network address + 1
myNetworkAddr=`ipcalc -n ${myHostIP} ${myNetmask} | cut -d= -f2`

#convert to an int
_oct1=`echo ${myNetworkAddr} | cut -d. -f1 | xargs -I{} echo "{} * 256 * 256 * 256" | bc`
_oct2=`echo ${myNetworkAddr} | cut -d. -f2 | xargs -I{} echo "{} * 256 * 256" | bc`
_oct3=`echo ${myNetworkAddr} | cut -d. -f3 | xargs -I{} echo "{} * 256" | bc`
_oct4=`echo ${myNetworkAddr} | cut -d. -f4 | xargs -I{} echo "{}" | bc`
_gatewayOct=`echo "${_oct1} + ${_oct2} + ${_oct3} + ${_oct4} + 1" | bc`

_oct1=`echo ${_gatewayOct} | xargs -I{} echo "{} / 256 / 256 / 256 % 256" | bc`
_oct2=`echo ${_gatewayOct} | xargs -I{} echo "{} / 256 / 256 % 256" | bc`
_oct3=`echo ${_gatewayOct} | xargs -I{} echo "{} / 256 % 256" | bc`
_oct4=`echo ${_gatewayOct} | xargs -I{} echo "{} % 256" | bc`
_gatewayAddr=`echo "${_oct1}.${_oct2}.${_oct3}.${_oct4}"`

myRoutes=`cat /var/run/configmaps/static-routes/static-routes.json | jq '.routes | join (" ")' | sed -e 's/\"//g'`

while [ 1 -eq 1 ]; do
    # SSH to it and add my routes
    for _route in ${myRoutes}; do
        echo "Adding route ${_route} via ${_gatewayAddr}"
        ssh -i /root/ssh-key root@${myHostIP} "ip route add ${_route} via ${_gatewayAddr}"
    done
    sleep 30
done
