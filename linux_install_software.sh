#!/bin/bash

export LC_ALL=C
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8


sudoCmd=""
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
fi


# fonts color
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
bold(){
    echo -e "\033[1m\033[01m$1\033[0m"
}



function showHeaderGreen(){
    echo
    green " =================================================="

    for parameter in "$@"
    do
        if [[ -n "${parameter}" ]]; then
            green " ${parameter}"
        fi
    done

    green " =================================================="
    echo
}
function showHeaderRed(){
    echo
    red " =================================================="
    for parameter in "$@"
    do
        if [[ -n "${parameter}" ]]; then
            red " ${parameter}"
        fi
    done
    red " =================================================="
    echo
}
function showInfoGreen(){
    echo
    for parameter in "$@"
    do
        if [[ -n "${parameter}" ]]; then
            green " ${parameter}"
        fi
    done
    echo
}


function promptContinueOpeartion(){
	read -p "Do you want to continue the operation? Press Enter to continue the operation by default, please enter[Y/n]:" isContinueInput
	isContinueInput=${isContinueInput:-Y}

	if [[ $isContinueInput == [Yy] ]]; then
		echo ""
	else 
		exit
	fi
}








osCPU=""
osArchitecture="arm"
osInfo=""
osRelease=""
osReleaseVersion=""
osReleaseVersionNo=""
osReleaseVersionNoShort=""
osReleaseVersionCodeName="CodeName"
osSystemPackage=""
osSystemMdPath=""
osSystemShell="bash"


function checkArchitecture(){
	# https://stackoverflow.com/questions/48678152/how-to-detect-386-amd64-arm-or-arm64-os-architecture-via-shell-bash

	case $(uname -m) in
		i386)   osArchitecture="386" ;;
		i686)   osArchitecture="386" ;;
		x86_64) osArchitecture="amd64" ;;
		arm)    dpkg --print-architecture | grep -q "arm64" && osArchitecture="arm64" || osArchitecture="arm" ;;
		aarch64)    dpkg --print-architecture | grep -q "arm64" && osArchitecture="arm64" || osArchitecture="arm" ;;
		* )     osArchitecture="arm" ;;
	esac
}

function checkCPU(){
	osCPUText=$(cat /proc/cpuinfo | grep vendor_id | uniq)
	if [[ $osCPUText =~ "GenuineIntel" ]]; then
		osCPU="intel"
    elif [[ $osCPUText =~ "AMD" ]]; then
        osCPU="amd"
    else
        echo
    fi

	# green " Status Status display -- the current CPU is: $osCPU"
}

# Check the system version number
getLinuxOSVersion(){
    if [[ -s /etc/redhat-release ]]; then
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/redhat-release)
    else
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/issue)
    fi

    # https://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script

    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        source /etc/os-release
        osInfo=$NAME
        osReleaseVersionNo=$VERSION_ID

        if [ -n "$VERSION_CODENAME" ]; then
            osReleaseVersionCodeName=$VERSION_CODENAME
        fi
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        osInfo=$(lsb_release -si)
        osReleaseVersionNo=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        osInfo=$DISTRIB_ID
        
        osReleaseVersionNo=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        osInfo=Debian
        osReleaseVersion=$(cat /etc/debian_version)
        osReleaseVersionNo=$(sed 's/\..*//' /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/redhat-release)
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        osInfo=$(uname -s)
        osReleaseVersionNo=$(uname -r)
    fi

    osReleaseVersionNoShort=$(echo $osReleaseVersionNo | sed 's/\..*//')
}

# Detection system release code
function getLinuxOSRelease(){
    if [[ -f /etc/redhat-release ]]; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    elif cat /etc/issue | grep -Eqi "debian|raspbian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="buster"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="bionic"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    elif cat /proc/version | grep -Eqi "debian|raspbian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="buster"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="bionic"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    fi

    getLinuxOSVersion
    checkArchitecture
	checkCPU
    

    [[ -z $(echo $SHELL|grep zsh) ]] && osSystemShell="bash" || osSystemShell="zsh"

    green " OS info: ${osInfo}, ${osRelease}, ${osReleaseVersion}, ${osReleaseVersionNo}, ${osReleaseVersionCodeName}, ${osCPU} CPU ${osArchitecture}, ${osSystemShell}, ${osSystemPackage}, ${osSystemMdPath}"
}





function promptContinueOpeartion(){
	read -r -p "Do you want to continue the operation? Press Enter to continue the operation by default, please enter[Y/n]:" isContinueInput
	isContinueInput=${isContinueInput:-Y}

	if [[ $isContinueInput == [Yy] ]]; then
		echo ""
	else 
		exit 1
	fi
}

osPort80=""
osPort443=""
osSELINUXCheck=""
osSELINUXCheckIsRebootInput=""

function testLinuxPortUsage(){
    $osSystemPackage -y install net-tools socat

    osPort80=$(netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80)
    osPort443=$(netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 443)

    if [ -n "$osPort80" ]; then
        process80=$(netstat -tlpn | awk -F '[: ]+' '$5=="80"{print $9}')
        red "==========================================================="
        red "It is detected that port 80 is occupied, and the occupied process is：${process80} "
        red "==========================================================="
        promptContinueOpeartion
    fi

    if [ -n "$osPort443" ]; then
        process443=$(netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}')
        red "============================================================="
        red "It is detected that port 443 is occupied, and the occupied process is：${process443} "
        red "============================================================="
        promptContinueOpeartion
    fi

    osSELINUXCheck=$(grep SELINUX= /etc/selinux/config | grep -v "#")
    if [ "$osSELINUXCheck" == "SELINUX=enforcing" ]; then
        red "======================================================================="
        red "It is detected that SELinux is in mandatory mode, and SELinux will be turned off to prevent failure to apply for a certificate. Please restart the VPS before executing this script"
        red "======================================================================="
        read -p "Reboot now? Please enter [Y/n] :" osSELINUXCheckIsRebootInput
        [ -z "${osSELINUXCheckIsRebootInput}" ] && osSELINUXCheckIsRebootInput="y"

        if [[ $osSELINUXCheckIsRebootInput == [Yy] ]]; then
            sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
            echo -e "VPS Rebooting..."
            reboot
        fi
        exit
    fi

    if [ "$osSELINUXCheck" == "SELINUX=permissive" ]; then
        red "======================================================================="
        red "It is detected that SELinux is in permissive mode. In order to prevent the failure to apply for a certificate, SELinux will be turned off. Please restart the VPS before executing this script"
        red "======================================================================="
        read -p "Reboot now? Please enter[Y/n] :" osSELINUXCheckIsRebootInput
        [ -z "${osSELINUXCheckIsRebootInput}" ] && osSELINUXCheckIsRebootInput="y"

        if [[ $osSELINUXCheckIsRebootInput == [Yy] ]]; then
            sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
            echo -e "VPS Rebooting..."
            reboot
        fi
        exit
    fi

    if [ "$osRelease" == "centos" ]; then
        if  [[ ${osReleaseVersionNoShort} == "6" || ${osReleaseVersionNoShort} == "5" ]]; then
            green " =================================================="
            red " This script does not support Centos 6 or earlier versions of Centos 6"
            green " =================================================="
            exit
        fi

        red " 关闭防火墙 firewalld"
        ${sudoCmd} systemctl stop firewalld
        ${sudoCmd} systemctl disable firewalld

    elif [ "$osRelease" == "ubuntu" ]; then
        if  [[ ${osReleaseVersionNoShort} == "14" || ${osReleaseVersionNoShort} == "12" ]]; then
            green " =================================================="
            red " This script does not support Ubuntu 14 or earlier versions of Ubuntu 14"
            green " =================================================="
            exit
        fi

        red " turn off firewall ufw"
        ${sudoCmd} systemctl stop ufw
        ${sudoCmd} systemctl disable ufw
        ufw disable
        
    elif [ "$osRelease" == "debian" ]; then
        $osSystemPackage update -y
    fi

}









# Edit SSH public key file for passwordless login
function editLinuxLoginWithPublicKey(){
    if [ ! -d "${HOME}/ssh" ]; then
        mkdir -p ${HOME}/.ssh
    fi

    vi ${HOME}/.ssh/authorized_keys
}


# Modify the SSH port number
function changeLinuxSSHPort(){
    green " Modify the port number for SSH login, do not use the commonly used port number. For example: 20|21|23|25|53|69|80|110|443|123!"
    read -p "Please enter the port number to be modified (must be a pure number and between 1024~65535 or 22):" osSSHLoginPortInput
    osSSHLoginPortInput=${osSSHLoginPortInput:-0}

    if [ $osSSHLoginPortInput -eq 22 -o $osSSHLoginPortInput -gt 1024 -a $osSSHLoginPortInput -lt 65535 ]; then
        sed -i "s/#\?Port [0-9]*/Port $osSSHLoginPortInput/g" /etc/ssh/sshd_config

        if [ "$osRelease" == "centos" ] ; then

            if  [[ ${osReleaseVersionNoShort} == "7" ]]; then
                yum -y install policycoreutils-python
            elif  [[ ${osReleaseVersionNoShort} == "8" ]]; then
                yum -y install policycoreutils-python-utils
            fi

            # semanage port -l
            semanage port -a -t ssh_port_t -p tcp ${osSSHLoginPortInput}
            if command -v firewall-cmd &> /dev/null; then
                firewall-cmd --permanent --zone=public --add-port=$osSSHLoginPortInput/tcp 
                firewall-cmd --reload
            fi


            ${sudoCmd} systemctl restart sshd.service

        fi

        if [ "$osRelease" == "ubuntu" ] || [ "$osRelease" == "debian" ] ; then
            semanage port -a -t ssh_port_t -p tcp $osSSHLoginPortInput
            ${sudoCmd} ufw allow $osSSHLoginPortInput/tcp

            ${sudoCmd} service ssh restart
            ${sudoCmd} systemctl restart ssh
        fi

        green "The setting is successful, please remember the set port number ${osSSHLoginPortInput}!"
        green "login server command: ssh -p ${osSSHLoginPortInput} root@111.111.111.your ip !"
    else
        echo "Wrong port number entered! Range: 22,1025~65534"
    fi
}



# set up北京时区
function setLinuxDateZone(){

    tempCurrentDateZone=$(date +'%z')

    echo
    if [[ ${tempCurrentDateZone} == "+0330" ]]; then
        yellow "The current time zone is already Tehran time  $tempCurrentDateZone | $(date -R) "
    else 
        green " =================================================="
        yellow " The current time zone is: $tempCurrentDateZone | $(date -R) "
        yellow " Whether to set the time zone to Tehran time +0330zone, so that the cron restart script runs according to Tehran time."
        green " =================================================="
        # read 默认值 https://stackoverflow.com/questions/2642585/read-a-variable-in-bash-with-a-default-value

        read -p "Is it set to Tehran time +0330 time zone? Please enter[Y/n]:" osTimezoneInput
        osTimezoneInput=${osTimezoneInput:-Y}

        if [[ $osTimezoneInput == [Yy] ]]; then
            if [[ -f /etc/localtime ]] && [[ -f /usr/share/zoneinfo/Asia/Tehran ]];  then
                mv /etc/localtime /etc/localtime.bak
                cp /usr/share/zoneinfo/Asia/Tehran /etc/localtime

                yellow " Set successfully! The current time zone has been set to $(date -R)"
                green " =================================================="
            fi
        fi

    fi
    echo

    if [ "$osRelease" == "centos" ]; then   
        if  [[ ${osReleaseVersionNoShort} == "7" ]]; then
            systemctl stop chronyd
            systemctl disable chronyd

            $osSystemPackage -y install ntpdate
            $osSystemPackage -y install ntp
            ntpdate -q 0.rhel.pool.ntp.org
            systemctl enable ntpd
            systemctl restart ntpd
            ntpdate -u  pool.ntp.org

        elif  [[ ${osReleaseVersionNoShort} == "8" || ${osReleaseVersionNoShort} == "9" ]]; then
            $osSystemPackage -y install chrony
            systemctl enable chronyd
            systemctl restart chronyd

            if command -v firewall-cmd &> /dev/null; then
                firewall-cmd --permanent --add-service=ntp
                firewall-cmd --reload
            fi

            chronyc sources

            echo
        fi
        
    else
        $osSystemPackage install -y ntp
        systemctl enable ntp
        systemctl restart ntp
    fi    
}





function DSMEditHosts(){
	green " ================================================== "
	green " Prepare to open the VI to edit /etc/hosts"
	green " Please use the root user to log in to the system's SSH to run this command"
	green " ================================================== "

    # nameserver 223.5.5.5
    # nameserver 8.8.8.8

    HostFilePath="/etc/hosts"

    if ! grep -q "github" "${HostFilePath}"; then
        echo "199.232.69.194               github.global.ssl.fastly.net" >> ${HostFilePath}
        echo "185.199.108.153              assets-cdn.github.com" >> ${HostFilePath}
        echo "185.199.108.133              raw.githubusercontent.com" >> ${HostFilePath}
        echo "140.82.114.3                 github.com" >> ${HostFilePath}
        echo "104.16.16.35                 registry.npmjs.org" >> ${HostFilePath}
    fi

	vi ${HostFilePath}
}









# Software Installation
function installSoftDownload(){
	if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
		if ! dpkg -l | grep -qw wget; then
			${osSystemPackage} -y install wget git unzip curl apt-transport-https
			
			# https://stackoverflow.com/questions/11116704/check-if-vt-x-is-activated-without-having-to-reboot-in-linux
			${osSystemPackage} -y install cpu-checker
		fi

		if ! dpkg -l | grep -qw curl; then
			${osSystemPackage} -y install curl git unzip wget apt-transport-https
			
			${osSystemPackage} -y install cpu-checker
		fi

	elif [[ "${osRelease}" == "centos" ]]; then

        if  [[ ${osReleaseVersion} == "8.1.1911" || ${osReleaseVersion} == "8.2.2004" || ${osReleaseVersion} == "8.0.1905" ]]; then

            # https://techglimpse.com/failed-metadata-repo-appstream-centos-8/

            cd /etc/yum.repos.d/
            sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
            sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
            yum update -y

            sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
            sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*

            ${sudoCmd} dnf install centos-release-stream -y
            ${sudoCmd} dnf swap centos-{linux,stream}-repos -y
            ${sudoCmd} dnf distro-sync -y
        fi
        
        if ! rpm -qa | grep -qw wget; then
		    ${osSystemPackage} -y install wget curl git unzip

        elif ! rpm -qa | grep -qw git; then
		    ${osSystemPackage} -y install wget curl git unzip
		fi
	fi
}



function installPackage(){
    echo
    green " =================================================="
    yellow " Start installing the software"
    green " =================================================="
    echo

    
    # sed -i '1s/^/nameserver 1.1.1.1 \n/' /etc/resolv.conf


    if [ "$osRelease" == "centos" ]; then
       
        # rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
        rm -f /etc/yum.repos.d/nginx.repo
        # cat > "/etc/yum.repos.d/nginx.repo" <<-EOF
# [nginx]
# name=nginx repo
# baseurl=https://nginx.org/packages/centos/$osReleaseVersionNoShort/\$basearch/
# gpgcheck=0
# enabled=1
# sslverify=0
# 
# EOF

        if ! rpm -qa | grep -qw iperf3; then
			${sudoCmd} ${osSystemPackage} install -y epel-release

            ${osSystemPackage} install -y curl wget git unzip zip tar bind-utils htop net-tools
            ${osSystemPackage} install -y xz jq redhat-lsb-core 
            ${osSystemPackage} install -y iputils
            ${osSystemPackage} install -y iperf3
		fi

        ${osSystemPackage} update -y


        # https://www.cyberciti.biz/faq/how-to-install-and-use-nginx-on-centos-8/
        if  [[ ${osReleaseVersionNoShort} == "8" || ${osReleaseVersionNoShort} == "9" ]]; then
            ${sudoCmd} yum module -y reset nginx
            ${sudoCmd} yum module -y enable nginx:1.20
            ${sudoCmd} yum module list nginx
        fi

    elif [ "$osRelease" == "ubuntu" ]; then
        
        # https://joshtronic.com/2018/12/17/how-to-install-the-latest-nginx-on-debian-and-ubuntu/
        # https://www.nginx.com/resources/wiki/start/topics/tutorials/install/
        
        $osSystemPackage install -y gnupg2 curl ca-certificates lsb-release ubuntu-keyring
        # wget -O - https://nginx.org/keys/nginx_signing.key | ${sudoCmd} apt-key add -
        curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

        rm -f /etc/apt/sources.list.d/nginx.list

        cat > "/etc/apt/sources.list.d/nginx.list" <<-EOF
deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg]   https://nginx.org/packages/ubuntu/ $osReleaseVersionCodeName nginx
# deb [arch=amd64] https://nginx.org/packages/ubuntu/ $osReleaseVersionCodeName nginx
# deb-src https://nginx.org/packages/ubuntu/ $osReleaseVersionCodeName nginx
EOF

        echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n"  | sudo tee /etc/apt/preferences.d/99-nginx

        if [[ "${osReleaseVersionNoShort}" == "22" || "${osReleaseVersionNoShort}" == "21" ]]; then
            echo
        fi



        ${osSystemPackage} update -y

        if ! dpkg -l | grep -qw iperf3; then
            ${sudoCmd} ${osSystemPackage} install -y software-properties-common
            ${osSystemPackage} install -y curl wget git unzip zip tar htop
            ${osSystemPackage} install -y xz-utils jq lsb-core lsb-release
            ${osSystemPackage} install -y iputils-ping
            ${osSystemPackage} install -y iperf3
		fi    

    elif [ "$osRelease" == "debian" ]; then
        # ${sudoCmd} add-apt-repository ppa:nginx/stable -y
        ${osSystemPackage} update -y

        apt install -y gnupg2
        apt install -y curl ca-certificates lsb-release
        wget https://nginx.org/keys/nginx_signing.key -O- | apt-key add - 

        rm -f /etc/apt/sources.list.d/nginx.list
        if [[ "${osReleaseVersionNoShort}" == "12" ]]; then
            echo
        else
            cat > "/etc/apt/sources.list.d/nginx.list" <<-EOF
deb https://nginx.org/packages/mainline/debian/ $osReleaseVersionCodeName nginx
deb-src https://nginx.org/packages/mainline/debian $osReleaseVersionCodeName nginx
EOF
        fi


        ${osSystemPackage} update -y

        if ! dpkg -l | grep -qw iperf3; then
            ${osSystemPackage} install -y curl wget git unzip zip tar htop
            ${osSystemPackage} install -y xz-utils jq lsb-core lsb-release
            ${osSystemPackage} install -y iputils-ping
            ${osSystemPackage} install -y iperf3
        fi        
    fi
}





function installSoftEditor(){
    # Install the micro editor
    if [[ ! -f "${HOME}/bin/micro" ]] ;  then
        mkdir -p ${HOME}/bin
        cd ${HOME}/bin
        curl https://getmic.ro | bash

        cp ${HOME}/bin/micro /usr/local/bin

        green " =================================================="
        green " Micro editor installed successfully!"
        green " =================================================="
    fi

    if [ "$osRelease" == "centos" ]; then   
        $osSystemPackage install -y xz  vim-minimal vim-enhanced vim-common nano
    else
        $osSystemPackage install -y vim-gui-common vim-runtime vim nano
    fi

    # Set vim Chinese garbled
    # if [[ ! -d "${HOME}/.vimrc" ]] ;  then
    #    cat > "${HOME}/.vimrc" <<-EOF
#set fileencodings=utf-8,gb2312,gb18030,gbk,ucs-bom,cp936,latin1
#set enc=utf8
#set fencs=utf8,gbk,gb2312,gb18030

#syntax on
#colorscheme elflord

#if has('mouse')
#  se mouse+=a
#  set number
#endif

#EOF
#    fi
}











# Updated script
function upgradeScript(){
    wget -Nq --no-check-certificate -O ./linux_install_software.sh "https://raw.githubusercontent.com/jinwyp/one_click_script/master/linux_install_software.sh"
    green " 本脚本升级成功! "
    chmod +x ./linux_install_software.sh
    sleep 2s
    exec "./linux_install_software.sh"
}

