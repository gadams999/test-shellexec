#!/usr/bin/env bash

{ # this ensures the entire script is downloaded #
# All commands expected to be run as normal user to take advantage of latest node version in ec2-user account
# provided by Cloud9

nodered_install() {
# Function not indented to preserve multiline "cat" and "echo" statements
set -e
echo "dollar 1: $1"
disp_id=$1

echo "DISP_ID: $disp_id"
exit
echo "******************** Installing Node-RED and Virtual Drink Dispenser ********************"

echo "Installing operating system dependencies"
sudo yum install pwgen -y -q

echo "Installing NPM modules"
echo
echo "Installing NPM module Node-RED..."
npm set progress=false && npm install -g node-red --silent > "/dev/null" 2>&1
echo "Installing NPM module Node-RED administration..."
npm set progress=false && npm install -g node-red-admin --silent > "/dev/null" 2>&1
echo "Installing NPM module Node-RED dashboard..."
npm set progress=false && npm install -g node-red-dashboard --silent > "/dev/null" 2>&1
echo "Installing NPM module bcrypt..."
npm set progress=false && npm install -g bcryptjs-cli --silent > "/dev/null" 2>&1

echo
echo "Generating self-signed certificate for HTTPS..."
openssl genrsa -out /home/ec2-user/node-key.pem 2048 > "/dev/null" 2>&1
openssl req -new -sha256 -key /home/ec2-user/node-key.pem -out /home/ec2-user/node.csr -subj "/C=US/ST=Washington/L=Seattle/CN=workshop-self-signed" > "/dev/null" 2>&1
openssl x509 -req -in /home/ec2-user/node.csr -signkey /home/ec2-user/node-key.pem -out /home/ec2-user/node-cert.pem > "/dev/null" 2>&1

/usr/bin/install -d -o ec2-user -g ec2-user -m 755 /home/ec2-user/.node-red

# TODO: replace with URLs from GitHub
echo "Copying template file for Node-RED and Virtual Drink Dispenser..."
/usr/bin/curl -s https://raw.githubusercontent.com/gadams999/test-shellexec/master/settings.js > /home/ec2-user/.node-red/settings.js
/usr/bin/curl -s https://raw.githubusercontent.com/gadams999/test-shellexec/master/virtual_dispenser.json > /home/ec2-user/.node-red/virtual_dispenser.json

# Modify flows file with dispenser Id
/bin/sed i "s/DISP_ID/$disp_id/g" /home/ec2-user/.node-red/virtual_dispenser.json

# modify the settings file with a new password
NODEPW=`shuf -n1 /usr/share/dict/words | tr -d '\n'`
encrypted=$(bcryptjs $NODEPW)
sed -i "s~REPLACE_WITH_PASSWORD~$encrypted~g" /home/ec2-user/.node-red/settings.js 
MY_IP=$(curl -s ifconfig.co)


# Install supervisor
echo "Installing supervisord and setting Node-RED to auto-start..."
sudo pip install -q supervisor
sudo sh -c '/usr/local/bin/echo_supervisord_conf > /etc/supervisord.conf'
# Append config for node-red
sudo sh -c 'cat << EOF >> /etc/supervisord.conf
[program:nodered]
command=$NVM_BIN/node-red virtual_dispenser.json
directory=/home/ec2-user
autostart=true
autorestart=true
startretries=3
stderr_logfile=/home/ec2-user/nodered.err.log
stdout_logfile=/home/ec2-user/nodered.out.log
user=ec2-user
environment=HOME="/home/ec2-user",PATH="$NVM_BIN:$PATH"
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
echo "Creating iptables/security group entries to allow in port 443 to Node-RED..."
sudo /sbin/iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 1880
sudo /etc/init.d/iptables save
aws ec2 authorize-security-group-ingress --group-name $(curl -s http://169.254.169.254/latest/meta-data/security-groups) --protocol tcp --port 443 --cidr 0.0.0.0/0

# Start service for first time interactive launch
# This will start Node-RED and load the virtual dispenser flows
echo "Start supervisord which will start Node-RED and the Virtual Drink Dispenser"
sudo service supervisor start

echo
echo
echo
echo
echo "********************** Your virtual dispenser is now ready for use **********************"
echo "***************************** Copy and save these settings ******************************"
echo "
                        Node-RED URL is: https://$MY_IP
                        Username is: admin
                        Password is: $NODEPW"
echo
echo
}

# BEGIN interpret - above is called only if script is executed on a Cloud9 instance

if [ -n "$C9_PROJECT" ]
then
    if [ $# -eq 0 ]
    then
        echo
        echo
        echo "No arguments supplied, you must provide the dispenser ID at the end of the curl line"
        exit 1
    else
        echo "argumnets: $@"
    fi
    nodered_install $1
else
    echo "Installation only works from AWS Cloud9 Instance"
fi

} # this ensures the entire script is downloaded #
