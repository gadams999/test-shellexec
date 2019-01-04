#!/usr/bin/env bash

{ # this ensures the entire script is downloaded #
# All commands expected to be run as normal user to take advantage of latest node in ec2-user

set -e

sudo yum install pwgen -y
npm install -g node-red
npm install -g node-red-admin
npm install -g node-red-dashboard
npm install -g bcryptjs-cli

openssl genrsa -out /home/ec2-user/node-key.pem 2048
openssl req -new -sha256 -key /home/ec2-user/node-key.pem -out /home/ec2-user/node.csr -subj "/C=US/ST=Washington/L=Seattle/CN=workshop-self-signed"
openssl x509 -req -in /home/ec2-user/node.csr -signkey /home/ec2-user/node-key.pem -out /home/ec2-user/node-cert.pem

/usr/bin/install -d -o ec2-user -g ec2-user -m 755 /home/ec2-user/.node-red

# replace with URLs from GitHub
#curl get settings.json to /home/ec2-user/.node-red/settings.json
#/usr/bin/curl https://s3.amazonaws.com/iotimmersiondaycontent/hol_files/hol_iot_connect_device.json > /home/ec2-user/.node-red/flows_nodered.json

cp /home/ec2-user/settings.js /home/ec2-user/.node-red/settings.js
cp /home/ec2-user/virtual_dispenser.json /home/ec2-user/.node-red/virtual_dispenser.json

# modify the settings file with a new password
NODEPW=`shuf -n1 /usr/share/dict/words | tr -d '\n'`
encrypted=$(bcryptjs $NODEPW)
sed -i "s~REPLACE_WITH_PASSWORD~$encrypted~g" /home/ec2-user/.node-red/settings.js 
MY_IP=$(curl -s ifconfig.co)


# Install supervisor
sudo pip install supervisor
sudo sh -c '/usr/local/bin/echo_supervisord_conf > /etc/supervisord.conf'
# Append config for node-red
sudo sh -c 'cat << EOF >> /etc/supervisord.conf
[program:nodered]
command=/home/ec2-user/.nvm/versions/node/v6.15.0/bin/node-red virtual_dispenser.json
directory=/home/ec2-user
autostart=true
autorestart=true
startretries=3
stderr_logfile=/home/ec2-user/nodered.err.log
stdout_logfile=/home/ec2-user/nodered.out.log
user=ec2-user
environment=HOME="/home/ec2-user",PATH="/home/ec2-user/.nvm/versions/node/v6.15.0/bin:$PATH"
EOF'

cat << 'EOF' >> supervisor
#!/bin/bash
#
# supervisor    Start/Stop the supervisor daemon.
#
# chkconfig: 345 90 10
# description:  Supervisor is a client/server system that allows its users to
#               monitor and control a number of processes on UNIX-like operating
#               systems.

. /etc/init.d/functions

DAEMON=/usr/local/bin/supervisord
PIDFILE=/var/run/supervisord.pid

[ -x "$DAEMON" ] || exit 0

start() {
        echo -n "Starting supervisord: "
        if [ -f $PIDFILE ]; then
                PID=`cat $PIDFILE`
                echo supervisord already running: $PID
                exit 2;
        else
                daemon  $DAEMON --pidfile $PIDFILE -c /etc/supervisord.conf -u ec2-user -d /home/ec2-user
                RETVAL=$?
                echo
                [ $RETVAL -eq 0 ] && touch /var/lock/subsys/supervisord
                return $RETVAL
        fi

}

stop() {
        echo -n "Shutting down supervisord: "
        echo
        killproc -p $PIDFILE supervisord
        echo
        rm -f /var/lock/subsys/supervisord
        return 0
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status supervisord
        ;;
    restart)
        stop
        start
        ;;
    *)
        echo "Usage:  {start|stop|status|restart}"
        exit 1
        ;;
esac
exit $?
EOF
# Setup supervisor to restart automatically
sudo mv supervisor /etc/init.d
sudo chmod +x /etc/init.d/supervisor
sudo chkconfig --add supervisor
sudo chkconfig supervisor on

# Map 443 to 1880 (Node-RED port running HTTPS)
# Add inbound for port 443 to the default security group on Cloud9
sudo /sbin/iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 1880
sudo /etc/init.d/iptables save
aws ec2 authorize-security-group-ingress --group-name $(curl -s http://169.254.169.254/latest/meta-data/security-groups) --protocol tcp --port 443 --cidr 0.0.0.0/0

echo "************* Copy and save these settings *************
                   Node-RED URL is: https://$MY_IP
                   Username is: admin
                   Password is: $NODEPW"

# Start service for first time interactive launch
# This will start Node-RED and load the virtual dispenser flows
sudo service supervisor start

} # this ensures the entire script is downloaded #
