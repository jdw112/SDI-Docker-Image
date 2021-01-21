#!/bin/bash
#echo Adding Current hostname to /etc/hosts file...
#echo testing hostfile addition...
#HOSTNAME=$(hostname)

#need to push hostname out to file in order for startup script to push that back to /etc/hosts on startup
#mkdir /opt/scripts
#echo $HOSTNAME >>/opt/scripts/hostname.txt

echo "Creating User home dir..."
mkdir /home/sdiadmin

echo "Creating User..."
useradd -g root -d /home/sdiadmin sdiadmin
echo "sdiadmin:sdiadmin" | chpasswd
chown sdiadmin /home/sdiadmin

echo "Updating OS..."
yum install -y glibc.x86_64 compat-libstdc++-33.x86_64 nss-softokn.x86_64 libXpm.x86_64 libXtst.x86_64 gtk2.x86_64 libcanberra-gtk2 unzip wget which dejavu-lgc-sans-fonts

echo "Installing SDI..."
env TDI_IMAGE=http://$DOCKERHOST:8080/SDI_7.2_XLIN86_64_ML.tar
env TDIFP_IMAGE=http://$DOCKERHOST:8080/7.2.0-ISS-SDI-FP0005.zip
env TDI_JVM=http://$DOCKERHOST:8080/ibm-java-jre-8.0-5.15-linux-x86_64.tgz
#env TDI_RSP=http://$DOCKERHOST:8080/CustomInstallRsp.txt
env TDI_INSTALL_HOME="/opt/IBM/TDI/V7.2"
env GIT_PLUGIN=http://$DOCKERHOST:8080/org.eclipse.egit.repository-4.2.0.201601211800-r.zip

touch /etc/inittab

mkdir /tmp/tdi
cd /tmp/tdi
wget --no-check-certificate $TDI_IMAGE
tar -xvf *.tar &&
    /tmp/tdi/linux_x86_64/install_sdiv72_linux_x86_64.bin -D\$TDI_SKIP_VERSION_CHECK\$="true" -D\$TDI_NOSHORTCUTS\$="true" -f /tmp/tdi/CustomInstallRsp.txt -i silent || : &&
    rm -rf /etc/inittab
rm -rf $TDI_INSTALL_HOME/_uninst

mkdir /tmp/fp
cd /tmp/fp
wget --no-check-certificate $TDIFP_IMAGE
unzip *.zip \  && cp /tmp/fp/7.2.0-ISS-SDI-FP00*/UpdateInstaller.jar $TDI_INSTALL_HOME/maintenance/.
$TDI_INSTALL_HOME/bin/applyUpdates.sh -update /tmp/fp/7.2.0-ISS-SDI-FP00*/SDI-7.2-FP00*.zip

mkdir /tmp/jvm
cd /tmp/jvm
wget --no-check-certificate $TDI_JVM
tar -zxvf *.tgz
/bin/cp -rf /tmp/jvm/ibm-java-x86_64*/. $TDI_INSTALL_HOME/jvm/

echo Cleaning up...
rm -rf /tmp/tdi
rm -rf /tmp/fp
rm -rf /tmp/jvm

echo "install finished"
echo DONE.
