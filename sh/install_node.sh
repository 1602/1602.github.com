#!/bin/bash
NODE_VERSION=0.3.1
NODE_FILE=node-v$NODE_VERSION
MY_USER=anatoliy
REDIS_VERSION=2.0.3

apt-get update
apt-get install -y build-essential git-core nginx libssl-dev pkg-config

wget http://nodejs.org/dist/$NODE_FILE.tar.gz
tar -zxvf $NODE_FILE.tar.gz
cd $NODE_FILE
./configure
make
make install
cd
rm -rf $NODE_FILE.tar.gz $NODE_FILE

sudo adduser \
    --system \
    --shell /bin/bash \
    --gecos 'User for running node.js projects' \
    --group \
    --disabled-password \
    --home /home/node \
    node_js

# Setup basic nginx proxy.
cat > /etc/nginx/sites-available/node_proxy.conf <<EOF
server {
    listen       80;
    # proxy to node
    location / {
        proxy_pass         http://127.0.0.1:1601/;
    }
}
EOF
ln -s /etc/nginx/sites-available/node_proxy.conf /etc/nginx/sites-enabled/node_proxy.conf
/etc/init.d/nginx restart

adduser --system --shell /bin/bash --group --disabled-password --home /home/$MY_USER $MY_USER

# install redis
wget http://redis.googlecode.com/files/redis-$REDIS_VERSION.tar.gz
tar xzvf redis-$REDIS_VERSION.tar.gz 
cd redis-$REDIS_VERSION
make
sudo make install

# run redis as service
cat > /etc/init/redis.conf <<EOF
  description "redis"

  start on startup
  stop on shutdown

  script
      # We found $HOME is needed. Without it, we ran into problems
      export HOME="/home/$MY_USER"

      cd /var/www/apps/boardgames/current
      exec sudo -u root sh -c "/usr/local/bin/redis-server >> /var/log/redis/redis.log 2>&1"
  end script
  respawn
EOF
mkdir -p /var/log/redis
start redis

# install npm
sudo chown -R $MY_USER /usr/local/{share/man,bin,lib/node}
cd
git clone http://github.com/isaacs/npm.git
cd npm/
make
make install
cd
rm -rf npm

# install npm packages
sudo -u $MY_USER sh -c "cd /home/$MY_USER && npm install redis express connect-redis socket.io jade"
