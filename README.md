Potree for Docker
=================
Usage:
```
Arguments:
    runserver: Runs Potree in Nginx. 
        No further expected commands.
    convert: Converts provided file into Potree format. 
        Further required commands: 
            -f or --file <file name>: input pointcloud file
        Further optional commands:
            -s3 or --s3: File is stored in AWS S3 bucket: ${S3_POINTCLOUD_INPUT_FOLDER}
            -n or --generate-page <page name>: Generates a ready to use web page with the given name.
            -o or --overwrite: overwrites existing pointcloud with same output name (-n or --name)
            --aabb \"<coordinates>\": Bounding cube as \"minX minY minZ maxX maxY maxZ\". 
            If not provided it is automatically computed
    download_pointclouds: Synchronizes pointclouds stored in ${BUCKET_NAME} to local storage
        No further expected commands.
    upload_pointclouds: Synchronizes pointclouds stored in local storage to ${BUCKET_NAME}
        No further expected commands.
    -h or --help: Display help text
    Environment variables required:
        AWS_ACCESS_KEY_ID: The AWS Access Key ID of your AWS account
        AWS_SECRET_ACCESS_KEY: The AWS Secret Access Key of your AWS account
        AWS_DEFAULT_REGION: The AWS region in which your S3 bucket resides.
```

docker-nginx
============

A high-performance Nginx base image for Docker to serve static websites. It will serve anything in the `/var/www` directory.

To build a Docker image for your site, you'll need to create a `Dockerfile`. For example, if your site is in a directory called `src/`, you could create this `Dockerfile`:

    FROM kyma/docker-nginx
    COPY src/ /var/www
    CMD 'nginx'

Then build and run it:

    $ docker build -t mysite .
    ...
    Successfully built 5ae2fb5cf4f8
    $ docker run -p 80:80 -d mysite
    da809981545f
    $ curl localhost
    ...

Docker Hub
----------
The trusted build information can be found on the Docker Hub at https://registry.hub.docker.com/u/kyma/docker-nginx/.

SSL
---

To use SSL, put your certs in `/etc/nginx/ssl` and enable the `default-ssl` site:

    ADD server.crt /etc/nginx/ssl/
    ADD server.key /etc/nginx/ssl/
    RUN ln -s /etc/nginx/sites-available/default-ssl /etc/nginx/sites-enabled/default-ssl

When you run it, you'll want to make port 443 available, e.g.:

    $ docker run -p 80:80 -p 443:443 -d mysite


nginx.conf
---------

The nginx.conf and mime.types are pulled with slight modifications from
the h5bp Nginx HTTP server boilerplate configs project at
https://github.com/h5bp/server-configs-nginx
