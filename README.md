# Docker-SDI7.2

Docker image of IBM Security Directory Integrator CE &amp; Server

Git Repo - https://github.ibm.com/IAM-L2/Docker-SDI7.2


----------

## **Building**

This container is built from Centos.  You need the IBM SDI Install Image, IBM SDI JVM Fixpack, and IBM SDI FP installation packages to build the image.
Docker Hub automated build will not work as these packages are not included in the Docker distribution.

1. Download product image 'IBM Security Directory Integrator Version 7.2 (part number: CIS7XML) from [IBM Passport Advantage Online](https://www-01.ibm.com/software/passportadvantage/pao_customer.html) .  Save the `SDI_7.2_XLIN86_64_ML.tar` image to the ./src-images directory.  As a reference note, the Dockerfile and docker-compose.yml should be in the parent directory of src-images.
2. Download the latest SDI 7.2 fixpack image from [IBM Support](http://www-01.ibm.com/support/docview.wss?uid=swg27010509).  Save the `7.2.0-ISS-SDI-FP000*.zip` image to the ./src-images directory.
3. Download the latest SDI 7.2 jvm image from [IBM Support](http://www-01.ibm.com/support/docview.wss?uid=swg27010509).  Save the (e.x.`ibm-java-jre-7.0-9.30-linux-x86_64.tgz` image to the ./src-images directory.
4. In the Dockerfile, update the filename parts of the urls found in the __TDI_IMAGE__ , __TDIFP_IMAGE__ , __TDI_JVM__ parameters to reference the file names from Steps 1-3.
5. On execution of the following command, a nginx web server will host the install images from Step 1-3.  The dockerfile will reference the images to perform the image build.
* Run ``export HOSTNAME="`hostname`" ; docker-compose down && docker-compose up -d web && docker-compose build && docker-compose down`` to build the image

----------

## ** Build Video**
<iframe src="https://ibm.ent.box.com/embed/s/9c8ypywo04fr3u3tni1tajqaezjd4mmz?sortColumn=date&view=list" width="500" height="400" frameborder="0" allowfullscreen webkitallowfullscreen msallowfullscreen></iframe>

----------

## ** Pull Video**
<iframe src="https://ibm.ent.box.com/embed/s/ynnizpoqapldhc0bcgrjw6a39eqkdg9c?sortColumn=date&view=list" width="500" height="400" frameborder="0" allowfullscreen webkitallowfullscreen msallowfullscreen></iframe>

----------

## **System Requirements**

* An X11 server (see Usage for an OS X example)

----------

## **Usage**

### SDI Server - 'The SDI Server in daemon mode is the intended command for the image'

```bash
docker run -d -v ~/Documents/TDISolutions:/root/TDI -p 1099:1099 -p 1098:1098 --rm --name sdiserver sdi:7.2.0.6
```

### SDI Config Editor

* Config Editor - Linux

```bash
docker run -v /tmp/.X11-unix:/tmp/.X11-unix -v ~/Documents/TDISolutions:/root/TDI -e DISPLAY=unix$DISPLAY --rm --name sdice sdi:7.2.0.6 "/opt/IBM/TDI/V7.2/ibmditk"
```

* Config Editor - MacOS

To run the IBM Security Directory Integrator Config Editor on the MacOS, do the following:

1. Install [XQuartz](https://www.xquartz.org)
2. Launch XQuartz and in _**preferences**_ -> _**security**_, enable **authenticate connections** and **allow connection from network clients**.
3. Add this bash function to your ~/.bash_profile file
4. Adjust the Solution Directory referenced in the bash script of Step#4
5. With the ~/.bash_profile saved, open a new terminal and execute `startSDI`

The bash script below is a combination of the 'Exposing X11 on the network, with authentication' section of https://github.com/chanezon/docker-tips/blob/master/x11/README.md and  https://fredrikaverpil.github.io/2016/07/31/docker-for-mac-and-gui-applications/

```bash
startSDI(){
    echo -e "SDI72 starting \xF0\x9F\x9A\x80"
    # Reference - https://github.com/chanezon/docker-tips/blob/master/x11/README.md
    if [ -z "$(ps -ef|grep XQuartz|grep -v grep)" ] ; then
        open -a XQuartz
        #socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\" &
    fi
    #   DISPLAY_MAC=`ifconfig en0 | grep "inet " | cut -d " " -f2`:0
    #  xhost content gained from https://fredrikaverpil.github.io/2016/07/31/docker-for-mac-and-gui-applications/
    ip=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}')
    xhost + $ip

    docker run  -v ~/Documents/TDISolutions:/root/TDI \
        -v ~/.Xauthority:/root/.Xauthority \
        -p 8080:1098 \
        -e DISPLAY=$ip:0 \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        --rm --name sdice sdi:7.2.0.6 "/opt/IBM/TDI/V7.2/ibmditk"
    echo -e "SDI72 stopped on $ip \xF0\x9f\x8d\xba"
    xhost - $ip

    ps -ef|grep XQuartz|grep -v grep | awk '{print $2}' | xargs kill
}
```

NOTE: If you find the Config Editor will not start.  Check if XQuartz has an orphaned lock file (e.g. /tmp/.X0-lock). Remove these lock file(s) before the start of XQuartz & SDI Config Editor.

----------

## ** Solution Directory **

The container image will have a default Solution Directory set to the location of /root/TDI. This location in the container will be used unless a Volume is mounted at run time to overlay this information with an external solution directory.  To mount an external `Solution Directory` volume into the container use the `Docker Volume` parameter [-v host_directory:container_directory].  If other directory mounts into the container are desired, the same `-v hostDirectory:containerDirectory` can be used.

    e.g.
    -v ~/Documents/TDISolutions:/root/TDI

----------

## Port

To expose a port of the SDI Server, use the -p parameter found with the `docker run` command.

|service   |(host port / container port)  | notes |
|---|---|---|
|derby   |-p 1527:1527   |
|rmi   |-p 1099:1099   |
|rest   |-p 1098:1098   | dashboard.auth.remote must be enabled in the solution.properties file

----------

## Memory

To adjust the JVM Heap of the SDI Server, use the -e parameter found with the `docker run` command.

    -e JVM_XMX=1024m
    -e JVM_XMS=256m