function installWireguard(){
    bash <(wget -qO- https://github.com/jinwyp/one_click_script/raw/master/install_kernel.sh)
    # wget -N --no-check-certificate https://github.com/jinwyp/one_click_script/raw/master/install_kernel.sh && chmod +x ./install_kernel.sh && ./install_kernel.sh
}












function toolboxSkybox(){
    wget -O skybox.sh https://raw.githubusercontent.com/BlueSkyXN/SKY-BOX/main/box.sh && chmod +x skybox.sh  && ./skybox.sh
}

function toolboxJcnf(){
    wget -O jcnfbox.sh https://raw.githubusercontent.com/Netflixxp/jcnf-box/main/jcnfbox.sh && chmod +x jcnfbox.sh && ./jcnfbox.sh
}


function installCasaOS(){
    wget -O- https://get.casaos.io | bash
}
function removeCasaOS(){
    casaos-uninstall
}























































configDownloadTempPath="${HOME}/temp"

function downloadAndUnzip(){
    if [ -z $1 ]; then
        green " ================================================== "
        green "     The download file address is empty!"
        green " ================================================== "
        exit
    fi
    if [ -z $2 ]; then
        green " ================================================== "
        green "     destination path address is empty!"
        green " ================================================== "
        exit
    fi
    if [ -z $3 ]; then
        green " ================================================== "
        green "     The filename of the downloaded file is empty!"
        green " ================================================== "
        exit
    fi

    mkdir -p ${configDownloadTempPath}

    if [[ $3 == *"tar.xz"* ]]; then
        green "===== Download and extract the tar.xz file: $3 "
        wget -O ${configDownloadTempPath}/$3 $1
        tar xf ${configDownloadTempPath}/$3 -C ${configDownloadTempPath}
        mv ${configDownloadTempPath}/* $2
        rm -rf ${configDownloadTempPath}

    elif [[ $3 == *"tar.gz"* ]]; then
        green "===== Download and extract the tar.gz file: $3 "
        wget -O ${configDownloadTempPath}/$3 $1
        tar zxvf ${configDownloadTempPath}/$3 -C ${configDownloadTempPath}
        mv ${configDownloadTempPath}/* $2
        rm -rf ${configDownloadTempPath}

    else
        green "===== Download and extract the zip file:  $3 "
        wget -O ${configDownloadTempPath}/$3 $1
        unzip -d $2 ${configDownloadTempPath}/$3
        rm -rf ${configDownloadTempPath}
    fi

}




function getGithubLatestReleaseVersion(){
    # https://github.com/p4gefau1t/trojan-go/issues/63
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -b 2-
}
function getGithubLatestReleaseVersion2(){
    # https://github.com/p4gefau1t/trojan-go/issues/63
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | sort -r | head -1 | cut -b 1-
}











function installNodejs(){
    
    showHeaderGreen "Prepare to install Nodejs"

    if [ "$osRelease" == "centos" ] ; then

        if [ "$osReleaseVersion" == "7" ]; then
            curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
            ${sudoCmd} yum install -y nodejs
        else
            ${sudoCmd} dnf module list nodejs
            ${sudoCmd} dnf module switch-to nodejs:16 -y
            ${sudoCmd} dnf module enable nodejs:16 -y
            ${sudoCmd} dnf module list nodejs
            ${sudoCmd} dnf install -y nodejs
        fi

    else 
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
        echo 'export NVM_DIR="$HOME/.nvm"' >> ${HOME}/.zshrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ${HOME}/.zshrc
        source ${HOME}/.zshrc

        command -v nvm
        nvm --version
        nvm ls-remote
        nvm install --lts

    fi

    echo
    green " Nodejs Version:"
    node --version 
    echo
    green " NPM Version:"
    npm --version  

    showHeaderGreen "ready to install PM2 process daemon"
    npm install -g pm2 

    showHeaderGreen "Nodejs and PM2 Successful installation !"
}




configDockerDownloadPath="${HOME}/download"
configDockerComposePath="/usr/local/lib/docker/cli-plugins"

function installDocker(){

    showHeaderGreen "ready to install Docker and Docker Compose"

    mkdir -p ${configDockerDownloadPath}
    cd ${configDockerDownloadPath}


    if [[ -s "/usr/bin/docker" ]]; then
        showHeaderRed "installed Docker. Docker already installed!"
    else

        if [[ "${osInfo}" == "AlmaLinux" ]]; then
            ${sudoCmd} yum module remove container-tools
            # https://linuxconfig.org/install-docker-on-almalinux
            ${sudoCmd} dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            ${sudoCmd} dnf remove -y podman buildah 
            ${sudoCmd} dnf install -y docker-ce docker-ce-cli containerd.io
 
        else
            # curl -fsSL https://get.docker.com -o get-docker.sh  
            curl -sSL https://get.daocloud.io/docker -o ${configDockerDownloadPath}/get-docker.sh  
            chmod +x ${configDockerDownloadPath}/get-docker.sh
            ${configDockerDownloadPath}/get-docker.sh

        fi
        ${sudoCmd}
        ${sudoCmd} systemctl start docker.service
        ${sudoCmd} systemctl enable docker.service
        
        showHeaderGreen "Docker installed successfully !"
        docker version
        echo
    fi


    if [[ -s "/usr/local/bin/docker-compose" ]]; then
        showHeaderRed "installed Docker Compose. Docker Compose already installed!"
    else

        versionDockerCompose=$(getGithubLatestReleaseVersion "docker/compose")

        # dockerComposeUrl="https://github.com/docker/compose/releases/download/v${versionDockerCompose}/docker-compose-$(uname -s)-$(uname -m)"
        dockerComposeUrl="https://github.com/docker/compose/releases/download/v2.9.0/docker-compose-linux-x86_64"
        dockerComposeUrl="https://get.daocloud.io/docker/compose/releases/download/v${versionDockerCompose}/docker-compose-linux-x86_64"
        
        showInfoGreen "Downloading  ${dockerComposeUrl}"


        mkdir -p ${configDockerComposePath}

        ${sudoCmd} wget -O ${configDockerComposePath}/docker-compose "${dockerComposeUrl}"
        ${sudoCmd} chmod a+x ${configDockerComposePath}/docker-compose
        ${sudoCmd} ln -s ${configDockerComposePath}/docker-compose /usr/local/bin/docker-compose
        #${sudoCmd} ln -s ${configDockerComposePath}/docker-compose /usr/bin/docker-compose

        rm -f "$(which dc)"
        ${sudoCmd} ln -s ${configDockerComposePath}/docker-compose /usr/bin/dc
        
        # rm -f "/usr/bin/docker-compose"
        # ${sudoCmd} ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
        
        showHeaderGreen "Docker-Compose installed successfully !"
        docker compose version
        echo
    fi

    showHeaderGreen "Docker and Docker Compose Successful installation !"
    # systemctl status docker.service
}

function removeDocker(){

    if [ "$osRelease" == "centos" ] ; then

        sudo yum remove docker docker-common container-selinux docker-selinux docker-engine

    else 
        sudo apt-get remove docker docker-engine

    fi

    rm -rf /var/lib/docker/

    rm -f "$(which dc)" 
    rm -f "/usr/bin/docker-compose"
    rm -f "/usr/local/bin/docker-compose"
    rm -f "${DOCKER_CONFIG}/cli-plugins/docker-compose"

    showHeaderGreen "Docker has been uninstalled !"
}


function addDockerRegistry(){

        cat > "/etc/docker/daemon.json" <<-EOF

{
  "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}

EOF

    ${sudoCmd} systemctl daemon-reload
    ${sudoCmd} systemctl restart docker
}




function installPortainer(){

    echo
    if [ -x "$(command -v docker)" ]; then
        green " Docker already installed"

    else
        red " Docker not install ! "
        exit
    fi

    echo
    docker volume create portainer_data

    echo
    docker pull portainer/portainer-ce
    
    echo
    docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce

    showHeaderGreen " Portainer Successful installation. Running at port 8000 !"
}

















































acmeSSLRegisterEmailInput=""
isDomainSSLGoogleEABKeyInput=""
isDomainSSLGoogleEABIdInput=""

function getHTTPSCertificateCheckEmail(){
    if [ -z $2 ]; then
        
        if [[ $1 == "email" ]]; then
            red " The input email address cannot be empty, please re-enter!"
            getHTTPSCertificateInputEmail
        elif [[ $1 == "googleEabKey" ]]; then
            red " Enter EAB key can not be empty, please re-enter!"
            getHTTPSCertificateInputGoogleEABKey
        elif [[ $1 == "googleEabId" ]]; then
            red " Enter EAB Id cannot be empty, please re-enter!"
            getHTTPSCertificateInputGoogleEABId            
        fi
    fi
}
function getHTTPSCertificateInputEmail(){
    echo
    read -r -p "Please enter your email address to apply for a certificate:" acmeSSLRegisterEmailInput
    getHTTPSCertificateCheckEmail "email" "${acmeSSLRegisterEmailInput}"
}
function getHTTPSCertificateInputGoogleEABKey(){
    echo
    read -r -p "Please enter Google EAB key :" isDomainSSLGoogleEABKeyInput
    getHTTPSCertificateCheckEmail "googleEabKey" "${isDomainSSLGoogleEABKeyInput}"
}
function getHTTPSCertificateInputGoogleEABId(){
    echo
    read -r -p "Please enter Google EAB id :" isDomainSSLGoogleEABIdInput
    getHTTPSCertificateCheckEmail "googleEabId" "${isDomainSSLGoogleEABIdInput}"
}

configNetworkRealIp=""
configSSLDomain=""

acmeSSLDays="89"
acmeSSLServerName="letsencrypt"
acmeSSLDNSProvider="dns_cf"

configRanPath="${HOME}/ran"
configSSLAcmeScriptPath="${HOME}/.acme.sh"
configWebsiteFatherPath="/nginxweb"
configSSLCertPath="${configWebsiteFatherPath}/cert"
configSSLCertPathV2board="${configWebsiteFatherPath}/cert/v2board"
configSSLCertKeyFilename="server.key"
configSSLCertFullchainFilename="server.crt"




function getHTTPSCertificateWithAcme(){

    # ApplicationhttpsCertificate
	mkdir -p ${configSSLCertPath}
	mkdir -p ${configWebsitePath}
	curl https://get.acme.sh | sh

    echo
    green " ================================================== "
    green " Please select a certificate provider, the default is to apply for a certificate through Letsencrypt.org "
    green " If the certificate application fails, such as too many applications through Letsencrypt.org in one day, you can choose BuyPass.com or ZeroSSL.com to apply."
    green " 1 Letsencrypt.org "
    green " 2 BuyPass.com "
    green " 3 ZeroSSL.com "
    green " 4 Google Public CA "
    echo
    read -r -p "Please select a certificate provider? The default is to apply through Letsencrypt.org, please enter pure numbers:" isDomainSSLFromLetInput
    isDomainSSLFromLetInput=${isDomainSSLFromLetInput:-1}
    
    if [[ "$isDomainSSLFromLetInput" == "2" ]]; then
        getHTTPSCertificateInputEmail
        acmeSSLDays="179"
        acmeSSLServerName="buypass"
        echo
        ${configSSLAcmeScriptPath}/acme.sh --register-account --accountemail ${acmeSSLRegisterEmailInput} --server buypass
        
    elif [[ "$isDomainSSLFromLetInput" == "3" ]]; then
        getHTTPSCertificateInputEmail
        acmeSSLServerName="zerossl"
        echo
        ${configSSLAcmeScriptPath}/acme.sh --register-account -m ${acmeSSLRegisterEmailInput} --server zerossl

    elif [[ "$isDomainSSLFromLetInput" == "4" ]]; then
        green " ================================================== "
        yellow " Please follow the link below to apply google Public CA  https://hostloc.com/thread-993780-1-1.html"
        yellow " For details, please refer to https://github.com/acmesh-official/acme.sh/wiki/Google-Public-CA"
        getHTTPSCertificateInputEmail
        acmeSSLServerName="google"
        getHTTPSCertificateInputGoogleEABKey
        getHTTPSCertificateInputGoogleEABId
        ${configSSLAcmeScriptPath}/acme.sh --register-account -m ${acmeSSLRegisterEmailInput} --server google --eab-kid ${isDomainSSLGoogleEABIdInput} --eab-hmac-key ${isDomainSSLGoogleEABKeyInput}    
    else
        acmeSSLServerName="letsencrypt"
        #${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --webroot ${configWebsitePath} --keylength ec-256 --days 89 --server letsencrypt
    fi


    echo
    green " ================================================== "
    green " Please select the acme.sh script to apply for the SSL certificate method: 1 http method, 2 dns method "
    green " The default is to press Enter directly to apply for http, otherwise it is to use dns"
    echo
    read -r -p "Please select an SSL certificate application method[Y/n]:" isAcmeSSLRequestMethodInput
    isAcmeSSLRequestMethodInput=${isAcmeSSLRequestMethodInput:-Y}
    echo

    if [[ $isAcmeSSLRequestMethodInput == [Yy] ]]; then
        acmeSSLHttpWebrootMode=""

        if [[ "${isInstallNginx}" == "true" ]]; then
            acmeDefaultValue="3"
            acmeDefaultText="3. webroot and use ran as a temporary web server"
            acmeSSLHttpWebrootMode="webrootran"
        else
            acmeDefaultValue="1"
            acmeDefaultText="1. standalone model"
            acmeSSLHttpWebrootMode="standalone"
        fi

        if [ -z "$1" ]; then
            green " ================================================== "
            green " please choose http How to apply for a certificate: The default is to enter directly ${acmeDefaultText} "
            green " 1 standalone model, Suitable for no web server installed, If you have chosen not to install Nginx please choose this model. Please make sure that port 80 is not occupied. Note: If port 80 is occupied after three months, the renewal will fail!"
            green " 2 webroot model, Suitable for already installed web server, E.g Caddy Apache or Nginx, Make sure the web server is running on port 80"
            green " 3 webroot model and use ran as a temporary web server, If you have chosen to install Nginx at the same time，please use this model, Can be renewed normally"
            green " 4 nginx model Fits already installed Nginx, please ensure Nginx already running"
            echo
            read -r -p "please choose httpHow to apply for a certificate? The default is ${acmeDefaultText}, Please enter pure numbers:" isAcmeSSLWebrootModeInput
       
            isAcmeSSLWebrootModeInput=${isAcmeSSLWebrootModeInput:-${acmeDefaultValue}}
            
            if [[ ${isAcmeSSLWebrootModeInput} == "1" ]]; then
                acmeSSLHttpWebrootMode="standalone"
            elif [[ ${isAcmeSSLWebrootModeInput} == "2" ]]; then
                acmeSSLHttpWebrootMode="webroot"
            elif [[ ${isAcmeSSLWebrootModeInput} == "4" ]]; then
                acmeSSLHttpWebrootMode="nginx"
            else
                acmeSSLHttpWebrootMode="webrootran"
            fi
        else
            if [[ $1 == "standalone" ]]; then
                acmeSSLHttpWebrootMode="standalone"
            elif [[ $1 == "webroot" ]]; then
                acmeSSLHttpWebrootMode="webroot"
            elif [[ $1 == "webrootran" ]] ; then
                acmeSSLHttpWebrootMode="webrootran"
            elif [[ $1 == "nginx" ]] ; then
                acmeSSLHttpWebrootMode="nginx"
            fi
        fi

        echo
        if [[ ${acmeSSLHttpWebrootMode} == "standalone" ]] ; then
            green " Start applying for a certificate acme.sh pass http standalone mode from ${acmeSSLServerName} Application, please ensure port 80 is not occupied "
            
            echo
            ${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --standalone --keylength ec-256 --days ${acmeSSLDays} --server ${acmeSSLServerName}
        
        elif [[ ${acmeSSLHttpWebrootMode} == "webroot" ]] ; then
            green " Start Application Certificate, acme.sh pass http webroot mode from ${acmeSSLServerName} Application, please ensure webserver E.g nginx already running on port 80  "
            
            echo
            read -r -p "Please enter the html website root directory path of the web server? E.g/usr/share/nginx/html:" isDomainSSLNginxWebrootFolderInput
            echo " The website root directory path you entered is ${isDomainSSLNginxWebrootFolderInput}"
            

            if [ -z "${isDomainSSLNginxWebrootFolderInput}" ]; then
                red " Enter the web server's html website root directory path cannot be empty, The website root will be set by default to ${configWebsitePath}, Please modify your web server configuration and then apply the certificate!"
            else
                configWebsitePath="${isDomainSSLNginxWebrootFolderInput}"
            fi
            
            echo
            ${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --webroot ${configWebsitePath} --keylength ec-256 --days ${acmeSSLDays} --server ${acmeSSLServerName}
        
        elif [[ ${acmeSSLHttpWebrootMode} == "nginx" ]] ; then
            green " Start Application Certificate, acme.sh pass http nginx mode from ${acmeSSLServerName} Application, please ensure webserver nginx already running "
            
            echo
            ${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --nginx --keylength ec-256 --days ${acmeSSLDays} --server ${acmeSSLServerName}

        elif [[ ${acmeSSLHttpWebrootMode} == "webrootran" ]] ; then

            # https://github.com/m3ng9i/ran/issues/10

            ranDownloadUrl="https://github.com/m3ng9i/ran/releases/download/v0.1.6/ran_linux_amd64.zip"
            ranDownloadFileName="ran_linux_amd64"
            
            if [[ "${osArchitecture}" == "arm64" || "${osArchitecture}" == "arm" ]]; then
                ranDownloadUrl="https://github.com/m3ng9i/ran/releases/download/v0.1.6/ran_linux_arm64.zip"
                ranDownloadFileName="ran_linux_arm64"
            fi


            mkdir -p ${configRanPath}
            
            if [[ -f "${configRanPath}/${ranDownloadFileName}" ]]; then
                green " detected ran already downloaded, ready to start ran temporary web server "
            else
                green " start download ran as temporary web server "
                downloadAndUnzip "${ranDownloadUrl}" "${configRanPath}" "${ranDownloadFileName}" 
                chmod +x "${configRanPath}/${ranDownloadFileName}"
            fi

            echo "nohup ${configRanPath}/${ranDownloadFileName} -l=false -g=false -sa=true -p=80 -r=${configWebsitePath} >/dev/null 2>&1 &"
            nohup ${configRanPath}/${ranDownloadFileName} -l=false -g=false -sa=true -p=80 -r=${configWebsitePath} >/dev/null 2>&1 &
            echo
            
            green " Start Application Certificate, acme.sh pass http webroot mode from ${acmeSSLServerName} Application, and use ran as temporary web server "
            echo
            ${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --webroot ${configWebsitePath} --keylength ec-256 --days ${acmeSSLDays} --server ${acmeSSLServerName}

            sleep 4
            ps -C ${ranDownloadFileName} -o pid= | xargs -I {} kill {}
        fi

    else
        green " Start Application Certificate, acme.sh pass dns mode Application "

        echo
        green "please choose DNS provider DNS provider: 1 CloudFlare, 2 AliYun,  3 DNSPod(Tencent), 4 GoDaddy "
        red "Notice CloudFlare For some free domains E.g .tk .cf etc. Use of API ApplicationDNS certificates is no longer supported "
        echo
        read -r -p "please choose DNS provider ? The default is to enter directly 1. CloudFlare, Please enter pure numbers:" isAcmeSSLDNSProviderInput
        isAcmeSSLDNSProviderInput=${isAcmeSSLDNSProviderInput:-1}    

        
        if [ "$isAcmeSSLDNSProviderInput" == "2" ]; then
            read -r -p "Please Input Ali Key: " Ali_Key
            export Ali_Key="${Ali_Key}"
            read -r -p "Please Input Ali Secret: " Ali_Secret
            export Ali_Secret="${Ali_Secret}"
            acmeSSLDNSProvider="dns_ali"

        elif [ "$isAcmeSSLDNSProviderInput" == "3" ]; then
            read -r -p "Please Input DNSPod API ID: " DP_Id
            export DP_Id="${DP_Id}"
            read -r -p "Please Input DNSPod API Key: " DP_Key
            export DP_Key="${DP_Key}"
            acmeSSLDNSProvider="dns_dp"

        elif [ "$isAcmeSSLDNSProviderInput" == "4" ]; then
            read -r -p "Please Input GoDaddy API Key: " gd_Key
            export GD_Key="${gd_Key}"
            read -r -p "Please Input GoDaddy API Secret: " gd_Secret
            export GD_Secret="${gd_Secret}"
            acmeSSLDNSProvider="dns_gd"

        else
            read -r -p "Please Input CloudFlare Email: " cf_email
            export CF_Email="${cf_email}"
            read -r -p "Please Input CloudFlare Global API Key: " cf_key
            export CF_Key="${cf_key}"
            acmeSSLDNSProvider="dns_cf"
        fi
        
        echo
        ${configSSLAcmeScriptPath}/acme.sh --issue -d "${configSSLDomain}" --dns ${acmeSSLDNSProvider} --force --keylength ec-256 --server ${acmeSSLServerName} --debug 
        
    fi

    echo
    if [[ ${isAcmeSSLWebrootModeInput} == "1" ]]; then
        ${configSSLAcmeScriptPath}/acme.sh --installcert --ecc -d ${configSSLDomain} \
        --key-file ${configSSLCertPath}/${configSSLCertKeyFilename} \
        --fullchain-file ${configSSLCertPath}/${configSSLCertFullchainFilename} 
    else
        ${configSSLAcmeScriptPath}/acme.sh --installcert --ecc -d ${configSSLDomain} \
        --key-file ${configSSLCertPath}/${configSSLCertKeyFilename} \
        --fullchain-file ${configSSLCertPath}/${configSSLCertFullchainFilename} \
        --reloadcmd "systemctl restart nginx.service"
    fi
    green " ================================================== "

}



function compareRealIpWithLocalIp(){
    echo
    echo
    green " Check whether the IP pointed to by the domain name is correct. Press Enter to check by default."
    red " If the IP pointed to by the domain name is not the local IP, or the CDN is turned on, it is inconvenient to close, or the VPS only has IPv6, you can choose whether to not detect"
    read -r -p "Check whether the IP pointed to by the domain name is correct? please enter[Y/n]:" isDomainValidInput
    isDomainValidInput=${isDomainValidInput:-Y}

    if [[ $isDomainValidInput == [Yy] ]]; then
        if [ -n "$1" ]; then
            configNetworkRealIp=$(ping $1 -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
            # https://unix.stackexchange.com/questions/22615/how-can-i-get-my-external-ip-address-in-a-shell-script
            configNetworkLocalIp1="$(curl http://whatismyip.akamai.com/)"
            configNetworkLocalIp2="$(curl https://checkip.amazonaws.com/)"
            #configNetworkLocalIp3="$(curl https://ipv4.icanhazip.com/)"
            #configNetworkLocalIp4="$(curl https://v4.ident.me/)"
            #configNetworkLocalIp5="$(curl https://api.ip.sb/ip)"
            #configNetworkLocalIp6="$(curl https://ipinfo.io/ip)"
            
            #configNetworkLocalIPv61="$(curl https://ipv6.icanhazip.com/)"
            #configNetworkLocalIPv62="$(curl https://v6.ident.me/)"

            green " ================================================== "
            green " The domain name resolution address is ${configNetworkRealIp}, The IP of this VPS is ${configNetworkLocalIp1} "

            echo
            if [[ ${configNetworkRealIp} == "${configNetworkLocalIp1}" || ${configNetworkRealIp} == "${configNetworkLocalIp2}" ]] ; then

                green " The IP address of the domain name resolution is normal!"
                green " ================================================== "
                true
            else
                red " The domain name resolution address and the IP address of this VPS are inconsistent!"
                red " This installation failed，please ensure The domain name resolution is normal, please check whether the domain name and DNS are valid!"
                green " ================================================== "
                false
            fi
        else
            green " ================================================== "        
            red "     Domain name entered incorrectly!"
            green " ================================================== "        
            false
        fi
        
    else
        green " ================================================== "
        green "     Do not check whether the domain name resolution is correct!"
        green " ================================================== "
        true
    fi
}



acmeSSLRegisterEmailInput=""
isDomainSSLGoogleEABKeyInput=""
isDomainSSLGoogleEABIdInput=""



function getHTTPSCertificateStep1(){

    testLinuxPortUsage

    echo
    green " ================================================== "
    yellow " please enter the domain name bound to this VPS E.gwww.xxx.com: (In this step, please close CDN and install after nginx to avoid application certificate failure due to port 80 occupation)"
    read -r -p "please enter the domain name resolved to this VPS:" configSSLDomain
    
    if compareRealIpWithLocalIp "${configSSLDomain}" ; then
        echo
        green " =================================================="
        green " Whether Application certificate? The default is to enter directlyApplicationCertificate, such as the second installation or existing certificate, you can choose No"
        green " If you already have an SSL certificate file, please put it in the following path"
        red " ${configSSLDomain} Domain name certificate content file path ${configSSLCertPath}/${configSSLCertFullchainFilename} "
        red " ${configSSLDomain} Domain name certificate private key file path ${configSSLCertPath}/${configSSLCertKeyFilename} "
        echo

        read -r -p "Is it an Application certificate? The default is to enter directly Automatic Application Certificate,please enter[Y/n]?" isDomainSSLRequestInput
        isDomainSSLRequestInput=${isDomainSSLRequestInput:-Y}

        if [[ $isDomainSSLRequestInput == [Yy] ]]; then
            
            getHTTPSCertificateWithAcme ""

            if test -s "${configSSLCertPath}/${configSSLCertFullchainFilename}"; then
                green " =================================================="
                green "   Domain name SSL certificate Application success !"
                green " ${configSSLDomain} Domain name certificate content file path ${configSSLCertPath}/${configSSLCertFullchainFilename} "
                green " ${configSSLDomain} Domain name certificate private key file path ${configSSLCertPath}/${configSSLCertKeyFilename} "
                green " =================================================="

            else
                red "==================================="
                red " Domain name certificate private key file path!"
                red " Please check whether the domain name and DNS are valid. Please do not apply the same domain name multiple times in one day.!"
                red " Please check whether ports 80 and 443 are open, VPS service providers may need to add additional firewall rules, E.g Alibaba Cloud, Google Cloud, etc.!"
                red " Restart the VPS, re-execute the script, you can re-select the repair certificate option and apply the certificate again ! "
                red "==================================="
                exit
            fi

        else
            green " =================================================="
            green "  If you do not have the certificate of the Application domain name, please put the certificate in the following directory, or modify the configuration yourself! "
            green "  ${configSSLDomain} Domain name certificate content file path ${configSSLCertPath}/${configSSLCertFullchainFilename} "
            green "  ${configSSLDomain} Domain name certificate private key file path ${configSSLCertPath}/${configSSLCertKeyFilename} "
            green " =================================================="
        fi
    else
        exit
    fi

}




















































































configAlistPort="$(($RANDOM + 4000))"
configAlistPort="5244"
configAlistSystemdServicePath="/etc/systemd/system/alist.service"


function installAlist(){
    echo
    green " =================================================="
    green " please choose install/update/remove Alist "
    green " 1. Install Alist "
    green " 2. Install Alist + Nginx (A domain name is required and resolved to the local IP)"
    green " 3. renew Alist"  
    red " 4. delete Alist"     
    echo
    read -r -p "Please enter pure numbers, The default is install:" languageInput
    
    createUserWWW

    case "${languageInput}" in
        1 )
            curl -fsSL "https://nn.ci/alist.sh" | bash -s install
            sed -i "/^\[Service\]/a \User=www-data" ${configAlistSystemdServicePath}
            ${sudoCmd} systemctl daemon-reload
            ${sudoCmd} systemctl restart alist       
        ;;
        2 )
            curl -fsSL "https://nn.ci/alist.sh" | bash -s install
            sed -i "/^\[Service\]/a \User=www-data" ${configAlistSystemdServicePath}
            ${sudoCmd} systemctl daemon-reload
            ${sudoCmd} systemctl restart alist    

            green " ================================================== "
            echo
            green "Whether to install Nginx web server, install Nginx to improve security and provide more features"
            green "If you want to install Nginx, you need to provide a domain name, and set the domain name DNS to resolve to the local IP"
            read -r -p "Do you want to install Nginx web server? Enter directly to install by default, please enter[Y/n]:" isNginxAlistInstallInput
            isNginxAlistInstallInput=${isNginxAlistInstallInput:-Y}

            if [[ "${isNginxAlistInstallInput}" == [Yy] ]]; then
                isInstallNginx="true"
                configSSLCertPath="${configSSLCertPath}/alist"
                getHTTPSCertificateStep1
                configInstallNginxMode="alist"
                installWebServerNginx
            fi
        ;;        
        3 )
            curl -fsSL "https://nn.ci/alist.sh" | bash -s update
        ;;
        4 )
            curl -fsSL "https://nn.ci/alist.sh" | bash -s uninstall
        ;;
        * )
            exit
        ;;
    esac
    echo
    green " =================================================="
    green " Alist The installation path is /opt/alist "
    green " =================================================="

}
function installAlistCert(){
        configSSLCertPath="${configSSLCertPath}/alist"
        getHTTPSCertificateStep1
}   































wwwUsername="www-data"
function createUserWWW(){
	isHaveWwwUser=$(cat /etc/passwd | cut -d ":" -f 1 | grep ^${wwwUsername}$)
	if [ "${isHaveWwwUser}" != "${wwwUsername}" ]; then
		${sudoCmd} groupadd ${wwwUsername}
		${sudoCmd} useradd -s /usr/sbin/nologin -g ${wwwUsername} ${wwwUsername} --no-create-home         
	fi
}
function createNewUserNologin(){
    newUsername=${1:-etherpad}
    if [[ -z $(cat /etc/passwd | grep ${newUsername}) ]]; then
        ${sudoCmd} useradd -M -s /sbin/nologin ${newUsername}
    fi
}
function createNewUser(){
    newUsername=${1:-etherpad}
    if [[ -z $(cat /etc/passwd | grep ${newUsername}) ]]; then
        ${sudoCmd} useradd -rm ${newUsername} -U
        if [ "$osRelease" == "centos" ]; then
            usermod -aG wheel ${newUsername}
        else
            usermod -aG sudo ${newUsername} 
        fi
    fi
}

configCloudrevePath="/usr/local/cloudreve"
configCloudreveDownloadCodeFolder="${configCloudrevePath}/download"
configCloudreveCommandFolder="${configCloudrevePath}/cmd"
configCloudreveReadme="${configCloudrevePath}/cmd/readme.txt"
configCloudreveIni="${configCloudrevePath}/cmd/conf.ini"
configCloudrevePort="$(($RANDOM + 4000))"


function installCloudreve(){

    if [ -f "${configCloudreveCommandFolder}/cloudreve" ]; then
        green " =================================================="
        green "     Cloudreve Already installed !"
        green " =================================================="
        exit
    fi

    createUserWWW

    versionCloudreve=$(getGithubLatestReleaseVersion2 "cloudreve/Cloudreve")

    green " ================================================== "
    green "   Prepare to install Cloudreve ${versionCloudreve}"
    green " ================================================== "


    mkdir -p ${configCloudreveDownloadCodeFolder}
    mkdir -p ${configCloudreveCommandFolder}
    cd ${configCloudrevePath}


    # https://github.com/cloudreve/Cloudreve/releases/download/3.5.3/cloudreve_3.5.3_linux_amd64.tar.gz
    # https://github.com/cloudreve/Cloudreve/releases/download/3.4.2/cloudreve_3.4.2_linux_arm.tar.gz
    # https://github.com/cloudreve/Cloudreve/releases/download/3.4.2/cloudreve_3.4.2_linux_arm64.tar.gz
    

    downloadFilenameCloudreve="cloudreve_${versionCloudreve}_linux_amd64.tar.gz"
    if [[ ${osArchitecture} == "arm" ]] ; then
        downloadFilenameCloudreve="cloudreve_${versionCloudreve}_linux_arm.tar.gz"
    fi
    if [[ ${osArchitecture} == "arm64" ]] ; then
        downloadFilenameCloudreve="cloudreve_${versionCloudreve}_linux_arm64.tar.gz"
    fi

    downloadAndUnzip "https://github.com/cloudreve/Cloudreve/releases/download/${versionCloudreve}/${downloadFilenameCloudreve}" "${configCloudreveDownloadCodeFolder}" "${downloadFilenameCloudreve}"

    mv ${configCloudreveDownloadCodeFolder}/cloudreve ${configCloudreveCommandFolder}/cloudreve
    chmod +x ${configCloudreveCommandFolder}/cloudreve


    cd ${configCloudreveCommandFolder}
    echo "nohup ${configCloudreveCommandFolder}/cloudreve > ${configCloudreveReadme} 2>&1 &"
    nohup ${configCloudreveCommandFolder}/cloudreve > ${configCloudreveReadme} 2>&1 &
    sleep 3
    pidCloudreve=$(ps -ef | grep cloudreve | grep -v grep | awk '{print $2}')
    echo "kill -9 ${pidCloudreve}"
    kill -9 ${pidCloudreve}
    echo

    ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${configCloudrevePath}
    ${sudoCmd} chmod -R 771 ${configCloudrevePath}


    cat > ${osSystemMdPath}cloudreve.service <<-EOF
[Unit]
Description=Cloudreve
Documentation=https://docs.cloudreve.org
After=network.target
Wants=network.target

[Service]
User=${wwwUsername}
WorkingDirectory=${configCloudreveCommandFolder}
ExecStart=${configCloudreveCommandFolder}/cloudreve -c ${configCloudreveIni}
Restart=on-abnormal
RestartSec=5s
KillMode=mixed

StandardOutput=null
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOF

    echo
    echo "Install cloudreve systemmd service ..."
    sed -i "s/5212/${configCloudrevePort}/g" ${configCloudreveIni}
    sed -i "s/5212/${configCloudrevePort}/g" ${configCloudreveReadme}

    systemctl daemon-reload
    systemctl start cloudreve
    systemctl enable cloudreve

    ${configCloudreveCommandFolder}/cloudreve -eject

    ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${configCloudrevePath}
    ${sudoCmd} chmod -R 771 ${configCloudrevePath}


    echo
    green " ================================================== "
    green " Cloudreve Installed ! Working port: ${configCloudrevePort}"
    green " Please visit http://your ip:${configCloudrevePort}"
    green " If you can't access, please set Firewall firewall rules to let go ${configCloudrevePort} port"
    green " View running status command: systemctl status cloudreve  reboot: systemctl restart cloudreve "
    green " Cloudreve INI configuration file path: ${configCloudreveIni}"
    green " Cloudreve Default SQLite database file path: ${configCloudreveCommandFolder}/cloudreve.db"
    green " Cloudreve readme Account password file path: ${configCloudreveReadme}"
    

    cat ${configCloudreveReadme}
    green " ================================================== "

    echo
    green "Whether to continue the installation Nginx web server, Installing Nginx improves security and provides more features"
    green "To install Nginx Domain name required, And set the domain name DNS has been resolved to the local IP"
    read -p "Whether to install Nginx web server? Enter directly to install by default, please enter[Y/n]:" isNginxInstallInput
    isNginxInstallInput=${isNginxInstallInput:-Y}

    if [[ "${isNginxInstallInput}" == [Yy] ]]; then
        isInstallNginx="true"
        configSSLCertPath="${configSSLCertPath}/cloudreve"
        getHTTPSCertificateStep1
        configInstallNginxMode="cloudreve"
        installWebServerNginx
    fi

}


function removeCloudreve(){

    echo
    read -p "Are you sure to uninstall Cloudreve? Press Enter to uninstall by default, please enter[Y/n]:" isRemoveCloudreveInput
    isRemoveCloudreveInput=${isRemoveCloudreveInput:-Y}

    if [[ "${isRemoveCloudreveInput}" == [Yy] ]]; then
        echo

        if [[ -f "${configCloudreveCommandFolder}/cloudreve" ]]; then
            echo
            green " ================================================== "
            red " Prepare to uninstall Cloudreve"
            green " ================================================== "
            echo

            ${sudoCmd} systemctl stop cloudreve.service
            ${sudoCmd} systemctl disable cloudreve.service

            rm -rf "${configSSLCertPath}/cloudreve"

            rm -rf ${configCloudrevePath}
            rm -f ${osSystemMdPath}cloudreve.service
            rm -f "${nginxConfigSiteConfPath}/cloudreve_site.conf"
            
            systemctl restart nginx.service
            showHeaderGreen "  Cloudreve removed !"
            
        else
            showHeaderRed " Cloudreve not found !"
        fi

    fi

    removeNginx
}






























configWebsitePath="${configWebsiteFatherPath}/html"
nginxAccessLogFilePath="${configWebsiteFatherPath}/nginx-access.log"
nginxErrorLogFilePath="${configWebsiteFatherPath}/nginx-error.log"

nginxConfigPath="/etc/nginx/nginx.conf"
nginxConfigSiteConfPath="/etc/nginx/conf.d"
nginxCloudreveStoragePath="${configWebsitePath}/cloudreve_storage"
nginxAlistStoragePath="${configWebsitePath}/alist_storage"
nginxTempPath="/var/lib/nginx/tmp"
nginxProxyTempPath="/var/lib/nginx/proxy_temp"
isInstallNginx="false"

function installWebServerNginx(){

    echo
    green " ================================================== "
    yellow "     start installation web server nginx !"
    green " ================================================== "
    echo

    if test -s ${nginxConfigPath}; then
        showHeaderRed "Nginx existed, Whether to continue the installation?" "Nginx already exists. Continue the installation? "
        promptContinueOpeartion

        ${sudoCmd} systemctl stop nginx.service
    else

        isInstallNginx="true"

        createUserWWW
        nginxUser="${wwwUsername} ${wwwUsername}"
        
        if [ "$osRelease" == "centos" ]; then
            ${osSystemPackage} install -y nginx-mod-stream
        else
            echo
            groupadd -r -g 4 adm

            apt autoremove -y
            apt-get remove --purge -y nginx-common
            apt-get remove --purge -y nginx-core
            apt-get remove --purge -y libnginx-mod-stream
            apt-get remove --purge -y libnginx-mod-http-xslt-filter libnginx-mod-http-geoip2 libnginx-mod-stream-geoip2 libnginx-mod-mail libnginx-mod-http-image-filter

            apt autoremove -y --purge nginx nginx-common nginx-core
            apt-get remove --purge -y nginx nginx-full nginx-common nginx-core

            #${osSystemPackage} install -y libnginx-mod-stream
        fi

        ${osSystemPackage} install -y nginx
        ${sudoCmd} systemctl enable nginx.service
        ${sudoCmd} systemctl stop nginx.service

        # 解决出现的nginx warning 错误 Failed to parse PID from file /run/nginx.pid: Invalid argument
        # https://www.kancloud.cn/tinywan/nginx_tutorial/753832
        
        mkdir -p /etc/systemd/system/nginx.service.d
        printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
        
        ${sudoCmd} systemctl daemon-reload

    fi





    mkdir -p ${configWebsitePath}
    mkdir -p "${nginxConfigSiteConfPath}"

    rm -rf ${configWebsitePath}/*
    downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/website2.zip" "${configWebsitePath}" "website2.zip"


    nginxConfigServerHttpInput=""

    if [[ "${configInstallNginxMode}" == "airuniverse" ]]; then
        configV2rayWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
        
        echo
        read -r -p "Whether to customize xray Websocket of Path? Enter directly to create a random path by default, please enter custom path (don't enter /):" isV2rayUserWSPathInput
        isV2rayUserWSPathInput=${isV2rayUserWSPathInput:-${configV2rayWebSocketPath}}
        
        if [[ -z $isV2rayUserWSPathInput ]]; then
            echo
        else
            configV2rayWebSocketPath=${isV2rayUserWSPathInput}
        fi

        configV2rayWebSocketPath="9b08c0d789"

        echo
        read -r -p "Enter the port number of xray? Enter directly The default is8799, please enter custom port number [1-65535]:" configV2rayPort
        configV2rayPort=${configV2rayPort:-8799}

        cat > "${nginxConfigSiteConfPath}/airuniverse.conf" <<-EOF

    server {
        listen 443 ssl http2;
        listen [::]:443 http2;
        server_name  $configSSLDomain;

        ssl_certificate       ${configSSLCertPath}/$configSSLCertFullchainFilename;
        ssl_certificate_key   ${configSSLCertPath}/$configSSLCertKeyFilename;
        ssl_protocols         TLSv1.2 TLSv1.3;
        ssl_ciphers           TLS-AES-256-GCM-SHA384:TLS-CHACHA20-POLY1305-SHA256:TLS-AES-128-GCM-SHA256:TLS-AES-128-CCM-8-SHA256:TLS-AES-128-CCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256;

        # Config for 0-RTT in TLSv1.3
        ssl_early_data on;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security "max-age=31536000";
        
        root $configWebsitePath;
        index index.php index.html index.htm;

        location /$configV2rayWebSocketPath {
            proxy_pass http://127.0.0.1:$configV2rayPort;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
    }

    server {
        listen  80;
        server_name  $configSSLDomain;
        root $configWebsitePath;
        index index.php index.html index.htm;
    }

EOF

    elif [[ "${configInstallNginxMode}" == "ghost" ]]; then

        cat > "${nginxConfigSiteConfPath}/ghost_site.conf" <<-EOF

    server {
        listen 443 ssl http2;
        listen [::]:443 http2;
        server_name  $configSSLDomain;

        ssl_certificate       ${configSSLCertPath}/$configSSLCertFullchainFilename;
        ssl_certificate_key   ${configSSLCertPath}/$configSSLCertKeyFilename;
        ssl_protocols         TLSv1.2 TLSv1.3;
        ssl_ciphers           TLS-AES-256-GCM-SHA384:TLS-CHACHA20-POLY1305-SHA256:TLS-AES-128-GCM-SHA256:TLS-AES-128-CCM-8-SHA256:TLS-AES-128-CCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256;

        # Config for 0-RTT in TLSv1.3
        ssl_early_data on;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security "max-age=31536000";
        
        root $configWebsitePath;
        index index.php index.html index.htm;

        location / {
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$http_host;
            proxy_pass http://127.0.0.1:3468;

            # If you want to use the local storage strategy, please delete the comment on the next line and change the size to the theoretical maximum file size
            client_max_body_size  7000m;
        }
    }

    server {
        listen 80;
        listen [::]:80;

        server_name  $configSSLDomain;
        root ${configGhostSitePath}/system/nginx-root; # Used for acme.sh SSL verification (https://acme.sh)
        index index.php index.html index.htm;

        location / {
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$http_host;
            proxy_pass http://127.0.0.1:3468;
        }

        location ~ /.well-known {
            allow all;
        }

        client_max_body_size 50m;
    }


EOF

    elif [[ "${configInstallNginxMode}" == "cloudreve" ]]; then
        mkdir -p ${configWebsitePath}/static
        cp -f -R ${configCloudreveCommandFolder}/statics/* ${configWebsitePath}/static
        mv -f ${configWebsitePath}/static/static/* ${configWebsitePath}/static

        mkdir -p ${nginxCloudreveStoragePath}
        ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${nginxCloudreveStoragePath}
        ${sudoCmd} chmod -R 774 ${nginxCloudreveStoragePath}

        cat > "${nginxConfigSiteConfPath}/cloudreve_site.conf" <<-EOF

    server {
        listen 443 ssl http2;
        listen [::]:443 http2;
        server_name  $configSSLDomain;

        ssl_certificate       ${configSSLCertPath}/$configSSLCertFullchainFilename;
        ssl_certificate_key   ${configSSLCertPath}/$configSSLCertKeyFilename;
        ssl_protocols         TLSv1.2 TLSv1.3;
        ssl_ciphers           TLS-AES-256-GCM-SHA384:TLS-CHACHA20-POLY1305-SHA256:TLS-AES-128-GCM-SHA256:TLS-AES-128-CCM-8-SHA256:TLS-AES-128-CCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256;

        # Config for 0-RTT in TLSv1.3
        ssl_early_data on;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security "max-age=31536000";
        
        root $configWebsitePath;
        index index.php index.html index.htm;

        location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$ {
            expires      3d;
            error_log /dev/null;
            access_log /dev/null;
        }
        
        location ~ .*\.(js|css)?$ {
            expires      24h;
            error_log /dev/null;
            access_log /dev/null; 
        }
        
        location /static {
            root $configWebsitePath;
        }

        location / {

            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$http_host;
            proxy_redirect off;
            proxy_pass http://127.0.0.1:${configCloudrevePort};

            # If you want to use the local storage strategy, please delete the comment on the next line and change the size to the theoretical maximum file size
            client_max_body_size   7000m;
        }
    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configSSLDomain;
        return 301 https://$configSSLDomain\$request_uri;
    }

EOF


    elif [[ "${configInstallNginxMode}" == "alist" ]]; then

        mkdir -p ${nginxAlistStoragePath}
        ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${nginxAlistStoragePath}
        ${sudoCmd} chmod -R 774 ${nginxAlistStoragePath}

        cat > "${nginxConfigSiteConfPath}/alist_site.conf" <<-EOF

    server {
        listen 443 ssl http2;
        listen [::]:443 http2;
        server_name  $configSSLDomain;

        ssl_certificate       ${configSSLCertPath}/$configSSLCertFullchainFilename;
        ssl_certificate_key   ${configSSLCertPath}/$configSSLCertKeyFilename;
        ssl_protocols         TLSv1.2 TLSv1.3;
        ssl_ciphers           TLS-AES-256-GCM-SHA384:TLS-CHACHA20-POLY1305-SHA256:TLS-AES-128-GCM-SHA256:TLS-AES-128-CCM-8-SHA256:TLS-AES-128-CCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256;

        # Config for 0-RTT in TLSv1.3
        ssl_early_data on;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security "max-age=31536000";
        
        root $configWebsitePath;
        index index.php index.html index.htm;

        location / {

            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$http_host;
            proxy_set_header Range \$http_range;
            proxy_set_header If-Range \$http_if_range;
            proxy_redirect off;
            proxy_pass http://127.0.0.1:${configAlistPort};

            # 上传的最大文件尺寸
            client_max_body_size   20000m;
        }
    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configSSLDomain;
        return 301 https://$configSSLDomain\$request_uri;
    }

EOF
    elif [[ "${configInstallNginxMode}" == "grist" ]]; then

        cat > "${nginxConfigSiteConfPath}/grist_site.conf" <<-EOF

    server {
        listen 443 ssl http2;
        listen [::]:443 http2;
        server_name  $configSSLDomain;

        ssl_certificate       ${configSSLCertPath}/$configSSLCertFullchainFilename;
        ssl_certificate_key   ${configSSLCertPath}/$configSSLCertKeyFilename;
        ssl_protocols         TLSv1.2 TLSv1.3;
        ssl_ciphers           TLS-AES-256-GCM-SHA384:TLS-CHACHA20-POLY1305-SHA256:TLS-AES-128-GCM-SHA256:TLS-AES-128-CCM-8-SHA256:TLS-AES-128-CCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256;

        # Config for 0-RTT in TLSv1.3
        ssl_early_data on;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security "max-age=31536000";
        
        root $configWebsitePath;
        index index.php index.html index.htm;

        location / {

            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$http_host;
            proxy_set_header Range \$http_range;
            proxy_set_header If-Range \$http_if_range;
            proxy_redirect off;
            proxy_pass http://127.0.0.1:8484;

        }
    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configSSLDomain;
        return 301 https://$configSSLDomain\$request_uri;
    }
EOF

    elif [[ "${configInstallNginxMode}" == "nocodb" ]]; then

        cat > "${nginxConfigSiteConfPath}/nocodb_site.conf" <<-EOF

    server {
        listen 443 ssl http2;
        listen [::]:443 http2;
        server_name  $configSSLDomain;

        ssl_certificate       ${configSSLCertPath}/$configSSLCertFullchainFilename;
        ssl_certificate_key   ${configSSLCertPath}/$configSSLCertKeyFilename;
        ssl_protocols         TLSv1.2 TLSv1.3;
        ssl_ciphers           TLS-AES-256-GCM-SHA384:TLS-CHACHA20-POLY1305-SHA256:TLS-AES-128-GCM-SHA256:TLS-AES-128-CCM-8-SHA256:TLS-AES-128-CCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256;

        # Config for 0-RTT in TLSv1.3
        ssl_early_data on;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security "max-age=31536000";
        
        root $configWebsitePath;
        index index.php index.html index.htm;

        location / {

            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$http_host;
            proxy_set_header Range \$http_range;
            proxy_set_header If-Range \$http_if_range;
            proxy_redirect off;
            proxy_pass http://127.0.0.1:8080;

        }
    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configSSLDomain;
        return 301 https://$configSSLDomain\$request_uri;
    }
EOF

    elif [[ "${configInstallNginxMode}" == "etherpad" ]]; then

        cat > "${nginxConfigSiteConfPath}/etherpad_site.conf" <<-EOF

    server {
        listen 443 ssl http2;
        listen [::]:443 http2;
        server_name  $configSSLDomain;

        ssl_certificate       ${configSSLCertPath}/$configSSLCertFullchainFilename;
        ssl_certificate_key   ${configSSLCertPath}/$configSSLCertKeyFilename;
        ssl_protocols         TLSv1.2 TLSv1.3;
        ssl_ciphers           TLS-AES-256-GCM-SHA384:TLS-CHACHA20-POLY1305-SHA256:TLS-AES-128-GCM-SHA256:TLS-AES-128-CCM-8-SHA256:TLS-AES-128-CCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256;

        # Config for 0-RTT in TLSv1.3
        ssl_early_data on;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security "max-age=31536000";
        
        root $configWebsitePath;
        index index.php index.html index.htm;

        location / {

            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$http_host;
            proxy_set_header Range \$http_range;
            proxy_set_header If-Range \$http_if_range;
            proxy_redirect off;
            proxy_pass http://127.0.0.1:9001;

        }
    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configSSLDomain;
        return 301 https://$configSSLDomain\$request_uri;
    }
EOF

    else
        echo
    fi


    # https://raw.githubusercontent.com/nginx/nginx/master/conf/mime.types

    cat > "${nginxConfigPath}" <<-EOF

include /etc/nginx/modules-enabled/*.conf;

# user  ${nginxUser};
user root;
worker_processes  auto;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}



http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] '
                      '"\$request" \$status \$body_bytes_sent  '
                      '"\$http_referer" "\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  $nginxAccessLogFilePath  main;
    error_log $nginxErrorLogFilePath;

    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  120;
    client_max_body_size 20m;
    gzip  on;
    proxy_temp_path ${nginxProxyTempPath} 1 2;
    client_body_temp_path ${nginxTempPath}/client_body 1 2;

    ${nginxConfigServerHttpInput}
    
    include ${nginxConfigSiteConfPath}/*.conf; 
}

EOF




    ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${configWebsiteFatherPath}
    ${sudoCmd} chmod -R 774 ${configWebsiteFatherPath}

    # /var/lib/nginx/tmp/client_body /var/lib/nginx/tmp/proxy 权限问题
    mkdir -p "${nginxTempPath}/client_body"
    mkdir -p "${nginxTempPath}/proxy"
    mkdir -p "${nginxProxyTempPath}"

    
    ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${nginxTempPath}
    ${sudoCmd} chmod -R 775 ${nginxTempPath}

    ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${nginxProxyTempPath}
    ${sudoCmd} chmod -R 775 ${nginxProxyTempPath}
    
    ${sudoCmd} systemctl start nginx.service

    echo
    green " ================================================== "
    green " web server nginx Successful installation. site is https://${configSSLDomain}"
    echo
	red " nginx configuration path ${nginxConfigPath} "
	green " nginx access log ${nginxAccessLogFilePath},  error log ${nginxErrorLogFilePath}  "
    green " nginx View log command: journalctl -n 50 -u nginx.service"
	green " nginx start command: systemctl start nginx.service  stop command: systemctl stop nginx.service  reboot command: systemctl restart nginx.service"
	green " nginx View running status command: systemctl status nginx.service "
    green " ================================================== "
    echo

    if [[ "${configInstallNginxMode}" == "alist" ]]; then
        green " Alist Installed ! Working port: ${configAlistPort}"
        green " Please visit https://${configSSLDomain}"
        green " start command: systemctl start alist  stop command: systemctl stop alist "
        green " View running status command: systemctl status alist  reboot: systemctl restart alist "
        green " Cloudreve INI configuration file path: /opt/alist/data/config.json "
        green " Cloudreve Default SQLite database file path: /opt/alist/data/data.db"
        red " Please select Local in Admin Panel-> Account-> Add-> Type, and set the Root Directory Path to ${nginxAlistStoragePath}"

        green " ================================================== "
    fi

    if [[ "${configInstallNginxMode}" == "cloudreve" ]]; then
        green " Cloudreve Installed ! Working port: ${configCloudrevePort}"
        green " Please visit https://${configSSLDomain}"
        green " View running status command: systemctl status cloudreve  reboot: systemctl restart cloudreve "
        green " Cloudreve INI configuration file path: ${configCloudreveIni}"
        green " Cloudreve Default SQLite database file path: ${configCloudreveCommandFolder}/cloudreve.db"
        green " Cloudreve readme Account password file path: ${configCloudreveReadme}"
        red " Please set it as Admin Panel->Storage Policy->Edit Default Storage Policy->Storage Path ${nginxCloudreveStoragePath}"

        cat ${configCloudreveReadme}
        green " ================================================== "
    fi
}

function removeNginx(){

    echo
    read -r -p "Are you sure to uninstallNginx? Press Enter to uninstall by default, please enter[Y/n]:" isRemoveNginxServerInput
    isRemoveNginxServerInput=${isRemoveNginxServerInput:-Y}

    if [[ "${isRemoveNginxServerInput}" == [Yy] ]]; then

        echo
        if [[ -f "${nginxConfigPath}" ]]; then
        
            showHeaderRed "Prepare to uninstall installed nginx"

            ${sudoCmd} systemctl stop nginx.service
            ${sudoCmd} systemctl disable nginx.service

            if [ "$osRelease" == "centos" ]; then
                yum remove -y nginx-mod-stream
                yum remove -y nginx
            else
                apt autoremove -y
                apt-get remove --purge -y nginx-common
                apt-get remove --purge -y nginx-core
                apt-get remove --purge -y libnginx-mod-stream
                apt-get remove --purge -y libnginx-mod-http-xslt-filter libnginx-mod-http-geoip2 libnginx-mod-stream-geoip2 libnginx-mod-mail libnginx-mod-http-image-filter

                apt autoremove -y --purge nginx nginx-common nginx-core
                apt-get remove --purge -y nginx nginx-full nginx-common nginx-core
            fi


            rm -f ${nginxAccessLogFilePath}
            rm -f ${nginxErrorLogFilePath}
            rm -f ${nginxConfigPath}
            rm -rf ${nginxConfigSiteConfPath}

            rm -rf "/etc/nginx"
            
            rm -rf ${configDownloadTempPath}

            echo
            read -r -p "Whether to delete the certificate and uninstall the acme.shApplication certificate tool, because the number of Application certificates in one day is limited, it is recommended not to delete the certificate by default,  please enter[y/N]:" isDomainSSLRemoveInput
            isDomainSSLRemoveInput=${isDomainSSLRemoveInput:-n}

            
            if [[ $isDomainSSLRemoveInput == [Yy] ]]; then
                rm -rf ${configWebsiteFatherPath}
                ${sudoCmd} bash ${configSSLAcmeScriptPath}/acme.sh --uninstall
                
                showHeaderGreen "Nginx Uninstallation is complete, the SSL certificate file has been delete!"

            else
                rm -rf ${configWebsitePath}
                showHeaderGreen "Nginx Uninstallation is complete, the SSL certificate files have been preserved to ${configSSLCertPath} "
            fi

        else
            showHeaderRed "system not installed Nginx, exit uninstall"
        fi
        echo

    fi    
}




















































configEtherpadProjectPath="${HOME}/etherpad"
configEtherpadDockerPath="${HOME}/etherpad/docker"

# Online collaborative Document
function installEtherpad(){
    if [[ -d "${configEtherpadDockerPath}" ]]; then
        showHeaderRed " Etherpad already installed !"
        exit
    fi
    showHeaderGreen "Get started with Docker installation Etherpad "

    createNewUserNologin "etherpad"
    ${sudoCmd} mkdir -p "${configEtherpadDockerPath}/data"
    cd "${configEtherpadDockerPath}" || exit

    ${sudoCmd} chown -R etherpad:root "${configEtherpadDockerPath}"
    ${sudoCmd} chmod -R 774 "${configEtherpadDockerPath}"

    docker pull etherpad/etherpad



    read -r -p "please enterAdmin password (The default is admin):" configEtherpadPasswordInput
    configEtherpadPasswordInput=${configEtherpadPasswordInput:-admin}
    echo

    green " ================================================== "
    echo
    green "Whether to install Nginx web server, Installing Nginx improves security and provides more features"
    green "To install Nginx Domain name required, And set the domain name DNS has been resolved to the local IP"
    echo
    read -r -p "Whether to install Nginx web server? Enter directly to install by default, please enter[Y/n]:" isNginxInstallInput
    isNginxInstallInput=${isNginxInstallInput:-Y}

    echo
    echo "docker run -d -p 9001:9001 -e ADMIN_PASSWORD=${configEtherpadPasswordInput} --name etherpad etherpad/etherpad"
    echo

    if [[ "${isNginxInstallInput}" == [Yy] ]]; then
        isInstallNginx="true"
        configSSLCertPath="${configSSLCertPath}/etherpad"
        getHTTPSCertificateStep1
        configInstallNginxMode="etherpad"
        installWebServerNginx

        docker run -d -p 9001:9001 -e 'ADMIN_PASSWORD=${configEtherpadPasswordInput}' -e TRUST_PROXY=true -v ${configEtherpadDockerPath}/data:/opt/etherpad-lite/var --name etherpad etherpad/etherpad

        ${sudoCmd} systemctl restart nginx.service
        showHeaderGreen "Etherpad install success !  https://${configSSLDomain}" \
        "Admin panel: https://${configSSLDomain}/admin   User: admin, Password: ${configEtherpadPasswordInput}" 
    else
        docker run -d -p 9001:9001 -e 'ADMIN_PASSWORD=${configEtherpadPasswordInput}' -v ${configEtherpadDockerPath}/data:/opt/etherpad-lite/var --name etherpad etherpad/etherpad

        showHeaderGreen "Etherpad install success !  http://your_ip:9001/" \
        "Admin panel: http://your_ip:9001/admin  User: admin, Password: ${configEtherpadPasswordInput}" 
    fi
}

function removeEtherpad(){
    echo
    read -r -p "Are you sure to uninstall Etherpad? Press Enter to uninstall by default, please enter[Y/n]:" isRemoveEtherpadInput
    isRemoveEtherpadInput=${isRemoveEtherpadInput:-Y}

    if [[ "${isRemoveEtherpadInput}" == [Yy] ]]; then

        echo
        if [[ -d "${configEtherpadDockerPath}" ]]; then

            showHeaderGreen "Prepare to uninstall the installed Etherpad"

            dockerIDEtherpad=$(docker ps -a -q --filter ancestor=etherpad/etherpad --format="{{.ID}}")
            if [[ -n "${dockerIDEtherpad}" ]]; then
                ${sudoCmd} docker stop "${dockerIDEtherpad}"
                ${sudoCmd} docker rm "${dockerIDEtherpad}"
            fi

            rm -rf "${configEtherpadProjectPath}"
            rm -f "${nginxConfigSiteConfPath}/etherpad_site.conf"
            
            systemctl restart nginx.service
            showHeaderGreen "Uninstalled successfully Etherpad Docker Version !"
            
        else
            showHeaderRed "system not installed Etherpad, exit uninstall"
        fi

    fi
    removeNginx
}






configNocoDBProjectPath="${HOME}/nocodb"
configNocoDBDockerPath="${HOME}/nocodb/docker"

# Online Spreadsheet
function installNocoDB(){

    if [[ -d "${configNocoDBDockerPath}" ]]; then
        showHeaderRed " NocoDB already installed !"
        exit
    fi
    showHeaderGreen "start Using the Docker way Install NocoDB "

    ${sudoCmd} mkdir -p "${configNocoDBDockerPath}/data"
    cd "${configNocoDBDockerPath}" || exit

    docker pull nocodb/nocodb:latest


    green " ================================================== "
    echo
    green "Whether to install Nginx web server, Installing Nginx improves security and provides more features"
    green "To install Nginx Domain name required, And set the domain name DNS has been resolved to the local IP"
    echo
    read -r -p "Whether to install Nginx web server? Enter directly to install by default, please enter[Y/n]:" isNginxInstallInput
    isNginxInstallInput=${isNginxInstallInput:-Y}

    echo
    echo "docker run -d --name nocodb -p 8080:8080  -v ${configNocoDBDockerPath}/data:/usr/app/data/ nocodb/nocodb:latest"
    echo

    if [[ "${isNginxInstallInput}" == [Yy] ]]; then
        isInstallNginx="true"
        configSSLCertPath="${configSSLCertPath}/nocodb"
        getHTTPSCertificateStep1
        configInstallNginxMode="nocodb"
        installWebServerNginx

        docker run -d --name nocodb -p 8080:8080 -v ${configNocoDBDockerPath}/data:/usr/app/data/ nocodb/nocodb:latest

        ${sudoCmd} systemctl restart nginx.service
        showHeaderGreen "NocoDB install success !  https://${configSSLDomain}" 
    else
        docker run -d --name nocodb -p 8080:8080 -v ${configNocoDBDockerPath}/data:/usr/app/data/ nocodb/nocodb:latest

        showHeaderGreen "NocoDB install success !  http://your_ip:8080/dashboard" 
    fi

}
function removeNocoDB(){
    echo
    read -r -p "Are you sure to uninstallNocoDB? Press Enter to uninstall by default, please enter[Y/n]:" isRemoveNocoDBInput
    isRemoveNocoDBInput=${isRemoveNocoDBInput:-Y}

    if [[ "${isRemoveNocoDBInput}" == [Yy] ]]; then

        echo
        if [[ -d "${configNocoDBDockerPath}" ]]; then

            showHeaderGreen "Prepare to uninstall the installed NocoDB"

            dockerIDNocoDB=$(docker ps -a -q --filter ancestor=nocodb/nocodb --format="{{.ID}}")
            if [[ -n "${dockerIDNocoDB}" ]]; then
                ${sudoCmd} docker stop "${dockerIDNocoDB}"
                ${sudoCmd} docker rm "${dockerIDNocoDB}"
            fi

            rm -rf "${configNocoDBProjectPath}"
            rm -f "${nginxConfigSiteConfPath}/nocodb_site.conf"
            
            systemctl restart nginx.service
            showHeaderGreen "Uninstalled successfully NocoDB Docker Version !"
            
        else
            showHeaderRed "system not installed NocoDB, exit uninstall"
        fi

    fi
    removeNginx
}



configGristProjectPath="${HOME}/grist"
configGristDockerPath="${HOME}/grist/docker"
configGristSecretKey="$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 32 | head -c 12)"

# Online Spreadsheet
function installGrist(){

    if [[ -d "${configGristDockerPath}" ]]; then
        showHeaderRed " Grist already installed !"
        exit
    fi
    showHeaderGreen "start Using the Docker way Install Grist "

    ${sudoCmd} mkdir -p ${configGristDockerPath}/persist
    cd "${configGristDockerPath}" || exit

    docker pull gristlabs/grist

    echo
    green " GRIST_SESSION_SECRET:  ${configGristSecretKey}"
    echo

    read -r -p "please enter Email:" configGristEmailInput
    configGristEmailInput=${configGristEmailInput:-you@example.com}
    echo

    read -r -p "please enter Team name:" configGristTeamInput
    configGristTeamInput=${configGristTeamInput:-singleteam}
    echo


    green " ================================================== "
    echo
    green "Whether to install Nginx web server, Installing Nginx improves security and provides more features"
    green "To install Nginx Domain name required, And set the domain name DNS has been resolved to the local IP"
    echo
    read -r -p "Whether to install Nginx web server? Enter directly to install by default, please enter[Y/n]:" isNginxInstallInput
    isNginxInstallInput=${isNginxInstallInput:-Y}

    echo
    echo "docker run -d -p 8484:8484 -v ${configGristDockerPath}/persist:/persist -e GRIST_SANDBOX_FLAVOR=gvisor -e GRIST_SINGLE_ORG=${configGristTeamInput} -e GRIST_SESSION_SECRET=${configGristSecretKey} --env GRIST_DEFAULT_EMAIL=${configGristEmailInput} gristlabs/grist"
    echo

    if [[ "${isNginxInstallInput}" == [Yy] ]]; then
        isInstallNginx="true"
        configSSLCertPath="${configSSLCertPath}/grist"
        getHTTPSCertificateStep1
        configInstallNginxMode="grist"
        installWebServerNginx

        docker run -d --name grist -p 8484:8484 -v ${configGristDockerPath}/persist:/persist -e GRIST_SANDBOX_FLAVOR=gvisor -e GRIST_SINGLE_ORG=${configGristTeamInput} \
        -e GRIST_SESSION_SECRET=${configGristSecretKey} --env GRIST_DEFAULT_EMAIL=${configGristEmailInput} -e APP_HOME_URL="https://${configSSLDomain}"  gristlabs/grist

        ${sudoCmd} systemctl restart nginx.service
        showHeaderGreen "Grist install success !  https://${configSSLDomain}" 
    else
        docker run -d --name grist -p 8484:8484 -v ${configGristDockerPath}/persist:/persist -e GRIST_SANDBOX_FLAVOR=gvisor -e GRIST_SINGLE_ORG=${configGristTeamInput} \
        -e GRIST_SESSION_SECRET=${configGristSecretKey} --env GRIST_DEFAULT_EMAIL=${configGristEmailInput} gristlabs/grist

        showHeaderGreen "Grist install success !  http://your_ip:8484" 
    fi

}
function removeGrist(){
    echo
    read -r -p "Are you sure to uninstallGrist? Press Enter to uninstall by default, please enter[Y/n]:" isRemoveGristInput
    isRemoveGristInput=${isRemoveGristInput:-Y}

    if [[ "${isRemoveGristInput}" == [Yy] ]]; then

        echo
        if [[ -d "${configGristDockerPath}" ]]; then

            showHeaderGreen "Prepare to uninstall the installed Grist"

            dockerIDGrist=$(docker ps -a -q --filter ancestor=gristlabs/grist --format="{{.ID}}")
            if [[ -n "${dockerIDGrist}" ]]; then
                ${sudoCmd} docker stop "${dockerIDGrist}"
                ${sudoCmd} docker rm "${dockerIDGrist}"
            fi


            rm -rf "${configGristProjectPath}"
            rm -f "${nginxConfigSiteConfPath}/grist_site.conf"
            
            systemctl restart nginx.service
            showHeaderGreen "Uninstalled successfully Grist Docker Version !"
        else
            showHeaderRed "system not installed Grist, exit uninstall"
        fi
    fi

    removeNginx
}




































# Video Conference System video conference system Install
function installJitsiMeet(){

    showHeaderGreen "ready to install video conference system Jitsi Meet !" \
    "Minimum Requirements: 4 GB RAM + 2 core CPU "

    echo
    green " =================================================="
    green " please choose Install method: (The default is 1 Docker way)"
    echo
    green " 1. Install Jitsi Meet by Docker"
    green " 2. Install Jitsi Meet directly, only support Debian 10 / Ubuntu 20.04"   
    echo
    read -r -p "Please enter pure numbers, The default is1 Docker way:" jitsimeetDockerInput
    
    case "${jitsimeetDockerInput}" in
        1 )
            installJitsiMeetByDocker    
        ;;
        2 )
            installJitsiMeetOnUbuntu
        ;;        
    
        * )
            installJitsiMeetByDocker
        ;;
    esac
}

configJitsiMeetProjectPath="${HOME}/jitsi_meet"
configJitsiMeetDockerPath="${HOME}/jitsi_meet/docker"
configJitsiMeetDownloadPath="${HOME}/jitsi_meet/download"

function installJitsiMeetByDocker(){
    
    if [ -f "${configJitsiMeetDockerPath}/docker-compose.yml" ]; then
        showHeaderRed "Jitsi Meet already installed !"
        exit
    fi

    showHeaderGreen "start installation Jitsi Meet by Docker"

    mkdir -p "${configJitsiMeetDownloadPath}"

    versionJitsiMeet=$(getGithubLatestReleaseVersion2 "jitsi/docker-jitsi-meet")
    #versionJitsiMeet="stable-7648-1"

    downloadAndUnzip "https://github.com/jitsi/docker-jitsi-meet/archive/refs/tags/${versionJitsiMeet}.zip" "${configJitsiMeetProjectPath}" "${versionJitsiMeet}.zip"

    # https://github.com/jitsi/docker-jitsi-meet/archive/refs/tags/stable-7439-2.zip

    mv -f "${configJitsiMeetProjectPath}/docker-jitsi-meet-${versionJitsiMeet}" "${configJitsiMeetProjectPath}/docker"

    cd "${configJitsiMeetDockerPath}" || exit
    cp -f "${configJitsiMeetDockerPath}/env.example"  "${configJitsiMeetDockerPath}/.env"

    "${configJitsiMeetDockerPath}/gen-passwords.sh"

    mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}

    configLocalVPSIp="$(curl https://ipv4.icanhazip.com/)"

    green " =================================================="
    echo
    read -r -p "please enter has been resolved to the domain name of the machine: " configSSLDomain
    echo
    read -r -p "please enter Email is used for Application SSL domain name certificate: " configEmailForSSLDomain
    echo

    sed -i "s|HTTP_PORT=8000|HTTP_PORT=80|g" "${configJitsiMeetDockerPath}/.env"
    sed -i "s|HTTPS_PORT=8443|HTTPS_PORT=443|g" "${configJitsiMeetDockerPath}/.env"
    sed -i "/HTTPS_PORT=443/a \ \nENABLE_HTTP_REDIRECT=1 \n " "${configJitsiMeetDockerPath}/.env"

    sed -i "s|#PUBLIC_URL=https:\/\/meet.example.com|PUBLIC_URL=https:\/\/${configSSLDomain}|g" "${configJitsiMeetDockerPath}/.env"
    sed -i "s|#DOCKER_HOST_ADDRESS=192.168.1.1|DOCKER_HOST_ADDRESS=${configLocalVPSIp}|g" "${configJitsiMeetDockerPath}/.env"
    
    sed -i "s|#ENABLE_LETSENCRYPT=1|ENABLE_LETSENCRYPT=1|g" "${configJitsiMeetDockerPath}/.env"
    sed -i "s|#LETSENCRYPT_DOMAIN=meet.example.com|LETSENCRYPT_DOMAIN=${configSSLDomain}|g" "${configJitsiMeetDockerPath}/.env"
    sed -i "s|#LETSENCRYPT_EMAIL=alice@atlanta.net|LETSENCRYPT_EMAIL=${configEmailForSSLDomain}|g" "${configJitsiMeetDockerPath}/.env"

    


    addPasswordForJitsiMeetDocker "first"


    showHeaderGreen "Jitsi Meet installed successfully!" "Visit https://${configSSLDomain} " \
    "stop command: docker-compose down | start command: docker-compose up -d " \
    "Jitsi Meet project file path ${configJitsiMeetDockerPath} " \
    "Web configuration file path ${HOME}/.jitsi-meet-cfg/web/config.js " \
    "View logs web: docker-compose logs -t -f web" \
    "View logs prosody: docker-compose logs -t -f prosody" \
    "View logs jvb: docker-compose logs -t -f jvb" \
    "View logs jicofo: docker-compose logs -t -f jicofo" 


}

function addPasswordForJitsiMeetDocker(){

    cd "${configJitsiMeetDockerPath}" || exit

    if [[ -z "$1" ]]; then
        
        docker-compose down
    else
        echo
    fi

    green " =================================================="
    echo
    green " Whether a password is required to initiate a meeting? The default is No Anyone can initiate a meeting"
    echo
    read -r -p "Whether a password is required to initiate a meeting? Enter directly The default is否, please enter[y/N]:" isJitsiMeetNeedPasswordInput
    isJitsiMeetNeedPasswordInput=${isJitsiMeetNeedPasswordInput:-N}

    if [[ ${isJitsiMeetNeedPasswordInput} == [Yy] ]]; then

        sed -i "s|#ENABLE_AUTH=1|ENABLE_AUTH=1|g" "${configJitsiMeetDockerPath}/.env"
        sed -i "s|#AUTH_TYPE=internal|AUTH_TYPE=internal|g" "${configJitsiMeetDockerPath}/.env"

        sed -i "s|#ENABLE_GUESTS=1|ENABLE_GUESTS=1|g" "${configJitsiMeetDockerPath}/.env"

        docker-compose up -d

        echo
        read -r -p "please enter Initiate meeting username, Enter directly The default isjitsi : " isJitsiMeetUsernameInput
        isJitsiMeetUsernameInput=${isJitsiMeetUsernameInput:-jitsi}
        echo
        read -r -p "please enter user's password, Enter directly The default isjitsi :" isJitsiMeetUserPasswordInput
        isJitsiMeetUserPasswordInput=${isJitsiMeetUserPasswordInput:-jitsi}
        echo


        docker-compose exec prosody prosodyctl --config /config/prosody.cfg.lua register ${isJitsiMeetUsernameInput} meet.jitsi ${isJitsiMeetUserPasswordInput}

        # User list: find /config/data/meet%2ejitsi/accounts -type f -exec basename {} .dat \;

    else

        sed -i "s|#\?ENABLE_AUTH=1|#ENABLE_AUTH=1|g" "${configJitsiMeetDockerPath}/.env"
        sed -i "s|#\?AUTH_TYPE=internal|#AUTH_TYPE=internal|g" "${configJitsiMeetDockerPath}/.env"

        sed -i "s|#\?ENABLE_GUESTS=1|#ENABLE_GUESTS=1|g" "${configJitsiMeetDockerPath}/.env"

        docker-compose up -d
    fi

    showHeaderGreen "Check document below for JWT and LDAP authentication" \
    "Docs: https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker#authentication"

}



configJitsiMeetVideoBridgeFilePath="/etc/jitsi/videobridge/sip-communicator.properties"
configJitsiMeetNginxConfigFolderPath="/etc/nginx/sites-available"
configJitsiMeetNginxConfigFolder2Path="/etc/nginx/sites-enabled"
configJitsiMeetNginxConfigOriginalFolderPath="/etc/nginx/conf.d"

function installJitsiMeetOnUbuntu(){

    if [ "$osRelease" == "centos" ]; then
        showHeaderRed "not support CentOS system!  Not support CentOS!"
        exit
    else
        sed -i '/packages.prosody.im/d' /etc/apt/sources.list

        ${sudoCmd} apt update -y 
        ${sudoCmd} apt install -y apt-transport-https

        if [ "$osRelease" == "ubuntu" ]; then
            ${sudoCmd} apt-add-repository universe -y
            ${sudoCmd} apt update -y 
        fi
    fi

    # Add the Prosody package repository
    echo "deb http://packages.prosody.im/debian $(lsb_release -sc) main" | ${sudoCmd} tee -a /etc/apt/sources.list
    wget https://prosody.im/files/prosody-debian-packages.key -O- | ${sudoCmd} apt-key add -

    # Add the Jitsi package repository
    curl https://download.jitsi.org/jitsi-key.gpg.key | ${sudoCmd} sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
    echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" | ${sudoCmd} tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null
    
    green " =================================================="
    ${sudoCmd} apt-get -y update
    green " =================================================="
    
    showInfoGreen "Setting firewall rules"
    ${sudoCmd} ufw allow 80/tcp
    ${sudoCmd} ufw allow 443/tcp
    ${sudoCmd} ufw allow 10000/udp

    ${sudoCmd} ufw allow 3478/udp
    ${sudoCmd} ufw allow 5349/tcp

    echo
    #echo "ufw enable"
    #${sudoCmd} ufw enable
    echo
    echo "ufw status verbose"
    ${sudoCmd} ufw status verbose


    showHeaderGreen "start installation Jitsi Meet"

    mkdir -p ${configJitsiMeetNginxConfigFolderPath}
    mkdir -p ${configJitsiMeetNginxConfigFolder2Path}
    
    # https://jitsi.org/downloads/ubuntu-debian-installations-instructions/    
    ${sudoCmd} apt-get -y install jitsi-meet

    #sudo apt-get -y install jigasi


    showHeaderGreen "Setting up nginx configuration"

    #configJitsiMeetNginxConfigFilePath="${configJitsiMeetNginxConfigFolderPath}/${configSSLDomain}.conf"
    #sed -i "s|jitsi-meet.example.com|${configSSLDomain}|g" "${configJitsiMeetNginxConfigFilePath}"

    ln -s ${configJitsiMeetNginxConfigFolderPath}/* ${configJitsiMeetNginxConfigOriginalFolderPath}/
    ${sudoCmd} systemctl restart nginx


    showHeaderGreen "Generate certificate with letsencrypt"
    ${sudoCmd} /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh

    # configSSLCertPath="${configSSLCertPath}/jitsimeet"
    # getHTTPSCertificateStep1

    # cp -f ${configSSLCertPath}/fullchain.cer "/etc/jitsi/meet/${configSSLDomain}.crt"
    # cp -f ${configSSLCertPath}/private.key "/etc/jitsi/meet/${configSSLDomain}.key"

    # /nginxweb/cert/jitsimeet/fullchain.cer
    # /nginxweb/cert/jitsimeet/private.key


    showHeaderGreen "Setting up jitsi meet local IP configuration"

    configLocalVPSIp="$(curl https://ipv4.icanhazip.com/)"
    echo
    read -r -p "please enter Native IP: Enter directly The default is ${configLocalVPSIp}" jitsimeetVPSIPInput
    jitsimeetVPSIPInput=${jitsimeetVPSIPInput:-${configLocalVPSIp}}

    sed -i 's|#\?org.ice4j.ice.harvest.STUN_MAPPING_HARVESTER_ADDRESSES|#org.ice4j.ice.harvest.STUN_MAPPING_HARVESTER_ADDRESSES|g' ${configJitsiMeetVideoBridgeFilePath}

    sed -i '/org.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS/d' ${configJitsiMeetVideoBridgeFilePath}
    sed -i '/org.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS/d' ${configJitsiMeetVideoBridgeFilePath}

    echo "org.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS=${jitsimeetVPSIPInput}" >> ${configJitsiMeetVideoBridgeFilePath}
    echo "org.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS=${jitsimeetVPSIPInput}" >> ${configJitsiMeetVideoBridgeFilePath}


    sed -i 's|#\?DefaultLimitNOFILE=.*|DefaultLimitNOFILE=65000|g' /etc/systemd/system.conf
    sed -i 's|#\?DefaultLimitNPROC=.*|DefaultLimitNPROC=65000|g' /etc/systemd/system.conf
    sed -i 's|#\?DefaultTasksMax=.*|DefaultTasksMax=65000|g' /etc/systemd/system.conf


    echo
    systemctl show --property DefaultLimitNPROC
    systemctl show --property DefaultLimitNOFILE
    systemctl show --property DefaultTasksMax

    ${sudoCmd} systemctl daemon-reload 

    secureAddPasswordForJitsiMeet "first"

    showHeaderGreen "Jitsi Meet installed successfully!" "Running port 80 443 4443 10000 3478 5349 !" \
    "reboot Videobridge Order: systemctl restart jitsi-videobridge2 | Log: /var/log/jitsi/jvb.log" \
    "reboot jicofo Order: systemctl restart jicofo | Log: /var/log/jitsi/jicofo.log" \
    "reboot XMPP Order: systemctl restart prosody | Log: /var/log/prosody/prosody.log"

}

function secureAddPasswordForJitsiMeet(){
    if [ -f "${configJitsiMeetDockerPath}/.env" ]; then
        addPasswordForJitsiMeetDocker
        exit
    fi
    
    green " =================================================="
    echo
    read -r -p "please enter has been resolved to the domain name of the machine: " configSSLDomain
    echo

    configJitsiMeetConfigFilePath="/etc/jitsi/meet/${configSSLDomain}-config.js"
    configJitsiMeetProsodyFilePath="/etc/prosody/conf.avail/${configSSLDomain}.cfg.lua"
    configJitsiMeetJicofoFilePath="/etc/jitsi/jicofo/jicofo.conf"

    echo
    green " Whether a password is required to initiate a meeting? The default is No Anyone can initiate a meeting"
    echo
    read -r -p "Whether a password is required to initiate a meeting? Enter directly The default is否, please enter[y/N]:" isJitsiMeetNeedPasswordInput
    isJitsiMeetNeedPasswordInput=${isJitsiMeetNeedPasswordInput:-N}

    if [[ ${isJitsiMeetNeedPasswordInput} == [Yy] ]]; then

        #sed -i 's|#\?authentication =.*|authentication = "jitsi-anonymous"|g' "${configJitsiMeetProsodyFilePath}"
        #sed -i 's|#\?authentication =.*|authentication = "internal_plain"|g' "${configJitsiMeetProsodyFilePath}"
        sed -i 's|#\?authentication =.*|authentication = "internal_hashed"|g' "${configJitsiMeetProsodyFilePath}"

        read -r -d '' configJitsiMeetProsodyVhost << EOM
VirtualHost "guest.${configSSLDomain}"
    authentication = "anonymous"
    c2s_require_encryption = false

EOM

        TEST1="${configJitsiMeetProsodyVhost//\\/\\\\}"
        TEST1="${TEST1//\//\\/}"
        TEST1="${TEST1//&/\\&}"
        TEST1="${TEST1//$'\n'/\\n}"

        sed -i "/muc_lobby_whitelist /a ${TEST1} \ \ " "${configJitsiMeetProsodyFilePath}"

        sed -i "/anonymousdomain/a \        anonymousdomain: 'guest.${configSSLDomain}'," "${configJitsiMeetConfigFilePath}"


        read -r -d '' configJitsiMeetJicofoVhost << EOM
    authentication: {
        enabled: true
        type: XMPP
        login-url: ${configSSLDomain}
    }

EOM

        TEST3="${configJitsiMeetJicofoVhost//\\/\\\\}"
        TEST3="${TEST3//\//\\/}"
        TEST3="${TEST3//&/\\&}"
        TEST3="${TEST3//$'\n'/\\n}"

        sed -i "/xmpp/i \    ${TEST3} \ \ " "${configJitsiMeetJicofoFilePath}"


        echo
        read -r -p "please enter Initiate meeting username, Enter directly The default isjitsi : " isJitsiMeetUsernameInput
        isJitsiMeetUsernameInput=${isJitsiMeetUsernameInput:-jitsi}
        echo
        read -r -p "please enter user's password, Enter directly The default isjitsi :" isJitsiMeetUserPasswordInput
        isJitsiMeetUserPasswordInput=${isJitsiMeetUserPasswordInput:-jitsi}
        echo

        ${sudoCmd} prosodyctl register "${isJitsiMeetUsernameInput}" "${configSSLDomain}" "${isJitsiMeetUserPasswordInput}"
        # User list:  /var/lib/prosody/v%2evr360%2ecf/accounts
   
        echo 
        green "Use the following command to add new user: " 
        yellow "prosodyctl register username domain_name password"
        green "Docs: https://prosody.im/doc/prosodyctl#user-management"
        echo
        echo

        showHeaderGreen "Please manually modify Jigasi configuration if you are using Jigasi" "Docs: https://jitsi.github.io/handbook/docs/devops-guide/secure-domain/"

    else 
        echo
        # https://stackoverflow.com/questions/4396974/sed-or-awk-delete-n-lines-following-a-pattern

        if [[ -z "$1" ]]; then
            sed -i 's|#\?authentication =.*|authentication = "jitsi-anonymous"|g' "${configJitsiMeetProsodyFilePath}"
            sed -i "/guest.${configSSLDomain}/{N;N;d}" "${configJitsiMeetProsodyFilePath}"

            sed -i "/anonymousdomain: 'guest.${configSSLDomain}/d" "${configJitsiMeetConfigFilePath}"

            sed -i "/authentication:/,+4d" "${configJitsiMeetJicofoFilePath}"
        fi
    fi

    ${sudoCmd} systemctl daemon-reload 
    ${sudoCmd} systemctl restart prosody
    ${sudoCmd} systemctl restart jicofo
    ${sudoCmd} systemctl restart jitsi-videobridge2
    ${sudoCmd} systemctl restart nginx

}

function removeJitsiMeet(){

    
    if [ -f "${configJitsiMeetDockerPath}/.env" ]; then
        showHeaderGreen "ready to uninstall Jitsi Meet Docker "

        cd "${configJitsiMeetDockerPath}" || exit

        docker-compose down

        rm -rf "${configJitsiMeetDockerPath}"
        rm -rf "${HOME}/.jitsi-meet-cfg"

        showHeaderGreen "Uninstalled successfully Jitsi Meet Docker Version !"
    else
        showHeaderRed "not found Jitsi Meet Docker !"

        showHeaderGreen "ready to uninstall video conferencing system Jitsi Meet non-Docker InstallVersion !"

        if [ "$osRelease" == "centos" ]; then
            showHeaderRed " not support CentOS system"
        else

            ${sudoCmd} apt purge -y jigasi jitsi-meet jitsi-meet-web-config jitsi-meet-prosody jitsi-meet-turnserver jitsi-meet-web jicofo jitsi-videobridge2 prosody
            ${sudoCmd} apt autoremove -y
            ${sudoCmd} apt purge -y jicofo jitsi-videobridge2 
            ${sudoCmd} apt autoremove -y

            rm -f /etc/prosody/prosody.cfg.lua
            rm -rf /etc/letsencrypt/live/*
            rm -rf /etc/letsencrypt/archive/*
            rm -f /etc/letsencrypt/renewal/*
            rm -f /etc/letsencrypt/keys/*

            showHeaderGreen "Uninstalled successfully Jitsi Meet non-Docker InstallVersion !"
        fi

        removeNginx    
    fi

    
}








































































configGhostProjectPath="/opt/ghost"
configGhostDockerPath="/opt/ghost/docker"
configGhostSitePath="/opt/ghost/site"
ghostUser="ghostsite"

function installCMSGhost(){
    if [[ -d "${configGhostDownloadPath}" ]]; then
        showHeaderRed "Ghost already installed !"
        exit
    fi
    showHeaderGreen "Prepare to install Ghost !"

    if ! command -v npm &> /dev/null ; then
        showHeaderRed "Npm could not be found, Please install Nodejs first !"
        exit
    fi

    isInstallNginx="true"
    configSSLCertPath="${configSSLCertPath}/ghost"
    getHTTPSCertificateStep1
    configInstallNginxMode="ghost"
    installWebServerNginx


    
    createNewUser "${ghostUser}"
    # passwd "${ghostUser}" ghost2022user

    # https://stackoverflow.com/questions/714915/using-the-passwd-command-from-within-a-shell-script
    echo "ghost2022user" | passwd "${ghostUser}" --stdin
    red " Password for linux user ghostsite: ghost2022user"
    echo

    ${sudoCmd} mkdir -p "${configGhostSitePath}"

    ${sudoCmd} chown -R ${ghostUser}:${ghostUser} "${configGhostProjectPath}"
    ${sudoCmd} chmod -R 775  "${configGhostProjectPath}"

    cd "${configGhostSitePath}" || exit
    ${sudoCmd} npm install ghost-cli@latest -g
    
    # su - "ghost" -c cd "${configGhostSitePath}"

    su - ${ghostUser} << EOF
    echo "--------------------"
    echo "Current user:"
    whoami
    echo
    cd "${configGhostSitePath}"
    ghost install --port 3468 --db=sqlite3 --no-setup-nginx --no-setup-ssl --no-setup-mysql --no-stack --no-prompt --dir ${configGhostSitePath} --url https://${configSSLDomain}
    echo "--------------------"
EOF

    echo
    echo "Current user: $(whoami)"
    echo

    showHeaderGreen "Ghost installed successfully! " \
    "Ghost Admin panel:  http://localhost:3468/ghost" \
    "The SQLite3 database located in ${configGhostSitePath}/content/data"

    showHeaderGreen " Please manually run following command if installation failed: " \
    "su - ${ghostUser}" \
    "cd ${configGhostSitePath}" \
    "ghost install --port 3468 --db=sqlite3 --no-setup-nginx --no-setup-ssl --no-setup-mysql --no-stack --no-prompt --dir ${configGhostSitePath} --url https://${configSSLDomain}"
    red "Input password 'ghost2022user' when ask for linux user 'ghostsite' password"


        read -r -d '' ghostConfigEmailInput << EOM
    "mail": {
      "from": "annajscool@freair.com",
      "transport": "SMTP",
      "options": {
        "host": "smtp.gmail.com",
        "service": "Gmail",
        "port": "465",
        "secure": true,
        "auth": {
          "user": "jinwyp2@gmail.com",
          "pass": "aslgotjzmwrkuvto"
        }
      }
    },
EOM


}


function removeCMSGhost(){
    echo
    read -r -p "Are you sure to uninstallGhost? Press Enter to uninstall by default, please enter[Y/n]:" isRemoveGhostInput
    isRemoveGhostInput=${isRemoveGhostInput:-Y}

    if [[ "${isRemoveGhostInput}" == [Yy] ]]; then

        echo
        if [[ -d "${configGhostSitePath}" ]]; then

            showHeaderGreen "Prepare to uninstall the installed Ghost"

    su - ${ghostUser} << EOF
    echo "--------------------"
    echo "Current user:"
    whoami
    echo
    cd "${configGhostSitePath}"
    ghost stop
    ghost uninstall
    echo "--------------------"
EOF

            userdel -r "${ghostUser}"

            rm -rf "${configGhostSitePath}"
            rm -f "${nginxConfigSiteConfPath}/ghost_site.conf"
            
            systemctl restart nginx.service
            showHeaderGreen "Uninstalled successfully Ghost !"
        else
            showHeaderRed "system not installed Ghost, exit uninstall"
        fi

    fi
    removeNginx

}






























configSogaConfigFilePath="/etc/soga/soga.conf"

function installSoga(){
    echo
    green " =================================================="
    green "  start installation Server-side program that supports V2board panels soga !"
    green " =================================================="
    echo

    # wget -O soga_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/sprov065/soga/master/install.sh" && chmod +x soga_install.sh && ./soga_install.sh
    wget -O soga_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/vaxilu/soga/master/install.sh" && chmod +x soga_install.sh && ./soga_install.sh

    replaceSogaConfig
}

function replaceSogaConfig(){

    if test -s ${configSogaConfigFilePath}; then

        echo
        green "please chooseSSL certificateApplication method: 1 Soga's built-in http method, 2 passacme.shApplication and place the certificate file"
        green "The default is to enter directly Soga's built-in http automatic Application model"
        green "choose no then passacme.shApplication certificate and place the certificate file, Support http and dnsmodel Application certificates, recommend this model"
        echo
        green "Notice: Soga There are 3 types of SSL certificate Application methods: 1 Soga's built-in http method, 2 Soga's built-in dns method, 3 Manually place certificate files "
        green "use if necessary Soga's built-in dns method Application SSL certificate method, Please edit manually soga.conf configuration file"
        echo
        read -p "please chooseSSL certificateApplication method ? The default is to enter directly http automatic Application model, choose no pass acme.sh manual Application and put the certificate, please enter[Y/n]:" isSSLRequestHTTPInput
        isSSLRequestHTTPInput=${isSSLRequestHTTPInput:-Y}

        if [[ $isSSLRequestHTTPInput == [Yy] ]]; then
            echo
            green " ================================================== "
            yellow " please enter is bound to the domain name of this VPS E.gwww.xxx.com: (In this step, please close the CDN and install after nginx to avoid the failure of the Application certificate due to port 80 occupation)"
            green " ================================================== "

            read configSSLDomain

            sed -i 's/cert_mode=/cert_mode=http/g' ${configSogaConfigFilePath}
        else
            configSSLCertPath="${configSSLCertPathV2board}"
            getHTTPSCertificateStep1
            sed -i "s?cert_file=?cert_file=${configSSLCertPath}/${configSSLCertFullchainFilename}?g" ${configSogaConfigFilePath}
            sed -i "s?key_file=?key_file=${configSSLCertPath}/${configSSLCertKeyFilename}?g" ${configSogaConfigFilePath}

        fi

        sed -i 's/type=sspanel-uim/type=v2board/g' ${configSogaConfigFilePath}

        sed -i "s/cert_domain=/cert_domain=${configSSLDomain}/g" ${configSogaConfigFilePath}

        read -p "please enter Panel Domain Name E.g www.123.com Do not prefix with http or https Don't bring the end/ :" inputV2boardDomain
        sed -i "s?webapi_url=?webapi_url=https://${inputV2boardDomain}/?g" ${configSogaConfigFilePath}

        read -p "please enterwebapi key communication key:" inputV2boardWebApiKey
        sed -i "s/webapi_key=/webapi_key=${inputV2boardWebApiKey}/g" ${configSogaConfigFilePath}

        read -p "please enter Node ID (pure numbers):" inputV2boardNodeId
        sed -i "s/node_id=1/node_id=${inputV2boardNodeId}/g" ${configSogaConfigFilePath}
    
        soga restart 

    fi

    manageSoga
}


function manageSoga(){
    echo -e ""
    echo "soga How to use the management script: "
    echo "------------------------------------------"
    echo "soga                    - Show management menu (more functions)"
    echo "soga start              - start up soga"
    echo "soga stop               - stop soga"
    echo "soga restart            - reboot soga"
    echo "soga status             - Check soga state"
    echo "soga enable             - set up soga Auto-start"
    echo "soga disable            - Cancel soga Auto-start"
    echo "soga log                - Check soga log"
    echo "soga update             - renew soga"
    echo "soga update x.x.x       - renew soga Specified version"
    echo "soga config             - show configuration file contents"
    echo "soga config xx=xx yy=yy - auto set upconfiguration file"
    echo "soga install            - Install soga"
    echo "soga uninstall          - uninstall soga"
    echo "soga version            - Check soga Version"
    echo "------------------------------------------"
}

function editSogaConfig(){
    vi ${configSogaConfigFilePath}
}



















configXrayRAccessLogFilePath="${HOME}/xrayr-access.log"
configXrayRErrorLogFilePath="${HOME}/xrayr-error.log"

configXrayRConfigFilePath="/etc/XrayR/config.yml"

function installXrayR(){
    echo
    green " =================================================="
    green "  start installation Server-side program that supports V2board panels XrayR !"
    green " =================================================="
    echo

    testLinuxPortUsage

    # https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh
    # https://raw.githubusercontent.com/Misaka-blog/XrayR-script/master/install.sh
    # https://raw.githubusercontent.com/long2k3pro/XrayR-release/master/install.sh

    wget -O xrayr_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/long2k3pro/XrayR-release/master/install.sh" && chmod +x xrayr_install.sh && ./xrayr_install.sh

    replaceXrayRConfig
}


function replaceXrayRConfig(){

    if test -s ${configXrayRConfigFilePath}; then

        echo
        green "please chooseSSL certificateApplication method: 1 XrayR built-in http Way, 2 passacme.sh Application and place the certificate file, "
        green "The default is to enter directly XrayR built-in http automatic Application model"
        green "choose no then passacme.shApplication certificate, Support more modelApplication certificates such as http and dns, it is recommended to use"
        echo
        green "Notice: XrayR There are 4 types of SSL certificates for Application Way: 1 XrayR built-in http Way, 2 XrayR built-in dns Way, 3 file Manually place certificate files, 4 none Not Application certificate"
        green "use if necessary XrayR built-indns Application SSL certificate method, Please edit manually ${configXrayRConfigFilePath} configuration file"
    
        read -p "please chooseSSL certificateApplication method ? The default is to enter directlyhttp automatic Application model, choose no则Manually place certificate files will also automatically apply the certificate, please enter[Y/n]:" isSSLRequestHTTPInput
        isSSLRequestHTTPInput=${isSSLRequestHTTPInput:-Y}

        configXrayRSSLRequestMode="http"
        if [[ $isSSLRequestHTTPInput == [Yy] ]]; then
            echo
            green " ================================================== "
            yellow " please enter is bound to the domain name of this VPS E.g www.xxx.com: (In this step, please close the CDN and install after nginx to avoid the failure of the Application certificate due to port 80 occupation)"
            green " ================================================== "

            read configSSLDomain

        else
            configSSLCertPath="${configSSLCertPathV2board}"
            getHTTPSCertificateStep1
            configXrayRSSLRequestMode="file"
        
            sed -i "s?./cert/node1.test.com.cert?${configSSLCertPath}/${configSSLCertFullchainFilename}?g" ${configXrayRConfigFilePath}
            sed -i "s?./cert/node1.test.com.key?${configSSLCertPath}/${configSSLCertKeyFilename}?g" ${configXrayRConfigFilePath}

        fi

        sed -i "s/CertMode: dns/CertMode: ${configXrayRSSLRequestMode}/g" ${configXrayRConfigFilePath}
        sed -i 's/CertDomain: "node1.test.com"/CertDomain: "www.xxxx.net"/g' ${configXrayRConfigFilePath}
        sed -i "s/www.xxxx.net/${configSSLDomain}/g" ${configXrayRConfigFilePath}

        echo
        read -p "please Choose Supported Panel Types ? The default is to enter directlyV2board, choose no then SSpanel, please enter[Y/n]:" isXrayRPanelTypeInput
        isXrayRPanelTypeInput=${isXrayRPanelTypeInput:-Y}
        configXrayRPanelType="SSpanel"

        if [[ $isXrayRPanelTypeInput == [Yy] ]]; then
            configXrayRPanelType="V2board"
            sed -i 's/PanelType: "SSpanel"/PanelType: "V2board"/g' ${configXrayRConfigFilePath}
        fi

        
        echo
        green "please enter Panel Domain Name, E.g www.123.com Do not prefix with httporhttps Do not end with /"
        green "Please ensure that the input domain name of other panels of V2boardor supports Https access, If you want to change to http Please edit manually configuration file ${configXrayRConfigFilePath}"
        read -p "please enter Panel Domain Name :" inputV2boardDomain
        sed -i "s?http://127.0.0.1:667?https://${inputV2boardDomain}?g" ${configXrayRConfigFilePath}

        read -p "please enter ApiKey communication key:" inputV2boardWebApiKey
        sed -i "s/123/${inputV2boardWebApiKey}/g" ${configXrayRConfigFilePath}

        read -p "please enter Node ID (pure numbers):" inputV2boardNodeId
        sed -i "s/41/${inputV2boardNodeId}/g" ${configXrayRConfigFilePath}
    

        echo
        read -p "please Node types supported by choose ? The default is to enter directlyV2ray, choose no is Trojan, please enter[Y/n]:" isXrayRNodeTypeInput
        isXrayRNodeTypeInput=${isXrayRNodeTypeInput:-Y}
        configXrayRNodeType="V2ray"

        if [[ $isXrayRNodeTypeInput == [Nn] ]]; then
            configXrayRNodeType="Trojan"
            sed -i 's/NodeType: V2ray/NodeType: Trojan/g' ${configXrayRConfigFilePath}

        else
            echo
            read -p "Whether to enable Vless protocol for V2ray ? By default, press Enter to select No, the Vmess protocol is enabled by default, and the Vless protocol is enabled by selecting Yes, please enter[y/N]:" isXrayRVlessSupportInput
            isXrayRVlessSupportInput=${isXrayRVlessSupportInput:-N}

            if [[ $isXrayRVlessSupportInput == [Yy] ]]; then
                sed -i 's/EnableVless: false/EnableVless: true/g' ${configXrayRConfigFilePath}
            fi

            echo
            read -p "Do you want to enable XTLS for V2ray? By default, press Enter to select No, Tls is enabled by default, and XTLS is enabled if Yes is selected, please enter[y/N]:" isXrayRXTLSSupportInput
            isXrayRXTLSSupportInput=${isXrayRXTLSSupportInput:-N}

            if [[ $isXrayRXTLSSupportInput == [Yy] ]]; then
                sed -i 's/EnableXTLS: false/EnableXTLS: true/g' ${configXrayRConfigFilePath}
            fi

        fi


        sed -i "s?# ./access.Log?${configXrayRAccessLogFilePath}?g" ${configXrayRConfigFilePath}
        sed -i "s?# ./error.log?${configXrayRErrorLogFilePath}?g" ${configXrayRConfigFilePath}
        sed -i "s?Level: none?Level: info?g" ${configXrayRConfigFilePath}
            

        XrayR restart 

    fi

    manageXrayR
}


function manageXrayR(){
    echo -e ""
    echo "XrayR How to use the management script (Compatible with xrayr execution, case insensitive): "
    echo "------------------------------------------"
    echo "XrayR                    - Show admin menu (function more)"
    echo "XrayR start              - start up XrayR"
    echo "XrayR stop               - stop XrayR"
    echo "XrayR restart            - reboot XrayR"
    echo "XrayR status             - Check XrayR state"
    echo "XrayR enable             - set up XrayR Auto-start"
    echo "XrayR disable            - Cancel XrayR Auto-start"
    echo "XrayR log                - Check XrayR log"
    echo "XrayR update             - renew XrayR"
    echo "XrayR update x.x.x       - renew XrayR Specified version"
    echo "XrayR config             - show configuration file contents"
    echo "XrayR install            - Install XrayR"
    echo "XrayR uninstall          - uninstall XrayR"
    echo "XrayR version            - Check XrayR Version"
    echo "------------------------------------------"
}

function editXrayRConfig(){
    vi ${configXrayRConfigFilePath}
}




























function installAiruAndNginx(){
    isInstallNginx="true"
    configSSLCertPath="${configSSLCertPathV2board}"
    getHTTPSCertificateStep1
    configInstallNginxMode="airuniverse"
    installWebServerNginx


    sed -i 's/\"force_close_tls\": \?false/\"force_close_tls\": true/g' ${configAirUniverseConfigFilePath}

    systemctl restart xray.service
    airu restart

}











function downgradeXray(){
    echo
    green " =================================================="
    green "  Prepare to downgrade Xray and Air-Universe !"
    green " =================================================="
    echo


    yellow " please choose Air-Universe Version to downgrade to, No downgrade by default"
    red " Notice Air-Universe latest version not support Xray 1.5.0 or older Version"
    red " use if necessary Xray 1.5.0 or Older Versions of Xray, please choose Air-Universe 1.0.0 or 0.9.2"
    echo
    green " 1. Do not downgrade Use the latest version"
    green " 2. 1.1.1 (not support Xray 1.5.0 or Older Version)"
    green " 3. 1.0.0 (only supported Xray 1.5.0 or Older Version)"
    green " 4. 0.9.2 (only supported Xray 1.5.0 or Older Version)"
    echo
    read -p "please chooseAir-UniverseVersion? Enter directly and select 1 by default, Please enter pure numbers:" isAirUniverseVersionInput
    isAirUniverseVersionInput=${isAirUniverseVersionInput:-1}


    downloadAirUniverseVersion=$(getGithubLatestReleaseVersion "crossfw/Air-Universe")
    downloadAirUniverseUrl="https://github.com/crossfw/Air-Universe/releases/download/v${downloadAirUniverseVersion}/Air-Universe-linux-64.zip"

    if [[ "${isAirUniverseVersionInput}" == "2" ]]; then
        downloadAirUniverseVersion="1.1.1"
    elif [[ "${isAirUniverseVersionInput}" == "3" ]]; then
        downloadAirUniverseVersion="1.0.0"
    elif [[ "${isAirUniverseVersionInput}" == "4" ]]; then
        downloadAirUniverseVersion="0.9.2"
    else
        echo
    fi

    if [[ "${isAirUniverseVersionInput}" == "1" ]]; then
        green " =================================================="
        green "  Selected not to downgrade Use the latest version Air-Universe ${downloadAirUniverseVersion}"
        green " =================================================="
        echo
    else
        # https://github.com/crossfw/Air-Universe/releases/download/v1.0.2/Air-Universe-linux-arm32-v6.zip
        # https://github.com/crossfw/Air-Universe/releases/download/v1.0.2/Air-Universe-linux-arm64-v8a.zip

        downloadAirUniverseUrl="https://github.com/crossfw/Air-Universe/releases/download/v${downloadAirUniverseVersion}/Air-Universe-linux-64.zip"
        airUniverseDownloadFilename="Air-Universe-linux-64_${downloadAirUniverseVersion}.zip"

        if [[ "${osArchitecture}" == "arm64" ]]; then
            downloadAirUniverseUrl="https://github.com/crossfw/Air-Universe/releases/download/v${downloadAirUniverseVersion}/Air-Universe-linux-arm64-v8a.zip"
            airUniverseDownloadFilename="Air-Universe-linux-arm64-v8a_${downloadAirUniverseVersion}.zip"
        fi

        if [[ "${osArchitecture}" == "arm" ]]; then
            downloadAirUniverseUrl="https://github.com/crossfw/Air-Universe/releases/download/v${downloadAirUniverseVersion}/Air-Universe-linux-arm32-v6.zip"
            airUniverseDownloadFilename="Air-Universe-linux-arm32-v6_${downloadAirUniverseVersion}.zip"
        fi


        airUniverseDownloadFolder="/root/airuniverse_temp"
        mkdir -p ${airUniverseDownloadFolder}

        wget -O ${airUniverseDownloadFolder}/${airUniverseDownloadFilename} ${downloadAirUniverseUrl}
        unzip -d ${airUniverseDownloadFolder} ${airUniverseDownloadFolder}/${airUniverseDownloadFilename}
        mv -f ${airUniverseDownloadFolder}/Air-Universe /usr/local/bin/au
        chmod +x /usr/local/bin/*

        rm -rf ${airUniverseDownloadFolder}

    fi



    echo
    yellow " please choose Xray Version to downgrade to, The default is to enter directly do not downgrade"
    echo
    green " 1. Do not downgrade Use the latest version"

     if [[ "${isAirUniverseVersionInput}" == "1" || "${isAirUniverseVersionInput}" == "2" ]]; then
        green " 2. 1.6.1"
        green " 3. 1.6.0"
        green " 4. 1.5.5"
        green " 5. 1.5.4"
        green " 6. 1.5.3"
    else
        green " 7. 1.5.0"
        green " 8. 1.4.5"
        green " 9. 1.4.0"
        green " 0. 1.3.1"
    fi

    echo
    read -p "please choose Xray Version? Enter directly and select 1 by default, Please enter pure numbers:" isXrayVersionInput
    isXrayVersionInput=${isXrayVersionInput:-1}

    downloadXrayVersion=$(getGithubLatestReleaseVersion "XTLS/Xray-core")
    downloadXrayUrl="https://github.com/XTLS/Xray-core/releases/download/v${downloadXrayVersion}/Xray-linux-64.zip"

    if [[ "${isXrayVersionInput}" == "2" ]]; then
        downloadXrayVersion="1.6.1"

    elif [[ "${isXrayVersionInput}" == "3" ]]; then
        downloadXrayVersion="1.6.0"

    elif [[ "${isXrayVersionInput}" == "4" ]]; then
        downloadXrayVersion="1.5.5"

    elif [[ "${isXrayVersionInput}" == "5" ]]; then
        downloadXrayVersion="1.5.4"

    elif [[ "${isXrayVersionInput}" == "6" ]]; then
        downloadXrayVersion="1.5.3"

    elif [[ "${isXrayVersionInput}" == "7" ]]; then
        downloadXrayVersion="1.5.0"

    elif [[ "${isXrayVersionInput}" == "8" ]]; then
        downloadXrayVersion="1.4.5"

    elif [[ "${isXrayVersionInput}" == "9" ]]; then
        downloadXrayVersion="1.4.0"

    elif [[ "${isXrayVersionInput}" == "0" ]]; then
        downloadXrayVersion="1.3.1"
    else
        echo
    fi

    if [[ "${isXrayVersionInput}" == "1" ]]; then
        green " =================================================="
        green "  Do selected not downgrade Use the latest version Xray ${downloadXrayVersion}"
        green " =================================================="
        echo
    else

        # https://github.com/XTLS/Xray-core/releases/download/v1.5.2/Xray-linux-arm32-v6.zip

        downloadXrayUrl="https://github.com/XTLS/Xray-core/releases/download/v${downloadXrayVersion}/Xray-linux-64.zip"
        xrayDownloadFilename="Xray-linux-64_${downloadXrayVersion}.zip"

        if [[ "${osArchitecture}" == "arm64" ]]; then
            downloadXrayUrl="https://github.com/XTLS/Xray-core/releases/download/v${downloadXrayVersion}/Xray-linux-arm64-v8a.zip"
            xrayDownloadFilename="Xray-linux-arm64-v8a_${downloadXrayVersion}.zip"
        fi

        if [[ "${osArchitecture}" == "arm" ]]; then
            downloadXrayUrl="https://github.com/XTLS/Xray-core/releases/download/v${downloadXrayVersion}/Xray-linux-arm32-v6.zip"
            xrayDownloadFilename="Xray-linux-arm32-v6_${downloadXrayVersion}.zip"
        fi


        xrayDownloadFolder="/root/xray_temp"
        mkdir -p ${xrayDownloadFolder}

        wget -O ${xrayDownloadFolder}/${xrayDownloadFilename} ${downloadXrayUrl}
        unzip -d ${xrayDownloadFolder} ${xrayDownloadFolder}/${xrayDownloadFilename}
        mv -f ${xrayDownloadFolder}/xray /usr/local/bin
        chmod +x /usr/local/bin/*
        rm -rf ${xrayDownloadFolder}

    fi

    if [[ -z $1 ]]; then
        echo
        
        airu stop
        systemctl stop xray.service

        chmod ugoa+rw ${configSSLCertPath}/*
        
        systemctl start xray.service
        echo
        airu start
        echo
        systemctl status xray.service
        echo
    fi    
}



configAirUniverseXrayAccessLogFilePath="${HOME}/xray_access.log"
configAirUniverseXrayErrorLogFilePath="${HOME}/xray_error.log"


configAirUniverseAccessLogFilePath="${HOME}/air-universe-access.log"
configAirUniverseErrorLogFilePath="${HOME}/air-universe-error.log"

configAirUniverseConfigFilePath="/usr/local/etc/au/au.json"
configAirUniverseXrayConfigFilePath="/usr/local/etc/xray/config.json"

configXrayPort="$(($RANDOM + 10000))"

function installAirUniverse(){
    echo
    green " =================================================="
    green "  start installation Server-side program that supports V2board panels Air-Universe !"
    green " =================================================="
    echo
    

    if [ -z "$1" ]; then
        testLinuxPortUsage

        # bash -c "$(curl -L https://github.com/crossfw/Xray-install/raw/main/install-release.sh)" @ install  
        # bash <(curl -Ls https://raw.githubusercontent.com/crossfw/Air-Universe-install/master/install.sh)
        
        # bash <(curl -Ls https://raw.githubusercontent.com/crossfw/Air-Universe-install/master/AirU.sh)
        wget -O /root/airu_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/crossfw/Air-Universe-install/master/AirU.sh" 
        chmod +x /root/airu_install.sh 
        cp -f /root/airu_install.sh /usr/bin/airu
        
        /root/airu_install.sh install 

        (crontab -l ; echo "30 4 * * 0,1,2,3,4,5,6 systemctl restart xray.service ") | sort - | uniq - | crontab -
        (crontab -l ; echo "32 4 * * 0,1,2,3,4,5,6 /usr/bin/airu restart ") | sort - | uniq - | crontab -

        downgradeXray "norestart"
    else
        echo
    fi



    if test -s ${configAirUniverseConfigFilePath}; then

        echo
        green "please chooseSSL certificateApplication method: 1 passacme.sh Application certificate, 2 Not Application certificate"
        green "The default is to enter directlypassacme.sh Application certificate, support http and dns For more WayApplication certificates, it is recommended to use"
        green "Note: Air-Universe There is no automatic certificate acquisition function itself, Use acme.sh Application certificate"
        echo
        read -r -p "please choose SSL certificate Application method ? The default is to enter directly Application Certificate, choose no then Not Application certificate, please enter[Y/n]:" isSSLRequestHTTPInput
        isSSLRequestHTTPInput=${isSSLRequestHTTPInput:-Y}

        if [[ $isSSLRequestHTTPInput == [Yy] ]]; then
            echo
            configSSLCertPath="${configSSLCertPathV2board}"
            getHTTPSCertificateStep1

            airUniverseConfigNodeIdNumberInput=$(grep "nodes_type"  ${configAirUniverseConfigFilePath} | awk -F  ":" '{print $2}')

            read -r -d '' airUniverseConfigProxyInput << EOM
        
        "type": "xray",
        "auto_generate": true,
        "in_tags": ${airUniverseConfigNodeIdNumberInput},
        "api_address": "127.0.0.1",
        "api_port": ${configXrayPort},
        "force_close_tls": false,
        "log_path": "${configAirUniverseAccessLogFilePath}",
        "cert": {
            "cert_path": "${configSSLCertPath}/${configSSLCertFullchainFilename}",
            "key_path": "${configSSLCertPath}/${configSSLCertKeyFilename}"
        },
        "speed_limit_level": [0, 10, 30, 100, 150, 300, 1000]
        
EOM

            # https://stackoverflow.com/questions/6684487/sed-replace-with-variable-with-multiple-lines

            TEST="${airUniverseConfigProxyInput//\\/\\\\}"
            TEST="${TEST//\//\\/}"
            TEST="${TEST//&/\\&}"
            TEST="${TEST//$'\n'/\\n}"

            sed -i "s/\"type\":\"xray\"/${TEST}/g" ${configAirUniverseConfigFilePath}
            sed -i "s/10085/${configXrayPort}/g" ${configAirUniverseXrayConfigFilePath}


            replaceAirUniverseConfigWARP "norestart"
            
            chmod ugoa+rwx ${configSSLCertPath}/${configSSLCertFullchainFilename}
            chmod ugoa+rwx ${configSSLCertPath}/${configSSLCertKeyFilename}
            chmod ugoa+rwx ${configSSLCertPath}/*

            # chown -R nobody:nogroup /var/log/v2ray

            echo
            green " =================================================="
            systemctl restart xray.service
            airu restart
            echo
            echo
            green " =================================================="
            green " Air-Universe Successful installation !"
            green " =================================================="
            
            manageAirUniverse
        else
            echo
            green "Do not Application SSL Certificate"
            read -r -p "Press enter to continue. Press enter to continue airu Order"
            airu
        fi



        green " ================================================== "
        echo
        green "Whether to install Nginx web server, Install Nginx can improve security"
        echo
        read -r -p "Whether to install Nginx web server? Enter directly by default Do not Install, please enter[y/N]:" isNginxAlistInstallInput
        isNginxAlistInstallInput=${isNginxAlistInstallInput:-n}

        if [[ "${isNginxAlistInstallInput}" == [Yy] ]]; then
            isInstallNginx="true"
            configSSLCertPath="${configSSLCertPathV2board}"
            configInstallNginxMode="airuniverse"
            installWebServerNginx

            sed -i 's/\"force_close_tls\": \?false/\"force_close_tls\": true/g' ${configAirUniverseConfigFilePath}

            systemctl restart xray.service
            airu restart
        fi



    else
        manageAirUniverse
    fi



    
}




function inputUnlockV2rayServerInfo(){
            echo
            echo
            yellow " please choose to unlock the protocol of the V2ray or Xray server for streaming "
            green " 1. VLess + TCP + TLS"
            green " 2. VLess + TCP + XTLS"
            green " 3. VLess + WS + TLS (supportCDN)"
            green " 4. VMess + TCP + TLS"
            green " 5. VMess + WS + TLS (supportCDN)"
            echo
                read -p "please choose agreement? Enter directly and select 3 by default, Please enter pure numbers:" isV2rayUnlockServerProtocolInput
            isV2rayUnlockServerProtocolInput=${isV2rayUnlockServerProtocolInput:-3}

            isV2rayUnlockOutboundServerProtocolText="vless"
            if [[ $isV2rayUnlockServerProtocolInput == "4" || $isV2rayUnlockServerProtocolInput == "5" ]]; then
                isV2rayUnlockOutboundServerProtocolText="vmess"
            fi

            isV2rayUnlockOutboundServerTCPText="tcp"
            unlockOutboundServerWebSocketSettingText=""
            if [[ $isV2rayUnlockServerProtocolInput == "3" ||  $isV2rayUnlockServerProtocolInput == "5" ]]; then
                isV2rayUnlockOutboundServerTCPText="ws"
                echo
                yellow " Please fill in the V2ray or Xray server Websocket that can unlock streaming media Path, The default is/"
                read -p "Please fill in Websocket Path? Enter directly The default is/ , please enter(Do not to include/):" isV2rayUnlockServerWSPathInput
                isV2rayUnlockServerWSPathInput=${isV2rayUnlockServerWSPathInput:-""}
                read -r -d '' unlockOutboundServerWebSocketSettingText << EOM
                ,
                "wsSettings": {
                    "path": "/${isV2rayUnlockServerWSPathInput}"
                }
EOM
            fi


            unlockOutboundServerXTLSFlowText=""
            isV2rayUnlockOutboundServerTLSText="tls"
            if [[ $isV2rayUnlockServerProtocolInput == "2" ]]; then
                isV2rayUnlockOutboundServerTCPText="tcp"
                isV2rayUnlockOutboundServerTLSText="xtls"

                echo
                yellow " please choose to unlock V2ray or Xray server for streaming media Flow under XTLSmodel "
                green " 1. VLess + TCP + XTLS (xtls-rprx-direct) recommend"
                green " 2. VLess + TCP + XTLS (xtls-rprx-splice) This item may fail to connect"
                read -p "please chooseFlow parameter? Enter directly and select 1 by default, Please enter pure numbers:" isV2rayUnlockServerFlowInput
                isV2rayUnlockServerFlowInput=${isV2rayUnlockServerFlowInput:-1}

                unlockOutboundServerXTLSFlowValue="xtls-rprx-direct"
                if [[ $isV2rayUnlockServerFlowInput == "1" ]]; then
                    unlockOutboundServerXTLSFlowValue="xtls-rprx-direct"
                else
                    unlockOutboundServerXTLSFlowValue="xtls-rprx-splice"
                fi
                read -r -d '' unlockOutboundServerXTLSFlowText << EOM
                                "flow": "${unlockOutboundServerXTLSFlowValue}",
EOM
            fi


            echo
            yellow " Please fill in the V2ray or Xray server address that can unlock streaming media, E.g www.example.com"
            read -p "Please fill in the address of the unlockable streaming media server? Enter directly The default is native, please enter:" isV2rayUnlockServerDomainInput
            isV2rayUnlockServerDomainInput=${isV2rayUnlockServerDomainInput:-127.0.0.1}

            echo
            yellow " Please fill in the V2ray or Xray server port number that can unlock streaming media, E.g 443"
            read -p "Please fill in the address of the unlockable streaming media server? Enter directly The default is443, please enter:" isV2rayUnlockServerPortInput
            isV2rayUnlockServerPortInput=${isV2rayUnlockServerPortInput:-443}

            echo
            yellow " Please fill in the user UUID of the V2ray or Xray server that can unlock streaming media, E.g 4aeaf80d-f89e-46a2-b3dc-bb815eae75ba"
            read -p "Please fill in user UUID? Enter directly The default is111, please enter:" isV2rayUnlockServerUserIDInput
            isV2rayUnlockServerUserIDInput=${isV2rayUnlockServerUserIDInput:-111}



            read -r -d '' v2rayConfigOutboundV2rayServerInput << EOM
        {
            "tag": "V2Ray_out",
            "protocol": "${isV2rayUnlockOutboundServerProtocolText}",
            "settings": {
                "vnext": [
                    {
                        "address": "${isV2rayUnlockServerDomainInput}",
                        "port": ${isV2rayUnlockServerPortInput},
                        "users": [
                            {
                                "id": "${isV2rayUnlockServerUserIDInput}",
                                "encryption": "none",
                                ${unlockOutboundServerXTLSFlowText}
                                "level": 0
                            }
                        ]
                    }
                ]
            },
            "streamSettings": {
                "network": "${isV2rayUnlockOutboundServerTCPText}",
                "security": "${isV2rayUnlockOutboundServerTLSText}",
                "${isV2rayUnlockOutboundServerTLSText}Settings": {
                    "serverName": "${isV2rayUnlockServerDomainInput}"
                }
                ${unlockOutboundServerWebSocketSettingText}
            }
        },
EOM
        
}


function replaceAirUniverseConfigWARP(){


    echo
    green " =================================================="
    yellow " Whether to use DNS to unblock streaming sites like Netflix HBO Disney"
    green " For unblocking, please fill in the IP address of the DNS server that unblocks Netflix, E.g 8.8.8.8"
    read -p "Whether to use DNS to unblock streaming media? Enter directly by default Do not unlock, Unlock please enter the IP address of the DNS server:" isV2rayUnlockDNSInput
    isV2rayUnlockDNSInput=${isV2rayUnlockDNSInput:-n}

    V2rayDNSUnlockText="AsIs"
    v2rayConfigDNSInput=""

    if [[ "${isV2rayUnlockDNSInput}" == [Nn] ]]; then
        V2rayDNSUnlockText="AsIs"
    else
        V2rayDNSUnlockText="UseIP"
        read -r -d '' v2rayConfigDNSOutboundSettingsInput << EOM
            "settings": {
                "domainStrategy": "UseIP"
            }
EOM

        read -r -d '' v2rayConfigDNSInput << EOM

    "dns": {
        "servers": [
            {
                "address": "${isV2rayUnlockDNSInput}",
                "port": 53,
                "domains": [
                    "geosite:netflix",
                    "geosite:youtube",
                    "geosite:bahamut",
                    "geosite:hulu",
                    "geosite:hbo",
                    "geosite:disney",
                    "geosite:bbc",
                    "geosite:4chan",
                    "geosite:fox",
                    "geosite:abema",
                    "geosite:dmm",
                    "geosite:niconico",
                    "geosite:pixiv",
                    "geosite:bilibili",
                    "geosite:viu",
                    "geosite:pornhub"
                ]
            },
        "localhost"
        ]
    }, 
EOM

    fi




    echo
    echo
    green " =================================================="
    yellow " Whether to use Cloudflare WARP to unblock streaming sites like Netflix"
    green " 1. Do not use unlock"
    green " 2. Unblocking with WARP Sock5 proxy recommend using"
    green " 3. Unlock with WARP IPv6"
    green " 4. The pass is forwarded to the unlockable v2ray or xray server to unlock"
    echo
    green " Select 1 by default Do not unlock. Choose 2,3 to unlock need to install Wireguard and Cloudflare WARP, You can re-run this script and select the first item, Install".
    red " recommend to Install Wireguard and Cloudflare WARP After that, then Install v2ray or xray. Actually install v2ray or xray first, After InstallWireguard and Cloudflare WARP is okay"
    red " But if you install v2ray or xray first, Selected to unlock google or other streaming media, then temporarily unable to access google and other video sites, Need to continue Install Wireguard and Cloudflare WARP solution"
    echo
    read -p "please enter? Enter directly and select 1 by default Do not unlock, Please enter pure numbers:" isV2rayUnlockWarpModeInput
    isV2rayUnlockWarpModeInput=${isV2rayUnlockWarpModeInput:-1}

    V2rayUnlockVideoSiteRuleText=""
    V2rayUnlockGoogleRuleText=""

    xrayConfigRuleInput=""
    V2rayUnlockVideoSiteOutboundTagText=""
    unlockWARPServerIpInput="127.0.0.1"
    unlockWARPServerPortInput="40000"
    configWARPPortFilePath="${HOME}/wireguard/warp-port"
    configWARPPortLocalServerPort="40000"
    configWARPPortLocalServerText=""

    if [[ -f "${configWARPPortFilePath}" ]]; then
        configWARPPortLocalServerPort="$(cat ${configWARPPortFilePath})"
        configWARPPortLocalServerText="detected This machine has been installed WARP Sock5, port number ${configWARPPortLocalServerPort}"
    fi
    
    if [[ $isV2rayUnlockWarpModeInput == "1" ]]; then
        echo
    else
        if [[ $isV2rayUnlockWarpModeInput == "2" ]]; then
            V2rayUnlockVideoSiteOutboundTagText="WARP_out"

            echo
            read -p "please enterWARP Sock5 proxy server address? Enter directly and default to this machine 127.0.0.1, please enter:" unlockWARPServerIpInput
            unlockWARPServerIpInput=${unlockWARPServerIpInput:-127.0.0.1}

            echo
            yellow " ${configWARPPortLocalServerText}"
            read -p "please enterWARP Sock5 proxy server port number? Enter directly by default ${configWARPPortLocalServerPort}, Please enter pure numbers:" unlockWARPServerPortInput
            unlockWARPServerPortInput=${unlockWARPServerPortInput:-$configWARPPortLocalServerPort}

        elif [[ $isV2rayUnlockWarpModeInput == "3" ]]; then

            V2rayUnlockVideoSiteOutboundTagText="IPv6_out"

        elif [[ $isV2rayUnlockWarpModeInput == "4" ]]; then

            echo
            green " Selected 4 pass forward to unlockable v2ray or xray server to unlock"
            green " You can modify the v2ray or xray configuration yourself, exist outbounds Add a tag to the field as V2Ray_out The unlockable v2ray server"

            V2rayUnlockVideoSiteOutboundTagText="V2Ray_out"

            inputUnlockV2rayServerInfo
        fi


        echo
        echo
        green " =================================================="
        yellow " please choose the streaming site to unblock:"
        echo
        green " 1. Do not unlock"
        green " 2. unlock Netflix limit"
        green " 3. unlock Youtube and Youtube Premium"
        green " 4. unlock Pornhub, Solve the problem that the video becomes corn and cannot be watched"
        green " 5. Simultaneously unlock Netflix and Pornhub limit"
        green " 6. Simultaneously unlock Netflix, Youtube and Pornhub limit"
        green " 7. Simultaneously unlock Netflix, Hulu, HBO, Disney, Spotify and Pornhub limit"
        green " 8. Simultaneously unlock Netflix, Hulu, HBO, Disney, Spotify, Youtube and Pornhub limit"
        green " 9. unlock All streaming include Netflix, Youtube, Hulu, HBO, Disney, BBC, Fox, niconico, dmm, Spotify, Pornhub "
        echo
        read -p "please enter unlock option? Enter directly and select 1 by default Do not unlock, Please enter pure numbers:" isV2rayUnlockVideoSiteInput
        isV2rayUnlockVideoSiteInput=${isV2rayUnlockVideoSiteInput:-1}

        if [[ $isV2rayUnlockVideoSiteInput == "2" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\""
            
        elif [[ $isV2rayUnlockVideoSiteInput == "3" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:youtube\""

        elif [[ $isV2rayUnlockVideoSiteInput == "4" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "5" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\", \"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "6" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\", \"geosite:youtube\", \"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "7" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\", \"geosite:disney\", \"geosite:spotify\", \"geosite:hulu\", \"geosite:hbo\", \"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "8" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\", \"geosite:disney\", \"geosite:spotify\", \"geosite:youtube\", \"geosite:hulu\", \"geosite:hbo\", \"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "9" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\", \"geosite:disney\", \"geosite:spotify\", \"geosite:youtube\", \"geosite:bahamut\", \"geosite:hulu\", \"geosite:hbo\", \"geosite:bbc\", \"geosite:4chan\", \"geosite:fox\", \"geosite:abema\", \"geosite:dmm\", \"geosite:niconico\", \"geosite:pixiv\", \"geosite:viu\", \"geosite:pornhub\""

        fi

    fi




    echo
    echo
    yellow " A big guy provides a V2ray server that can unlock Netflix Singapore, Do not guaranteed to always be available"
    read -p "Whether to pass Mystic Force unlock Netflix Singapore? Enter directly by default Do not unlock, please enter[y/N]:" isV2rayUnlockGoNetflixInput
    isV2rayUnlockGoNetflixInput=${isV2rayUnlockGoNetflixInput:-n}

    v2rayConfigRouteGoNetflixInput=""
    v2rayConfigOutboundV2rayGoNetflixServerInput=""
    if [[ "${isV2rayUnlockGoNetflixInput}" == [Nn] ]]; then
        echo
    else
        removeString="\"geosite:netflix\", "
        V2rayUnlockVideoSiteRuleText=${V2rayUnlockVideoSiteRuleText#"$removeString"}
        removeString2="\"geosite:disney\", "
        V2rayUnlockVideoSiteRuleText=${V2rayUnlockVideoSiteRuleText#"$removeString2"}
        read -r -d '' v2rayConfigRouteGoNetflixInput << EOM
            {
                "type": "field",
                "outboundTag": "GoNetflix",
                "domain": [ "geosite:netflix", "geosite:disney" ] 
            },
EOM

        read -r -d '' v2rayConfigOutboundV2rayGoNetflixServerInput << EOM
        {
            "tag": "GoNetflix",
            "protocol": "vmess",
            "streamSettings": {
                "network": "ws",
                "security": "tls",
                "tlsSettings": {
                    "allowInsecure": false
                },
                "wsSettings": {
                    "path": "ws"
                }
            },
            "mux": {
                "enabled": true,
                "concurrency": 8
            },
            "settings": {
                "vnext": [{
                    "address": "free-sg-01.unblocknetflix.cf",
                    "port": 443,
                    "users": [
                        { "id": "402d7490-6d4b-42d4-80ed-e681b0e6f1f9", "security": "auto", "alterId": 0 }
                    ]
                }]
            }
        },
EOM
    fi



    echo
    echo
    green " =================================================="
    yellow " please choose avoid popping Google reCAPTCHA CAPTCHA WAY"
    echo
    green " 1. Do not unlock"
    green " 2. use WARP Sock5 agent unlock"
    green " 3. Unlock with WARP IPv6 recommend using"
    green " 4. The pass is forwarded to the unlockable v2ray or xray server to unlock"
    echo
    read -p "please enter unlock option? Enter directly and select 1 by default Do not unlock, Please enter pure numbers:" isV2rayUnlockGoogleInput
    isV2rayUnlockGoogleInput=${isV2rayUnlockGoogleInput:-1}

    if [[ $isV2rayUnlockWarpModeInput == $isV2rayUnlockGoogleInput ]]; then
        V2rayUnlockVideoSiteRuleText+=", \"geosite:google\" "
        V2rayUnlockVideoSiteRuleTextFirstChar="${V2rayUnlockVideoSiteRuleText:0:1}"

        if [[ $V2rayUnlockVideoSiteRuleTextFirstChar == "," ]]; then
            V2rayUnlockVideoSiteRuleText="${V2rayUnlockVideoSiteRuleText:1}"
        fi

        # 修复一个都Do not unlock的bug 都选1的bug
        if [[ -z "${V2rayUnlockVideoSiteOutboundTagText}" ]]; then
            V2rayUnlockVideoSiteOutboundTagText="IPv6_out"
            V2rayUnlockVideoSiteRuleText="\"test.com\""
        fi

        read -r -d '' xrayConfigRuleInput << EOM
            {
                "type": "field",
                "outboundTag": "${V2rayUnlockVideoSiteOutboundTagText}",
                "domain": [${V2rayUnlockVideoSiteRuleText}] 
            },
EOM

    else
        V2rayUnlockGoogleRuleText="\"geosite:google\""

        if [[ $isV2rayUnlockGoogleInput == "2" ]]; then
            V2rayUnlockGoogleOutboundTagText="WARP_out"
            echo
            read -p "please enterWARP Sock5 proxy server address? Enter directly and default to this machine 127.0.0.1, please enter:" unlockWARPServerIpInput
            unlockWARPServerIpInput=${unlockWARPServerIpInput:-127.0.0.1}

            echo
            yellow " ${configWARPPortLocalServerText}"
            read -p "please enterWARP Sock5 proxy server port number? Enter directly by default ${configWARPPortLocalServerPort}, Please enter pure numbers:" unlockWARPServerPortInput
            unlockWARPServerPortInput=${unlockWARPServerPortInput:-$configWARPPortLocalServerPort}           

        elif [[ $isV2rayUnlockGoogleInput == "3" ]]; then
            V2rayUnlockGoogleOutboundTagText="IPv6_out"

        elif [[ $isV2rayUnlockGoogleInput == "4" ]]; then
            V2rayUnlockGoogleOutboundTagText="V2Ray_out"
            inputUnlockV2rayServerInfo
        else
            V2rayUnlockGoogleOutboundTagText="IPv4_out"
        fi

        # 修复一个都Do not unlock的bug 都选1的bug
        if [[ -z "${V2rayUnlockVideoSiteOutboundTagText}" ]]; then
            V2rayUnlockVideoSiteOutboundTagText="IPv6_out"
            V2rayUnlockVideoSiteRuleText="\"test.com\""
        fi

        read -r -d '' xrayConfigRuleInput << EOM
            {
                "type": "field",
                "outboundTag": "${V2rayUnlockGoogleOutboundTagText}",
                "domain": [${V2rayUnlockGoogleRuleText}] 
            },
            {
                "type": "field",
                "outboundTag": "${V2rayUnlockVideoSiteOutboundTagText}",
                "domain": [${V2rayUnlockVideoSiteRuleText}] 
            },
EOM
    fi


    read -r -d '' xrayConfigProxyInput << EOM
    
    ${v2rayConfigDNSInput}
    "outbounds": [
        {
            "tag": "IPv4_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "${V2rayDNSUnlockText}"
            }
        },
        {
            "tag": "blackhole",
            "protocol": "blackhole",
            "settings": {}
        },

        ${v2rayConfigOutboundV2rayServerInput}
        ${v2rayConfigOutboundV2rayGoNetflixServerInput}
        {
            "tag":"IPv6_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv6" 
            }
        },
        {
            "tag": "WARP_out",
            "protocol": "socks",
            "settings": {
                "servers": [
                    {
                        "address": "${unlockWARPServerIpInput}",
                        "port": ${unlockWARPServerPortInput}
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp"
            }
        }      
    ],
    "routing": {
        "rules": [
            {
                "inboundTag": [
                    "api"
                ],
                "outboundTag": "api",
                "type": "field"
            },
            ${xrayConfigRuleInput}
            ${v2rayConfigRouteGoNetflixInput}
            {
                "type": "field",
                "protocol": [
                    "bittorrent"
                ],
                "outboundTag": "blackhole"
            },
            {
                "type": "field",
                "ip": [
                    "127.0.0.1/32",
                    "10.0.0.0/8",
                    "fc00::/7",
                    "fe80::/10",
                    "172.16.0.0/12"
                ],
                "outboundTag": "blackhole"
            }
        ]
    }
}
EOM

    

    if [[ "${isV2rayUnlockWarpModeInput}" == "1" && "${isV2rayUnlockGoogleInput}" == "1"  && "${isV2rayUnlockGoNetflixInput}" == [Nn]  ]]; then
        if [[ "${isV2rayUnlockDNSInput}" == [Nn] ]]; then
            echo
        else
            TEST="${v2rayConfigDNSInput//\\/\\\\}"
            TEST="${TEST//\//\\/}"
            TEST="${TEST//&/\\&}"
            TEST="${TEST//$'\n'/\\n}"

            sed -i "/outbounds/i \    ${TEST}" ${configAirUniverseXrayConfigFilePath}

            TEST2="${v2rayConfigDNSOutboundSettingsInput//\\/\\\\}"
            TEST2="${TEST2//\//\\/}"
            TEST2="${TEST2//&/\\&}"
            TEST2="${TEST2//$'\n'/\\n}"

            # https://stackoverflow.com/questions/4396974/sed-or-awk-delete-n-lines-following-a-pattern

            sed -i -e '/freedom/{n;d}' ${configAirUniverseXrayConfigFilePath}
            sed -i "/freedom/a \      ${TEST2}" ${configAirUniverseXrayConfigFilePath}

        fi
    else
        
        # https://stackoverflow.com/questions/31091332/how-to-use-sed-to-delete-multiple-lines-when-the-pattern-is-matched-and-stop-unt/31091398
        sed -i '/outbounds/,/^&/d' ${configAirUniverseXrayConfigFilePath}
        cat >> ${configAirUniverseXrayConfigFilePath} <<-EOF

  ${xrayConfigProxyInput}

EOF
    fi


    chmod ugoa+rwx ${configSSLCertPath}/${configSSLCertFullchainFilename}
    chmod ugoa+rwx ${configSSLCertPath}/${configSSLCertKeyFilename}

    # -z 为空
    if [[ -z $1 ]]; then
        echo
        green " =================================================="
        green " reboot xray and air-universe Serve "
        systemctl restart xray.service
        airu restart
        green " =================================================="
        echo
    fi

}










function manageAirUniverse(){
    echo -e ""
    green " =================================================="       
    echo "    Air-Universe How to use the management script: "
    echo 
    echo "airu              - Show admin menu (function more)"
    echo "airu start        - start up Air-Universe"
    echo "airu stop         - stop Air-Universe"
    echo "airu restart      - reboot Air-Universe"
    echo "airu status       - Check Air-Universe state"
    echo "airu enable       - set up Air-Universe Auto-start"
    echo "airu disable      - Cancel Air-Universe Auto-start"
    echo "airu log          - Check Air-Universe log"
    echo "airu update x.x.x - renew Air-Universe Specified version"
    echo "airu install      - Install Air-Universe"
    echo "airu uninstall    - uninstall Air-Universe"
    echo "airu version      - Check Air-Universe Version"
    echo "------------------------------------------"
    green " Air-Universe configuration file ${configAirUniverseConfigFilePath} "
    green " Xray configuration file ${configAirUniverseXrayConfigFilePath}"
    green " =================================================="    
    echo
}



function removeAirUniverse(){
    rm -rf /usr/local/etc/xray
    /root/airu_install.sh uninstall
    rm -f /usr/bin/airu 
    rm -f /usr/local/bin/au
    rm -f /usr/local/bin/xray
    
    rm -rf ${configSSLCertPathV2board}

    crontab -r 
    green " crontab timed task cleared!"
    echo

    removeNginx
}
































































netflixMitmToolDownloadFolder="${HOME}/netflix_mitm_tool"
netflixMitmToolDownloadFilename="mitm-vip-unlocker-x86_64-linux-musl.zip"
netflixMitmToolUrl="https://github.com/jinwyp/one_click_script/raw/master/download/mitm-vip-unlocker-x86_64-linux-musl.zip"
configNetflixMitmPort="34567"
configNetflixMitmToken="-t token123"

function installShareNetflixAccount(){
    echo
    green " ================================================== "
    yellow " ready to install Netflix account sharing server program"
    yellow " A Netflix account is required to provide Shared Serve "
    yellow " The installed server needs to have native unlock Netflix"
    red " Please be sure to use it for private use. Do not share it publicly. Netflix also limits the number of existing online users at the same time."
    green " ================================================== "

    promptContinueOpeartion 

    echo
    read -p "whether to generate random port number? Enter directly by default 34567 Do not generate random ports number, please enter[y/N]:" isNetflixMimePortInput
    isNetflixMimePortInput=${isNetflixMimePortInput:-n}

    if [[ $isNetflixMimePortInput == [Nn] ]]; then
        echo
    else
        configNetflixMitmPort="$(($RANDOM + 10000))"
    fi

    echo
    read -p "Whether to generate a random administrator token password? Enter directly by default token123 Do not generate random token, please enter[y/N]:" isNetflixMimeTokenInput
    isNetflixMitmTokenInput=${isNetflixMitmTokenInput:-n}

    if [[ $isNetflixMitmTokenInput == [Nn] ]]; then
        echo
    else
        configNetflixMitmToken=""
    fi


    mkdir -p ${netflixMitmToolDownloadFolder}
    cd ${netflixMitmToolDownloadFolder}

    wget -P ${netflixMitmToolDownloadFolder} ${netflixMitmToolUrl}
    unzip -d ${netflixMitmToolDownloadFolder} ${netflixMitmToolDownloadFolder}/${netflixMitmToolDownloadFilename}
    chmod +x ./mitm-vip-unlocker
    ./mitm-vip-unlocker genca


    cat > ${osSystemMdPath}netflix_mitm.service <<-EOF
[Unit]
Description=mitm-vip-unlocker
After=network.target

[Service]
Type=simple
WorkingDirectory=${netflixMitmToolDownloadFolder}
PIDFile=${netflixMitmToolDownloadFolder}/mitm-vip-unlocker.pid
ExecStart=${netflixMitmToolDownloadFolder}/mitm-vip-unlocker run -b 0.0.0.0:${configNetflixMitmPort} ${configNetflixMitmToken}
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF

    ${sudoCmd} chmod +x ${osSystemMdPath}netflix_mitm.service
    ${sudoCmd} systemctl daemon-reload
    ${sudoCmd} systemctl start netflix_mitm.service
    #${sudoCmd} systemctl enable netflix_mitm.service

cat > ${netflixMitmToolDownloadFolder}/netflix_mitm_readme <<-EOF
admin for browser plugins of token for: ${configNetflixMitmToken}

The port the server is running on number is: ${configNetflixMitmPort}


The specific steps for subsequent operations are as follows:

1. Certificate file has been generated, default exist directory ${netflixMitmToolDownloadFolder}/ca/cert.crt under the folder, Please download cert.crt locally
2. exist on your own client machine,Install好Certificatecert.crt then turn on http acting, proxy server address is: your ip:${configNetflixMitmPort}

chrome Can use SwitchyOmega plugin as http proxy https://github.com/FelisCatus/SwitchyOmega 

Create a new scenario E.g name is Netflix proxy Enter proxy httpServer your ip port ${configNetflixMitmPort}   
 
Then exist automatically switch, add several Netflix domain names to the menu, and choose to use the Netflix proxy scenario.

netflix.com
netflix.net
nflxext.com
nflximg.net
nflxso.net
nflxvideo.net


3. 第一次使用需要上传的已登录Netflix账号的 cookie, 具体方法如下
使用Netflix账号登录Netflix官网. 然后Install EditThisCookie 这个浏览器插件. 添加一个key为admin, value 值为 ${configNetflixMitmToken} 

一切已经完成, 其他设备就可以InstallCertificatecert.crt, 使用http代理填入你的ip:${configNetflixMitmPort}, 就可以Do not需要账号看奈菲了


EOF

	green " ================================================== "
	green " Netflix account sharing server program Successful installation !"
    green " reboot command: systemctl restart netflix_mitm.service"
	green " View running status command:  systemctl status netflix_mitm.service "
	green " View log command: journalctl -n 40 -u netflix_mitm.service "
    echo
	green " The port number of the server running is: ${configNetflixMitmPort}"
	green " The token for the administrator admin used by the browser plug-in is: ${configNetflixMitmToken}"
	green " You can also check using configuration information ${netflixMitmToolDownloadFolder}/netflix_mitm_readme "
    echo
    green " The specific steps for subsequent operations are as follows:"
    green " 1. Certificate file has been generated, The default exists of the current directory's caunder the folder, Please download cert.crt locally"
    green " 2. exist on your own client machine,Install Certificatecert.crt and enable http proxy, proxy server address is: your ip:${configNetflixMitmPort} "
    green " chrome Can use SwitchyOmega plugin as http proxy https://github.com/FelisCatus/SwitchyOmega "
    echo
    green " 3. The first time to use the cookie of the logged-in Netflix account that needs to be uploaded, the specific method is as follows"
    green " Log in to the Netflix official website with your Netflix account. Then Install EditThisCookie This browser plug-in. Add a key as admin, value value is ${configNetflixMitmToken} "
    green " EditThisCookie browser plugin https://chrome.google.com/webstore/detail/editthiscookie/fngmhnnpilhplaeedifhccceomclgfbg"
    echo
    green " everything is done, Other devices can install Certificatecert.crt, fill in your ip using http proxy:${configNetflixMitmPort}, You can Do not need an account to watch Natflix"
    green " ================================================== "

}



function removeShareNetflixAccount(){
    if [[ -f "${netflixMitmToolDownloadFolder}/mitm-vip-unlocker" ]]; then
        echo
        green " ================================================== "
        red " Prepare to uninstall the installed Netflix account sharing server program mitm-vip-unlocker"
        green " ================================================== "
        echo

        ${sudoCmd} systemctl stop netflix_mitm.service
        ${sudoCmd} systemctl disable netflix_mitm.service
        ${sudoCmd} systemctl daemon-reload

        rm -rf ${netflixMitmToolDownloadFolder}
        rm -f ${osSystemMdPath}netflix_mitm.service

        echo
        green " ================================================== "
        green "  Netflix account sharing server program mitm-vip-unlocker uninstall completed !"
        green " ================================================== "
        
    else
        red " system not installed Netflix account sharing server program mitm-vip-unlocker, exit uninstall"
    fi
}





































openVPNSocksFolder="/root/openvpn_docker"
function runOpenVPNSocks(){
    mkdir -p ${openVPNSocksFolder}

    green "docker run -it --rm --device=/dev/net/tun --cap-add=NET_ADMIN  --name openvpn-client  --volume ${openVPNSocksFolder}/:/etc/openvpn/:ro -p 10808:1080  kizzx2/openvpn-client-socks"
    docker run -it --rm --device=/dev/net/tun --cap-add=NET_ADMIN  --name openvpn-client  --volume ${openVPNSocksFolder}/:/etc/openvpn/:ro -p 10808:1080  kizzx2/openvpn-client-socks
 
    curl --proxy socks5h://localhost:10808 ipinfo.io
    curl --proxy socks5h://localhost:10808 http://ip111.cn/
}







function startMenuOther(){
    clear

    if [[ ${configLanguage} == "cn" ]] ; then
    
        green " =================================================="
        echo
        green " 21. Install XrayR Server side"
        green " 22. stop, reboot, View logs, etc., manage XrayR Server side"
        green " 23. edit XrayR configuration file ${configXrayRConfigFilePath}"        
        echo
        green " 41. Install Soga Server side"
        green " 42. stop, reboot, View logs, etc., manage Soga Server"
        green " 43. edit Soga configuration file ${configSogaConfigFilePath}"
        echo
        green " 62. Install the shared Netflix account on the server side, you can Do not use the Netflix account to watch Netflix directly"
        red " 63. uninstall shared Netflix account Server"
        echo
        green " 71. Tool Script Collection by BlueSkyXN "
        green " 72. Tool Script Collection by jcnf "
        echo
        green " 9. Back to previous menu"
        green " 0. exit script"    

    else
        green " =================================================="
        echo
        green " 21. Install XrayR server side "
        green " 22. Stop, restart, show log, manage XrayR server side "
        green " 23. Using VI open XrayR config file ${configXrayRConfigFilePath}"        
        echo
        green " 41. Install Soga server side "
        green " 42. Stop, restart, show log, manage Soga server side "
        green " 43. Using VI open Soga config file ${configSogaConfigFilePath}"
        echo
        green " 62. Install Netflix account share service server, Play Netflix without Netflix account"
        red " 63. Remove Netflix account share service server"    
        echo
        green " 71. toolkit by BlueSkyXN "
        green " 72. toolkit by jcnf "
        echo
        green " 9. Back to main menu"
        green " 0. exit"

    fi


    echo
    read -p "Please input number:" menuNumberInput
    case "$menuNumberInput" in
        21 )
            setLinuxDateZone
            installXrayR
        ;;
        22 )
            manageXrayR
        ;;
        23 )
            editXrayRConfig
        ;;    
        41 )
            setLinuxDateZone
            installSoga 
        ;;
        42 )
            manageSoga
        ;;                                        
        43 )
            editSogaConfig
        ;;
        62 )
            installShareNetflixAccount
        ;;
        63 )
            removeShareNetflixAccount
        ;;
        71 )
            toolboxSkybox
        ;;
        72 )
            toolboxJcnf
        ;;        
        9)
            start_menu
        ;;
        0 )
            exit 1
        ;;
        * )
            clear
            red "please enter the correct number !"
            sleep 2s
            startMenuOther
        ;;
    esac
}

















function start_menu(){
    clear

    if [[ $1 == "first" ]] ; then
        getLinuxOSRelease
        installSoftDownload
    fi

    if [[ ${configLanguage} == "cn" ]] ; then
    green " =================================================="
    green " Linux Common tools One-click Install script | 2022-9-29 | systemsupport：centos7+ / debian9+ / ubuntu16.04+"
    green " =================================================="
    green " 1. Install linux kernel BBR Plus, Install WireGuard, for unlock Netflix limit andavoid popping Google reCAPTCHA Human verification"
    echo
    green " 3. Edit authorized_keys file with VI Fill in the public key for SSH password-free login to increase security"
    green " 4. Modify SSH login port number"
    green " 5. set up time zone is Tehran time"
    green " 6. Edit /etc/hosts with VI"
    echo
    green " 11. Install Vim Nano Micro editor"
    green " 12. Install Nodejs and PM2"
    green " 13. Install Docker and Docker Compose"
    red " 14. uninstall Docker and Docker Compose"
    green " 15. set up Docker Hub mirror "
    green " 16. Install Portainer "
    echo
    green " 21. Install Cloudreve cloud disk system "
    red " 22. uninstall Cloudreve cloud disk system "
    green " 23. Install/renew/delete Alist cloud disk file list system "
    echo
    green " 28. Install CasaOS system(include Nextcloud cloud disk and AdGuard DNS Wait)  "
    red " 29. uninstall CasaOS system " 
    echo
    green " 31. Install Grist Exist line Excel table(similar Airtable)  "
    red " 32. uninstall Grist Exist line Excel table " 
    green " 33. Install NocoDB Exist line Excel table(similar Airtable)  "
    red " 34. uninstall NocoDB Exist line Excel table " 
    green " 35. Install Etherpad Multi-person collaborative document(similar Word)  "
    red " 36. uninstall Etherpad Multi-person collaborative document "     
    echo
    green " 41. Install Ghost Blog blog system "
    red " 42. uninstall Ghost Blog blog system "     
    echo

    green " 47. Installvideo conferencing system Jitsi Meet "
    red " 48. uninstall Jitsi Meet "
    green " 49. Jitsi Meet Whether to initiate a meeting requires password authentication"

    echo
    green " 51. Install Air-Universe Server side"
    red " 52. uninstall Air-Universe"
    green " 53. stop, reboot, View logs, etc., manage Air-Universe Server"
    green " 54. Work with WARP (Wireguard) to use IPV6 unlock google man-machine authentication and Netflix and other streaming sites"
    green " 55. Upgrade or downgrade Air-Universe to 1.0.0 or 0.9.2, downgrade Xray to 1.5 or 1.4"
    green " 56. Re-ApplicationCertificate and modify Air-Universe configuration file ${configAirUniverseConfigFilePath}"
    echo 
    green " 61. Separate Application domain name SSLCertificate"
    echo
    green " 77. Submenu Install V2board Server side XrayR, V2Ray-Poseidon, Soga"
    echo
    green " 88. upgrade script"
    green " 0. exit script"

    else
    green " =================================================="
    green " Linux tools installation script | 2022-9-29 | OS support：centos7+ / debian9+ / ubuntu16.04+"
    green " =================================================="
    green " 1. Install linux kernel,  bbr plus kernel, WireGuard and Cloudflare WARP. Unlock Netflix geo restriction and avoid Google reCAPTCHA"
    echo
    green " 3. Using VI open authorized_keys file, enter your public key. Then save file. In order to login VPS without Password"
    green " 4. Modify SSH login port number. Secure your VPS"
    green " 5. Set timezone to Beijing time"
    green " 6. Using VI open /etc/hosts file"
    echo
    green " 11. Install Vim Nano Micro editor"
    green " 12. Install Nodejs and PM2"
    green " 13. Install Docker and Docker Compose"
    red " 14. Remove Docker and Docker Compose"
    green " 15. Set Docker Hub Registry"
    green " 16. Install Portainer "
    echo
    green " 21. Install Cloudreve cloud storage system"
    red " 22. Remove Cloudreve cloud storage system"
    green " 23. Install/Update/Remove Alist file list storage system "
    echo
    green " 28. Install CasaOS(Including Nextcloud, AdGuard DNS )  "
    red " 29. Remove CasaOS "     
    echo
    green " 31. Install Grist Online Spreadsheet (Airtable alternative)"
    red " 32. Remove Grist Online Spreadsheet (Airtable alternative)"
    green " 33. Install NocoDB Online Spreadsheet (Airtable alternative)"
    red " 34. Remove NocoDB Online Spreadsheet (Airtable alternative)"
    green " 35. Install Etherpad collaborative editor (Word alternative)"
    red " 36. Remove Etherpad collaborative editor (Word alternative)"
    echo
    green " 41. Install Ghost Blog "
    red " 42. Remove Ghost Blog "     
    echo    
    green " 47. Install Jitsi Meet video conference system"
    red " 48. Remove Jitsi Meet video conference system"
    green " 49. Modify Jitsi Meet whether to Start a meeting requires password authentication"

    echo
    green " 51. Install Air-Universe server side "
    red " 52. Remove Air-Universe"
    green " 53. Stop, restart, show log, manage Air-Universe server side "
    green " 54. Using WARP (Wireguard) and IPV6 Unlock Netflix geo restriction and avoid Google reCAPTCHA"
    green " 55. Upgrade or downgrade Air-Universe to 1.0.0 or 0.9.2, downgrade Xray to 1.5 / 1.4"
    green " 56. Redo to get a free SSL certificate for domain name and modify Air-Universe config file ${configAirUniverseConfigFilePath}"
    echo 
    green " 61. Get a free SSL certificate for domain name only"
    echo
    green " 77. Submenu. install XrayR, V2Ray-Poseidon, Soga for V2board panel"
    echo
    green " 88. upgrade this script to latest version"
    green " 0. exit"

    fi


    echo
    read -p "Please input number:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            installWireguard
        ;;    
        3 )
            editLinuxLoginWithPublicKey
        ;;
        4 )
            changeLinuxSSHPort
            sleep 10s
            start_menu
        ;;
        5 )
            setLinuxDateZone
            sleep 4s
            start_menu
        ;;
        6 )
            DSMEditHosts
        ;;
        11 )
            installSoftEditor
        ;;
        12 )
            installPackage
            installNodejs
        ;;
        13 )
            testLinuxPortUsage
            setLinuxDateZone
            installPackage
            installDocker
        ;;
        14 )
            removeDocker 
        ;;
        15 )
            addDockerRegistry
        ;;
        16 )
            installPortainer 
        ;;
        21 )
            installCloudreve
        ;;
        22 )
            removeCloudreve
        ;;
        23 )
            installAlist
        ;;
        28 )
            installCasaOS
        ;;
        29 )
            removeCasaOS
        ;;
        31 )
            installGrist
        ;;
        32 )
            removeGrist
        ;;
        33 )
            installNocoDB
        ;;
        34 )
            removeNocoDB
        ;;
        35 )
            installEtherpad
        ;;
        36 )
            removeEtherpad
        ;;
        41 )
            installCMSGhost
        ;;
        42 )
            removeCMSGhost
        ;;
        47 )
            installJitsiMeet
        ;;
        48 )
            removeJitsiMeet
        ;;
        49 )
            secureAddPasswordForJitsiMeet
        ;;


        51 )
            setLinuxDateZone
            installAirUniverse
        ;;
        52 )
            removeAirUniverse
        ;;                                        
        53 )
            manageAirUniverse
        ;;                                        
        54 )
            replaceAirUniverseConfigWARP
        ;;
        55 )
            downgradeXray
        ;;
        56 )
            installAirUniverse "ssl"
        ;;
        57 )
            installAiruAndNginx
        ;;
        61 )
            getHTTPSCertificateStep1
        ;;
        77 )
            startMenuOther
        ;;
        88 )
            upgradeScript
        ;;
        89 )
                su - ghostsite << EOF
    echo "--------------------"
    echo "Current user: $(whoami)"
    whoami
    $(whoami)
    # ghost install --port 3468 --db=sqlite3 --no-prompt --dir ${configGhostSitePath} --url https://${configSSLDomain}
    echo "--------------------"
EOF
whoami
sudo -u ghostsite bash << EOF
echo "In"
whoami
EOF
echo "Out"
whoami
        ;;
        0 )
            exit 1
        ;;
        * )
            clear
            red "please enter the correct number !"
            sleep 2s
            start_menu
        ;;
    esac
}






function setLanguage(){
    echo
    green " =================================================="
    green " Please choose your language"
    green " 1. 中文"
    green " 2. English"  
    echo
    read -p "Please input your language:" languageInput
    
    case "${languageInput}" in
        1 )
            echo "cn" > ${configLanguageFilePath}
            showMenu
        ;;
        2 )
            echo "en" > ${configLanguageFilePath}
            showMenu
        ;;
        * )
            red " Please input the correct number !"
            setLanguage
        ;;
    esac

}

configLanguageFilePath="${HOME}/language_setting_v2ray_trojan.md"
configLanguage="cn"

function showMenu(){

    if [ -f "${configLanguageFilePath}" ]; then
        configLanguage=$(cat ${configLanguageFilePath})

        case "${configLanguage}" in
        cn )
            start_menu "first"
        ;;
        en )
            start_menu "first"
        ;;
        * )
            setLanguage
        ;;
        esac
    else
        setLanguage
    fi
}

showMenu
