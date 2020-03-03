rm -rf /tmp && \
cp -Lr /var/config/actual/* /opt/webapps/config/ && \
cp -ar /opt/webapps/public/. /var/www/ && \
cp -Lr /var/lib/initializers/* /opt/webapps/config/initializers/
