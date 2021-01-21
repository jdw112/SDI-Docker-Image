# This file describes the standard way to build Docker image, using docker
#
# Usage:
#
# # To Assemble and build the full SDI dev docker environment, refer to the Building instructions found in the Readme
#
# start container
#  docker run -d -p 1099:1099 -p 1098:1098 --rm --name sdi72 jdwillia/sdi72
#
# Readme:
# https://github.ibm.com/IAM-L2/Docker-SDI7.2/blob/master/README.md

FROM centos:7

LABEL maintainer Jason Williams <jdwillia@us.ibm.com> \
	version="1.1" \
	description="This image is IBM Security Directory Integrator 7.2 CE & Server on Centos"

# Packaged dependencies
#RUN yum -y update && yum install -y \
RUN yum install -y \
	glibc.x86_64 \
	compat-libstdc++-33.x86_64 \
	nss-softokn.x86_64 \
	libXpm.x86_64 \
	libXtst.x86_64 \
	gtk2.x86_64 \
	libcanberra-gtk2 \
	unzip \
	wget \
	which \
	dejavu-lgc-sans-fonts

# Set location of Security Directory Integrator product(tar), fixpack(zip), and JVM(tgz) Images as wget urls references
# To minimize the size of the image, at this time it's better to fetch 'wget' the images then to use ADD or COPY.  Using ADD or COPY will create unwanted layers
# e.g.  ARG TDI_IMAGE="https://localhost/shared/static/SDI_7.2_XLIN86_64_ML.tar"

# USE THE DOCKER HOST IP FOR THE IP OF THE HTTPSERVER IN THE FOLLOWING 3 ARG.
# This will reference the nginx container serving the src images
ARG DOCKERHOST

ARG TDI_IMAGE=http://$DOCKERHOST:8080/SDI_7.2_XLIN86_64_ML.tar
ARG TDIFP_IMAGE=http://$DOCKERHOST:8080/7.2.0-ISS-SDI-FP0006.zip
ARG TDI_JVM=http://$DOCKERHOST:8080/ibm-java-jre-8.0-5.30-linux-x86_64.tgz
ARG TDI_INSTALL_HOME="/opt/IBM/TDI/V7.2"
# plugin obtained from https://www.eclipse.org/downloads/download.php?file=/egit/updates-4.2/org.eclipse.egit.repository-4.2.0.201601211800-r.zip&mirror_id=518
ARG GIT_PLUGIN=http://$DOCKERHOST:8080/org.eclipse.egit.repository-4.2.0.201601211800-r.zip


# Set default JVM Heap Max & Min for image.  Use -e to adjust these at runtime
ENV JVM_XMX="512m" JVM_XMS="128m"

# Copy files to Docker image
# The CustomInstallRsp.txt will only install the Server & Config Editor components
COPY src-images/CustomInstallRsp.txt /tmp/tdi/

# To minimize the layers in the image, all software installs will occur in one layer
# '|| :' will ignore "cant find KDE or GNOME" errors given by the TDI Installer.
# The /etc/inittab file is required by the TDI Installer though removed later in the RUN process
# The
RUN touch /etc/inittab \
	&& cd /tmp/tdi ; wget --no-check-certificate $TDI_IMAGE ; tar -xvf *.tar \
	&& /tmp/tdi/linux_x86_64/install_sdiv72_linux_x86_64.bin -D\$TDI_SKIP_VERSION_CHECK\$="true" -D\$TDI_NOSHORTCUTS\$="true" -f /tmp/tdi/CustomInstallRsp.txt -i silent || : \
	&& rm -rf /etc/inittab ; rm -rf $TDI_INSTALL_HOME/_uninst \
	&& mkdir /tmp/fp ; cd /tmp/fp ; wget --no-check-certificate $TDIFP_IMAGE ; unzip *.zip \
	&& cp /tmp/fp/7.2.0-ISS-SDI-FP00*/UpdateInstaller.jar $TDI_INSTALL_HOME/maintenance/. ; $TDI_INSTALL_HOME/bin/applyUpdates.sh -update /tmp/fp/7.2.0-ISS-SDI-FP00*/SDI-7.2-FP00*.zip \
	&& mkdir /tmp/jvm ; cd /tmp/jvm ; wget --no-check-certificate $TDI_JVM ; tar -zxvf *.tgz ; /bin/cp -rf /tmp/jvm/ibm-java-x86_64*/. $TDI_INSTALL_HOME/jvm/ \
	&& cd / ; rm -rf /tmp/tdi ; rm -rf /tmp/fp ; rm -rf /tmp/jvm || : \
	&& echo TDI_SOLDIR=/root/TDI > $TDI_INSTALL_HOME/bin/defaultSolDir.sh \
	&& mkdir -p $TDI_INSTALL_HOME/eclipseDropins/GIT/eclipse ; wget --directory-prefix=$TDI_INSTALL_HOME/eclipseDropins/GIT/eclipse --no-check-certificate $GIT_PLUGIN \
	&& cd $TDI_INSTALL_HOME/eclipseDropins/GIT/eclipse ; unzip $TDI_INSTALL_HOME/eclipseDropins/GIT/eclipse/*.zip ; rm -rf $TDI_INSTALL_HOME/eclipseDropins/GIT/eclipse/*.zip \
	&& mkdir -p $TDI_INSTALL_HOME/ce/eclipsece/links ; echo path=/opt/IBM/TDI/V7.2/eclipseDropins/GIT > $TDI_INSTALL_HOME/ce/eclipsece/links/egit.link

## File modifications
RUN sed -i 's/\permission java.net.SocketPermission.*/permission java.net.SocketPermission "localhost:0-", "listen";/' $TDI_INSTALL_HOME/jvm/jre/lib/security/java.policy \
	&& sed -i "s|com.ibm.di.store.hostname=localhost|com.ibm.di.store.hostname=0.0.0.0|" $TDI_INSTALL_HOME/etc/global.properties \
	&& sed -i 's|-cp|-Xmx$JVM_XMX -Xms$JVM_XMS -cp|' $TDI_INSTALL_HOME/ibmdisrv \
	&& sed -i 's|-vmargs|-vmargs -Dorg.eclipse.swt.internal.gtk.cairoGraphics=false|' $TDI_INSTALL_HOME/ibmditk \
	&& sed -i "/dashboard.auth.user.admin=/c\dashboard.auth.user.admin=admin" $TDI_INSTALL_HOME/etc/global.properties \
	&& sed -i 's|dashboard.auth.remote=deny|dashboard.auth.remote=properties|' $TDI_INSTALL_HOME/etc/global.properties

EXPOSE 1099 1098 1527

# The SDI Server in daemon mode is the intended command for the image
CMD ["bash","/opt/IBM/TDI/V7.2/ibmdisrv","-d","&"]