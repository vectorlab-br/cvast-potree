# Our base image, for now, Ubuntu
FROM ubuntu:14.04

MAINTAINER Vincent Meijer "vmeijer@usf.edu"

# Environment variables
ENV INSTALL_DIR=/install

# Install dependencies
# Fix error for add-apt-repository: command not found
RUN apt-get update -y &&\
	apt-get install -y software-properties-common 

# Install Nginx.
RUN add-apt-repository -y ppa:nginx/stable &&\
	apt-get update -y &&\
	apt-get install -y nginx &&\
	rm -rf /var/lib/apt/lists/* &&\
	chown -R www-data:www-data /var/lib/nginx

WORKDIR ${INSTALL_DIR}  
RUN apt-get update -y &&\ 
	apt-get install -y python2.7 &&\
	apt-get install -y curl &&\
	curl -O https://bootstrap.pypa.io/get-pip.py &&\
	python2.7 get-pip.py &&\
	pip install awscli

# Config
RUN rm /etc/nginx/nginx.conf /etc/nginx/mime.types
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/mime.types /etc/nginx/mime.types
RUN mkdir /etc/nginx/ssl
COPY config/default /etc/nginx/sites-enabled/default
COPY config/default-ssl /etc/nginx/sites-available/default-ssl

# Copy content
COPY www /var/www

#Copy entrypoint script (to sync S3 bucket after deployment)
COPY entrypoint.sh ${INSTALL_DIR}/entrypoint.sh


# Expose both the HTTP (80) and HTTPS (443) ports
EXPOSE 80 443

# Define mountable directories.
VOLUME ["/var/log/nginx", "/var/www/potree/resources/pointclouds"]

# Define default command.
ENTRYPOINT ${INSTALL_DIR}/entrypoint.sh
