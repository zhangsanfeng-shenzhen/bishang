#/sbin/sh
sudo electron-cash daemon start
sudo electron-cash daemon load_wallet
sudo killall -9 nginx
sudo /etc/init.d/redis-server
sudo /usr/local/openresty/nginx/sbin/nginx -p `pwd`/ -c nginx.conf
