FROM ubuntu/nginx
# FROM ubuntu:16.04

# MAINTAINER Vincent Meijer "vmeijer@usf.edu" 

# Environment variables
ENV INSTALL_DIR=/docker
ENV POTREE_ROOT=/potree
ENV POTREE_CONVERTER_ROOT=${POTREE_ROOT}/potree_converter
ENV LASTOOLS_ROOT=${POTREE_ROOT}/lastools
ENV POINTCLOUD_INPUT_FOLDER=/pointcloud_input_folder

RUN mkdir ${POTREE_ROOT}
RUN mkdir ${POTREE_CONVERTER_ROOT}
RUN mkdir ${LASTOOLS_ROOT}

WORKDIR ${INSTALL_DIR} 

# Install dependencies
# Install software-properties-common to fix error for add-apt-repository: command not found
# RUN apt-get update -y &&\
	# apt-get install -y software-properties-common &&\
	# add-apt-repository -y ppa:nginx/stable &&\
	# add-apt-repository ppa:george-edison55/cmake-3.x &&\
	# apt-get update -y &&\
	# apt-get install -y nginx &&\
	# chown -R www-data:www-data /var/lib/nginx &&\
	### apt-get install -y python2.7 &&\
	# apt-get install -y python3.12 &&\
	# apt-get install -y curl &&\
	# curl -O https://bootstrap.pypa.io/get-pip.py &&\
	### python2.7 get-pip.py &&\
	# python3.10 get-pip.py &&\
	# pip install awscli &&\
	# apt-get install -y dos2unix &&\
	# apt-get install -y git &&\
	# apt-get update -y &&\
	# apt-get install -y g++ &&\
	# apt-get install -y cmake &&\
	# apt-get install -y build-essential &&\
	# apt-get install -y libboost-all-dev &&\
	# rm -rf /var/lib/apt/lists/*

	RUN apt update -y &&\
	apt upgrade -y &&\
	apt install python3 -y &&\
	apt install python3-pip -y &&\
	apt install dos2unix -y


# WORKDIR ${LASTOOLS_ROOT}	
# RUN git clone https://github.com/m-schuetz/LAStools.git master &&\
# 	cd master/LASzip &&\
# 	mkdir build &&\
# 	cd build &&\
# 	cmake -DCMAKE_BUILD_TYPE=Release .. &&\
# 	make VERBOSE=1

# COPY potree_converter ${POTREE_CONVERTER_ROOT}

# WORKDIR ${POTREE_CONVERTER_ROOT}
# RUN mkdir build &&\
# 	cd build &&\
# 	cmake -DCMAKE_BUILD_TYPE=Release -DLASZIP_INCLUDE_DIRS=${LASTOOLS_ROOT}/master/LASzip/dll -DLASZIP_LIBRARY=${LASTOOLS_ROOT}/master/LASzip/build/src/liblaszip.so .. &&\
# 	make &&\
# 	cp -R ${POTREE_CONVERTER_ROOT}/PotreeConverter/resources/ ${POTREE_ROOT}/resources &&\
# 	cp ${POTREE_CONVERTER_ROOT}/build/PotreeConverter/PotreeConverter /usr/bin

 	
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
COPY /docker/entrypoint.sh ${INSTALL_DIR}/entrypoint.sh
RUN chmod -R 700 ${INSTALL_DIR}
RUN dos2unix ${INSTALL_DIR}/*

# Create point cloud input folder
RUN mkdir ${POINTCLOUD_INPUT_FOLDER}
RUN chmod -R 777 ${POINTCLOUD_INPUT_FOLDER}

# Define mountable directories.
VOLUME ["/var/log/nginx", "/var/www/potree/resources/pointclouds"]

WORKDIR ${POTREE_ROOT}

# Define default command.
ENTRYPOINT ["/docker/entrypoint.sh"]
CMD ["runserver"]
