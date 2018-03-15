#
# Docker instance showing a 389 instance with TLS and SSL enabled
# inspired by ioggstream/389ds and minkwe/389ds
#  
# docker build --rm --tag kdfischer/389ds .
   
FROM debian:buster
LABEL maintainer="Kasper D. Fischer <kasper.fischer@rub.de>"
VOLUME ["/etc/dirsrv", "/var/lib/dirsrv", "/var/log/dirsrv", "/certs"]

# install needed packages
RUN apt-get update && apt-get install -y \
        389-ds \
        curl \
        ldap-utils \
        supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# supervisord
COPY supervisord.conf /etc/supervisor/supervisord.conf

# confd
RUN curl -qL https://github.com/kelseyhightower/confd/releases/download/v0.15.0/confd-0.15.0-linux-amd64 -o /usr/local/bin/confd && \
    chmod +x /usr/local/bin/confd
COPY confd                  /etc/confd

# Disable SELINUX
#RUN rm -fr /usr/lib/systemd/system && \
#    sed -i 's/updateSelinuxPolicy($inf);//g' /usr/lib64/dirsrv/perl/* && \
#    sed -i '/if (@errs = startServer($inf))/,/}/d' /usr/lib64/dirsrv/perl/* 

# Move config to temporary location until volume is ready
RUN mkdir /etc/dirsrv-tmpl && mv /etc/dirsrv/* /etc/dirsrv-tmpl/

EXPOSE 389 636

# The 389-ds setup will fail because the hostname can't reliable be determined, 
# so we'll bypass it and then install.
#RUN sed -i 's/checkHostname {/checkHostname {\nreturn();/g' /usr/lib64/dirsrv/perl/DSUtil.pm 

# start 389-ds
COPY init-ssl.ldif /init-ssl.ldif
COPY run_server.sh /run_server.sh
COPY start.sh /start.sh
COPY dirsrv-dir /etc/systemctl/dirsrv-dir
	
CMD ["/start.sh"]
