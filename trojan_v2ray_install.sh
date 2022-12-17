#!/bin/bash

export LC_ALL=C
#export LANG=C
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8


sudoCmd=""
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
fi


uninstall() {
    ${sudoCmd} "$(which rm)" -rf $1
    printf "File or Folder Deleted: %s\n" $1
}


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

	# green " Status display -- current CPU is: $osCPU"
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
	read -p "Do you want to continue the operation? Press Enter to continue the operation by default, please enter [Y/n]:" isContinueInput
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
        red "It is detected that port 80 is occupied, and the occupied process is ：${process80} "
        red "==========================================================="
        promptContinueOpeartion
    fi

    if [ -n "$osPort443" ]; then
        process443=$(netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}')
        red "============================================================="
        red "It is detected that port 443 is occupied, and the occupied process is ：${process443} "
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
            echo -e "VPS restarting..."
            reboot
        fi
        exit
    fi

    if [ "$osSELINUXCheck" == "SELINUX=permissive" ]; then
        red "======================================================================="
        red "It is detected that SELinux is in permissive mode. In order to prevent the failure to apply for a certificate, SELinux will be turned off. Please restart the VPS before executing this script"
        red "======================================================================="
        read -p "Reboot now? Please enter [Y/n] :" osSELINUXCheckIsRebootInput
        [ -z "${osSELINUXCheckIsRebootInput}" ] && osSELINUXCheckIsRebootInput="y"

        if [[ $osSELINUXCheckIsRebootInput == [Yy] ]]; then
            sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
            echo -e "VPS restarting..."
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

        red " turn off firewall firewalld"
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


# View port usage
function checkPortUsage(){
    # https://stackoverflow.com/questions/2013547/assigning-default-values-to-shell-variables-with-a-single-command-in-bash

    portNum="${1:-80}"
    # check port 80 is running
    # http://www.letuknowit.com/post/98.html
    # However, it is generally written as follows, an extra plus sign indicates that consecutive record separators are treated as one

    osPort80=$(netstat -tupln | awk -F '[ ]+' '$1=="tcp"||$1=="tcp6"{print $4}' | grep -w "${portNum}")

    if [ -n "$osPort80" ]; then
        process80=$(netstat -tupln | grep -w "${portNum}" | awk -F '[ ]+' '{print $7}')

        showHeaderRed "detected ${portNum} port is busy, the busy process is: ${process80} "

        if [[ ${portNum} == "80" ]] ; then
            green " close if necessary apache2 Please run the following command: "
            green " Run following command to stop apache2: "
            green " ${sudoCmd} systemctl stop apache2 "
            green " ${sudoCmd} systemctl disable apache2 "
        fi


        promptContinueOpeartion
    fi

}







# Edit SSH public key file for passwordless login
function editLinuxLoginWithPublicKey(){
    if [ ! -d "${HOME}/ssh" ]; then
        mkdir -p ${HOME}/.ssh
    fi

    vi ${HOME}/.ssh/authorized_keys
}



# Set up SSH root login

function setLinuxRootLogin(){

    read -p "Is it set to allow root login (ssh key or password login)? Please enter [Y/n]:" osIsRootLoginInput
    osIsRootLoginInput=${osIsRootLoginInput:-Y}

    if [[ $osIsRootLoginInput == [Yy] ]]; then

        if [ "$osRelease" == "centos" ] || [ "$osRelease" == "debian" ] ; then
            ${sudoCmd} sed -i 's/#\?PermitRootLogin \(yes\|no\|Yes\|No\|prohibit-password\)/PermitRootLogin yes/g' /etc/ssh/sshd_config
        fi
        if [ "$osRelease" == "ubuntu" ]; then
            ${sudoCmd} sed -i 's/#\?PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
        fi

        green "Set to allow root login success!"
    fi


    read -p "Is it set to allow root to log in with a password (in the previous step, please allow root to log in first)? Please enter [Y/n]:" osIsRootLoginWithPasswordInput
    osIsRootLoginWithPasswordInput=${osIsRootLoginWithPasswordInput:-Y}

    if [[ $osIsRootLoginWithPasswordInput == [Yy] ]]; then
        sed -i 's/#\?PasswordAuthentication \(yes\|no\)/PasswordAuthentication yes/g' /etc/ssh/sshd_config
        green "Set to allow root to use password to log in successfully !"
    fi


    ${sudoCmd} sed -i 's/#\?TCPKeepAlive yes/TCPKeepAlive yes/g' /etc/ssh/sshd_config
    ${sudoCmd} sed -i 's/#\?ClientAliveCountMax 3/ClientAliveCountMax 30/g' /etc/ssh/sshd_config
    ${sudoCmd} sed -i 's/#\?ClientAliveInterval [0-9]*/ClientAliveInterval 40/g' /etc/ssh/sshd_config

    if [ "$osRelease" == "centos" ] ; then

        ${sudoCmd} service sshd restart
        ${sudoCmd} systemctl restart sshd

        green "The setup is successful, please use the shell tool software to log in to the vps server !"
    fi

    if [ "$osRelease" == "ubuntu" ] || [ "$osRelease" == "debian" ] ; then
        
        ${sudoCmd} service ssh restart
        ${sudoCmd} systemctl restart ssh

        green "The setup is successful, please use the shell tool software to log in to the vps server !"
    fi

    # /etc/init.d/ssh restart
}


# Modify the SSH port number
function changeLinuxSSHPort(){
    green " Modify the port number for SSH login, do not use the commonly used port number. For example 20|21|23|25|53|69|80|110|443|123!"
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
        red "Wrong port number entered! Range : 22,1025~65534. Exit !"
    fi
}


# Set Tehran time zone
function setLinuxDateZone(){

    tempCurrentDateZone=$(date +'%z')

    echo
    if [[ ${tempCurrentDateZone} == "+0330" ]]; then
        yellow "The current time zone is already Tehran time  $tempCurrentDateZone | $(date -R) "
    else 
        green " =================================================="
        yellow " The current time zone is: $tempCurrentDateZone | $(date -R) "
        yellow "Whether to set the time zone to Tehran time +0330 zone, so that the cron restart script will run according to Tehran time."
        green " =================================================="
        # read Defaults https://stackoverflow.com/questions/2642585/read-a-variable-in-bash-with-a-default-value

        read -p "Is it set to Tehran time +0330 time zone? Please enter [Y/n]:" osTimezoneInput
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

            echo ""
            echo "chrony sources:"

            chronyc sources

            echo ""
            echo ""
        fi
        
    else
        $osSystemPackage install -y ntp
        systemctl enable ntp
        systemctl restart ntp
    fi    
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

        if  [[ ${osReleaseVersion} == "8.1.1911" || ${osReleaseVersion} == "8.2.2004" || ${osReleaseVersion} == "8.0.1905" || ${osReleaseVersion} == "8.5.2111" ]]; then

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
            
        elif ! rpm -qa | grep -qw unzip; then
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

            ${osSystemPackage} install -y curl wget git unzip zip tar
            ${osSystemPackage} install -y redhat-lsb-core 
            ${osSystemPackage} install -y bind-utils net-tools
            ${osSystemPackage} install -y xz jq
            ${osSystemPackage} install -y iputils
            ${osSystemPackage} install -y iperf3 
            ${osSystemPackage} install -y htop 
		fi
        yum clean all
        
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
        green " micro Editor installed successfully!"
        green " =================================================="
    fi

    if [ "$osRelease" == "centos" ]; then   
        $osSystemPackage install -y xz  vim-minimal vim-enhanced vim-common nano
    else
        $osSystemPackage install -y vim-gui-common vim-runtime vim nano
    fi

    # Set vim Chinese garbled
    #if [[ ! -d "${HOME}/.vimrc" ]] ;  then
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

function installSoftOhMyZsh(){

    echo
    green " =================================================="
    yellow " start installation ZSH"
    green " =================================================="
    echo

    if [ "$osRelease" == "centos" ]; then

        ${sudoCmd} $osSystemPackage install zsh -y
        $osSystemPackage install util-linux-user -y

    elif [ "$osRelease" == "ubuntu" ]; then

        ${sudoCmd} $osSystemPackage install zsh -y

    elif [ "$osRelease" == "debian" ]; then

        ${sudoCmd} $osSystemPackage install zsh -y
    fi

    green " =================================================="
    green " ZSH Successful installation"
    green " =================================================="

    # Install oh-my-zsh
    if [[ ! -d "${HOME}/.oh-my-zsh" ]] ;  then

        green " =================================================="
        yellow " start installation oh-my-zsh"
        green " =================================================="
        curl -Lo ${HOME}/ohmyzsh_install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
        chmod +x ${HOME}/ohmyzsh_install.sh
        sh ${HOME}/ohmyzsh_install.sh --unattended
    fi

    if [[ ! -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]] ;  then
        git clone "https://github.com/zsh-users/zsh-autosuggestions" "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

        # configure zshrc document
        zshConfig=${HOME}/.zshrc
        zshTheme="maran"
        sed -i 's/ZSH_THEME=.*/ZSH_THEME="'"${zshTheme}"'"/' $zshConfig
        sed -i 's/plugins=(git)/plugins=(git cp history z rsync colorize nvm zsh-autosuggestions)/' $zshConfig

        zshAutosuggestionsConfig=${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
        sed -i "s/ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'/ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=1'/" $zshAutosuggestionsConfig


        # Actually change the default shell to zsh
        zsh=$(which zsh)

        if ! chsh -s "$zsh"; then
            red "chsh command unsuccessful. Change your default shell manually."
        else
            export SHELL="$zsh"
            green "===== Shell successfully changed to '$zsh'."
        fi


        echo 'alias ll="ls -ahl"' >> ${HOME}/.zshrc
        echo 'alias mi="micro"' >> ${HOME}/.zshrc

        green " =================================================="
        yellow " oh-my-zsh The installation is successful, please use the exit command to log out of the server and then log in again.!"
        green " =================================================="

    fi

}








# Updated script
function upgradeScript(){
    wget -Nq --no-check-certificate -O ./trojan_v2ray_install.sh "https://raw.githubusercontent.com/kontorol/one_click_script/master/trojan_v2ray_install.sh"
    green " The script was upgraded successfully! "
    chmod +x ./trojan_v2ray_install.sh
    sleep 2s
    exec "./trojan_v2ray_install.sh"
}

function installWireguard(){
    bash <(wget -qO- https://github.com/kontorol/one_click_script/raw/master/install_kernel.sh)
    # wget -N --no-check-certificate https://github.com/kontorol/one_click_script/raw/master/install_kernel.sh && chmod +x ./install_kernel.sh && ./install_kernel.sh
}



















# network speed test

function vps_netflix(){
    # bash <(curl -sSL https://raw.githubusercontent.com/Netflixxp/NF/main/nf.sh)
    # bash <(curl -sSL "https://github.com/CoiaPrant/Netflix_Unlock_Information/raw/main/netflix.sh")
    # bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh)

	# wget -N --no-check-certificate https://github.com/CoiaPrant/Netflix_Unlock_Information/raw/main/netflix.sh && chmod +x netflix.sh && ./netflix.sh
    # wget -N --no-check-certificate -O netflixcheck https://github.com/sjlleo/netflix-verify/releases/download/2.61/nf_2.61_linux_amd64 && chmod +x ./netflixcheck && ./netflixcheck -method full

	wget -N --no-check-certificate -O ./netflix.sh https://github.com/CoiaPrant/MediaUnlock_Test/raw/main/check.sh && chmod +x ./netflix.sh && ./netflix.sh
}

function vps_netflix2(){
	wget -N --no-check-certificate -O ./netflix.sh https://github.com/lmc999/RegionRestrictionCheck/raw/main/check.sh && chmod +x ./netflix.sh && ./netflix.sh
}

function vps_netflix_jin(){
    # wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/SimpleNetflix/dev/nf.sh && chmod +x ./nf.sh
	wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/kontorol/one_click_script/master/netflix_check.sh && chmod +x ./nf.sh && ./nf.sh
}



function vps_netflixgo(){
    wget -qN --no-check-certificate -O netflixGo https://github.com/sjlleo/netflix-verify/releases/download/v3.1.0/nf_linux_amd64 && chmod +x ./netflixGo && ./netflixGo
    # wget -qN --no-check-certificate -O netflixGo https://github.com/sjlleo/netflix-verify/releases/download/2.61/nf_2.61_linux_amd64 && chmod +x ./netflixGo && ./netflixGo -method full
    echo
    echo
    wget -qN --no-check-certificate -O disneyplusGo https://github.com/sjlleo/VerifyDisneyPlus/releases/download/1.01/dp_1.01_linux_amd64 && chmod +x ./disneyplusGo && ./disneyplusGo
}


function vps_superspeed(){
    bash <(curl -Lso- https://git.io/superspeed_uxh)
    # bash <(curl -Lso- https://git.io/Jlkmw)
    # https://github.com/coolaj/sh/blob/main/speedtest.sh


    # bash <(curl -Lso- https://raw.githubusercontent.com/uxh/superspeed/master/superspeed.sh)

    # bash <(curl -Lso- https://raw.githubusercontent.com/zq/superspeed/master/superspeed.sh)
	# bash <(curl -Lso- https://git.io/superspeed.sh)


    #wget -N --no-check-certificate https://raw.githubusercontent.com/flyzy2005/superspeed/master/superspeed.sh && chmod +x superspeed.sh && ./superspeed.sh
    #wget -N --no-check-certificate https://raw.githubusercontent.com/zq/superspeed/master/superspeed.sh && chmod +x superspeed.sh && ./superspeed.sh

    # bash <(curl -Lso- https://git.io/superspeed)
	#wget -N --no-check-certificate https://raw.githubusercontent.com/ernisn/superspeed/master/superspeed.sh && chmod +x superspeed.sh && ./superspeed.sh
	
	#wget -N --no-check-certificate https://raw.githubusercontent.com/oooldking/script/master/superspeed.sh && chmod +x superspeed.sh && ./superspeed.sh
}

function vps_yabs(){
	curl -sL yabs.sh | bash
}
function vps_bench(){
    wget -N --no-check-certificate https://raw.githubusercontent.com/kontorol/one_click_script/master/bench.sh && chmod +x bench.sh && bash bench.sh
	# wget -N --no-check-certificate https://raw.githubusercontent.com/teddysun/across/master/bench.sh && chmod +x bench.sh && bash bench.sh
}
function vps_bench_dedicated(){
    # bash -c "$(wget -qO- https://github.com/Aniverse/A/raw/i/a)"
	wget -N --no-check-certificate -O dedicated_server_bench.sh https://raw.githubusercontent.com/Aniverse/A/i/a && chmod +x dedicated_server_bench.sh && bash dedicated_server_bench.sh
}

function vps_zbench(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/FunctionClub/ZBench/master/ZBench-CN.sh && chmod +x ZBench-CN.sh && bash ZBench-CN.sh
}
function vps_LemonBench(){
    wget -N --no-check-certificate -O LemonBench.sh https://ilemonra.in/LemonBenchIntl && chmod +x LemonBench.sh && ./LemonBench.sh fast
}

function vps_testrace(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/nanqinlang-script/testrace/master/testrace.sh && chmod +x testrace.sh && ./testrace.sh
}

function vps_autoBestTrace(){
    wget -N --no-check-certificate -O autoBestTrace.sh https://raw.githubusercontent.com/zq/shell/master/autoBestTrace.sh && chmod +x autoBestTrace.sh && ./autoBestTrace.sh
}
function vps_mtrTrace(){
    curl https://raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
}
function vps_returnroute(){
    # https://www.zhujizixun.com/6216.html
    # https://91ai.net/thread-1015693-5-1.html
    # https://github.com/zhucaidan/mtr_trace
    wget --no-check-certificate -O route https://tutu.ovh/bash/returnroute/route  && chmod +x route && ./route
}
function vps_returnroute2(){
    # curl https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh | sh
    wget -N --no-check-certificate -O routeGo.sh https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh && chmod +x routeGo.sh && ./routeGo.sh
}




function installBBR(){
    wget -N --no-check-certificate -O tcp_old.sh "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp_old.sh && ./tcp_old.sh
}

function installBBR2(){
    wget -N --no-check-certificate "https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
}


function installSWAP(){
    bash <(wget --no-check-certificate -qO- 'https://www.moerats.com/usr/shell/swap.sh')
}



function installBTPanel(){
    if [ "$osRelease" == "centos" ]; then
        yum install -y wget && wget -O install.sh http://download.bt.cn/install/install_6.0.sh && sh install.sh
    else
        # curl -sSO http://download.bt.cn/install/install_panel.sh && bash install_panel.sh
        wget -O install.sh http://download.bt.cn/install/install-ubuntu_6.0.sh && sudo bash install.sh

    fi
}

function installBTPanelCrack(){
    echo "US node (directly enter 11 digits and 1 password at will to log in)"
    if [ "$osRelease" == "centos" ]; then
        yum install -y wget && wget -O btinstall.sh http://io.yu.al/install/install_6.0.sh && sh btinstall.sh
        # yum install -y wget && wget -O install.sh https://download.fenhao.me/install/install_6.0.sh && sh install.sh
    else
        wget -O btinstall.sh http://io.yu.al/install/install_panel.sh && sudo bash btinstall.sh
        #wget -O install.sh https://download.fenhao.me/install/install-ubuntu_6.0.sh && sudo bash install.sh
    fi
}

function installBTPanelCrackHostcli(){
    if [ "$osRelease" == "centos" ]; then
        yum install -y wget && wget -O btinstall.sh http://v7.hostcli.com/install/install_6.0.sh && sh btinstall.sh
    else
        wget -O btinstall.sh http://v7.hostcli.com/install/install-ubuntu_6.0.sh && sudo bash btinstall.sh
    fi
}













































configWebsiteFatherPath="/nginxweb"
configWebsitePath="${configWebsiteFatherPath}/html"
nginxAccessLogFilePath="${configWebsiteFatherPath}/nginx-access.log"
nginxErrorLogFilePath="${configWebsiteFatherPath}/nginx-error.log"

configTrojanWindowsCliPrefixPath=$(cat /dev/urandom | head -1 | md5sum | head -c 20)
configWebsiteDownloadPath="${configWebsitePath}/download/${configTrojanWindowsCliPrefixPath}"
configDownloadTempPath="${HOME}/temp"



versionTrojan="1.16.0"
downloadFilenameTrojan="trojan-${versionTrojan}-linux-amd64.tar.xz"

versionTrojanGo="0.10.6"
downloadFilenameTrojanGo="trojan-go-linux-amd64.zip"

versionV2ray="4.45.2"
downloadFilenameV2ray="v2ray-linux-64.zip"

versionXray="1.5.5"
downloadFilenameXray="Xray-linux-64.zip"

versionTrojanWeb="2.10.5"
downloadFilenameTrojanWeb="trojan-linux-amd64"

isTrojanMultiPassword="no"
promptInfoTrojanName="-go"

isTrojanGoSupportWebsocket="false"
configTrojanGoWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
configTrojanPasswordPrefixInputDefault=$(cat /dev/urandom | head -1 | md5sum | head -c 3)


trojanInstallType="4"
configTrojanPath="${HOME}/trojan"
configTrojanGoPath="${HOME}/trojan-go"
configTrojanBasePath="${configTrojanGoPath}"

configTrojanWebPath="${HOME}/trojan-web"
configTrojanLogFile="${HOME}/trojan-access.log"


configTrojanBaseVersion=${versionTrojan}

configTrojanWebNginxPath=$(cat /dev/urandom | head -1 | md5sum | head -c 5)
configTrojanWebPort="$(($RANDOM + 10000))"

configInstallNginxMode=""
nginxConfigPath="/etc/nginx/nginx.conf"
nginxConfigSiteConfPath="/etc/nginx/conf.d"


promptInfoXrayInstall="V2ray"
promptInfoXrayVersion=""
promptInfoXrayName="v2ray"
promptInfoXrayNameServiceName=""
isXray="no"

configV2rayWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
configV2rayGRPCServiceName=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
configV2rayPort="$(($RANDOM + 10000))"
configV2rayGRPCPort="$(($RANDOM + 10000))"
configV2rayVmesWSPort="$(($RANDOM + 10000))"
configV2rayVmessTCPPort="$(($RANDOM + 10000))"
configV2rayPortShowInfo=$configV2rayPort
configV2rayPortGRPCShowInfo=$configV2rayGRPCPort
configV2rayIsTlsShowInfo="tls"
configV2rayTrojanPort="$(($RANDOM + 10000))"

configV2rayPath="${HOME}/v2ray"
configV2rayAccessLogFilePath="${HOME}/v2ray-access.log"
configV2rayErrorLogFilePath="${HOME}/v2ray-error.log"
configV2rayVmessImportLinkFile1Path="${configV2rayPath}/vmess_link1.json"
configV2rayVmessImportLinkFile2Path="${configV2rayPath}/vmess_link2.json"
configV2rayVlessImportLinkFile1Path="${configV2rayPath}/vless_link1.json"
configV2rayVlessImportLinkFile2Path="${configV2rayPath}/vless_link2.json"

configV2rayProtocol="vmess"
configV2rayWorkingMode=""
configV2rayWorkingNotChangeMode=""
configV2rayStreamSetting=""


configReadme=${HOME}/readme_trojan_v2ray.txt


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
        green "===== Download and extract the tar file: $3 "
        wget -O ${configDownloadTempPath}/$3 $1
        tar xf ${configDownloadTempPath}/$3 -C ${configDownloadTempPath}

        mv ${configDownloadTempPath}/* $2
         

    elif [[ $3 == *"tar.gz"* ]]; then
        green "===== Download and extract the tar.gz file: $3 "
        wget -O ${configDownloadTempPath}/$3 $1
        tar -xzvf ${configDownloadTempPath}/$3 -C ${configDownloadTempPath}
        mv ${configDownloadTempPath}/easymosdns/* $2
        
    else  
        green "===== Download and extract the zip file:  $3 "
        wget -O ${configDownloadTempPath}/$3 $1
        unzip -d $2 ${configDownloadTempPath}/$3
    fi
    rm -rf ${configDownloadTempPath}/*

}

function getGithubLatestReleaseVersion(){
    # https://github.com/p4gefau1t/trojan-go/issues/63
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -b 2-
}

function getV2rayVersion(){
    # https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz

    echo 

    if [[ $1 == "v2ray" ]] ; then
        echo
        green " ================================================== "
        green " Please select the version of V2ray, the default is to enter the stable version 4.45.2 (recommended)"
        green " Select otherwise to install the latest version V2ray 5.1.0 User Preview"
        echo
        read -r -p "Do you want to install the stable version of V2ray? The default is to enter the stable version 4.45.2, please enter [Y/n]:" isInstallXrayVersionInput
        isInstallXrayVersionInput=${isInstallXrayVersionInput:-Y}
        echo

        if [[ $isInstallXrayVersionInput == [Yy] ]]; then
            versionV2ray="4.45.2"
        else
            versionV2ray=$(getGithubLatestReleaseVersion "v2fly/v2ray-core")
        fi
        echo "versionV2ray: ${versionV2ray}"
    fi

    if [[ $1 == "xray" ]] ; then
        versionXray=$(getGithubLatestReleaseVersion "XTLS/Xray-core")
        echo "versionXray: ${versionXray}"
    fi


    if [[ $1 == "trojan-web" ]] ; then
        versionTrojanWeb=$(getGithubLatestReleaseVersion "Jrohy/trojan")
        echo "versionTrojanWeb: ${versionTrojanWeb}"
    fi

    if [[ $1 == "wgcf" ]] ; then
        versionWgcf=$(getGithubLatestReleaseVersion "ViRb3/wgcf")
        downloadFilenameWgcf="wgcf_${versionWgcf}_linux_amd64"
        echo "versionWgcf: ${versionWgcf}"
    fi

}








configNetworkRealIp=""
configSSLDomain=""



acmeSSLRegisterEmailInput=""
isDomainSSLGoogleEABKeyInput=""
isDomainSSLGoogleEABIdInput=""

function getHTTPSCertificateCheckEmail(){
    if [ -z $2 ]; then
        
        if [[ $1 == "email" ]]; then
            red " The input email address cannot be empty, please re-enter !"
            getHTTPSCertificateInputEmail
        elif [[ $1 == "googleEabKey" ]]; then
            red " Enter EAB key can not be empty, please re-enter !"
            getHTTPSCertificateInputGoogleEABKey
        elif [[ $1 == "googleEabId" ]]; then
            red " Enter EAB Id cannot be empty, please re-enter !"
            getHTTPSCertificateInputGoogleEABId            
        fi
    fi
}
function getHTTPSCertificateInputEmail(){
    echo
    read -r -p "Please enter your email address to apply for a SSL certificate:" acmeSSLRegisterEmailInput
    getHTTPSCertificateCheckEmail "email" "${acmeSSLRegisterEmailInput}"
}
function getHTTPSCertificateInputGoogleEABKey(){
    echo
    read -r -p "Please enter Google EAB key :" isDomainSSLGoogleEABKeyInput
    getHTTPSCertificateCheckEmail "googleEabKey" "${isDomainSSLGoogleEABKeyInput}"
}
function getHTTPSCertificateInputGoogleEABId(){
    echo
    read -r -p "please enter Google EAB id :" isDomainSSLGoogleEABIdInput
    getHTTPSCertificateCheckEmail "googleEabId" "${isDomainSSLGoogleEABIdInput}"
}


acmeSSLDays="89"
acmeSSLServerName="letsencrypt"
acmeSSLDNSProvider="dns_cf"

configRanPath="${HOME}/ran"
configSSLAcmeScriptPath="${HOME}/.acme.sh"
configSSLCertPath="${configWebsiteFatherPath}/cert"

configSSLCertKeyFilename="private.key"
configSSLCertFullchainFilename="fullchain.cer"


function renewCertificationWithAcme(){

    # https://stackoverflow.com/questions/8880603/loop-through-an-array-of-strings-in-bash
    # https://stackoverflow.com/questions/9954680/how-to-store-directory-files-listing-into-an-array
    
    shopt -s nullglob
    renewDomainArray=("${configSSLAcmeScriptPath}"/*ecc*)

    COUNTER1=1

    if [ ${#renewDomainArray[@]} -ne 0 ]; then
        echo
        green " ================================================== "
        green " It is detected that the machine has already applied for a domain name certificate. Whether to add a new domain name certificate"
        yellow " Reinstall trojan or v2ray after a new install or uninstall please select Add instead of Renew "
        echo
        green " 1. Newly apply for a domain name certificate"
        green " 2. Renew the applied domain name certificate"
        green " 3. Delete the domain name certificate that has been applied for"
        echo
        read -r -p "Please choose whether to add a domain name certificate? By default, press Enter to add, please enter pure numbers:" isAcmeSSLAddNewInput
        isAcmeSSLAddNewInput=${isAcmeSSLAddNewInput:-1}
        if [[ "$isAcmeSSLAddNewInput" == "2" || "$isAcmeSSLAddNewInput" == "3" ]]; then

            echo
            green " ================================================== "
            green " Please select a domain name to renew or delete:"
            echo
            for renewDomainName in "${renewDomainArray[@]}"; do
                
                substr=${renewDomainName##*/}
                substr=${substr%_ecc*}
                renewDomainArrayFix[${COUNTER1}]="$substr"
                echo " ${COUNTER1}. 域名: ${substr}"

                COUNTER1=$((COUNTER1 +1))
            done

            echo
            read -r -p "Please select a domain name? Please enter only numbers:" isRenewDomainSelectNumberInput
            isRenewDomainSelectNumberInput=${isRenewDomainSelectNumberInput:-99}
        
            if [[ "$isRenewDomainSelectNumberInput" == "99" ]]; then
                red " Input errors, please re-enter!"
                echo
                read -r -p "Please select a domain name? Please enter only numbers:" isRenewDomainSelectNumberInput
                isRenewDomainSelectNumberInput=${isRenewDomainSelectNumberInput:-99}

                if [[ "$isRenewDomainSelectNumberInput" == "99" ]]; then
                    red " typo, exit!"
                    exit
                else
                    echo
                fi
            else
                echo
            fi

            configSSLRenewDomain=${renewDomainArrayFix[${isRenewDomainSelectNumberInput}]}


            if [[ -n $(${configSSLAcmeScriptPath}/acme.sh --list | grep ${configSSLRenewDomain}) ]]; then

                if [[ "$isAcmeSSLAddNewInput" == "2" ]]; then
                    ${configSSLAcmeScriptPath}/acme.sh --renew -d ${configSSLRenewDomain} --force --ecc
                    echo
                    green " domain name ${configSSLRenewDomain} 's certificate has been successfully renewed!"

                elif [[ "$isAcmeSSLAddNewInput" == "3" ]]; then
                    ${configSSLAcmeScriptPath}/acme.sh --revoke -d ${configSSLRenewDomain} --ecc
                    ${configSSLAcmeScriptPath}/acme.sh --remove -d ${configSSLRenewDomain} --ecc

                    rm -rf "${configSSLAcmeScriptPath}/${configSSLRenewDomain}_ecc"
                    echo
                    green " domain name ${configSSLRenewDomain} The certificate has been deleted successfully!"
                    exit
                fi  
            else
                echo
                red " domain name ${configSSLRenewDomain} certificate does not exist！"
            fi

        else 
            getHTTPSCertificateStep1
        fi

    else
        getHTTPSCertificateStep1
    fi

}

function getHTTPSCertificateWithAcme(){

    # Apply for https certificate
	mkdir -p ${configSSLCertPath}
	mkdir -p ${configWebsitePath}
	
    getHTTPSCertificateInputEmail

	curl https://get.acme.sh | sh -s email=${acmeSSLRegisterEmailInput}



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

        acmeSSLDays="179"
        acmeSSLServerName="buypass"
        echo
        ${configSSLAcmeScriptPath}/acme.sh --register-account --accountemail ${acmeSSLRegisterEmailInput} --server buypass
        
    elif [[ "$isDomainSSLFromLetInput" == "3" ]]; then

        acmeSSLServerName="zerossl"
        echo
        ${configSSLAcmeScriptPath}/acme.sh --register-account -m ${acmeSSLRegisterEmailInput} --server zerossl

    elif [[ "$isDomainSSLFromLetInput" == "4" ]]; then
        green " ================================================== "
        yellow " Please follow the link below to apply google Public CA  https://hostloc.com/thread-993780-1-1.html"
        yellow " For details, please refer to https://github.com/acmesh-official/acme.sh/wiki/Google-Public-CA"

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
    green "Please select the acme.sh script to apply for the SSL certificate method: 1 http method, 2 dns method "
    green " The default is to press Enter directly to apply for http, otherwise it is to use dns"
    echo
    read -r -p "Please select an SSL certificate application method [Y/n]:" isAcmeSSLRequestMethodInput
    isAcmeSSLRequestMethodInput=${isAcmeSSLRequestMethodInput:-Y}
    echo

    if [[ $isAcmeSSLRequestMethodInput == [Yy] ]]; then
        acmeSSLHttpWebrootMode=""

        if [[ -n "${configInstallNginxMode}" ]]; then
            acmeDefaultValue="3"
            acmeDefaultText="3. webroot and use ran as a temporary web server"
            acmeSSLHttpWebrootMode="webrootran"
        else
            acmeDefaultValue="1"
            acmeDefaultText="1. standalone model"
            acmeSSLHttpWebrootMode="standalone"
        fi
        
        if [ -z "$1" ]; then

            checkPortUsage "80"
 
            green " ================================================== "
            green " please choose http How to apply for a certificate: The default is to enter directly ${acmeDefaultText} "
            green " 1 standaloneMode, suitable for no web server installed, if you have chosen not to install Nginx, please select this mode. Please ensure that port 80 is not occupied. Note: If port 80 is occupied after three months, the renewal will fail!"
            green " 2 webroot Mode, suitable for already installed web server, such as Caddy Apache or Nginx, please make sure the web server is running on port 80"
            green " 3 webroot Mode and use ran as a temporary web server, if you have chosen to install Nginx at the same time, please use this mode, you can renew normally"
            green " 4 nginx Mode Suitable for Nginx already installed, please make sure Nginx is already running"
            echo
            read -r -p "Please select http application certificate method? The default is ${acmeDefaultText}, Please enter pure numbers:" isAcmeSSLWebrootModeInput

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
            green " Start requesting certificate acme.sh via http standalone mode from ${acmeSSLServerName} To apply, please make sure that port 80 is not occupied "
            
            echo
            ${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --standalone --keylength ec-256 --days ${acmeSSLDays} --server ${acmeSSLServerName}
        
        elif [[ ${acmeSSLHttpWebrootMode} == "webroot" ]] ; then
            green " To start applying for a certificate, acme.sh via http webroot mode from ${acmeSSLServerName} To apply, please make sure that the web server such as nginx is already running on port 80 "
            
            echo
            read -r -p "Please enter the html website root directory path of the web server ? E.g:/usr/share/nginx/html:" isDomainSSLNginxWebrootFolderInput
            echo " The website root directory path you entered is ${isDomainSSLNginxWebrootFolderInput}"

            if [ -z ${isDomainSSLNginxWebrootFolderInput} ]; then
                red " The html website root directory path of the entered web server cannot be empty, and the website root directory will be set to ${configWebsitePath}, Please modify your web server configuration before applying for a certificate!"
                
            else
                configWebsitePath="${isDomainSSLNginxWebrootFolderInput}"
            fi
            
            echo
            ${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --webroot ${configWebsitePath} --keylength ec-256 --days ${acmeSSLDays} --server ${acmeSSLServerName}
        
        elif [[ ${acmeSSLHttpWebrootMode} == "nginx" ]] ; then
            green "Start applying for a certificate, acme.sh pass http nginx mode from ${acmeSSLServerName} To apply, please make sure the web server nginx is running "
            
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
                green " Detected ran has been downloaded, ready to start ran temporary web server "
            else
                green " Start downloading ran as a temporary web server "
                downloadAndUnzip "${ranDownloadUrl}" "${configRanPath}" "${ranDownloadFileName}" 
                chmod +x "${configRanPath}/${ranDownloadFileName}"
            fi

            echo "nohup ${configRanPath}/${ranDownloadFileName} -l=false -g=false -sa=true -p=80 -r=${configWebsitePath} >/dev/null 2>&1 &"
            nohup ${configRanPath}/${ranDownloadFileName} -l=false -g=false -sa=true -p=80 -r=${configWebsitePath} >/dev/null 2>&1 &
            echo
            
            green " To start applying for a certificate, acme.sh via http webroot mode from ${acmeSSLServerName} application, and use ran as a temporary web server "
            echo
            ${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --webroot ${configWebsitePath} --keylength ec-256 --days ${acmeSSLDays} --server ${acmeSSLServerName}

            sleep 4
            ps -C ${ranDownloadFileName} -o pid= | xargs -I {} kill {}
        fi

    else
        green " 开始申请证书, acme.sh 通过 dns mode 申请 "

        echo
        green "Please select DNS provider DNS provider: 1 CloudFlare, 2 AliYun,  3 DNSPod(Tencent), 4 GoDaddy "
        red "Note that CloudFlare no longer supports using API to apply for DNS certificates for some free domain names such as .tk .cf, etc. "
        echo
        read -r -p "Please select a DNS provider? The default is 1. CloudFlare, please enter pure numbers:" isAcmeSSLDNSProviderInput
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
    green " Check whether the IP pointed to by the domain name is correct. Press Enter to check by default."
    red " If the IP pointed to by the domain name is not the local IP, or the CDN is turned on and it is inconvenient to close, or the VPS only has IPv6, you can choose whether to not detect"
    read -r -p "Does the detection domain name point to the correct IP? Please enter [Y/n]:" isDomainValidInput
    isDomainValidInput=${isDomainValidInput:-Y}

    if [[ $isDomainValidInput == [Yy] ]]; then
        if [[ -n "$1" ]]; then
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
            green " The domain name resolution address is ${configNetworkRealIp},The IP of this VPS is ${configNetworkLocalIp1} "

            echo
            if [[ ${configNetworkRealIp} == "${configNetworkLocalIp1}" || ${configNetworkRealIp} == "${configNetworkLocalIp2}" ]] ; then

                green " The IP address of the domain name resolution is normal !"
                green " ================================================== "
                true
            else
                red "The domain name resolution address is inconsistent with the IP address of this VPS !"
                red " This installation failed, please ensure that the domain name resolution is normal, please check whether the domain name and DNS are valid!"
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


function getHTTPSCertificateStep1(){
    
    echo
    green " ================================================== "
    yellow " Please enter the domain name that resolves to this VPS, such as www.xxx.com: (In this step, please close the CDN and install it after nginx to avoid the failure to apply for a certificate due to port 80 occupation)"
    read -r -p "Please enter the domain name resolved to this VPS:" configSSLDomain

    if compareRealIpWithLocalIp "${configSSLDomain}" ; then
        echo
        green " =================================================="
        green " Do you want to apply for a certificate? The default is to directly press Enter to apply for a certificate, such as the second installation or an existing certificate, you can choose No"
        green " If you already have an SSL certificate file, please put it in the following path"
        red " ${configSSLDomain} Domain name certificate content file path ${configSSLCertPath}/${configSSLCertFullchainFilename} "
        red " ${configSSLDomain} Domain name certificate private key file path ${configSSLCertPath}/${configSSLCertKeyFilename} "
        echo

        read -r -p "Do you want to apply for a certificate? By default, press Enter to automatically apply for a certificate, please enter [Y/n]:" isDomainSSLRequestInput
        isDomainSSLRequestInput=${isDomainSSLRequestInput:-Y}

        if [[ $isDomainSSLRequestInput == [Yy] ]]; then
            getHTTPSCertificateWithAcme ""
        else
            green " =================================================="
            green " If you do not apply for a domain name certificate, please put the certificate in the following directory, or modify the trojan or v2ray configuration by yourself !"
            green " ${configSSLDomain} Domain name certificate content file path ${configSSLCertPath}/${configSSLCertFullchainFilename} "
            green " ${configSSLDomain} Domain name certificate private key file path ${configSSLCertPath}/${configSSLCertKeyFilename} "
            green " =================================================="
        fi
    else
        exit
    fi

}












wwwUsername="www-data"
function createUserWWW(){
	isHaveWwwUser=$(cat /etc/passwd | cut -d ":" -f 1 | grep ^${wwwUsername}$)
	if [ "${isHaveWwwUser}" != "${wwwUsername}" ]; then
		${sudoCmd} groupadd ${wwwUsername}
		${sudoCmd} useradd -s /usr/sbin/nologin -g ${wwwUsername} ${wwwUsername} --no-create-home         
	fi
}

function stopServiceNginx(){
    serviceNginxStatus=$(ps -aux | grep "nginx: worker" | grep -v "grep")
    if [[ -n "$serviceNginxStatus" ]]; then
        ${sudoCmd} systemctl stop nginx.service
    fi
}

function stopServiceV2ray(){
    if [[ -f "${osSystemMdPath}v2ray.service" ]] || [[ -f "/etc/systemd/system/v2ray.service" ]] || [[ -f "/lib/systemd/system/v2ray.service" ]] ; then
        ${sudoCmd} systemctl stop v2ray.service
    fi
    if [[ -f "${osSystemMdPath}xray.service" ]] || [[ -f "/etc/systemd/system/xray.service" ]] || [[ -f "/lib/systemd/system/xray.service" ]] ; then
        ${sudoCmd} systemctl stop xray.service
    fi    
}



function installWebServerNginx(){

    echo
    green " ================================================== "
    yellow "    Start installing the web server nginx !"
    green " ================================================== "
    echo

    if test -s ${nginxConfigPath}; then
        showHeaderRed "Nginx already exists, do you want to continue the installation? " "Nginx already exists. Continue the installation? "
        promptContinueOpeartion

        ${sudoCmd} systemctl stop nginx.service
    else
        stopServiceV2ray

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

        # Solve the nginx that appears warning mistake Failed to parse PID from file /run/nginx.pid: Invalid argument
        # https://www.kancloud.cn/tinywan/nginx_tutorial/753832
        
        mkdir -p /etc/systemd/system/nginx.service.d
        printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
        
        ${sudoCmd} systemctl daemon-reload

    fi



    
    mkdir -p ${configWebsitePath}
    mkdir -p "${nginxConfigSiteConfPath}"


    nginxConfigServerHttpInput=""
    nginxConfigServerHttpGrpcInput=""
    nginxConfigStreamConfigInput=""
    nginxConfigNginxModuleInput=""
    nginxConfigDefaultWebsiteLocation=""

    echo
    green " =================================================="
    green " Whether to reverse the specified website? The default is not to reverse the website, use the bootstrap static page as a camouflage website)"
    green " If you need a reverse website, please enter the URL such as www.baidu.com (do not enter https://)"
    echo
    read -r -p "Whether to reverse the specified website, the default is to enter directly without reverse generation, please enter the reverse generation URL:" configNginxDefaultWebsiteInput
    configNginxDefaultWebsiteInput=${configNginxDefaultWebsiteInput:-}

        if [[ -n "${configNginxDefaultWebsiteInput}" ]]; then
            read -r -d '' nginxConfigDefaultWebsiteLocation << EOM

        location / {
            proxy_pass https://$configNginxDefaultWebsiteInput;

        }

EOM

        fi

    if [[ "${configInstallNginxMode}" == "noSSL" ]]; then
        if [[ ${configV2rayWorkingNotChangeMode} == "true" ]]; then
            inputV2rayStreamSettings
        fi

        if [[ "${configV2rayStreamSetting}" == "grpc" || "${configV2rayStreamSetting}" == "wsgrpc" ]]; then
            read -r -d '' nginxConfigServerHttpGrpcInput << EOM

        location /$configV2rayGRPCServiceName {
            grpc_pass grpc://127.0.0.1:$configV2rayGRPCPort;
            grpc_connect_timeout 60s;
            grpc_read_timeout 720m;
            grpc_send_timeout 720m;
            grpc_set_header X-Real-IP \$remote_addr;
            grpc_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }

        

EOM

        fi

        cat > "${nginxConfigSiteConfPath}/nossl_site.conf" <<-EOF
    server {
        listen       80;
        server_name  $configSSLDomain;
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

        ${nginxConfigServerHttpGrpcInput}

        ${nginxConfigDefaultWebsiteLocation}
    }

EOF


    elif [[ "${configInstallNginxMode}" == "v2raySSL" ]]; then
        inputV2rayStreamSettings

        cat > "${nginxConfigSiteConfPath}/v2rayssl_site.conf" <<-EOF
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

        location /$configV2rayGRPCServiceName {
            grpc_pass grpc://127.0.0.1:$configV2rayGRPCPort;
            grpc_connect_timeout 60s;
            grpc_read_timeout 720m;
            grpc_send_timeout 720m;
            grpc_set_header X-Real-IP \$remote_addr;
            grpc_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }

        ${nginxConfigDefaultWebsiteLocation}
    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configSSLDomain;
        return 301 https://$configSSLDomain\$request_uri;
    }

EOF


    elif [[ "${configInstallNginxMode}" == "sni" ]]; then

        if [ "$osRelease" == "centos" ]; then
        read -r -d '' nginxConfigNginxModuleInput << EOM
load_module /usr/lib64/nginx/modules/ngx_stream_module.so;
EOM
        else
        read -r -d '' nginxConfigNginxModuleInput << EOM
include /etc/nginx/modules-enabled/*.conf;
# load_module /usr/lib/nginx/modules/ngx_stream_module.so;
EOM
        fi



        nginxConfigStreamFakeWebsiteDomainInput=""

        nginxConfigStreamOwnWebsiteInput=""
        nginxConfigStreamOwnWebsiteMapInput=""

        if [[ "${isNginxSNIModeInput}" == "4" || "${isNginxSNIModeInput}" == "5" || "${isNginxSNIModeInput}" == "6" ]]; then

            read -r -d '' nginxConfigStreamOwnWebsiteInput << EOM
    server {
        listen 8000 ssl http2;
        listen [::]:8000 http2;
        server_name  $configNginxSNIDomainWebsite;

        ssl_certificate       ${configNginxSNIDomainWebsiteCertPath}/$configSSLCertFullchainFilename;
        ssl_certificate_key   ${configNginxSNIDomainWebsiteCertPath}/$configSSLCertKeyFilename;
        ssl_protocols         TLSv1.2 TLSv1.3;
        ssl_ciphers           TLS-AES-256-GCM-SHA384:TLS-CHACHA20-POLY1305-SHA256:TLS-AES-128-GCM-SHA256:TLS-AES-128-CCM-8-SHA256:TLS-AES-128-CCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256;

        # Config for 0-RTT in TLSv1.3
        ssl_early_data on;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security "max-age=31536000";
        
        root $configWebsitePath;
        index index.php index.html index.htm;

    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configNginxSNIDomainWebsite;
        return 301 https://$configNginxSNIDomainWebsite\$request_uri;
    }
EOM

            read -r -d '' nginxConfigStreamOwnWebsiteMapInput << EOM
        ${configNginxSNIDomainWebsite} web;
EOM
        fi


        nginxConfigStreamTrojanMapInput=""
        nginxConfigStreamTrojanUpstreamInput=""

        if [[ "${isNginxSNIModeInput}" == "1" || "${isNginxSNIModeInput}" == "2" || "${isNginxSNIModeInput}" == "4" || "${isNginxSNIModeInput}" == "5" ]]; then
            
            nginxConfigStreamFakeWebsiteDomainInput="${configNginxSNIDomainTrojan}"

            read -r -d '' nginxConfigStreamTrojanMapInput << EOM
        ${configNginxSNIDomainTrojan} trojan;
EOM

            read -r -d '' nginxConfigStreamTrojanUpstreamInput << EOM
    upstream trojan {
        server 127.0.0.1:$configV2rayTrojanPort;
    }
EOM
        fi


        nginxConfigStreamV2rayMapInput=""
        nginxConfigStreamV2rayUpstreamInput=""

        if [[ "${isNginxSNIModeInput}" == "1" || "${isNginxSNIModeInput}" == "3" || "${isNginxSNIModeInput}" == "4" || "${isNginxSNIModeInput}" == "6" ]]; then

            nginxConfigStreamFakeWebsiteDomainInput="${nginxConfigStreamFakeWebsiteDomainInput} ${configNginxSNIDomainV2ray}"

            read -r -d '' nginxConfigStreamV2rayMapInput << EOM
        ${configNginxSNIDomainV2ray} v2ray;
EOM

            read -r -d '' nginxConfigStreamV2rayUpstreamInput << EOM
    upstream v2ray {
        server 127.0.0.1:$configV2rayPort;
    }
EOM
        fi


        cat > "${nginxConfigSiteConfPath}/sni_site.conf" <<-EOF
    server {
        listen       80;
        server_name  $nginxConfigStreamFakeWebsiteDomainInput;
        root $configWebsitePath;
        index index.php index.html index.htm;

    }

    ${nginxConfigStreamOwnWebsiteInput}

EOF


        read -r -d '' nginxConfigStreamConfigInput << EOM
stream {
    map \$ssl_preread_server_name \$filtered_sni_name {
        ${nginxConfigStreamOwnWebsiteMapInput}
        ${nginxConfigStreamTrojanMapInput}
        ${nginxConfigStreamV2rayMapInput}
    }
    
    ${nginxConfigStreamTrojanUpstreamInput}

    ${nginxConfigStreamV2rayUpstreamInput}

    upstream web {
        server 127.0.0.1:8000;
    }

    server {
        listen 443;
        listen [::]:443;
        resolver 8.8.8.8;
        ssl_preread on;
        proxy_pass \$filtered_sni_name;
    }
}

EOM

    elif [[ "${configInstallNginxMode}" == "trojanWeb" ]]; then

        cat > "${nginxConfigSiteConfPath}/trojanweb_site.conf" <<-EOF
    server {
        listen       80;
        server_name  $configSSLDomain;
        root $configWebsitePath;
        index index.php index.html index.htm;

        location /$configTrojanWebNginxPath {
            proxy_pass http://127.0.0.1:$configTrojanWebPort/;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Host \$http_host;
        }

        location ~* ^/(static|common|auth|trojan)/ {
            proxy_pass  http://127.0.0.1:$configTrojanWebPort;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;
        }

        # http redirect to https
        if ( \$remote_addr != 127.0.0.1 ){
            rewrite ^/(.*)$ https://$configSSLDomain/\$1 redirect;
        }
    }

EOF

    else
        echo
    fi



    cat > "${nginxConfigPath}" <<-EOF

${nginxConfigNginxModuleInput}

# user  ${nginxUser};
user root;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}


${nginxConfigStreamConfigInput}


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


    include ${nginxConfigSiteConfPath}/*.conf; 
}

EOF





    # Download fake site and set up fake site
    rm -rf ${configWebsitePath}/*
    mkdir -p ${configWebsiteDownloadPath}

    downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/website2.zip" "${configWebsitePath}" "website2.zip"

    if [ "${configInstallNginxMode}" != "trojanWeb" ] ; then
        wget -P "${configWebsiteDownloadPath}" "https://github.com/jinwyp/one_click_script/raw/master/download/trojan-mac.zip"
        wget -P "${configWebsiteDownloadPath}" "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray-windows.zip" 
        wget -P "${configWebsiteDownloadPath}" "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray-mac.zip"
    fi


    # downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/trojan_client_all.zip" "${configWebsiteDownloadPath}" "trojan_client_all.zip"
    # downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/trojan-qt5.zip" "${configWebsiteDownloadPath}" "trojan-qt5.zip"
    # downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray_client_all.zip" "${configWebsiteDownloadPath}" "v2ray_client_all.zip"

    #wget -P "${configWebsiteDownloadPath}" "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray-android.zip"

    ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${configWebsiteFatherPath}
    ${sudoCmd} chmod -R 774 ${configWebsiteFatherPath}

    ${sudoCmd} systemctl start nginx.service

    green " ================================================== "
    green "       Web server nginx installed successfully !!"
    green "    Masquerade site as http://${configSSLDomain}"

	if [[ "${configInstallNginxMode}" == "trojanWeb" ]] ; then
	    yellow "    Trojan-web ${versionTrojanWeb} Visual management panel address  http://${configSSLDomain}/${configTrojanWebNginxPath} "
	    green "    Trojan-web Visual Administration Panel Executable file path ${configTrojanWebPath}/trojan-web"
        green "    Trojan-web stop command: systemctl stop trojan-web.service  start command: systemctl start trojan-web.service  restart command: systemctl restart trojan-web.service"
	    green "    Trojan Server-side executable path /usr/bin/trojan/trojan"
	    green "    Trojan Server-side configuration path /usr/local/etc/trojan/config.json "
	    green "    Trojan stop command: systemctl stop trojan.service  start command: systemctl start trojan.service  restart command: systemctl restart trojan.service"
	fi

    green "    The static html content of the fake site is placed in the directory ${configWebsitePath}, You can change the content of the website by yourself!"
	red "    nginx configuration path ${nginxConfigPath} "
	green "    nginx access log ${nginxAccessLogFilePath} "
	green "    nginx error log ${nginxErrorLogFilePath} "
    green "    nginx View log command: journalctl -n 50 -u nginx.service"
	green "    nginx start command: systemctl start nginx.service  stop command: systemctl stop nginx.service  restart command: systemctl restart nginx.service"
	green "    nginx View running status command: systemctl status nginx.service "

    green " ================================================== "

    cat >> ${configReadme} <<-EOF

web server nginx The installation was successful! The disguised site is ${configSSLDomain}   
The static html content of the fake site is placed in the directory ${configWebsitePath}, You can change the content of the website by yourself.
nginx configuration path ${nginxConfigPath}
nginx access log ${nginxAccessLogFilePath}
nginx error log ${nginxErrorLogFilePath}

nginx View log command: journalctl -n 50 -u nginx.service

nginx start command: systemctl start nginx.service  
nginx stop command: systemctl stop nginx.service  
nginx restart command: systemctl restart nginx.service
nginx View running status command: systemctl status nginx.service


EOF

	if [[ "${configInstallNginxMode}" == "trojanWeb" ]] ; then
        cat >> ${configReadme} <<-EOF

Installed Trojan-web ${versionTrojanWeb} Visual management panel 
address  http://${configSSLDomain}/${configTrojanWebNginxPath}
Trojan-web stop command: systemctl stop trojan-web.service  
Trojan-web start command: systemctl start trojan-web.service  
Trojan-web restart command: systemctl restart trojan-web.service

Trojan Server-side configuration path /usr/local/etc/trojan/config.json
Trojan stop command: systemctl stop trojan.service
Trojan start command: systemctl start trojan.service
Trojan restart command: systemctl restart trojan.service
Trojan View running status command: systemctl status trojan.service

EOF
	fi

}

function removeNginx(){

    echo
    read -r -p "Are you sure to uninstall Nginx?? Press Enter to uninstall by default, please enter [Y/n]:" isRemoveNginxServerInput
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

            rm -f ${configReadme}

            rm -rf "/etc/nginx"
            
            rm -rf ${configDownloadTempPath}

            echo
            read -r -p "Whether to delete the certificate and uninstall the acme.sh certificate application tool, because the number of times to apply for a certificate in one day is limited, it is recommended not to delete the certificate by default, please enter [y/N]:" isDomainSSLRemoveInput
            isDomainSSLRemoveInput=${isDomainSSLRemoveInput:-n}

            
            if [[ $isDomainSSLRemoveInput == [Yy] ]]; then
                rm -rf ${configWebsiteFatherPath}
                ${sudoCmd} bash ${configSSLAcmeScriptPath}/acme.sh --uninstall
                
                showHeaderGreen "Nginx Uninstallation is complete, SSL certificate files have been removed!"
                
            else
                rm -rf ${configWebsitePath}

                showHeaderGreen "Nginx Uninstallation is complete, leaving the SSL certificate file to ${configSSLCertPath} "
            fi

        else
            showHeaderRed "Nginx is not installed in the system, exit to uninstall"
        fi
        echo

    fi    
}






























configNginxSNIDomainWebsite=""
configNginxSNIDomainV2ray=""
configNginxSNIDomainTrojan=""

configSSLCertPath="${configWebsiteFatherPath}/cert"
configNginxSNIDomainTrojanCertPath="${configWebsiteFatherPath}/cert/nginxsni/trojan"
configNginxSNIDomainV2rayCertPath="${configWebsiteFatherPath}/cert/nginxsni/v2ray"
configNginxSNIDomainWebsiteCertPath="${configWebsiteFatherPath}/cert/nginxsni/web"

function checkNginxSNIDomain(){

    if compareRealIpWithLocalIp "$2" ; then

        if [ "$1" = "trojan" ]; then
            configNginxSNIDomainTrojan=$2
            configSSLCertPath="${configNginxSNIDomainTrojanCertPath}"

        elif [ "$1" = "v2ray" ]; then
            configNginxSNIDomainV2ray=$2
            configSSLCertPath="${configNginxSNIDomainV2rayCertPath}"

        elif [ "$1" = "website" ]; then
            configNginxSNIDomainWebsite=$2
            configSSLCertPath="${configNginxSNIDomainWebsiteCertPath}"
        fi
        
        configSSLDomain="$2"
        mkdir -p ${configSSLCertPath}

        echo
        green " =================================================="
        green " Do you want to apply for a certificate? The default is to directly press Enter to apply for a certificate, such as the second installation or an existing certificate, you can choose No"
        green " If you already have an SSL certificate file, please put it in the following path"
        red " ${configSSLDomain} Domain name certificate content file path ${configSSLCertPath}/${configSSLCertFullchainFilename} "
        red " ${configSSLDomain} Domain name certificate private key file path ${configSSLCertPath}/${configSSLCertKeyFilename} "
        echo

        read -p "Do you want to apply for a certificate? By default, press Enter to automatically apply for a certificate, please enter [Y/n]:" isDomainSSLRequestInput
        isDomainSSLRequestInput=${isDomainSSLRequestInput:-Y}

        if [[ $isDomainSSLRequestInput == [Yy] ]]; then
            getHTTPSCertificateWithAcme ""
        else
            green " =================================================="
            green " If you do not apply for a domain name certificate, please put the certificate in the following directory, or modify the trojan or v2ray configuration by yourself !"
            green " ${configSSLDomain} Domain name certificate content file path ${configSSLCertPath}/${configSSLCertFullchainFilename} "
            green " ${configSSLDomain} Domain name certificate private key file path ${configSSLCertPath}/${configSSLCertKeyFilename} "
            green " =================================================="
        fi
    else
        inputNginxSNIDomain $1
    fi

}

function inputNginxSNIDomain(){
    echo
    green " ================================================== "

    if [ "$1" = "trojan" ]; then
        yellow " Please enter the domain name resolved to this VPS for use by Trojan, such as www.xxx.com: (For this step, please close the CDN and install it)"
        read -p "Please enter the domain name resolved to this VPS:" configNginxSNIDomainDefault
        
    elif [ "$1" = "v2ray" ]; then
        yellow " Please enter the domain name resolved to this VPS for use by V2ray, such as www.xxx.com: (For this step, please close the CDN and install it)"
        read -p "Please enter the domain name resolved to this VPS:" configNginxSNIDomainDefault
        
    elif [ "$1" = "website" ]; then
        yellow " Please enter the domain name resolved to this VPS for use on existing websites, such as www.xxx.com: (Please close the CDN and install it in this step)"
        read -p "Please enter the domain name resolved to this VPS:" configNginxSNIDomainDefault

    fi

    checkNginxSNIDomain $1 ${configNginxSNIDomainDefault}
    
}

function inputXraySystemdServiceName(){

    if [ "$1" = "v2ray_nginxOptional" ]; then
        echo
        green " ================================================== "
        yellow " Please enter a custom V2ray or Xray Systemd service name suffix, the default is empty"
        green " The default is to enter directly without entering characters, that is, v2ray.service or xray.service"
        green " The characters entered will be suffixed e.g. v2ray-xxx.service or xray-xxx.service"
        green " This feature is used to install multiple on one VPS v2ray / xray"
        echo
        read -p "Please enter a custom Xray service name suffix, the default is empty:" configXraySystemdServiceNameSuffix
        configXraySystemdServiceNameSuffix=${configXraySystemdServiceNameSuffix:-""}

        if [ -n "${configXraySystemdServiceNameSuffix}" ]; then
            promptInfoXrayNameServiceName="-${configXraySystemdServiceNameSuffix}"
            configSSLCertPath="${configSSLCertPath}/xray_${configXraySystemdServiceNameSuffix}"
        fi
        echo
    fi

}

function installTrojanV2rayWithNginx(){

    stopServiceNginx
    testLinuxPortUsage
    installPackage

    echo
    if [ "$1" = "v2ray" ]; then
        read -r -p "Do you want to install directly using the IP of this VPS without applying for a certificate for the domain name? By default, press Enter to not apply for a certificate, please enter [Y/n]:" isDomainIPRequestInput
        isDomainIPRequestInput=${isDomainIPRequestInput:-Y}

        if [[ $isDomainIPRequestInput == [Yy] ]]; then
            echo
            read -r -p "Please enter the IP of this VPS or resolve to the domain name of this VPS:" configSSLDomain
            installV2ray
            exit
        fi

    elif [ "$1" = "nginxSNI_trojan_v2ray" ]; then
        green " ================================================== "
        yellow " Please select the installation mode of Nginx SNI + Trojan + V2ray, the default is 1"
        red " You must use 2 or 3 different domain names and set up DNS resolution, otherwise you cannot apply for an SSL certificate"
        echo
        green " 1. Nginx + Trojan + V2ray + fake website"
        green " 2. Nginx + Trojan + fake website"
        green " 3. Nginx + V2ray + fake website"
        green " 4. Nginx + Trojan + V2ray + Existing site coexists"
        green " 5. Nginx + Trojan + Existing site coexists"
        green " 6. Nginx + V2ray + Existing site coexists"

        echo 
        read -p "Please select the installation mode of Nginx SNI directly press Enter to select 1 by default, please enter pure numbers:" isNginxSNIModeInput
        isNginxSNIModeInput=${isNginxSNIModeInput:-1}

        if [[ "${isNginxSNIModeInput}" == "1" ]]; then
            inputNginxSNIDomain "trojan"
            inputNginxSNIDomain "v2ray"
            

            installWebServerNginx
            installTrojanServer
            installV2ray

        elif [[ "${isNginxSNIModeInput}" == "2" ]]; then
            inputNginxSNIDomain "trojan"

            installWebServerNginx
            installTrojanServer

        elif [[ "${isNginxSNIModeInput}" == "3" ]]; then
            inputNginxSNIDomain "v2ray"

            installWebServerNginx
            installV2ray

        elif [[ "${isNginxSNIModeInput}" == "4" ]]; then
            inputNginxSNIDomain "trojan"
            inputNginxSNIDomain "v2ray"
            inputNginxSNIDomain "website"

            installWebServerNginx
            installTrojanServer
            installV2ray

        elif [[ "${isNginxSNIModeInput}" == "5" ]]; then
            inputNginxSNIDomain "trojan"
            inputNginxSNIDomain "website"

            installWebServerNginx
            installTrojanServer

        elif [[ "${isNginxSNIModeInput}" == "6" ]]; then
            inputNginxSNIDomain "v2ray"
            inputNginxSNIDomain "website"

            installWebServerNginx
            installV2ray
            
        fi

        exit
    fi

    inputXraySystemdServiceName "$1"
    renewCertificationWithAcme ""

    echo
    if test -s ${configSSLCertPath}/${configSSLCertFullchainFilename}; then
    
        green " ================================================== "
        green " Domain detected ${configSSLDomain} The certificate file obtained successfully!"
        green " ${configSSLDomain} Domain name certificate content file path ${configSSLCertPath}/${configSSLCertFullchainFilename} "
        green " ${configSSLDomain} Domain name certificate private key file path ${configSSLCertPath}/${configSSLCertKeyFilename} "        
        green " ================================================== "
        echo

        if [ "$1" == "trojan_nginx" ]; then
            installWebServerNginx
            installTrojanServer

        elif [ "$1" = "trojan" ]; then
            installTrojanServer

        elif [ "$1" = "nginx_v2ray" ]; then
            installWebServerNginx
            installV2ray

        elif [ "$1" = "v2ray_nginxOptional" ]; then
            echo
            green " Whether to install Nginx to provide disguised websites, if there is an existing website or a pagoda panel, please select N not to install"
            read -r -p "Are you sure to install Nginx to disguise the website? Press Enter to install it by default, please enter [Y/n]:" isInstallNginxServerInput
            isInstallNginxServerInput=${isInstallNginxServerInput:-Y}

            if [[ "${isInstallNginxServerInput}" == [Yy] ]]; then
                installWebServerNginx
            fi

            if [[ "${configV2rayWorkingMode}" == "trojan" ]]; then
                installTrojanServer
            fi
            installV2ray

        elif [ "$1" = "v2ray" ]; then
            installV2ray

        elif [ "$1" = "trojan_nginx_v2ray" ]; then
            installWebServerNginx
            installTrojanServer
            installV2ray

        else
            echo
        fi
    else
        red " ================================================== "
        red " The https certificate was not successfully applied, and the installation failed!"
        red " Please check whether the domain name and DNS are valid, please do not apply for the same domain name multiple times in one day!"
        red " Please check whether ports 80 and 443 are open, VPS service providers may need to add additional firewall rules, such as Alibaba Cloud, Google Cloud, etc.!"
        red " Restart the VPS, re-execute the script, you can re-select this item to apply for the certificate again ! "
        red " ================================================== "
        exit
    fi    
}



















































function getTrojanGoVersion(){

    if [[ "${isTrojanTypeInput}" == "1" ]]; then
        versionTrojan=$(getGithubLatestReleaseVersion "trojan-gfw/trojan")
        downloadFilenameTrojan="trojan-${versionTrojan}-linux-amd64.tar.xz"
        echo "versionTrojan: ${versionTrojan}"
        configTrojanBaseVersion=${versionTrojan}
        configTrojanBasePath="${configTrojanPath}"
        promptInfoTrojanName=""

    elif [[ "${isTrojanTypeInput}" == "2" ]]; then
        versionTrojanGo=$(getGithubLatestReleaseVersion "p4gefau1t/trojan-go")
        echo "versionTrojanGo: ${versionTrojanGo}"
        configTrojanBaseVersion=${versionTrojanGo}
        configTrojanBasePath="${configTrojanGoPath}"
        promptInfoTrojanName="-go"

    elif [[ "${isTrojanTypeInput}" == "3" ]]; then
        versionTrojanGo=$(getGithubLatestReleaseVersion "fregie/trojan-go")
        echo "versionTrojanGo: ${versionTrojanGo}"
        configTrojanBaseVersion=${versionTrojanGo}
        configTrojanBasePath="${configTrojanGoPath}"
        promptInfoTrojanName="-go"

    else
        #versionTrojanGo=$(getGithubLatestReleaseVersion "Potterli20/trojan-go-fork")
        versionTrojanGo="V2022.10.17"
        echo "versionTrojanGo: ${versionTrojanGo}"
        configTrojanBaseVersion=${versionTrojanGo}
        configTrojanBasePath="${configTrojanGoPath}"
        promptInfoTrojanName="-go"

    fi
}

function downloadTrojanBin(){
    
    if [[ ${osArchitecture} == "arm" ]] ; then
        downloadFilenameTrojanGo="trojan-go-linux-arm.zip"
    fi
    if [[ ${osArchitecture} == "arm64" ]] ; then
        downloadFilenameTrojanGo="trojan-go-linux-armv8.zip"
    fi

    if [[ "${isTrojanTypeInput}" == "1" ]]; then
        # https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz
        if [[ ${osArchitecture} == "arm" || ${osArchitecture} == "arm64" ]] ; then
            red "Trojan not support arm on linux! "
            exit
        fi
        downloadAndUnzip "https://github.com/trojan-gfw/trojan/releases/download/v${versionTrojan}/${downloadFilenameTrojan}" "${configTrojanBasePath}" "${downloadFilenameTrojan}"
        mv -f ${configTrojanBasePath}/trojan ${configTrojanBasePath}/trojan-temp
        mv -f ${configTrojanBasePath}/trojan-temp/* ${configTrojanBasePath}/


    elif [[ "${isTrojanTypeInput}" == "2" ]]; then
        # https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip
        downloadAndUnzip "https://github.com/p4gefau1t/trojan-go/releases/download/v${versionTrojanGo}/${downloadFilenameTrojanGo}" "${configTrojanBasePath}" "${downloadFilenameTrojanGo}"
    
    elif [[ "${isTrojanTypeInput}" == "3" ]]; then
        # https://github.com/fregie/trojan-go/releases/download/v1.0.5/trojan-go-linux-amd64.zip
        downloadAndUnzip "https://github.com/fregie/trojan-go/releases/download/v${versionTrojanGo}/${downloadFilenameTrojanGo}" "${configTrojanBasePath}" "${downloadFilenameTrojanGo}"
        
    else
        downloadFilenameTrojanGo="trojan-go-fork-linux-amd64.zip"
        if [[ ${osArchitecture} == "arm" ]] ; then
            downloadFilenameTrojanGo="trojan-go-fork-linux-arm.zip"
        fi
        if [[ ${osArchitecture} == "arm64" ]] ; then
            downloadFilenameTrojanGo="trojan-go-fork-linux-armv8.zip"
        fi
        # https://github.com/Potterli20/trojan-go-fork/releases/download/V2022.10.17/trojan-go-fork-linux-amd64.zip
        downloadAndUnzip "https://github.com/Potterli20/trojan-go-fork/releases/download/${versionTrojanGo}/${downloadFilenameTrojanGo}" "${configTrojanBasePath}" "${downloadFilenameTrojanGo}"
        mv -f ${configTrojanBasePath}/trojan-go-fork ${configTrojanBasePath}/trojan-go
    fi

}

function generateTrojanPassword(){
    trojanPassword1=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword2=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword3=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword4=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword5=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword6=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword7=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword8=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword9=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword10=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
}

function installTrojanServer(){

    if [[ -f "${configTrojanPath}/trojan" ]]; then
        green " =================================================="
        red "  Trojan has been installed, exit the installation !"
        red "  Trojan already installed !"
        green " =================================================="
        exit
    fi

    if [[ -f "${configTrojanGoPath}/trojan-go" ]]; then
        green " =================================================="
        red "  Trojan-go has been installed, exit the installation !"
        red "  Trojan-go already installed !"
        green " =================================================="
        exit
    fi


    generateTrojanPassword


    echo
    green " =================================================="
    green " Please select install Trojan or Trojan-go ? Default selection 4 Modified version Trojan-go "
    echo
    green " 1 original Trojan not support websocket (not support websocket)"
    green " 2 original Trojan-go support websocket (support websocket)"
    green " 3 Revision Trojan-go support websocket by fregie (support websocket)"
    green " 4 Revision Trojan-go Support for simulated browser fingerprint support websocket by Potterli20 (support websocket)"
    echo
    read -r -p "Please choose which Trojan ? Enter directly and select 4 by default, please enter pure numbers:" isTrojanTypeInput
    isTrojanTypeInput=${isTrojanTypeInput:-4}

    if [[ "${isTrojanTypeInput}" == "1" ]]; then
        trojanInstallType="1"
    elif [[ "${isTrojanTypeInput}" == "2" ]]; then
        trojanInstallType="2"
    elif [[ "${isTrojanTypeInput}" == "3" ]]; then
        trojanInstallType="3"
    else
        trojanInstallType="4"
    fi

    if [[ "${trojanInstallType}" != "1" ]]; then
        echo
        green " =================================================="
        green " Enable Websocket or not, default is Y"
        green " Whether to open Websocket For CDN transfer, note that the original trojan client does not support Websocket"
        echo
        read -r -p "Please choose whether to enable Websocket? Direct Enter is enabled by default, please enter [Y/n]:" isTrojanGoWebsocketInput
        isTrojanGoWebsocketInput=${isTrojanGoWebsocketInput:-Y}

        if [[ "${isTrojanGoWebsocketInput}" == [Yy] ]]; then
            isTrojanGoSupportWebsocket="true"
        else
            isTrojanGoSupportWebsocket="false"
        fi
    fi

    echo
    getTrojanGoVersion
    echo


    showHeaderGreen " start installation Trojan${promptInfoTrojanName} Version: ${configTrojanBaseVersion} !"
    echo
    green " =================================================="
    green " Input trojan${promptInfoTrojanName} password prefix, default is ramdom char: "
    green " please enter trojan${promptInfoTrojanName} Password prefix? (several random passwords and passwords with this prefix will be generated)"
    echo

    read -r -p "Please enter the prefix of the password, and press Enter to generate the prefix randomly by default :" configTrojanPasswordPrefixInput
    configTrojanPasswordPrefixInput=${configTrojanPasswordPrefixInput:-${configTrojanPasswordPrefixInputDefault}}

    echo
    echo
    if [[ "$configV2rayWorkingMode" != "trojan" && "$configV2rayWorkingMode" != "sni" ]] ; then
        configV2rayTrojanPort=443

        inputV2rayServerPort "textMainTrojanPort"
        configV2rayTrojanPort=${isTrojanUserPortInput}         
    fi

    configV2rayTrojanReadmePort=${configV2rayTrojanPort}    

    if [[ "$configV2rayWorkingMode" == "sni" ]] ; then
        configSSLCertPath="${configNginxSNIDomainTrojanCertPath}"
        configSSLDomain=${configNginxSNIDomainTrojan}   

        configV2rayTrojanReadmePort=443 
    fi

    rm -rf "${configTrojanBasePath}"
    mkdir -p "${configTrojanBasePath}"
    cd "${configTrojanBasePath}" || exit

    echo
    downloadTrojanBin

    if [ "${isTrojanMultiPassword}" = "no" ] ; then
        read -r -d '' trojanConfigUserpasswordInput << EOM
        "${trojanPassword1}",
        "${trojanPassword2}",
        "${trojanPassword3}",
        "${trojanPassword4}",
        "${trojanPassword5}",
        "${trojanPassword6}",
        "${trojanPassword7}",
        "${trojanPassword8}",
        "${trojanPassword9}",
        "${trojanPassword10}",
        "${configTrojanPasswordPrefixInput}202201",
        "${configTrojanPasswordPrefixInput}202202",
        "${configTrojanPasswordPrefixInput}202203",
        "${configTrojanPasswordPrefixInput}202204",
        "${configTrojanPasswordPrefixInput}202205",
        "${configTrojanPasswordPrefixInput}202206",
        "${configTrojanPasswordPrefixInput}202207",
        "${configTrojanPasswordPrefixInput}202208",
        "${configTrojanPasswordPrefixInput}202209",
        "${configTrojanPasswordPrefixInput}202210"
EOM

    else

        read -r -d '' trojanConfigUserpasswordInput << EOM
        "${trojanPassword1}",
        "${trojanPassword2}",
        "${trojanPassword3}",
        "${trojanPassword4}",
        "${trojanPassword5}",
        "${trojanPassword6}",
        "${trojanPassword7}",
        "${trojanPassword8}",
        "${trojanPassword9}",
        "${trojanPassword10}",
        "${configTrojanPasswordPrefixInput}202200",
        "${configTrojanPasswordPrefixInput}202201",
        "${configTrojanPasswordPrefixInput}202202",
        "${configTrojanPasswordPrefixInput}202203",
        "${configTrojanPasswordPrefixInput}202204",
        "${configTrojanPasswordPrefixInput}202205",
        "${configTrojanPasswordPrefixInput}202206",
        "${configTrojanPasswordPrefixInput}202207",
        "${configTrojanPasswordPrefixInput}202208",
        "${configTrojanPasswordPrefixInput}202209",
        "${configTrojanPasswordPrefixInput}202210",
        "${configTrojanPasswordPrefixInput}202211",
        "${configTrojanPasswordPrefixInput}202212",
        "${configTrojanPasswordPrefixInput}202213",
        "${configTrojanPasswordPrefixInput}202214",
        "${configTrojanPasswordPrefixInput}202215",
        "${configTrojanPasswordPrefixInput}202216",
        "${configTrojanPasswordPrefixInput}202217",
        "${configTrojanPasswordPrefixInput}202218",
        "${configTrojanPasswordPrefixInput}202219",
        "${configTrojanPasswordPrefixInput}202220",
        "${configTrojanPasswordPrefixInput}202221",
        "${configTrojanPasswordPrefixInput}202222",
        "${configTrojanPasswordPrefixInput}202223",
        "${configTrojanPasswordPrefixInput}202224",
        "${configTrojanPasswordPrefixInput}202225",
        "${configTrojanPasswordPrefixInput}202226",
        "${configTrojanPasswordPrefixInput}202227",
        "${configTrojanPasswordPrefixInput}202228",
        "${configTrojanPasswordPrefixInput}202229",
        "${configTrojanPasswordPrefixInput}202230",
        "${configTrojanPasswordPrefixInput}202231",
        "${configTrojanPasswordPrefixInput}202232",
        "${configTrojanPasswordPrefixInput}202233",
        "${configTrojanPasswordPrefixInput}202234",
        "${configTrojanPasswordPrefixInput}202235",
        "${configTrojanPasswordPrefixInput}202236",
        "${configTrojanPasswordPrefixInput}202237",
        "${configTrojanPasswordPrefixInput}202238",
        "${configTrojanPasswordPrefixInput}202239",
        "${configTrojanPasswordPrefixInput}202240",
        "${configTrojanPasswordPrefixInput}202241",
        "${configTrojanPasswordPrefixInput}202242",
        "${configTrojanPasswordPrefixInput}202243",
        "${configTrojanPasswordPrefixInput}202244",
        "${configTrojanPasswordPrefixInput}202245",
        "${configTrojanPasswordPrefixInput}202246",
        "${configTrojanPasswordPrefixInput}202247",
        "${configTrojanPasswordPrefixInput}202248",
        "${configTrojanPasswordPrefixInput}202249",
        "${configTrojanPasswordPrefixInput}202250",
        "${configTrojanPasswordPrefixInput}202251",
        "${configTrojanPasswordPrefixInput}202252",
        "${configTrojanPasswordPrefixInput}202253",
        "${configTrojanPasswordPrefixInput}202254",
        "${configTrojanPasswordPrefixInput}202255",
        "${configTrojanPasswordPrefixInput}202256",
        "${configTrojanPasswordPrefixInput}202257",
        "${configTrojanPasswordPrefixInput}202258",
        "${configTrojanPasswordPrefixInput}202259",
        "${configTrojanPasswordPrefixInput}202260",
        "${configTrojanPasswordPrefixInput}202261",
        "${configTrojanPasswordPrefixInput}202262",
        "${configTrojanPasswordPrefixInput}202263",
        "${configTrojanPasswordPrefixInput}202264",
        "${configTrojanPasswordPrefixInput}202265",
        "${configTrojanPasswordPrefixInput}202266",
        "${configTrojanPasswordPrefixInput}202267",
        "${configTrojanPasswordPrefixInput}202268",
        "${configTrojanPasswordPrefixInput}202269",
        "${configTrojanPasswordPrefixInput}202270",
        "${configTrojanPasswordPrefixInput}202271",
        "${configTrojanPasswordPrefixInput}202272",
        "${configTrojanPasswordPrefixInput}202273",
        "${configTrojanPasswordPrefixInput}202274",
        "${configTrojanPasswordPrefixInput}202275",
        "${configTrojanPasswordPrefixInput}202276",
        "${configTrojanPasswordPrefixInput}202277",
        "${configTrojanPasswordPrefixInput}202278",
        "${configTrojanPasswordPrefixInput}202279",
        "${configTrojanPasswordPrefixInput}202280",
        "${configTrojanPasswordPrefixInput}202281",
        "${configTrojanPasswordPrefixInput}202282",
        "${configTrojanPasswordPrefixInput}202283",
        "${configTrojanPasswordPrefixInput}202284",
        "${configTrojanPasswordPrefixInput}202285",
        "${configTrojanPasswordPrefixInput}202286",
        "${configTrojanPasswordPrefixInput}202287",
        "${configTrojanPasswordPrefixInput}202288",
        "${configTrojanPasswordPrefixInput}202289",
        "${configTrojanPasswordPrefixInput}202290",
        "${configTrojanPasswordPrefixInput}202291",
        "${configTrojanPasswordPrefixInput}202292",
        "${configTrojanPasswordPrefixInput}202293",
        "${configTrojanPasswordPrefixInput}202294",
        "${configTrojanPasswordPrefixInput}202295",
        "${configTrojanPasswordPrefixInput}202296",
        "${configTrojanPasswordPrefixInput}202297",
        "${configTrojanPasswordPrefixInput}202298",
        "${configTrojanPasswordPrefixInput}202299"
EOM

    fi




    if [[ "${isTrojanTypeInput}" == "1" ]]; then

        # Add trojan server-side configuration
	    cat > ${configTrojanBasePath}/server.json <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": ${configV2rayTrojanPort},
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        ${trojanConfigUserpasswordInput}
    ],
    "log_level": 1,
    "ssl": {
        "cert": "${configSSLCertPath}/$configSSLCertFullchainFilename",
        "key": "${configSSLCertPath}/$configSSLCertKeyFilename",
        "key_password": "",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
	    "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
EOF

        # rm /etc/systemd/system/trojan.service   
        # Add startup script
        cat > ${osSystemMdPath}trojan.service <<-EOF
[Unit]
Description=trojan
After=network.target

[Service]
Type=simple
PIDFile=${configTrojanBasePath}/trojan.pid
ExecStart=${configTrojanBasePath}/trojan -l ${configTrojanLogFile} -c "${configTrojanBasePath}/server.json"
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
RestartPreventExitStatus=23
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF


    else

    # Add trojan-go server-side configuration
    cat > ${configTrojanBasePath}/server.json <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": ${configV2rayTrojanPort},
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        ${trojanConfigUserpasswordInput}
    ],
    "log_level": 1,
    "log_file": "${configTrojanLogFile}",
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "${configSSLCertPath}/$configSSLCertFullchainFilename",
        "key": "${configSSLCertPath}/$configSSLCertKeyFilename",
        "sni": "${configSSLDomain}",
        "fallback_addr": "127.0.0.1",
        "fallback_port": 80, 
        "fingerprint": "chrome"
    },
    "websocket": {
        "enabled": ${isTrojanGoSupportWebsocket},
        "path": "/${configTrojanGoWebSocketPath}",
        "host": "${configSSLDomain}"
    }
}
EOF


    # Add startup script
    cat > ${osSystemMdPath}trojan-go.service <<-EOF
[Unit]
Description=trojan-go
After=network.target

[Service]
Type=simple
PIDFile=${configTrojanBasePath}/trojan-go.pid
ExecStart=${configTrojanBasePath}/trojan-go -config "${configTrojanBasePath}/server.json"
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF

    fi

    ${sudoCmd} chown -R root:root ${configTrojanBasePath}
    ${sudoCmd} chmod -R 774 ${configTrojanBasePath}
    ${sudoCmd} chmod +x ${osSystemMdPath}trojan${promptInfoTrojanName}.service
    ${sudoCmd} systemctl daemon-reload
    ${sudoCmd} systemctl start trojan${promptInfoTrojanName}.service
    ${sudoCmd} systemctl enable trojan${promptInfoTrojanName}.service


    # Set up cron scheduled tasks
    # https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job

    # (crontab -l 2>/dev/null | grep -v '^[a-zA-Z]'; echo "15 4 * * 0,1,2,3,4,5,6 systemctl restart trojan.service") | sort - | uniq - | crontab -
    (crontab -l ; echo "10 4 * * 0,1,2,3,4,5,6 systemctl restart trojan${promptInfoTrojanName}.service") | sort - | uniq - | crontab -


	green "======================================================================"
	green "    Trojan${promptInfoTrojanName} Version: ${configTrojanBaseVersion} Successful installation !"

    if [[ ${configInstallNginxMode} == "noSSL" ]]; then
        green "    Masquerade site as https://${configSSLDomain}"
	    green "    The static html content of the fake site is placed in the directory ${configWebsitePath}, You can change the content of the website by yourself!"
    fi

	red "    Trojan${promptInfoTrojanName} Server-side configuration path ${configTrojanBasePath}/server.json "
	red "    Trojan${promptInfoTrojanName} Run log file path: ${configTrojanLogFile} "
	green "    Trojan${promptInfoTrojanName} View log command: journalctl -n 50 -u trojan${promptInfoTrojanName}.service "

	green "    Trojan${promptInfoTrojanName} stop command: systemctl stop trojan${promptInfoTrojanName}.service  start command: systemctl start trojan${promptInfoTrojanName}.service  restart command: systemctl restart trojan${promptInfoTrojanName}.service"
	green "    Trojan${promptInfoTrojanName} View running status command:  systemctl status trojan${promptInfoTrojanName}.service "
	green "    Trojan${promptInfoTrojanName} The server will automatically restart every day to prevent memory leaks. Run crontab -l Command View scheduled restart commands !"
	green "======================================================================"

    echo
	yellow "Trojan${promptInfoTrojanName} The configuration information is as follows, please copy and save by yourself, and choose one of the passwords !"
	yellow "server address: ${configSSLDomain}  port: ${configV2rayTrojanReadmePort}"
	yellow "password 1: ${trojanPassword1}"
	yellow "password 2: ${trojanPassword2}"
	yellow "password 3: ${trojanPassword3}"
	yellow "password 4: ${trojanPassword4}"
	yellow "password 5: ${trojanPassword5}"
	yellow "password 6: ${trojanPassword6}"
	yellow "password 7: ${trojanPassword7}"
	yellow "password 8: ${trojanPassword8}"
	yellow "password 9: ${trojanPassword9}"
	yellow "password 10: ${trojanPassword10}"

    tempTextInfoTrojanPassword="There are a total of 100 passwords with the prefix you specify: from ${configTrojanPasswordPrefixInput}202200 arrive ${configTrojanPasswordPrefixInput}202299 can be used"
    if [ "${isTrojanMultiPassword}" = "no" ] ; then
        tempTextInfoTrojanPassword="You specify a prefix of 10 passwords: from ${configTrojanPasswordPrefixInput}202201 arrive ${configTrojanPasswordPrefixInput}202220 can be used"
    fi
	yellow "${tempTextInfoTrojanPassword}" 
	yellow "Example: password:${configTrojanPasswordPrefixInput}202202 or password:${configTrojanPasswordPrefixInput}202209 can be used"

    if [[ ${isTrojanGoSupportWebsocket} == "true" ]]; then
        yellow "Websocket path path is: /${configTrojanGoWebSocketPath}"
        # yellow "Websocket obfuscation_password The obfuscated password is: ${trojanPasswordWS}"
        yellow "Websocket Double TLS is: true on"
    fi

    echo
    green "======================================================================"
    yellow " Trojan${promptInfoTrojanName} Little rocket Shadowrocket link address"

    if [ "$isTrojanTypeInput" != "1" ] ; then
        if [[ ${isTrojanGoSupportWebsocket} == "true" ]]; then
            green " trojan://${trojanPassword1}@${configSSLDomain}:${configV2rayTrojanReadmePort}?peer=${configSSLDomain}&sni=${configSSLDomain}&plugin=obfs-local;obfs=websocket;obfs-host=${configSSLDomain};obfs-uri=/${configTrojanGoWebSocketPath}#${configSSLDomain}_trojan_go_ws"
            echo
            yellow " QR code Trojan${promptInfoTrojanName} "
		    green "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=trojan%3a%2f%2f${trojanPassword1}%40${configSSLDomain}%3a${configV2rayTrojanReadmePort}%3fallowInsecure%3d0%26peer%3d${configSSLDomain}%26plugin%3dobfs-local%3bobfs%3dwebsocket%3bobfs-host%3d${configSSLDomain}%3bobfs-uri%3d/${configTrojanGoWebSocketPath}%23${configSSLDomain}_trojan_go_ws"

            echo
            yellow " Trojan${promptInfoTrojanName} QV2ray link address"
            green " trojan-go://${trojanPassword1}@${configSSLDomain}:${configV2rayTrojanReadmePort}?sni=${configSSLDomain}&type=ws&host=${configSSLDomain}&path=%2F${configTrojanGoWebSocketPath}#${configSSLDomain}_trojan_go_ws"
        
        else
            green " trojan://${trojanPassword1}@${configSSLDomain}:${configV2rayTrojanReadmePort}?peer=${configSSLDomain}&sni=${configSSLDomain}#${configSSLDomain}_trojan_go"
            echo
            yellow " QR code Trojan${promptInfoTrojanName} "
            green "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=trojan%3a%2f%2f${trojanPassword1}%40${configSSLDomain}%3a${configV2rayTrojanReadmePort}%3fpeer%3d${configSSLDomain}%26sni%3d${configSSLDomain}%23${configSSLDomain}_trojan_go"

            echo
            yellow " Trojan${promptInfoTrojanName} QV2ray link address"
            green " trojan-go://${trojanPassword1}@${configSSLDomain}:${configV2rayTrojanReadmePort}?sni=${configSSLDomain}&type=original&host=${configSSLDomain}#${configSSLDomain}_trojan_go"
        fi

    else
        green " trojan://${trojanPassword1}@${configSSLDomain}:${configV2rayTrojanReadmePort}?peer=${configSSLDomain}&sni=${configSSLDomain}#${configSSLDomain}_trojan"
        echo
        yellow " QR code Trojan${promptInfoTrojanName} "
		green "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=trojan%3a%2f%2f${trojanPassword1}%40${configSSLDomain}%3a${configV2rayTrojanReadmePort}%3fpeer%3d${configSSLDomain}%26sni%3d${configSSLDomain}%23${configSSLDomain}_trojan"

    fi

	echo
	green "======================================================================"
	green "Please download the corresponding trojan client:"
	yellow "1 Windows client下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/v2ray-windows.zip"
	#yellow "  Windows Download another version of the client：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-Qt5-windows.zip"
	#yellow "  Windows Client command line version download：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-win-cli.zip"
	#yellow "  Windows The client command line version needs to be used with a browser plug-in，For example switchyomega etc.! "
    yellow "2 MacOS Client Downloads：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/v2ray-mac.zip"
    yellow "  MacOS Another client download：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-mac.zip"
    #yellow "  MacOS Client Trojan-Qt5 download：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-Qt5-mac.zip"
    yellow "3 Android Client Downloads https://github.com/trojan-gfw/igniter/releases "
    yellow "  Android Another client download https://github.com/2dust/v2rayNG/releases "
    yellow "  Android Client Clash Download https://github.com/Kr328/ClashForAndroid/releases "
    yellow "4 iOS Client please install Little Rocket https://shadowsockshelp.github.io/ios/ "
    yellow "  iOS Please install Little Rocket to another address https://lueyingpro.github.io/shadowrocket/index.html "
    yellow "  iOS There is a problem installing the small rocket tutorial https://github.com/shadowrocketHelp/help/ "
    green "======================================================================"
	green "Tutorials and other resources:"
	green "access https://www.v2rayssr.com/vpn-client.html Download client and tutorial"
    green "access https://westworldss.com/portal/page/download Download client and tutorial"
	green "======================================================================"
	green "other Windows client:"
	green "https://dl.trojan-cdn.com/trojan (exe is Win client, dmg is Mac client)"
	green "https://github.com/Qv2ray/Qv2ray/releases (exe is Win client, dmg is Mac client)"
	green "https://github.com/Dr-Incognito/V2Ray-Desktop/releases (exe is Win client, dmg is Mac client)"
	green "https://github.com/Fndroid/clash_for_windows_pkg/releases"
	green "======================================================================"
	green "Other Mac clients:"
	green "https://dl.trojan-cdn.com/trojan (exe is Win client, dmg is Mac client)"
	green "https://github.com/Qv2ray/Qv2ray/releases (exe is Win client, dmg is Mac client)"
	green "https://github.com/Dr-Incognito/V2Ray-Desktop/releases (exe is Win client, dmg is Mac client)"
	green "https://github.com/yichengchen/clashX/releases "
	green "======================================================================"



    cat >> ${configReadme} <<-EOF

Trojan${promptInfoTrojanName} Version: ${configTrojanBaseVersion} Successful installation !
Trojan${promptInfoTrojanName} Server-side configuration path ${configTrojanBasePath}/server.json

Trojan${promptInfoTrojanName} Run log file path: ${configTrojanLogFile} 
Trojan${promptInfoTrojanName} View log command: journalctl -n 50 -u trojan${promptInfoTrojanName}.service

Trojan${promptInfoTrojanName} start command: systemctl start trojan${promptInfoTrojanName}.service
Trojan${promptInfoTrojanName} stop command: systemctl stop trojan${promptInfoTrojanName}.service  
Trojan${promptInfoTrojanName} restart command: systemctl restart trojan${promptInfoTrojanName}.service
Trojan${promptInfoTrojanName} View running status command: systemctl status trojan${promptInfoTrojanName}.service

Trojan${promptInfoTrojanName} server address: ${configSSLDomain}  port: ${configV2rayTrojanReadmePort}

password1: ${trojanPassword1}
password2: ${trojanPassword2}
password3: ${trojanPassword3}
password4: ${trojanPassword4}
password5: ${trojanPassword5}
password6: ${trojanPassword6}
password7: ${trojanPassword7}
password8: ${trojanPassword8}
password9: ${trojanPassword9}
password10: ${trojanPassword10}
${tempTextInfoTrojanPassword}
Example: password:${configTrojanPasswordPrefixInput}202202 or password:${configTrojanPasswordPrefixInput}202209 can be used

If trojan-go is enabled Websocket，Then the Websocket path path is: /${configTrojanGoWebSocketPath}

small rocket link:
trojan://${trojanPassword1}@${configSSLDomain}:${configV2rayTrojanReadmePort}?peer=${configSSLDomain}&sni=${configSSLDomain}#${configSSLDomain}_trojan"

QR code Trojan${promptInfoTrojanName}
https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=trojan%3a%2f%2f${trojanPassword1}%40${configSSLDomain}%3a${configV2rayTrojanReadmePort}%3fpeer%3d${configSSLDomain}%26sni%3d${configSSLDomain}%23${configSSLDomain}_trojan

EOF
}

function removeTrojan(){

    if [[ -f "${configTrojanGoPath}/trojan-go" ]]; then

        promptInfoTrojanName="-go"
        configTrojanBasePath="${configTrojanGoPath}"

    elif [[ -f "${configTrojanPath}/trojan" ]]; then

        promptInfoTrojanName=""
        configTrojanBasePath="${configTrojanPath}"

    else
        red " system not installed Trojan / Trojan-go, exit uninstall"
        red " Trojan or Trojan-go not install, exit"
        exit
    fi

    echo
    green " ================================================== "
    green " Are you sure to uninstall Trojan${promptInfoTrojanName} ? "
    read -r -p "Are you sure to uninstall Trojan${promptInfoTrojanName}? Press Enter to uninstall by default, please enter [Y/n]:" isRemoveTrojanServerInput
    isRemoveTrojanServerInput=${isRemoveTrojanServerInput:-Y}

    if [[ "${isRemoveTrojanServerInput}" == [Yy] ]]; then
        
        echo
        green " ================================================== "
        red " Prepare to uninstall the installed Trojan${promptInfoTrojanName}"
        green " ================================================== "
        echo

        ${sudoCmd} systemctl stop trojan${promptInfoTrojanName}.service
        ${sudoCmd} systemctl disable trojan${promptInfoTrojanName}.service

        rm -rf ${configTrojanBasePath}
        rm -f ${osSystemMdPath}trojan${promptInfoTrojanName}.service
        rm -f ${configTrojanLogFile}

        rm -f ${configReadme}

        crontab -l | grep -v "trojan${promptInfoTrojanName}"  | crontab -

        echo
        green " ================================================== "
        green "  Trojan${promptInfoTrojanName} Uninstall is complete ! Trojan${promptInfoTrojanName} uninstall success !"
        green "  crontab Scheduled task deleted ! crontab remove success !"
        green " ================================================== "
    fi
}



























get_ip(){
    local IP
    IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v '^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\.' | head -n 1 )
    [ -z "${IP}" ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z "${IP}" ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    echo "${IP}"
}

get_ipv6(){
    local ipv6
    ipv6=$(wget -qO- -t1 -T2 ipv6.icanhazip.com)
    [ -z "${ipv6}" ] && return 1 || return 0
}

genShadowsocksPassword(){
    if [ -z "$1" ]; then

        shadowsocksPassword1=$(openssl rand -base64 32 | head -c 12)
        shadowsocksPassword2=$(openssl rand -base64 32 | head -c 12)
        shadowsocksPassword3=$(openssl rand -base64 32 | head -c 12)
        shadowsocksPassword4=$(openssl rand -base64 32 | head -c 12)
        shadowsocksPassword5=$(openssl rand -base64 32 | head -c 12)
    else
        PSlength=$1

        shadowsocksPassword0=$(openssl rand -base64 "${PSlength}")
        shadowsocksPassword1=$(openssl rand -base64 "${PSlength}")
        shadowsocksPassword2=$(openssl rand -base64 "${PSlength}")
        shadowsocksPassword3=$(openssl rand -base64 "${PSlength}")
        shadowsocksPassword4=$(openssl rand -base64 "${PSlength}")
        shadowsocksPassword5=$(openssl rand -base64 "${PSlength}")
    fi
}

selectShadowsocksMethod(){

    # 建议使用 AEAD (method 为 aes-256-gcm、aes-128-gcm、chacha20-poly1305 即可开启 AEAD)
    # 也可以使用传统的 method (method 为 aes-256-cfb、aes-128-cfb、chacha20、salsa20 等)
    echo
    green " =================================================="
    yellow " please choose Shadowsocks Encryption method (default 7 2022-blake3-aes-256-gcm):"
    yellow " Pls select Shadowsocks encryption method (default is 7 2022-blake3-aes-256-gcm):"
    echo
    green " 1. aes-256-gcm"
    green " 2. aes-128-gcm"
    green " 3. chacha20-poly1305"
    green " 4. chacha20-ietf-poly1305"
    green " 5. xchacha20-ietf-poly1305"
    green " 6. 2022-blake3-aes-128-gcm"
    green " 7. 2022-blake3-aes-256-gcm"
    green " 8. 2022-blake3-chacha20-poly1305"
    echo
    read -r -p "Please select an encryption method? Press Enter to select 7 by default, please enter pure numbers:" isShadowsocksMethodInput
    isShadowsocksMethodInput=${isShadowsocksMethodInput:-7}
    
    genShadowsocksPassword

    if [[ "${isShadowsocksMethodInput}" == "1" ]]; then
        shadowsocksMethod="aes-256-gcm"
    elif [[ "${isShadowsocksMethodInput}" == "2" ]]; then
        shadowsocksMethod="aes-128-gcm"
    elif [[ "${isShadowsocksMethodInput}" == "3" ]]; then
        shadowsocksMethod="chacha20-poly1305"
    elif [[ "${isShadowsocksMethodInput}" == "4" ]]; then
        shadowsocksMethod="chacha20-ietf-poly1305"
    elif [[ "${isShadowsocksMethodInput}" == "5" ]]; then
        shadowsocksMethod="xchacha20-ietf-poly1305"

    elif [[ "${isShadowsocksMethodInput}" == "6" ]]; then
        shadowsocksMethod="2022-blake3-aes-128-gcm"
        genShadowsocksPassword "16"

    elif [[ "${isShadowsocksMethodInput}" == "7" ]]; then
        shadowsocksMethod="2022-blake3-aes-256-gcm"
        genShadowsocksPassword "32"

    elif [[ "${isShadowsocksMethodInput}" == "8" ]]; then
        shadowsocksMethod="2022-blake3-chacha20-poly1305"
        genShadowsocksPassword "32"       
    else
        shadowsocksMethod="aes-256-gcm"
    fi

    echo
}


configSSRustPath="/root/shadowsocksrust"

configSSXrayPath="/root/shadowsocksxray"
configSSXrayPort="$(($RANDOM + 10000))"
configSSAccessLogFilePath="${HOME}/ss-access.log"
configSSErrorLogFilePath="${HOME}/ss-error.log"



function installShadowsocksRust(){
    if [ -f "${configSSRustPath}/xray"  ]; then
        showHeaderGreen " installed Shadowsocks Rust, exit the installation !" \
        " Shadowsocks Rust already installed, exit !"
        exit 0
    fi

    showHeaderGreen " start installation Shadowsocks Rust " \
    " Prepare to install Shadowsocks Rust "  

    configNetworkVPSIP=$(get_ip)

    echo
    green " ================================================== "
    green " Shadowsocks Rust Version, default is latest 1.15.0-alpha, choose no is 1.14.3 "
    green " please choose Shadowsocks Rust version, the default is to press Enter directly to the latest version 1.15.0-alpha, choose whether to be 1.14.3"
    echo
    read -r -p "Do you want to install the latest version? The default version is the latest version, please enter [Y/n]:" isInstallSSRustVersionInput
    isInstallSSRustVersionInput=${isInstallSSRustVersionInput:-Y}
    echo

    if [[ $isInstallSSRustVersionInput == [Yy] ]]; then
        versionShadowsocksRust="1.15.0-alpha.9"
        #versionShadowsocksRust=$(getGithubLatestReleaseVersion "shadowsocks/shadowsocks-rust")
    else
        versionShadowsocksRust="1.14.3"
    fi
    echo "Version: ${versionShadowsocksRust}"



    echo
    green " Ready to download and install Shadowsocks Rust: ${versionXray} !"
    green " Prepare to download and install Shadowsocks Rust Version: ${versionXray} !"
    echo
    mkdir -p "${configSSRustPath}"
    cd "${configSSRustPath}" || exit
    rm -rf ${configSSRustPath}/*

    # https://github.com/shadowsocks/shadowsocks-rust/releases/download/v1.14.3/shadowsocks-v1.14.3.x86_64-unknown-linux-musl.tar.xz
    # https://github.com/shadowsocks/shadowsocks-rust/releases/download/v1.14.3/shadowsocks-v1.14.3.arm-unknown-linux-musleabi.tar.xz
    
    downloadFilenameShadowsocksRust="shadowsocks-v${versionShadowsocksRust}.x86_64-unknown-linux-musl.tar.xz"
    if [[ ${osArchitecture} == "arm" ]] ; then
        downloadFilenameShadowsocksRust="shadowsocks-v${versionShadowsocksRust}.arm-unknown-linux-musleabi.tar.xz"
    fi
    if [[ ${osArchitecture} == "arm64" ]] ; then
        downloadFilenameShadowsocksRust="shadowsocks-v${versionShadowsocksRust}.arm-unknown-linux-musleabi.tar.xz"
    fi

    downloadAndUnzip "https://github.com/shadowsocks/shadowsocks-rust/releases/download/v${versionShadowsocksRust}/${downloadFilenameShadowsocksRust}" "${configSSRustPath}" "${downloadFilenameShadowsocksRust}"

    selectShadowsocksMethod

    cat > ${configSSRustPath}/shadowsocks.json <<-EOF
{
    "server": "0.0.0.0",
    "server_port": ${configSSXrayPort},
    "password": "${shadowsocksPassword1}",
    "timeout": 300,
    "method": "${shadowsocksMethod}"
}
EOF

    cat > ${osSystemMdPath}shadowsocksrust.service <<-EOF

[Unit]
Description=ssserver service
After=network.target

[Service]
ExecStart=${configSSRustPath}/ssserver -c ${configSSRustPath}/shadowsocks.json
ExecStop=/usr/bin/killall ssserver
Restart=on-failure
RestartSec=30
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

    ${sudoCmd} chmod +x ${configSSRustPath}/ssserver
    ${sudoCmd} chmod +x ${osSystemMdPath}shadowsocksrust.service
    ${sudoCmd} systemctl daemon-reload
    
    ${sudoCmd} systemctl enable shadowsocksrust.service
    ${sudoCmd} systemctl restart shadowsocksrust.service

    (crontab -l ; echo "22 4 * * 0,1,2,3,4,5,6 systemctl restart shadowsocksrust.service") | sort - | uniq - | crontab -

    configShadowsocksLink=$(echo -n "${shadowsocksMethod}:${shadowsocksPassword1}@${configNetworkVPSIP}:${configSSXrayPort}" | base64 -w0)
    configShadowsocksLinkFull="ss://${configShadowsocksLink}"

    cat > ${configSSRustPath}/clientConfig.json <<-EOF

=========== client Shadowsocks Configuration parameters password任选其一 =============

{
    protocol: Shadowsocks,
    address: IP ${configNetworkVPSIP},
    port: ${configSSXrayPort},
    Encryption: ${shadowsocksMethod},
    password1: ${shadowsocksPassword1}
    Aliases: give yourself an arbitrary name
}

Shadowsocks import link:
ss://${shadowsocksMethod}:${configShadowsocksPasswordPrefix}${shadowsocksPassword1}@${configNetworkVPSIP}:${configSSXrayPort}

or

${configShadowsocksLinkFull}

EOF



    showHeaderGreen " Shadowsocks Rust Successful installation !"

	red " ShadowsocksRust Server-side configuration path ${configSSRustPath}/shadowsocks.json !"
    green " ShadowsocksRust View log command: journalctl -n 50 -u shadowsocksrust.service "
	green " ShadowsocksRust stop command: systemctl stop shadowsocksrust.service  start command: systemctl start shadowsocksrust.service "
	green " ShadowsocksRust restart command: systemctl restart shadowsocksrust.service"
	green " ShadowsocksRust View running status command:  systemctl status shadowsocksrust.service "
	green " ShadowsocksRust The server will automatically restart every day to prevent memory leaks. Run crontab -l Command View scheduled restart commands !"

    echo
	cat "${configSSRustPath}/clientConfig.json"
    echo


}


function installShadowsocks(){

    if [ -f "${configSSXrayPath}/xray"  ]; then
        showHeaderGreen " installed Shadowsocks Xray, exit the installation !" \
        " Shadowsocks Xray already installed, exit !"
        exit 0
    fi



    showHeaderGreen " start installation Xray Shadowsocks " \
    " Prepare to install Xray Shadowsocks "  

    configNetworkVPSIP=$(get_ip)

    getV2rayVersion "xray"
    green " Ready to download and install Xray Version: ${versionXray} !"
    green " Prepare to download and install Xray Version: ${versionXray} !"

    echo
    mkdir -p "${configSSXrayPath}"
    cd "${configSSXrayPath}" || exit
    rm -rf ${configSSXrayPath}/*

    downloadV2rayXrayBin "shadowsocks"

    selectShadowsocksMethod

    if [[ "${isShadowsocksMethodInput}" == "6" || "${isShadowsocksMethodInput}" == "7" || "${isShadowsocksMethodInput}" == "8" ]]; then
        read -r -d '' shadowsocksXrayConfigInboundInput << EOM
    "inbounds": [
        {
            "port": ${configSSXrayPort},
            "protocol": "shadowsocks",
            "settings": {
                "method": "${shadowsocksMethod}",
                "password": "${shadowsocksPassword0}",
                "network": "tcp,udp",
                "clients": [
                    { "password": "${shadowsocksPassword1}", "email": "password101@gmail.com" },
                    { "password": "${shadowsocksPassword2}", "email": "password102@gmail.com" },
                    { "password": "${shadowsocksPassword3}", "email": "password103@gmail.com" },
                    { "password": "${shadowsocksPassword4}", "email": "password104@gmail.com" },
                    { "password": "${shadowsocksPassword5}", "email": "password105@gmail.com" }
                ]
            }
        }
    ],
EOM


else

    read -r -d '' shadowsocksXrayConfigInboundInput << EOM
    "inbounds": [
        {
            "port": ${configSSXrayPort},
            "protocol": "shadowsocks",
            "settings": {
                "network": "tcp,udp",
                "clients": [
                    { "password": "${shadowsocksPassword1}", "method": "${shadowsocksMethod}", "email": "password101@gmail.com" },
                    { "password": "${shadowsocksPassword2}", "method": "${shadowsocksMethod}", "email": "password102@gmail.com" },
                    { "password": "${shadowsocksPassword3}", "method": "${shadowsocksMethod}", "email": "password103@gmail.com" },
                    { "password": "${shadowsocksPassword4}", "method": "${shadowsocksMethod}", "email": "password104@gmail.com" },
                    { "password": "${shadowsocksPassword5}", "method": "${shadowsocksMethod}", "email": "password105@gmail.com" }
                ]
            }
        }
    ],
EOM


fi

    echo
    green " An old sister-in-law provides a server that can unblock Netflix in Singapore, and it is not guaranteed to be available all the time"
    echo
    read -r -p "Do you want to unblock Netflix Singapore through Laoyizi? Enter directly without unlocking by default, please enter [y/N]:" isV2rayUnlockGoNetflixInput
    isV2rayUnlockGoNetflixInput=${isV2rayUnlockGoNetflixInput:-n}
    if [[ $isV2rayUnlockGoNetflixInput == [Nn] ]]; then
        shadowsocksXrayConfigRouteInput=""
    else
        read -r -d '' shadowsocksXrayConfigRouteInput << EOM
    "routing": {
        "rules": [
            {
                "type": "field",
                "outboundTag": "GoNetflix",
                "domain": [ "geosite:netflix", "geosite:disney" ] 
            },
            {
                "type": "field",
                "outboundTag": "IPv4_out",
                "network": "udp,tcp"
            }
        ]
    }
EOM
    fi




    cat > ${configSSXrayPath}/config.json <<-EOF
{
    "log" : {
        "access": "${configSSAccessLogFilePath}",
        "error": "${configSSErrorLogFilePath}",
        "loglevel": "warning"
    },
    ${shadowsocksXrayConfigInboundInput}
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        },        
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
        }

    ],
    ${shadowsocksXrayConfigRouteInput}
}
EOF





        cat > ${osSystemMdPath}shadowsocksxray.service <<-EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
Type=simple
# This service runs as root. You may consider to run it as another user for security concerns.
# By uncommenting User=nobody and commenting out User=root, the service will run as user nobody.
# More discussion at https://github.com/v2ray/v2ray-core/issues/1011
User=root
#User=nobody
#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=${configSSXrayPath}/xray run -config ${configSSXrayPath}/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    ${sudoCmd} chmod +x ${configSSXrayPath}/xray
    ${sudoCmd} chmod +x ${osSystemMdPath}shadowsocksxray.service
    ${sudoCmd} systemctl daemon-reload
    
    ${sudoCmd} systemctl enable shadowsocksxray.service
    ${sudoCmd} systemctl restart shadowsocksxray.service



    # 设置 cron 定时任务
    # https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job

    (crontab -l ; echo "10 4 * * 0,1,2,3,4,5,6 rm -f /root/ss-*") | sort - | uniq - | crontab -
    (crontab -l ; echo "20 4 * * 0,1,2,3,4,5,6 systemctl restart shadowsocksxray.service") | sort - | uniq - | crontab -



if [[ "${isShadowsocksMethodInput}" == "6" || "${isShadowsocksMethodInput}" == "7" || "${isShadowsocksMethodInput}" == "8" ]]; then
    configShadowsocksPasswordPrefix="${shadowsocksPassword0}:"
else
    configShadowsocksPasswordPrefix=""
fi

    configShadowsocksLink=$(echo -n "${shadowsocksMethod}:${configShadowsocksPasswordPrefix}${shadowsocksPassword1}@${configNetworkVPSIP}:${configSSXrayPort}" | base64 -w0)
    configShadowsocksLinkFull="ss://${configShadowsocksLink}"

    cat > ${configSSXrayPath}/clientConfig.json <<-EOF

=========== client Shadowsocks Configuration parameters password任选其一 =============

{
    protocol: Shadowsocks,
    address: IP ${configNetworkVPSIP},
    port: ${configSSXrayPort},
    Encryption: ${shadowsocksMethod},
    password1: ${configShadowsocksPasswordPrefix}${shadowsocksPassword1},
    password2: ${configShadowsocksPasswordPrefix}${shadowsocksPassword2},
    password3: ${configShadowsocksPasswordPrefix}${shadowsocksPassword3},
    password4: ${configShadowsocksPasswordPrefix}${shadowsocksPassword4},
    password5: ${configShadowsocksPasswordPrefix}${shadowsocksPassword5},
    Aliases: give yourself an arbitrary name
}

Shadowsocks import link:
ss://${shadowsocksMethod}:${configShadowsocksPasswordPrefix}${shadowsocksPassword1}@${configNetworkVPSIP}:${configSSXrayPort}

or

${configShadowsocksLinkFull}


EOF


    showHeaderGreen " Shadowsocks Xray ${versionXray} Successful installation !"

	red " Shadowsocksxray Server-side configuration path ${configSSXrayPath}/config.json !"
	green " Shadowsocksxray access log ${configSSAccessLogFilePath} !"
	green " Shadowsocksxray error log ${configSSErrorLogFilePath} ! "
	green " Shadowsocksxray View log command: journalctl -n 50 -u shadowsocksxray.service "
	green " Shadowsocksxray stop command: systemctl stop shadowsocksxray.service  start command: systemctl start shadowsocksxray.service "
	green " Shadowsocksxray restart command: systemctl restart shadowsocksxray.service"
	green " Shadowsocksxray View running status command:  systemctl status shadowsocksxray.service "
	green " Shadowsocksxray The server will automatically restart every day to prevent memory leaks. Run the crontab -l command to view the scheduled restart command !"

    echo
	cat "${configSSXrayPath}/clientConfig.json"
    echo

}




function removeShadowsocks(){

    if [[ -f "${configSSXrayPath}/xray" ]]; then
        echo
        green " ================================================== "
        green " Are you sure to remove Shadowsocks Xray ? "
        echo
        read -r -p "Are you sure to uninstall Shadowsocks Xray? Press Enter to uninstall by default, please enter [Y/n]:" isRemoveShadowsocksServerInput
        isRemoveShadowsocksServerInput=${isRemoveShadowsocksServerInput:-Y}

        if [[ "${isRemoveShadowsocksServerInput}" == [Yy] ]]; then

            ${sudoCmd} systemctl stop shadowsocksxray.service
            ${sudoCmd} systemctl disable shadowsocksxray.service

            rm -rf ${configSSXrayPath}
            rm -f ${osSystemMdPath}shadowsocksxray.service
            rm -f ${configSSAccessLogFilePath}
            rm -f ${configSSErrorLogFilePath}

            crontab -l | grep -v "rm" | crontab -
            crontab -l | grep -v "shadowsocksxray" | crontab -

            showHeaderGreen " Shadowsocks Xray Uninstall is complete !" \
            " Shadowsocks Xray uninstalled successfully !"
            
        fi

    else
        showHeaderRed " system not installed Shadowsocks Xray, exit uninstall !" \
        " Shadowsocks Xray not found, exit !"
        exit 0
    fi


  

    if [[ -f "${configSSRustPath}/ssserver" ]]; then
        echo
        green " ================================================== "
        green " Are you sure to remove Shadowsocks Rust ? "
        echo
        read -r -p "Are you sure to uninstall Shadowsocks Rust? Press Enter to uninstall by default, please enter [Y/n]:" isRemoveShadowsocksServerInput
        isRemoveShadowsocksServerInput=${isRemoveShadowsocksServerInput:-Y}

        if [[ "${isRemoveShadowsocksServerInput}" == [Yy] ]]; then

            ${sudoCmd} systemctl stop shadowsocksrust.service
            ${sudoCmd} systemctl disable shadowsocksrust.service

            rm -rf ${configSSRustPath}
            rm -f ${osSystemMdPath}shadowsocksrust.service

            crontab -l | grep -v "shadowsocksrust" | crontab -

            showHeaderGreen " Shadowsocks Rust Uninstall is complete !" \
            " Shadowsocks Rust uninstalled successfully !"
        fi
    else
        showHeaderRed " Shadowsocks Rust is not installed in the system, exit uninstall !" \
        " Shadowsocks Rust not found, exit !"
        exit 0
    fi

}
































function downloadV2rayXrayBin(){
    if [ -z $1 ]; then
        tempDownloadV2rayPath="${configV2rayPath}"
    elif [ $1 = "shadowsocks" ]; then
        isXray="yes"
        tempDownloadV2rayPath="${configSSXrayPath}"

    else
        tempDownloadV2rayPath="${configDownloadTempPath}/upgrade/${promptInfoXrayName}"
    fi

    if [ "$isXray" = "no" ] ; then
        # https://github.com/v2fly/v2ray-core/releases/download/v4.41.1/v2ray-linux-64.zip
        # https://github.com/v2fly/v2ray-core/releases/download/v4.41.1/v2ray-linux-arm32-v6.zip
        # https://github.com/v2fly/v2ray-core/releases/download/v4.44.0/v2ray-linux-arm64-v8a.zip
        
        if [[ ${osArchitecture} == "arm" ]] ; then
            downloadFilenameV2ray="v2ray-linux-arm32-v6.zip"
        fi
        if [[ ${osArchitecture} == "arm64" ]] ; then
            downloadFilenameV2ray="v2ray-linux-arm64-v8a.zip"
        fi

        downloadAndUnzip "https://github.com/v2fly/v2ray-core/releases/download/v${versionV2ray}/${downloadFilenameV2ray}" "${tempDownloadV2rayPath}" "${downloadFilenameV2ray}"

    else
        # https://github.com/XTLS/Xray-core/releases/download/v1.5.0/Xray-linux-64.zip
        # https://github.com/XTLS/Xray-core/releases/download/v1.5.2/Xray-linux-arm32-v6.zip
        if [[ ${osArchitecture} == "arm" ]] ; then
            downloadFilenameXray="Xray-linux-arm32-v6.zip"
        fi
        if [[ ${osArchitecture} == "arm64" ]] ; then
            downloadFilenameXray="Xray-linux-arm64-v8a.zip"
        fi

        downloadAndUnzip "https://github.com/XTLS/Xray-core/releases/download/v${versionXray}/${downloadFilenameXray}" "${tempDownloadV2rayPath}" "${downloadFilenameXray}"
    fi
}



function inputV2rayStreamSettings(){
    echo
    green " =================================================="
    yellow " Please select the StreamSettings transport protocol of V2ray or Xray, the default is 3 Websocket"
    echo
    green " 1. TCP "
    green " 2. KCP "
    green " 3. WebSocket Support CDN"
    green " 4. HTTP/2 (Note that Nginx does not support HTTP/2 forwarding)"
    green " 5. QUIC "
    green " 6. gRPC Support CDN"
    green " 7. WebSocket + gRPC Support CDN"
    echo
    read -p "Please select a transmission protocol? Press Enter to select 3 Websocket by default, please enter pure numbers:" isV2rayStreamSettingInput
    isV2rayStreamSettingInput=${isV2rayStreamSettingInput:-3}

    if [[ $isV2rayStreamSettingInput == 1 ]]; then
        configV2rayStreamSetting="tcp"

    elif [[ $isV2rayStreamSettingInput == 2 ]]; then
        configV2rayStreamSetting="kcp"
        inputV2rayKCPSeedPassword

    elif [[ $isV2rayStreamSettingInput == 4 ]]; then
        configV2rayStreamSetting="h2"
        inputV2rayWSPath "h2"
    elif [[ $isV2rayStreamSettingInput == 5 ]]; then
        configV2rayStreamSetting="quic"
        inputV2rayKCPSeedPassword "quic"

    elif [[ $isV2rayStreamSettingInput == 6 ]]; then
        configV2rayStreamSetting="grpc"

    elif [[ $isV2rayStreamSettingInput == 7 ]]; then
        configV2rayStreamSetting="wsgrpc"

    else
        configV2rayStreamSetting="ws"
        inputV2rayWSPath
    fi


    if [[ "${configInstallNginxMode}" == "v2raySSL" || ${configV2rayWorkingNotChangeMode} == "true" ]]; then

         if [[ "${configV2rayStreamSetting}" == "grpc" ]]; then
            inputV2rayGRPCPath

        elif [[ "${configV2rayStreamSetting}" == "wsgrpc" ]]; then
            inputV2rayWSPath
            inputV2rayGRPCPath
        fi

    else

        if [[ "${configV2rayStreamSetting}" == "grpc" ]]; then
            inputV2rayServerPort "textMainGRPCPort"

            configV2rayGRPCPort=${isV2rayUserPortGRPCInput}   
            configV2rayPortGRPCShowInfo=${isV2rayUserPortGRPCInput}   

            inputV2rayGRPCPath

        elif [[ "${configV2rayStreamSetting}" == "wsgrpc" ]]; then
            inputV2rayWSPath

            inputV2rayServerPort "textMainGRPCPort"

            configV2rayGRPCPort=${isV2rayUserPortGRPCInput}   
            configV2rayPortGRPCShowInfo=${isV2rayUserPortGRPCInput}   

            inputV2rayGRPCPath
        fi

    fi
}

function inputV2rayKCPSeedPassword(){ 
    echo
    configV2rayKCPSeedPassword=$(cat /dev/urandom | head -1 | md5sum | head -c 4)

    configV2rayKCPQuicText="KCP's Seed Obfuscated Password"
    if [[ $1 == "quic" ]]; then
        configV2rayKCPQuicText="QUIC of key key"
    fi 

    read -p "Whether to customize ${promptInfoXrayName} of ${configV2rayKCPQuicText}? Press Enter to create a random password by default, please enter a custom password:" isV2rayUserKCPSeedInput
    isV2rayUserKCPSeedInput=${isV2rayUserKCPSeedInput:-${configV2rayKCPSeedPassword}}

    if [[ -z $isV2rayUserKCPSeedInput ]]; then
        echo
    else
        configV2rayKCPSeedPassword=${isV2rayUserKCPSeedInput}
    fi
}


function inputV2rayWSPath(){ 
    echo
    configV2rayWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)

    configV2rayWSH2Text="WS"
    if [[ $1 == "h2" ]]; then
        configV2rayWSH2Text="HTTP2"
    fi 

    read -r -p "Whether to customize ${promptInfoXrayName} of ${configV2rayWSH2Text}of Path? Enter directly to create a random path by default, please enter a custom path (do not enter /):" isV2rayUserWSPathInput
    isV2rayUserWSPathInput=${isV2rayUserWSPathInput:-${configV2rayWebSocketPath}}

    if [[ -z $isV2rayUserWSPathInput ]]; then
        echo
    else
        configV2rayWebSocketPath=${isV2rayUserWSPathInput}
    fi
}

function inputV2rayGRPCPath(){ 
    echo
    configV2rayGRPCServiceName=$(cat /dev/urandom | head -1 | md5sum | head -c 8)

    read -p "Whether to customize ${promptInfoXrayName} of gRPC of serviceName ? Enter directly to create a random path by default, please enter a custom path (do not enter /):" isV2rayUserGRPCPathInput
    isV2rayUserGRPCPathInput=${isV2rayUserGRPCPathInput:-${configV2rayGRPCServiceName}}

    if [[ -z $isV2rayUserGRPCPathInput ]]; then
        echo
    else
        configV2rayGRPCServiceName=${isV2rayUserGRPCPathInput}
    fi
}


function inputV2rayServerPort(){  
    echo
	if [[ $1 == "textMainPort" ]]; then
        green " Whether to customize ${promptInfoXrayName} port number? To support cloudflare's CDN, you need to use the HTTPS port number supported by cloudflare. For example 443 8443 2053 2083 2087 2096 port"
        green " For details, please refer to the official cloudflare documentation https://developers.cloudflare.com/fundamentals/get-started/network-ports"
        read -p "Whether to customize ${promptInfoXrayName} The port number? Enter directly and the default is ${configV2rayPortShowInfo}, Please enter a custom port number [1-65535]:" isV2rayUserPortInput
        isV2rayUserPortInput=${isV2rayUserPortInput:-${configV2rayPortShowInfo}}
		checkPortInUse "${isV2rayUserPortInput}" $1 
	fi

	if [[ $1 == "textMainGRPCPort" ]]; then
        green " If you use gRPC protocol and want to support cloudflare's CDN, you need to enter port 443"
        read -p "Whether to customize ${promptInfoXrayName} The port number of gRPC? Enter directly and the default is ${configV2rayPortGRPCShowInfo}, Please enter a custom port number [1-65535]:" isV2rayUserPortGRPCInput
        isV2rayUserPortGRPCInput=${isV2rayUserPortGRPCInput:-${configV2rayPortGRPCShowInfo}}
		checkPortInUse "${isV2rayUserPortGRPCInput}" $1 
	fi    

	if [[ $1 == "textAdditionalPort" ]]; then
        green " Whether to add an additional listening port, the same as the main port ${configV2rayPort} work together at the same time"
        green " Generally used when the transfer machine cannot use port 443, it is used when using an extra port to transfer to the target host"
        read -p "Whether to give ${promptInfoXrayName} Add an additional listening port? Enter the default No, please enter the additional port number [1-65535]:" isV2rayAdditionalPortInput
        isV2rayAdditionalPortInput=${isV2rayAdditionalPortInput:-999999}
        checkPortInUse "${isV2rayAdditionalPortInput}" $1 
	fi


    if [[ $1 == "textMainTrojanPort" ]]; then
        green "Whether to customize Trojan${promptInfoTrojanName} The port number? Enter directly and the default is ${configV2rayTrojanPort}"
        read -p "Whether to customize Trojan ${promptInfoTrojanName} The port number? Enter directly and the default is ${configV2rayTrojanPort}, Please enter a custom port number [1-65535]:" isTrojanUserPortInput
        isTrojanUserPortInput=${isTrojanUserPortInput:-${configV2rayTrojanPort}}
		checkPortInUse "${isTrojanUserPortInput}" $1 
	fi    
}

function checkPortInUse(){ 
    if [ $1 = "999999" ]; then
        echo
    elif [[ $1 -gt 1 && $1 -le 65535 ]]; then
        isPortUsed=$(netstat -tulpn | grep -e ":$1") ;
        if [ -z "${isPortUsed}" ]; then 
            green "The input port number $1 is not occupied, continue the installation..."  
            
        else
            processInUsedName=$(echo "${isPortUsed}" | awk '{print $7}' | awk -F"/" '{print $2}')
            red "input port number $1 Has been ${processInUsedName} Occupied! Please exit the installation, check if the port is occupied or re-enter!"  
            inputV2rayServerPort $2
        fi
    else
        red "Wrong port number entered! Must be [1-65535]. Please re-enter" 
        inputV2rayServerPort $2 
    fi
}


v2rayVmessLinkQR1=""
v2rayVmessLinkQR2=""
v2rayVlessLinkQR1=""
v2rayVlessLinkQR2=""
v2rayPassword1UrlEncoded=""

function rawUrlEncode() {
    # https://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command


    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo
    green "== URL Encoded: ${encoded}"    # You can either set a return variable (FASTER) 
    v2rayPassword1UrlEncoded="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

function generateVmessImportLink(){
    # https://github.com/2dust/v2rayN/wiki/%E5%88%86%E4%BA%AB%E9%93%BE%E6%8E%A5%E6%A0%BC%E5%BC%8F%E8%AF%B4%E6%98%8E(ver-2)

    configV2rayVmessLinkConfigTls="tls"
    if [[ "${configV2rayIsTlsShowInfo}" == "none" ]]; then
        configV2rayVmessLinkConfigTls=""
    fi

    configV2rayVmessLinkStreamSetting1="${configV2rayStreamSetting}"
    configV2rayVmessLinkStreamSetting2=""
    if [[ "${configV2rayStreamSetting}" == "wsgrpc" ]]; then
        configV2rayVmessLinkStreamSetting1="ws"
        configV2rayVmessLinkStreamSetting2="grpc"
    fi

    configV2rayProtocolDisplayName="${configV2rayProtocol}"
    configV2rayProtocolDisplayHeaderType="none"
    configV2rayVmessLinkConfigPath=""
    configV2rayVmessLinkConfigPath2=""

    if [[ "${configV2rayWorkingMode}" == "vlessTCPVmessWS" ]]; then
        configV2rayVmessLinkStreamSetting1="ws"
        configV2rayVmessLinkStreamSetting2="tcp"

        configV2rayVmessLinkConfigPath="${configV2rayWebSocketPath}"
        configV2rayVmessLinkConfigPath2="/tcp${configV2rayWebSocketPath}" 

        configV2rayVmessLinkConfigTls="tls" 

        configV2rayProtocolDisplayName="vmess"

        configV2rayProtocolDisplayHeaderType="http"
    fi



    configV2rayVmessLinkConfigHost="${configSSLDomain}"
    if [[ "${configV2rayStreamSetting}" == "quic" ]]; then
        configV2rayVmessLinkConfigHost="none"
    fi


    if [[ "${configV2rayStreamSetting}" == "kcp" || "${configV2rayStreamSetting}" == "quic" ]]; then
        configV2rayVmessLinkConfigPath="${configV2rayKCPSeedPassword}"

    elif [[ "${configV2rayStreamSetting}" == "h2" || "${configV2rayStreamSetting}" == "ws" ]]; then
        configV2rayVmessLinkConfigPath="${configV2rayWebSocketPath}"

    elif [[ "${configV2rayStreamSetting}" == "grpc" ]]; then
        configV2rayVmessLinkConfigPath="${configV2rayGRPCServiceName}"

    elif [[ "${configV2rayStreamSetting}" == "wsgrpc" ]]; then
        configV2rayVmessLinkConfigPath="${configV2rayWebSocketPath}"
        configV2rayVmessLinkConfigPath2="${configV2rayGRPCServiceName}"
    fi

    cat > ${configV2rayVmessImportLinkFile1Path} <<-EOF
{
    "v": "2",
    "ps": "${configSSLDomain}_${configV2rayProtocolDisplayName}_${configV2rayVmessLinkStreamSetting1}",
    "add": "${configSSLDomain}",
    "port": "${configV2rayPortShowInfo}",
    "id": "${v2rayPassword1}",
    "aid": "0",
    "net": "${configV2rayVmessLinkStreamSetting1}",
    "type": "none",
    "host": "${configV2rayVmessLinkConfigHost}",
    "path": "${configV2rayVmessLinkConfigPath}",
    "tls": "${configV2rayVmessLinkConfigTls}",
    "sni": "${configSSLDomain}"
}

EOF

    cat > ${configV2rayVmessImportLinkFile2Path} <<-EOF
{
    "v": "2",
    "ps": "${configSSLDomain}_${configV2rayProtocolDisplayName}_${configV2rayVmessLinkStreamSetting2}",
    "add": "${configSSLDomain}",
    "port": "${configV2rayPortShowInfo}",
    "id": "${v2rayPassword1}",
    "aid": "0",
    "net": "${configV2rayVmessLinkStreamSetting2}",
    "type": "${configV2rayProtocolDisplayHeaderType}",
    "host": "${configV2rayVmessLinkConfigHost}",
    "path": "${configV2rayVmessLinkConfigPath2}",
    "tls": "${configV2rayVmessLinkConfigTls}",
    "sni": "${configSSLDomain}"
}

EOF

    v2rayVmessLinkQR1="vmess://$(cat ${configV2rayVmessImportLinkFile1Path} | base64 -w 0)"
    v2rayVmessLinkQR2="vmess://$(cat ${configV2rayVmessImportLinkFile2Path} | base64 -w 0)"
}

function generateVLessImportLink(){
    # https://github.com/XTLS/Xray-core/discussions/716


    generateVmessImportLink
    rawUrlEncode "${v2rayPassword1}"

    if [[ "${configV2rayStreamSetting}" == "" ]]; then

        configV2rayVlessXtlsFlow="tls"
        configV2rayVlessXtlsFlowShowInfo="null"
        if [[ "${configV2rayIsTlsShowInfo}" == "xtls" ]]; then
            configV2rayVlessXtlsFlow="xtls&flow=xtls-rprx-direct"
            configV2rayVlessXtlsFlowShowInfo="xtls-rprx-direct"
        fi

        if [[ "$configV2rayWorkingMode" == "vlessgRPC" ]]; then
            cat > ${configV2rayVlessImportLinkFile1Path} <<-EOF
${configV2rayProtocol}://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPortShowInfo}?encryption=none&security=${configV2rayVlessXtlsFlow}&type=grpc&host=${configSSLDomain}&serviceName=%2f${configV2rayGRPCServiceName}#${configSSLDomain}+gRPC_${configV2rayIsTlsShowInfo}
EOF
        else
            cat > ${configV2rayVlessImportLinkFile1Path} <<-EOF
${configV2rayProtocol}://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPortShowInfo}?encryption=none&security=${configV2rayVlessXtlsFlow}&type=tcp&host=${configSSLDomain}#${configSSLDomain}+TCP_${configV2rayIsTlsShowInfo}
EOF

            cat > ${configV2rayVlessImportLinkFile2Path} <<-EOF
${configV2rayProtocol}://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPortShowInfo}?encryption=none&security=tls&type=ws&host=${configSSLDomain}&path=%2f${configV2rayWebSocketPath}#${configSSLDomain}+WebSocket_${configV2rayIsTlsShowInfo}
EOF
        fi

        v2rayVlessLinkQR1="$(cat ${configV2rayVlessImportLinkFile1Path})"
        v2rayVlessLinkQR2="$(cat ${configV2rayVlessImportLinkFile2Path})"
    else

	    if [[ "${configV2rayProtocol}" == "vless" ]]; then

            cat > ${configV2rayVlessImportLinkFile1Path} <<-EOF
${configV2rayProtocol}://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPortShowInfo}?encryption=none&security=${configV2rayIsTlsShowInfo}&type=${configV2rayVmessLinkStreamSetting1}&host=${configSSLDomain}&path=%2f${configV2rayVmessLinkConfigPath}&headerType=none&seed=${configV2rayKCPSeedPassword}&quicSecurity=none&key=${configV2rayKCPSeedPassword}&serviceName=${configV2rayVmessLinkConfigPath}#${configSSLDomain}+${configV2rayVmessLinkStreamSetting1}_${configV2rayIsTlsShowInfo}
EOF
            cat > ${configV2rayVlessImportLinkFile2Path} <<-EOF
${configV2rayProtocol}://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPortShowInfo}?encryption=none&security=${configV2rayIsTlsShowInfo}&type=${configV2rayVmessLinkStreamSetting2}&host=${configSSLDomain}&path=%2f${configV2rayVmessLinkConfigPath2}&headerType=none&seed=${configV2rayKCPSeedPassword}&quicSecurity=none&key=${configV2rayKCPSeedPassword}&serviceName=${configV2rayVmessLinkConfigPath2}#${configSSLDomain}+${configV2rayVmessLinkStreamSetting2}_${configV2rayIsTlsShowInfo}
EOF

            v2rayVlessLinkQR1="$(cat ${configV2rayVlessImportLinkFile1Path})"
            v2rayVlessLinkQR2="$(cat ${configV2rayVlessImportLinkFile2Path})"
	    fi

    fi
}




function inputUnlockV2rayServerInfo(){
            echo
            yellow " Please select the protocol of the V2ray or Xray server that can unblock streaming "
            green " 1. VLess + TCP + TLS"
            green " 2. VLess + TCP + XTLS"
            green " 3. VLess + WS + TLS (Support CDN)"
            green " 4. VMess + TCP + TLS"
            green " 5. VMess + WS + TLS (Support CDN)"
            echo
            read -p "Please select a protocol? Press Enter to select 3 by default, please enter pure numbers:" isV2rayUnlockServerProtocolInput
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
                yellow " Please fill in the V2ray or Xray server Websocket Path that can unlock streaming media, the default is /"
                read -p "Please fill in Websocket Path? Enter directly and the default is / , please enter (do not include /):" isV2rayUnlockServerWSPathInput
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
                yellow " Please select V2ray or Xray server Flow in XTLS mode to unblock streaming "
                green " 1. VLess + TCP + XTLS (xtls-rprx-direct) recommend"
                green " 2. VLess + TCP + XTLS (xtls-rprx-splice) This item may fail to connect"
                read -p "Please select the Flow parameter? Press Enter to select 1 by default, please enter pure numbers:" isV2rayUnlockServerFlowInput
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
            yellow " Please fill in the V2ray or Xray server address that can unlock streaming media, for example www.example.com"
            read -p "Please fill in the address of the unlockable streaming media server? Enter directly and the default is this machine, please enter:" isV2rayUnlockServerDomainInput
            isV2rayUnlockServerDomainInput=${isV2rayUnlockServerDomainInput:-127.0.0.1}

            echo
            yellow " Please fill in the V2ray or Xray server port number that can unlock streaming media, for example 443"
            read -p "Please fill in the address of the unlockable streaming media server? Enter directly and the default is 443, please enter:" isV2rayUnlockServerPortInput
            isV2rayUnlockServerPortInput=${isV2rayUnlockServerPortInput:-443}

            echo
            yellow " Please fill in the user UUID of the V2ray or Xray server that can unlock streaming media, for example 4aeaf80d-f89e-46a2-b3dc-bb815eae75ba"
            read -p "Please fill in the user UUID? Enter directly and the default is 111, please enter:" isV2rayUnlockServerUserIDInput
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




function installV2ray(){

    v2rayPassword1=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword2=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword3=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword4=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword5=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword6=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword7=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword8=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword9=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword10=$(cat /proc/sys/kernel/random/uuid)

    echo
    if [ -f "${configV2rayPath}/xray" ] || [ -f "${configV2rayPath}/v2ray" ] || [ -f "/usr/local/bin/v2ray" ] || [ -f "/usr/bin/v2ray" ]; then
        green " =================================================="
        green "     V2ray or Xray has been installed, exit the installation !"
        green " =================================================="
        exit
    fi

    green " =================================================="
    green "    start installation V2ray or Xray "
    green " =================================================="    
    echo

    if [[ ( $configV2rayWorkingMode == "trojan" ) || ( $configV2rayWorkingMode == "vlessTCPVmessWS" ) || ( $configV2rayWorkingMode == "vlessTCPWS" ) || ( $configV2rayWorkingMode == "vlessTCPWSgRPC" ) || ( $configV2rayWorkingMode == "vlessTCPWSTrojan" ) || ( $configV2rayWorkingMode == "sni" ) ]]; then
        echo
        green " Whether to use XTLS instead of TLS encryption, XTLS is a Xray-specific encryption method, which is faster and uses TLS encryption by default"
        green " Since V2ray does not support XTLS, if XTLS encryption is selected it will be served using the Xray kernel"
        read -p "Whether to use XTLS? Enter directly and the default is TLS encryption, please enter [y/N]:" isXrayXTLSInput
        isXrayXTLSInput=${isXrayXTLSInput:-n}
        
        if [[ $isXrayXTLSInput == [Yy] ]]; then
            promptInfoXrayName="xray"
            isXray="yes"
            configV2rayIsTlsShowInfo="xtls"
        else
            echo
            read -p "Do you want to use Xray kernel? Press Enter to default to V2ray kernel, please enter [y/N]:" isV2rayOrXrayCoreInput
            isV2rayOrXrayCoreInput=${isV2rayOrXrayCoreInput:-n}

            if [[ $isV2rayOrXrayCoreInput == [Yy] ]]; then
                promptInfoXrayName="xray"
                isXray="yes"
            fi        
        fi
    else
        read -r -p "Do you want to use Xray kernel? Press Enter to default to V2ray kernel, please enter [y/N]:" isV2rayOrXrayCoreInput
        isV2rayOrXrayCoreInput=${isV2rayOrXrayCoreInput:-n}

        if [[ $isV2rayOrXrayCoreInput == [Yy] ]]; then
            promptInfoXrayName="xray"
            isXray="yes"
        fi
    fi


    if [[ -n "${configV2rayWorkingMode}" ]]; then
    
        if [[ "${configV2rayWorkingMode}" != "sni" ]]; then
            configV2rayProtocol="vless"

            configV2rayPort=443
            configV2rayPortShowInfo=$configV2rayPort

            inputV2rayServerPort "textMainPort"
            configV2rayPort=${isV2rayUserPortInput}   
            configV2rayPortShowInfo=${isV2rayUserPortInput} 

        else
            configV2rayProtocol="vless"

            configV2rayPortShowInfo=443
            configV2rayPortGRPCShowInfo=443
        fi

    else
        echo
        read -p "Are you using the VLESS protocol? Press Enter and the default is the VMess protocol, please enter [y/N]:" isV2rayUseVLessInput
        isV2rayUseVLessInput=${isV2rayUseVLessInput:-n}

        if [[ $isV2rayUseVLessInput == [Yy] ]]; then
            configV2rayProtocol="vless"
        else
            configV2rayProtocol="vmess"
        fi

        
        if [[ ${configInstallNginxMode} == "v2raySSL" ]]; then
            configV2rayPortShowInfo=443
            configV2rayPortGRPCShowInfo=443

        else
            if [[ ${configV2rayWorkingNotChangeMode} == "true" ]]; then
                configV2rayPortShowInfo=443
                configV2rayPortGRPCShowInfo=443

            else
                configV2rayIsTlsShowInfo="none"

                configV2rayPort="$(($RANDOM + 10000))"
                configV2rayPortShowInfo=$configV2rayPort

                inputV2rayServerPort "textMainPort"
                configV2rayPort=${isV2rayUserPortInput}   
                configV2rayPortShowInfo=${isV2rayUserPortInput}  

                inputV2rayStreamSettings
            fi


        fi
    fi

    if [[ "$configV2rayWorkingMode" == "sni" ]] ; then
        configSSLCertPath="${configNginxSNIDomainV2rayCertPath}"
        configSSLDomain=${configNginxSNIDomainV2ray}
    fi

    
    # 增加任意门
    if [[ ${configInstallNginxMode} == "v2raySSL" ]]; then
        echo
    else
        
        inputV2rayServerPort "textAdditionalPort"

        if [[ $isV2rayAdditionalPortInput == "999999" ]]; then
            v2rayConfigAdditionalPortInput=""
        else
            read -r -d '' v2rayConfigAdditionalPortInput << EOM
        ,
        {
            "listen": "0.0.0.0",
            "port": ${isV2rayAdditionalPortInput}, 
            "protocol": "dokodemo-door",
            "settings": {
                "address": "127.0.0.1",
                "port": ${configV2rayPort},
                "network": "tcp, udp",
                "followRedirect": false 
            },
            "sniffing": {
                "enabled": true,
                "destOverride": ["http", "tls"]
            }
        }     
EOM

        fi
    fi



    echo
    read -p "Whether to customize ${promptInfoXrayName} password? Press Enter to create a random password by default, please enter a custom UUID password :" isV2rayUserPassordInput
    isV2rayUserPassordInput=${isV2rayUserPassordInput:-''}

    if [ -z "${isV2rayUserPassordInput}" ]; then
        isV2rayUserPassordInput=""
    else
        v2rayPassword1=${isV2rayUserPassordInput}
    fi














    echo
    echo
    isV2rayUnlockWarpModeInput="1"
    V2rayDNSUnlockText="AsIs"
    V2rayUnlockVideoSiteOutboundTagText=""
    unlockWARPServerIpInput="127.0.0.1"
    unlockWARPServerPortInput="40000"
    configWARPPortFilePath="${HOME}/wireguard/warp-port"
    configWARPPortLocalServerPort="40000"
    configWARPPortLocalServerText=""

    if [[ -f "${configWARPPortFilePath}" ]]; then
        configWARPPortLocalServerPort="$(cat ${configWARPPortFilePath})"
        configWARPPortLocalServerText="Detected that the machine has installed WARP Sock5, port number ${configWARPPortLocalServerPort}"
    fi

    green " =================================================="
    yellow " Whether to unblock streaming sites like Netflix HBO Disney+"
    read -p " Do you want to unlock the streaming media website? Enter directly without unlocking by default, please enter [y/N]:" isV2rayUnlockStreamWebsiteInput
    isV2rayUnlockStreamWebsiteInput=${isV2rayUnlockStreamWebsiteInput:-n}

    if [[ $isV2rayUnlockStreamWebsiteInput == [Yy] ]]; then



    echo
    green " =================================================="
    yellow " Whether to use DNS to unblock streaming sites like Netflix HBO Disney+"
    green " For unblocking, please fill in the IP address of the DNS server that unblocks Netflix, for example 8.8.8.8"
    read -p "Do you want to use DNS to unlock streaming media? Press Enter to unlock by default, please enter the IP address of the DNS server to unlock:" isV2rayUnlockDNSInput
    isV2rayUnlockDNSInput=${isV2rayUnlockDNSInput:-n}

    V2rayDNSUnlockText="AsIs"
    v2rayConfigDNSInput=""

    if [[ "${isV2rayUnlockDNSInput}" == [Nn] ]]; then
        V2rayDNSUnlockText="AsIs"
    else
        V2rayDNSUnlockText="UseIP"
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
    echo
    green " 1. without unlocking"
    green " 2. Unblock with WARP Sock5 Proxy Recommended"
    green " 3. Unlock with WARP IPv6"
    green " 4. Unlock by forwarding to an unlockable v2ray or xray server"
    echo
    green " By default, 1 is not unlocked. If you choose 2 and 3 to unlock, you need to install Wireguard and Cloudflare WARP, you can re-run this script and choose the first installation".
    red " It is recommended to install Wireguard and Cloudflare WARP first, and then install v2ray or xray. In fact, it is no problem to install v2ray or xray first, and then install Wireguard and Cloudflare WARP"
    red " But if you install v2ray or xray first, and choose to unlock google or other streaming media, you will be temporarily unable to access google and other video sites, you need to continue to install Wireguard and Cloudflare WARP to solve the problem"
    echo
    read -p "Please input? Enter directly and select 1 by default to not unlock, please input pure numbers:" isV2rayUnlockWarpModeInput
    isV2rayUnlockWarpModeInput=${isV2rayUnlockWarpModeInput:-1}
    
    V2rayUnlockVideoSiteRuleText=""
    V2rayUnlockGoogleRuleText=""
    
    v2rayConfigRouteInput=""
    V2rayUnlockVideoSiteOutboundTagText=""



    if [[ $isV2rayUnlockWarpModeInput == "1" ]]; then
        echo
    else
        if [[ $isV2rayUnlockWarpModeInput == "2" ]]; then
            V2rayUnlockVideoSiteOutboundTagText="WARP_out"

            echo
            read -p "Please enter the WARP Sock5 proxy server address? Enter the default local machine 127.0.0.1, please enter:" unlockWARPServerIpInput
            unlockWARPServerIpInput=${unlockWARPServerIpInput:-127.0.0.1}

            echo
            yellow " ${configWARPPortLocalServerText}"
            read -p "Please enter the port number of the WARP Sock5 proxy server? Press Enter to default ${configWARPPortLocalServerPort}, Please enter pure numbers:" unlockWARPServerPortInput
            unlockWARPServerPortInput=${unlockWARPServerPortInput:-$configWARPPortLocalServerPort}

        elif [[ $isV2rayUnlockWarpModeInput == "3" ]]; then

            V2rayUnlockVideoSiteOutboundTagText="IPv6_out"

        elif [[ $isV2rayUnlockWarpModeInput == "4" ]]; then

            echo
            green " Selected 4 Unlock by forwarding to an unlockable v2ray or xray server"
            green " You can modify the v2ray or xray configuration by yourself, and add an unlockable v2ray server with the tag V2Ray_out in the outbounds field"

            V2rayUnlockVideoSiteOutboundTagText="V2Ray_out"

            inputUnlockV2rayServerInfo
        fi



        echo
        echo
        green " =================================================="
        yellow " Please select a streaming site to unblock:"
        echo
        green " 1. not unlocked"
        green " 2. Unblock Netflix restrictions"
        green " 3. Unblock Youtube and Youtube Premium"
        green " 4. Unlock Pornhub, solve the problem that the video becomes corn and cannot be watched"
        green " 5. Unblock Netflix and Pornhub at the same time"
        green " 6. Unblock Netflix, Youtube and Pornhub simultaneously"
        green " 7. Unblock Netflix, Hulu, HBO, Disney and Pornhub simultaneously"
        green " 8. Unblock Netflix, Hulu, HBO, Disney, Youtube and Pornhub simultaneously"
        green " 9. Unblocks all streaming media including Netflix, Youtube, Hulu, HBO, Disney, BBC, Fox, niconico, dmm, Spotify, Pornhub and more"
        echo
        read -p "Please enter the unlock option? Press Enter and select 1 by default to not unlock, please enter pure numbers:" isV2rayUnlockVideoSiteInput
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
    yellow " An old sister-in-law provides a server that can unblock Netflix in Singapore, and it is not guaranteed to be available all the time"
    read -p "Do you want to unblock Netflix Singapore through Laoyizi? Enter directly without unlocking by default, please enter [y/N]:" isV2rayUnlockGoNetflixInput
    isV2rayUnlockGoNetflixInput=${isV2rayUnlockGoNetflixInput:-n}

    v2rayConfigRouteGoNetflixInput=""
    v2rayConfigOutboundV2rayGoNetflixServerInput=""
    if [[ $isV2rayUnlockGoNetflixInput == [Nn] ]]; then
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



    fi




    echo
    green " =================================================="
    yellow " Please select a way to avoid pop-up of Google reCAPTCHA captcha"
    echo
    green " 1. not unlocked"
    green " 2. Unlock with WARP Sock5 Proxy"
    green " 3. Unblock with WARP IPv6 Recommended"
    green " 4. Unlock by forwarding to an unlockable v2ray or xray server"
    echo
    read -r -p "Please enter the unlock option? Press Enter and select 1 by default to not unlock, please enter pure numbers:" isV2rayUnlockGoogleInput
    isV2rayUnlockGoogleInput=${isV2rayUnlockGoogleInput:-1}

    if [[ "${isV2rayUnlockWarpModeInput}" == "${isV2rayUnlockGoogleInput}" ]]; then
        V2rayUnlockVideoSiteRuleText+=", \"geosite:google\" "
        V2rayUnlockVideoSiteRuleTextFirstChar="${V2rayUnlockVideoSiteRuleText:0:1}"

        if [[ $V2rayUnlockVideoSiteRuleTextFirstChar == "," ]]; then
            V2rayUnlockVideoSiteRuleText="${V2rayUnlockVideoSiteRuleText:1}"
        fi

        # Fix a bug that is not unlocked, choose 1 bug
        if [[ -z "${V2rayUnlockVideoSiteOutboundTagText}" ]]; then
            V2rayUnlockVideoSiteOutboundTagText="IPv6_out"
            V2rayUnlockVideoSiteRuleText="\"test.com\""
        fi

        read -r -d '' v2rayConfigRouteInput << EOM
    "routing": {
        "rules": [
            ${v2rayConfigRouteGoNetflixInput}
            {
                "type": "field",
                "outboundTag": "${V2rayUnlockVideoSiteOutboundTagText}",
                "domain": [${V2rayUnlockVideoSiteRuleText}] 
            },
            {
                "type": "field",
                "outboundTag": "IPv4_out",
                "network": "udp,tcp"
            }
        ]
    },
EOM

    else
        V2rayUnlockGoogleRuleText="\"geosite:google\""

        if [[ $isV2rayUnlockGoogleInput == "2" ]]; then
            V2rayUnlockGoogleOutboundTagText="WARP_out"
            echo
            read -p "Please enter the WARP Sock5 proxy server address? Enter the default local machine 127.0.0.1, please enter:" unlockWARPServerIpInput
            unlockWARPServerIpInput=${unlockWARPServerIpInput:-127.0.0.1}

            echo
            yellow " ${configWARPPortLocalServerText}"
            read -r -p "Please enter the port number of the WARP Sock5 proxy server? Press Enter to default${configWARPPortLocalServerPort}, Please enter pure numbers:" unlockWARPServerPortInput
            unlockWARPServerPortInput=${unlockWARPServerPortInput:-$configWARPPortLocalServerPort}       

        elif [[ $isV2rayUnlockGoogleInput == "3" ]]; then
            V2rayUnlockGoogleOutboundTagText="IPv6_out"

        elif [[ $isV2rayUnlockGoogleInput == "4" ]]; then
            V2rayUnlockGoogleOutboundTagText="V2Ray_out"
            inputUnlockV2rayServerInfo
        else
            V2rayUnlockGoogleOutboundTagText="IPv4_out"
        fi

        # Fix a bug that is not unlocked, choose 1 bug
        if [[ -z "${V2rayUnlockVideoSiteOutboundTagText}" ]]; then
            V2rayUnlockVideoSiteOutboundTagText="IPv6_out"
            V2rayUnlockVideoSiteRuleText="\"xxxxx.com\""
        fi
        
        read -r -d '' v2rayConfigRouteInput << EOM
    "routing": {
        "rules": [
            ${v2rayConfigRouteGoNetflixInput}
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
            {
                "type": "field",
                "outboundTag": "IPv4_out",
                "network": "udp,tcp"
            }
        ]
    },
EOM
    fi


    read -r -d '' v2rayConfigOutboundInput << EOM
    "outbounds": [
        {
            "tag":"IPv4_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "${V2rayDNSUnlockText}"
            }
        },        
        {
            "tag": "blocked",
            "protocol": "blackhole",
            "settings": {}
        },
        {
            "tag":"IPv6_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv6" 
            }
        },
        ${v2rayConfigOutboundV2rayServerInput}
        ${v2rayConfigOutboundV2rayGoNetflixServerInput}
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
    ]

EOM












    echo
    green " =================================================="
    if [ "$isXray" = "no" ] ; then
        getV2rayVersion "v2ray"
        green "    Ready to download and install V2ray Version: ${versionV2ray} !"
        promptInfoXrayInstall="V2ray"
        promptInfoXrayVersion=${versionV2ray}
    else
        getV2rayVersion "xray"
        green "   Ready to download and install Xray Version: ${versionXray} !"
        promptInfoXrayInstall="Xray"
        promptInfoXrayVersion=${versionXray}
    fi
    echo


    mkdir -p "${configV2rayPath}"
    cd "${configV2rayPath}" || exit
    rm -rf ${configV2rayPath}/*

    downloadV2rayXrayBin


    # 增加 v2ray server端配置

    if [[ "$configV2rayWorkingMode" == "vlessTCPWSTrojan" ]]; then
        trojanPassword1=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
        trojanPassword2=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
        trojanPassword3=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
        trojanPassword4=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
        trojanPassword5=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
        trojanPassword6=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
        trojanPassword7=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
        trojanPassword8=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
        trojanPassword9=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
        trojanPassword10=$(cat /dev/urandom | head -1 | md5sum | head -c 10)

        echo
        yellow " Please enter the prefix of the trojan password? (several random passwords and passwords with this prefix will be generated)"
        read -p " Please enter the prefix of the password, and press Enter to generate the prefix randomly by default:" configTrojanPasswordPrefixInput
        configTrojanPasswordPrefixInput=${configTrojanPasswordPrefixInput:-${configTrojanPasswordPrefixInputDefault}}
    fi

    if [ "${isTrojanMultiPassword}" = "no" ] ; then
    read -r -d '' v2rayConfigUserpasswordTrojanInput << EOM
                    { "password": "${trojanPassword1}", "level": 0, "email": "password111@gmail.com" },
                    { "password": "${trojanPassword2}", "level": 0, "email": "password112@gmail.com" },
                    { "password": "${trojanPassword3}", "level": 0, "email": "password113@gmail.com" },
                    { "password": "${trojanPassword4}", "level": 0, "email": "password114@gmail.com" },
                    { "password": "${trojanPassword5}", "level": 0, "email": "password115@gmail.com" },
                    { "password": "${trojanPassword6}", "level": 0, "email": "password116@gmail.com" },
                    { "password": "${trojanPassword7}", "level": 0, "email": "password117@gmail.com" },
                    { "password": "${trojanPassword8}", "level": 0, "email": "password118@gmail.com" },
                    { "password": "${trojanPassword9}", "level": 0, "email": "password119@gmail.com" },
                    { "password": "${trojanPassword10}", "level": 0, "email": "password120@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202201", "level": 0, "email": "password201@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202202", "level": 0, "email": "password202@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202203", "level": 0, "email": "password203@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202204", "level": 0, "email": "password204@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202205", "level": 0, "email": "password205@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202206", "level": 0, "email": "password206@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202207", "level": 0, "email": "password207@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202208", "level": 0, "email": "password208@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202209", "level": 0, "email": "password209@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202210", "level": 0, "email": "password210@gmail.com" }

EOM
    else

    read -r -d '' v2rayConfigUserpasswordTrojanInput << EOM
                    { "password": "${trojanPassword1}", "level": 0, "email": "password111@gmail.com" },
                    { "password": "${trojanPassword2}", "level": 0, "email": "password112@gmail.com" },
                    { "password": "${trojanPassword3}", "level": 0, "email": "password113@gmail.com" },
                    { "password": "${trojanPassword4}", "level": 0, "email": "password114@gmail.com" },
                    { "password": "${trojanPassword5}", "level": 0, "email": "password115@gmail.com" },
                    { "password": "${trojanPassword6}", "level": 0, "email": "password116@gmail.com" },
                    { "password": "${trojanPassword7}", "level": 0, "email": "password117@gmail.com" },
                    { "password": "${trojanPassword8}", "level": 0, "email": "password118@gmail.com" },
                    { "password": "${trojanPassword9}", "level": 0, "email": "password119@gmail.com" },
                    { "password": "${trojanPassword10}", "level": 0, "email": "password120@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202200", "level": 0, "email": "password200@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202201", "level": 0, "email": "password201@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202202", "level": 0, "email": "password202@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202203", "level": 0, "email": "password203@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202204", "level": 0, "email": "password204@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202205", "level": 0, "email": "password205@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202206", "level": 0, "email": "password206@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202207", "level": 0, "email": "password207@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202208", "level": 0, "email": "password208@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202209", "level": 0, "email": "password209@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202210", "level": 0, "email": "password210@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202211", "level": 0, "email": "password211@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202212", "level": 0, "email": "password212@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202213", "level": 0, "email": "password213@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202214", "level": 0, "email": "password214@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202215", "level": 0, "email": "password215@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202216", "level": 0, "email": "password216@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202217", "level": 0, "email": "password217@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202218", "level": 0, "email": "password218@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202219", "level": 0, "email": "password219@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202220", "level": 0, "email": "password220@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202221", "level": 0, "email": "password221@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202222", "level": 0, "email": "password222@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202223", "level": 0, "email": "password223@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202224", "level": 0, "email": "password224@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202225", "level": 0, "email": "password225@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202226", "level": 0, "email": "password226@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202227", "level": 0, "email": "password227@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202228", "level": 0, "email": "password228@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202229", "level": 0, "email": "password229@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202230", "level": 0, "email": "password230@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202231", "level": 0, "email": "password231@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202232", "level": 0, "email": "password232@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202233", "level": 0, "email": "password233@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202234", "level": 0, "email": "password234@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202235", "level": 0, "email": "password235@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202236", "level": 0, "email": "password236@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202237", "level": 0, "email": "password237@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202238", "level": 0, "email": "password238@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202239", "level": 0, "email": "password239@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202240", "level": 0, "email": "password240@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202241", "level": 0, "email": "password241@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202242", "level": 0, "email": "password242@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202243", "level": 0, "email": "password243@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202244", "level": 0, "email": "password244@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202245", "level": 0, "email": "password245@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202246", "level": 0, "email": "password246@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202247", "level": 0, "email": "password247@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202248", "level": 0, "email": "password248@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202249", "level": 0, "email": "password249@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202250", "level": 0, "email": "password250@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202251", "level": 0, "email": "password251@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202252", "level": 0, "email": "password252@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202253", "level": 0, "email": "password253@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202254", "level": 0, "email": "password254@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202255", "level": 0, "email": "password255@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202256", "level": 0, "email": "password256@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202257", "level": 0, "email": "password257@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202258", "level": 0, "email": "password258@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202259", "level": 0, "email": "password259@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202260", "level": 0, "email": "password260@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202261", "level": 0, "email": "password261@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202262", "level": 0, "email": "password262@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202263", "level": 0, "email": "password263@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202264", "level": 0, "email": "password264@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202265", "level": 0, "email": "password265@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202266", "level": 0, "email": "password266@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202267", "level": 0, "email": "password267@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202268", "level": 0, "email": "password268@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202269", "level": 0, "email": "password269@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202270", "level": 0, "email": "password270@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202271", "level": 0, "email": "password271@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202272", "level": 0, "email": "password272@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202273", "level": 0, "email": "password273@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202274", "level": 0, "email": "password274@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202275", "level": 0, "email": "password275@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202276", "level": 0, "email": "password276@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202277", "level": 0, "email": "password277@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202278", "level": 0, "email": "password278@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202279", "level": 0, "email": "password279@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202280", "level": 0, "email": "password280@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202281", "level": 0, "email": "password281@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202282", "level": 0, "email": "password282@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202283", "level": 0, "email": "password283@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202284", "level": 0, "email": "password284@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202285", "level": 0, "email": "password285@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202286", "level": 0, "email": "password286@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202287", "level": 0, "email": "password287@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202288", "level": 0, "email": "password288@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202289", "level": 0, "email": "password289@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202290", "level": 0, "email": "password290@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202291", "level": 0, "email": "password291@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202292", "level": 0, "email": "password292@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202293", "level": 0, "email": "password293@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202294", "level": 0, "email": "password294@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202295", "level": 0, "email": "password295@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202296", "level": 0, "email": "password296@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202297", "level": 0, "email": "password297@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202298", "level": 0, "email": "password298@gmail.com" },
                    { "password": "${configTrojanPasswordPrefixInput}202299", "level": 0, "email": "password299@gmail.com" }

EOM
    fi

    if [[ "${configV2rayIsTlsShowInfo}" == "xtls"  ]]; then
    read -r -d '' v2rayConfigUserpasswordInput << EOM
                    { "id": "${v2rayPassword1}", "flow": "xtls-rprx-direct", "level": 0, "email": "password11@gmail.com" },
                    { "id": "${v2rayPassword2}", "flow": "xtls-rprx-direct", "level": 0, "email": "password12@gmail.com" },
                    { "id": "${v2rayPassword3}", "flow": "xtls-rprx-direct", "level": 0, "email": "password13@gmail.com" },
                    { "id": "${v2rayPassword4}", "flow": "xtls-rprx-direct", "level": 0, "email": "password14@gmail.com" },
                    { "id": "${v2rayPassword5}", "flow": "xtls-rprx-direct", "level": 0, "email": "password15@gmail.com" },
                    { "id": "${v2rayPassword6}", "flow": "xtls-rprx-direct", "level": 0, "email": "password16@gmail.com" },
                    { "id": "${v2rayPassword7}", "flow": "xtls-rprx-direct", "level": 0, "email": "password17@gmail.com" },
                    { "id": "${v2rayPassword8}", "flow": "xtls-rprx-direct", "level": 0, "email": "password18@gmail.com" },
                    { "id": "${v2rayPassword9}", "flow": "xtls-rprx-direct", "level": 0, "email": "password19@gmail.com" },
                    { "id": "${v2rayPassword10}", "flow": "xtls-rprx-direct", "level": 0, "email": "password20@gmail.com" }

EOM

    else
    read -r -d '' v2rayConfigUserpasswordInput << EOM
                    { "id": "${v2rayPassword1}", "level": 0, "email": "password11@gmail.com" },
                    { "id": "${v2rayPassword2}", "level": 0, "email": "password12@gmail.com" },
                    { "id": "${v2rayPassword3}", "level": 0, "email": "password13@gmail.com" },
                    { "id": "${v2rayPassword4}", "level": 0, "email": "password14@gmail.com" },
                    { "id": "${v2rayPassword5}", "level": 0, "email": "password15@gmail.com" },
                    { "id": "${v2rayPassword6}", "level": 0, "email": "password16@gmail.com" },
                    { "id": "${v2rayPassword7}", "level": 0, "email": "password17@gmail.com" },
                    { "id": "${v2rayPassword8}", "level": 0, "email": "password18@gmail.com" },
                    { "id": "${v2rayPassword9}", "level": 0, "email": "password19@gmail.com" },
                    { "id": "${v2rayPassword10}", "level": 0, "email": "password20@gmail.com" }

EOM

    fi










    v2rayConfigInboundInput=""

    if [[ "${configV2rayStreamSetting}" == "grpc" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM

    "inbounds": [
        {
            "port": ${configV2rayGRPCPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "grpc",
                "security": "none",
                "grpcSettings": {
                    "serviceName": "${configV2rayGRPCServiceName}" 
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],

EOM

    elif [[ "${configV2rayStreamSetting}" == "ws" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM

    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "/${configV2rayWebSocketPath}"
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],

EOM


    elif [[ "${configV2rayStreamSetting}" == "wsgrpc" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM

    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "/${configV2rayWebSocketPath}"
                }
            }
        },
        {
            "port": ${configV2rayGRPCPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "grpc",
                "security": "none",
                "grpcSettings": {
                    "serviceName": "${configV2rayGRPCServiceName}" 
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],

EOM

    elif [[ "${configV2rayStreamSetting}" == "tcp" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM

    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none",
                "tcpSettings": {
                    "acceptProxyProtocol": false,
                    "header": {
                        "type": "none"
                    }
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],

EOM


    elif [[ "${configV2rayStreamSetting}" == "kcp" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM

    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "kcp",
                "security": "none",
                "kcpSettings": {
                    "seed": "${configV2rayKCPSeedPassword}"
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],

EOM

    elif [[ "${configV2rayStreamSetting}" == "h2" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM

    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "h2",
                "security": "none",
                "httpSettings": {
                    "path": "/${configV2rayWebSocketPath}"
                }            
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],

EOM

    elif [[ "${configV2rayStreamSetting}" == "quic" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM

    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "quic",
                "security": "none",
                "quicSettings": {
                    "security": "aes-128-gcm",
                    "key": "${configV2rayKCPSeedPassword}",
                    "header": {
                        "type": "none"
                    }
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],

EOM

    fi









    if [[ "$configV2rayWorkingMode" == "vlessTCPVmessWS" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM
    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 80
                    },
                    {
                        "path": "/${configV2rayWebSocketPath}",
                        "dest": ${configV2rayVmesWSPort},
                        "xver": 1
                    },
                    {
                        "path": "/tcp${configV2rayWebSocketPath}",
                        "dest": ${configV2rayVmessTCPPort},
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "${configV2rayIsTlsShowInfo}",
                "${configV2rayIsTlsShowInfo}Settings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/$configSSLCertFullchainFilename",
                            "keyFile": "${configSSLCertPath}/$configSSLCertKeyFilename"
                        }
                    ]
                }
            }
        },
        {
            "port": ${configV2rayVmesWSPort},
            "listen": "127.0.0.1",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": true,
                    "path": "/${configV2rayWebSocketPath}" 
                }
            }
        },
        {
            "port": ${configV2rayVmessTCPPort},
            "listen": "127.0.0.1",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none",
                "tcpSettings": {
                    "acceptProxyProtocol": true,
                    "header": {
                        "type": "http",
                        "request": {
                            "path": [
                                "/tcp${configV2rayWebSocketPath}"
                            ]
                        }
                    }
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],
EOM


    elif [[ "$configV2rayWorkingMode" == "vlessgRPC" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM
    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 80
                    }
                ]
            },
            "streamSettings": {
                "network": "grpc",
                "security": "tls",
                "tlsSettings": {
                    "alpn": [
                        "h2", 
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/$configSSLCertFullchainFilename",
                            "keyFile": "${configSSLCertPath}/$configSSLCertKeyFilename"
                        }
                    ]
                },
                "grpcSettings": {
                    "serviceName": "${configV2rayGRPCServiceName}"
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],
EOM


    elif [[ $configV2rayWorkingMode == "vlessTCPWS" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM
    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 80
                    },
                    {
                        "path": "/${configV2rayWebSocketPath}",
                        "dest": ${configV2rayVmesWSPort},
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "${configV2rayIsTlsShowInfo}",
                "${configV2rayIsTlsShowInfo}Settings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/$configSSLCertFullchainFilename",
                            "keyFile": "${configSSLCertPath}/$configSSLCertKeyFilename"
                        }
                    ]
                }
            }
        },
        {
            "port": ${configV2rayVmesWSPort},
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": true,
                    "path": "/${configV2rayWebSocketPath}" 
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],
EOM


    elif [[ "$configV2rayWorkingMode" == "vlessTCPWSgRPC" || "$configV2rayWorkingMode" == "sni" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM
    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 80
                    },
                    {
                        "path": "/${configV2rayWebSocketPath}",
                        "dest": ${configV2rayVmesWSPort},
                        "xver": 1
                    },
                    {
                        "path": "/${configV2rayGRPCServiceName}",
                        "dest": ${configV2rayGRPCPort},
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "${configV2rayIsTlsShowInfo}",
                "${configV2rayIsTlsShowInfo}Settings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/$configSSLCertFullchainFilename",
                            "keyFile": "${configSSLCertPath}/$configSSLCertKeyFilename"
                        }
                    ]
                }
            }
        },
        {
            "port": ${configV2rayVmesWSPort},
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": true,
                    "path": "/${configV2rayWebSocketPath}" 
                }
            }
        },
        {
            "port": ${configV2rayGRPCPort},
            "protocol": "vless",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "grpc",
                "security": "none",
                "grpcSettings": {
                    "serviceName": "${configV2rayGRPCServiceName}"
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],
EOM


    elif [[  $configV2rayWorkingMode == "vlessTCPWSTrojan" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM
    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": ${configV2rayTrojanPort},
                        "xver": 1
                    },
                    {
                        "path": "/${configV2rayWebSocketPath}",
                        "dest": ${configV2rayVmesWSPort},
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "${configV2rayIsTlsShowInfo}",
                "${configV2rayIsTlsShowInfo}Settings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/$configSSLCertFullchainFilename",
                            "keyFile": "${configSSLCertPath}/$configSSLCertKeyFilename"
                        }
                    ]
                }
            }
        },
        {
            "port": ${configV2rayTrojanPort},
            "listen": "127.0.0.1",
            "protocol": "trojan",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordTrojanInput}
                ],
                "fallbacks": [
                    {
                        "dest": 80 
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none",
                "tcpSettings": {
                    "acceptProxyProtocol": true
                }
            }
        },
        {
            "port": ${configV2rayVmesWSPort},
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": true,
                    "path": "/${configV2rayWebSocketPath}" 
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],
EOM



    elif [[ $configV2rayWorkingMode == "trojan" ]]; then
read -r -d '' v2rayConfigInboundInput << EOM
    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 80
                    },
                    {
                        "path": "/${configTrojanGoWebSocketPath}",
                        "dest": ${configV2rayTrojanPort},
                        "xver": 1
                    },
                    {
                        "path": "/${configV2rayWebSocketPath}",
                        "dest": ${configV2rayVmesWSPort},
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "${configV2rayIsTlsShowInfo}",
                "${configV2rayIsTlsShowInfo}Settings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/$configSSLCertFullchainFilename",
                            "keyFile": "${configSSLCertPath}/$configSSLCertKeyFilename"
                        }
                    ]
                }
            }
        },
        {
            "port": ${configV2rayVmesWSPort},
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": true,
                    "path": "/${configV2rayWebSocketPath}" 
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],
EOM

    fi



    cat > ${configV2rayPath}/config.json <<-EOF
{
    "log" : {
        "access": "${configV2rayAccessLogFilePath}",
        "error": "${configV2rayErrorLogFilePath}",
        "loglevel": "warning"
    },
    ${v2rayConfigDNSInput}
    ${v2rayConfigInboundInput}
    ${v2rayConfigRouteInput}
    ${v2rayConfigOutboundInput}
}
EOF










    systemmdServiceFixV2ray5="run"
    if [[ $versionV2ray == "4.45.2" ]]; then
        systemmdServiceFixV2ray5=""
    fi



    # Added V2ray startup script
    if [ "$isXray" = "no" ] ; then
    
        cat > ${osSystemMdPath}${promptInfoXrayName}${promptInfoXrayNameServiceName}.service <<-EOF
[Unit]
Description=V2Ray
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
Type=simple
# This service runs as root. You may consider to run it as another user for security concerns.
# By uncommenting User=nobody and commenting out User=root, the service will run as user nobody.
# More discussion at https://github.com/v2ray/v2ray-core/issues/1011
User=root
#User=nobody
#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=${configV2rayPath}/v2ray ${systemmdServiceFixV2ray5} -config ${configV2rayPath}/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
    else
        cat > ${osSystemMdPath}${promptInfoXrayName}${promptInfoXrayNameServiceName}.service <<-EOF
[Unit]
Description=Xray
Documentation=https://xtls.github.io/
After=network.target nss-lookup.target

[Service]
Type=simple
# This service runs as root. You may consider to run it as another user for security concerns.
# By uncommenting User=nobody and commenting out User=root, the service will run as user nobody.
# More discussion at https://github.com/v2ray/v2ray-core/issues/1011
User=root
#User=nobody
#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=${configV2rayPath}/xray run -config ${configV2rayPath}/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
    fi

    ${sudoCmd} chmod +x ${configV2rayPath}/${promptInfoXrayName}
    ${sudoCmd} chmod +x ${osSystemMdPath}${promptInfoXrayName}${promptInfoXrayNameServiceName}.service
    ${sudoCmd} systemctl daemon-reload
    
    ${sudoCmd} systemctl enable ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service
    ${sudoCmd} systemctl restart ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service








    generateVLessImportLink

    if [[ "${configV2rayStreamSetting}" == "tcp" ]]; then
        cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall} Client configuration parameters =============
{
    protocol: ${configV2rayProtocol},
    address: ${configSSLDomain},
    port: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    extra id/AlterID: 0,  // AlterID, Vmess Please fill in 0, if it is Vless protocol, this item is not required
    Encryption: aes-128-gcm,  // None if Vless protocol
    Transfer Protocol: tcp,
    underlying transport protocol: ${configV2rayIsTlsShowInfo},
    Aliases: give yourself an arbitrary name
}

import link Vmess Base64 Format:
${v2rayVmessLinkQR1}

Import link Vless format:
${v2rayVlessLinkQR1}

EOF

    elif [[ "${configV2rayStreamSetting}" == "kcp" ]]; then
        cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall} Client configuration parameters =============
{
    protocol: ${configV2rayProtocol},
    address: ${configSSLDomain},
    port: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    extra id/AlterID: 0,  // AlterID, Vmess Please fill in 0, if it is Vless protocol, this item is not required
    Encryption: aes-128-gcm,  // None if Vless protocol
    Transfer Protocol: kcp,
    underlying transport protocol: ${configV2rayIsTlsShowInfo},
    seed obfuscated password: "${configV2rayKCPSeedPassword}",
    Aliases: give yourself an arbitrary name
}

Import link Vmess Base64 format:
${v2rayVmessLinkQR1}

Import link Vless format:
${v2rayVlessLinkQR1}


EOF

    elif [[ "${configV2rayStreamSetting}" == "h2" ]]; then
        cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall} Client configuration parameters =============
{
    protocol: ${configV2rayProtocol},
    address: ${configSSLDomain},
    port: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    additional id/AlterID: 0,  // AlterID, Vmess please fill in 0, This item is not required if it is Vlessprotocol
    Encryption: aes-128-gcm,  // None if Vless protocol
    transport protocol: h2,
    low-level transport protocol: ${configV2rayIsTlsShowInfo},
    path path:/${configV2rayWebSocketPath},
    Aliases: give yourself an arbitrary name
}

import link Vmess Base64 Format:
${v2rayVmessLinkQR1}

import link Vless Format:
${v2rayVlessLinkQR1}

EOF

    elif [[ "${configV2rayStreamSetting}" == "quic" ]]; then
        cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall} Client configuration parameters =============
{
    protocol: ${configV2rayProtocol},
    address: ${configSSLDomain},
    port: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    additional id/AlterID: 0,  // AlterID, Vmess please fill in 0, This item is not required if it is Vlessprotocol
    Encryption: aes-128-gcm,  // None if Vless protocol
    transport protocol: quic,
    low-level transport protocol: ${configV2rayIsTlsShowInfo},
    Quic security: none,
    key 加密时所用的密钥: "${configV2rayKCPSeedPassword}",
    Aliases: give yourself an arbitrary name
}

import link Vmess Base64 Format:
${v2rayVmessLinkQR1}

import link Vless Format:
${v2rayVlessLinkQR1}

EOF


    elif [[ "${configV2rayStreamSetting}" == "grpc" ]]; then
        cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall} Client configuration parameters =============
{
    protocol: ${configV2rayProtocol},
    address: ${configSSLDomain},
    port: ${configV2rayPortGRPCShowInfo},
    uuid: ${v2rayPassword1},
    additional id/AlterID: 0,  // AlterID, Vmess please fill in 0, This item is not required if it is Vlessprotocol
    Encryption: aes-128-gcm,  // None if Vless protocol
    transport protocol: gRPC,
    gRPC serviceName: ${configV2rayGRPCServiceName},    // serviceName not allowed/
    low-level transport protocol: ${configV2rayIsTlsShowInfo},
    Aliases: give yourself an arbitrary name
}

import link Vmess Base64 Format:
${v2rayVmessLinkQR1}

import link Vless Format:
${v2rayVlessLinkQR1}

EOF

    elif [[ "${configV2rayStreamSetting}" == "wsgrpc" ]]; then
        cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall}  Client configuration parameters =============
{
    protocol: ${configV2rayProtocol},
    address: ${configSSLDomain},
    port: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    additional id/AlterID: 0,  // AlterID, Vmess please fill in 0, This item is not required if it is Vlessprotocol
    Encryption: aes-128-gcm,  // None if Vless protocol
    transport protocol: websocket,
    websocket path:/${configV2rayWebSocketPath},
    low-level transport protocol: ${configV2rayIsTlsShowInfo},
    Aliases: give yourself an arbitrary name
}

import link Vmess Base64 Format:
${v2rayVmessLinkQR1}

import link Vless Format:
${v2rayVlessLinkQR1}


=========== ${promptInfoXrayInstall} gRPC  Client configuration parameters =============
{
    protocol: ${configV2rayProtocol},
    address: ${configSSLDomain},
    port: ${configV2rayPortGRPCShowInfo},
    uuid: ${v2rayPassword1},
    additional id/AlterID: 0,  // AlterID, Vmess please fill in 0, This item is not required if it is Vlessprotocol
    Encryption: aes-128-gcm,  // None if Vless protocol
    transport protocol: gRPC,
    gRPC serviceName: ${configV2rayGRPCServiceName},    // serviceName not allowed/
    low-level transport protocol: ${configV2rayIsTlsShowInfo},
    Aliases: give yourself an arbitrary name
}

import link Vmess Base64 Format:
${v2rayVmessLinkQR2}

import link Vless Format:
${v2rayVlessLinkQR2}

EOF

    elif [[ "${configV2rayStreamSetting}" == "ws" ]]; then
        cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall} Client configuration parameters =============
{
    protocol: ${configV2rayProtocol},
    address: ${configSSLDomain},
    port: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    additional id/AlterID: 0,  // AlterID, Vmess please fill in 0, This item is not required if it is Vlessprotocol
    Encryption: aes-128-gcm,  // None if Vless protocol
    transport protocol: websocket,
    websocket path:/${configV2rayWebSocketPath},
    low-level transport protocol: ${configV2rayIsTlsShowInfo},
    Aliases: give yourself an arbitrary name
}

import link Vmess Base64 Format:
${v2rayVmessLinkQR1}

import link Vless Format:
${v2rayVlessLinkQR1}

EOF

    fi





    if [[ "$configV2rayWorkingMode" == "vlessTCPVmessWS" ]]; then

        cat > ${configV2rayPath}/clientConfig.json <<-EOF

VLess runs on${configV2rayPortShowInfo}port (VLess-TCP-TLS) + (VMess-TCP-TLS) + (VMess-WS-TLS)  Support CDN

=========== ${promptInfoXrayInstall} client VLess-TCP-TLS Configuration parameters =============
{
    protocol: VLess,
    address: ${configSSLDomain},
    port: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    additional id: 0,  // AlterID This item is not required if it is Vlessprotocol
    Flow Control: ${configV2rayVlessXtlsFlowShowInfo},
    Encryption: none,  // None if Vless protocol
    transport protocol: tcp ,
    websocket path:none,
    low-level transport protocol: ${configV2rayIsTlsShowInfo},
    Aliases: give yourself an arbitrary name
}

import link Vless Format:
${v2rayVlessLinkQR1}


=========== ${promptInfoXrayInstall} client VMess-WS-TLS Configuration parameters Support CDN =============
{
    protocol: VMess,
    address: ${configSSLDomain},
    port: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    additional id: 0,  // AlterID This item is not required if it is Vlessprotocol
    Encryption: auto,  // None if Vless protocol
    transport protocol: websocket,
    websocket path:/${configV2rayWebSocketPath},
    low-level transport protocol:tls,
    Aliases: give yourself an arbitrary name
}

import link Vmess Base64 Format:
${v2rayVmessLinkQR1}



=========== ${promptInfoXrayInstall} client VMess-TCP-TLS Configuration parameters Support CDN =============
{
    protocol: VMess,
    address: ${configSSLDomain},
    port: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    additional id: 0,  // AlterID This item is not required if it is Vlessprotocol
    Encryption: auto,  // None if Vless protocol
    transport protocol: tcp,
    camouflage type: http,
    path:/tcp${configV2rayWebSocketPath},
    low-level transport protocol:tls,
    Aliases: give yourself an arbitrary name
}

import link Vmess Base64 Format:
${v2rayVmessLinkQR2}


EOF

    elif [[ "$configV2rayWorkingMode" == "vlessgRPC" ]]; then

    cat > ${configV2rayPath}/clientConfig.json <<-EOF
 VLess runs on${configV2rayPortShowInfo}port (VLess-gRPC-TLS) Support CDN

=========== ${promptInfoXrayInstall} client VLess-gRPC-TLS Configuration parameters Support CDN =============
{
    protocol: VLess,
    address: ${configSSLDomain},
    port: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    additional id: 0,  // AlterID This item is not required if it is Vlessprotocol
    Flow Control: ${configV2rayVlessXtlsFlowShowInfo},
    Encryption: none,  
    transport protocol: gRPC,
    gRPC serviceName: ${configV2rayGRPCServiceName},
    low-level transport protocol: ${configV2rayIsTlsShowInfo},
    Aliases: give yourself an arbitrary name
}

import link Vless Format:
${v2rayVlessLinkQR1}

EOF

    elif [[ "$configV2rayWorkingMode" == "vlessTCPWS" ]]; then

    cat > ${configV2rayPath}/clientConfig.json <<-EOF
VLess runs on${configV2rayPortShowInfo}port (VLess-TCP-TLS) + (VLess-WS-TLS) Support CDN

=========== ${promptInfoXrayInstall} client VLess-TCP-TLS Configuration parameters =============
{
    protocol: VLess,
    address: ${configSSLDomain},
    port: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    additional id: 0,  // AlterID This item is not required if it is Vlessprotocol
    Flow Control: ${configV2rayVlessXtlsFlowShowInfo},
    Encryption: none, 
    transport protocol: tcp ,
    websocket path:none,
    low-level transport protocol: ${configV2rayIsTlsShowInfo},
    Aliases: give yourself an arbitrary name
}

import link Vless Format:
${v2rayVlessLinkQR1}


=========== ${promptInfoXrayInstall} client VLess-WS-TLS Configuration parameters Support CDN =============
{
    protocol: VLess,
    address: ${configSSLDomain},
    port: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    additional id: 0,  // AlterID This item is not required if it is Vlessprotocol
    Flow Control: ${configV2rayVlessXtlsFlowShowInfo},
    Encryption: none,  
    transport protocol: websocket,
    websocket path:/${configV2rayWebSocketPath},
    low-level transport protocol:tls,     
    Aliases: give yourself an arbitrary name
}

import link Vless Format:
vless://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPortShowInfo}?encryption=none&security=tls&type=ws&host=${configSSLDomain}&path=%2f${configV2rayWebSocketPath}#${configSSLDomain}+WebSocket_tls

EOF

    elif [[ "$configV2rayWorkingMode" == "vlessTCPWSgRPC" || "$configV2rayWorkingMode" == "sni" ]]; then

    cat > ${configV2rayPath}/clientConfig.json <<-EOF
VLess runs on${configV2rayPortShowInfo}port (VLess-TCP-TLS) + (VLess-WS-TLS) + (VLess-gRPC-TLS)Support CDN

=========== ${promptInfoXrayInstall} client VLess-TCP-TLS Configuration parameters =============
{
    protocol: VLess,
    address: ${configSSLDomain},
    port: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    additional id: 0,  // AlterID This item is not required if it is Vlessprotocol
    Flow Control: null
    Encryption: none, 
    transport protocol: tcp ,
    websocket path:none,
    low-level transport protocol: ${configV2rayIsTlsShowInfo},
    Aliases: give yourself an arbitrary name
}

import link Vless Format:
${v2rayVlessLinkQR1}


=========== ${promptInfoXrayInstall} client VLess-WS-TLS Configuration parameters Support CDN =============
{
    protocol: VLess,
    address: ${configSSLDomain},
    port: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    additional id: 0,  // AlterID This item is not required if it is Vlessprotocol
    Flow Control: ${configV2rayVlessXtlsFlowShowInfo},
    Encryption: none,  
    transport protocol: websocket,
    websocket path:/${configV2rayWebSocketPath},
    low-level transport protocol:tls,     
    Aliases: give yourself an arbitrary name
}

import link Vless Format:
vless://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPortShowInfo}?encryption=none&security=tls&type=ws&host=${configSSLDomain}&path=%2f${configV2rayWebSocketPath}#${configSSLDomain}+WebSocket_tls


=========== ${promptInfoXrayInstall} client VLess-gRPC-TLS Configuration parameters Support CDN =============
{
    protocol: VLess,
    address: ${configSSLDomain},
    port: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    additional id: 0,  // AlterID This item is not required if it is Vlessprotocol
    Flow Control:  null,
    Encryption: none,  
    transport protocol: gRPC,
    gRPC serviceName: ${configV2rayGRPCServiceName},
    low-level transport protocol:tls,     
    Aliases: give yourself an arbitrary name
}

import link Vless Format:
vless://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPortShowInfo}?encryption=none&security=tls&type=grpc&serviceName=${configV2rayGRPCServiceName}&host=${configSSLDomain}#${configSSLDomain}+gRPC_tls

EOF

    elif [[ "$configV2rayWorkingMode" == "vlessTCPWSTrojan" ]]; then
    cat > ${configV2rayPath}/clientConfig.json <<-EOF
VLess runs on${configV2rayPortShowInfo}port (VLess-TCP-TLS) + (VLess-WS-TLS) + (Trojan)Support CDN

=========== ${promptInfoXrayInstall} client VLess-TCP-TLS Configuration parameters =============
{
    protocol: VLess,
    address: ${configSSLDomain},
    port: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    additional id: 0,  // AlterID This item is not required if it is Vlessprotocol
    Flow Control: xtls-rprx-direct
    Encryption: none,  
    transport protocol: tcp ,
    websocket path:none,
    low-level transport protocol: ${configV2rayIsTlsShowInfo},
    Aliases: give yourself an arbitrary name
}

import link Vless Format:
${v2rayVlessLinkQR1}


=========== ${promptInfoXrayInstall} client VLess-WS-TLS Configuration parameters Support CDN =============
{
    protocol: VLess,
    address: ${configSSLDomain},
    port: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    additional id: 0,  // AlterID This item is not required if it is Vlessprotocol
    Flow Control: ${configV2rayVlessXtlsFlowShowInfo}, 
    Encryption: none,  
    transport protocol: websocket,
    websocket path:/${configV2rayWebSocketPath},
    low-level transport protocol:tls,     
    Aliases: give yourself an arbitrary name
}

import link:
vless://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPort}?encryption=none&security=tls&type=ws&host=${configSSLDomain}&path=%2f${configV2rayWebSocketPath}#${configSSLDomain}+WebSocket_tls


=========== Trojan${promptInfoTrojanName}server address: ${configSSLDomain}  port: $configV2rayPort

password1: ${trojanPassword1}
password2: ${trojanPassword2}
password3: ${trojanPassword3}
password4: ${trojanPassword4}
password5: ${trojanPassword5}
password6: ${trojanPassword6}
password7: ${trojanPassword7}
password8: ${trojanPassword8}
password9: ${trojanPassword9}
password10: ${trojanPassword10}
you specify the prefix A total of 10 passwords: from ${configTrojanPasswordPrefixInput}202201 arrive ${configTrojanPasswordPrefixInput}202210 can be used
E.g: password:${configTrojanPasswordPrefixInput}202202 or password:${configTrojanPasswordPrefixInput}202209 can be used

small rocket link:
trojan://${trojanPassword1}@${configSSLDomain}:${configV2rayPort}?peer=${configSSLDomain}&sni=${configSSLDomain}#${configSSLDomain}_trojan

QR code Trojan${promptInfoTrojanName}
https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=trojan%3a%2f%2f${trojanPassword1}%40${configSSLDomain}%3a${configV2rayPort}%3fpeer%3d${configSSLDomain}%26sni%3d${configSSLDomain}%23${configSSLDomain}_trojan

EOF

    elif [[ "$configV2rayWorkingMode" == "trojan" ]]; then
    cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall} client VLess-TCP-TLS Configuration parameters =============
{
    protocol: VLess,
    address: ${configSSLDomain},
    port: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    additional id: 0,  // AlterID This item is not required if it is Vlessprotocol
    Flow Control: xtls-rprx-direct
    Encryption: none,  
    transport protocol: tcp ,
    websocket path:none,
    low-level transport protocol: ${configV2rayIsTlsShowInfo},
    Aliases: give yourself an arbitrary name
}

import link Vless Format:
${v2rayVlessLinkQR1}


=========== ${promptInfoXrayInstall} client VLess-WS-TLS Configuration parameters Support CDN =============
{
    protocol: VLess,
    address: ${configSSLDomain},
    port: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    additional id: 0,  // AlterID This item is not required if it is Vlessprotocol
    Flow Control: ${configV2rayVlessXtlsFlowShowInfo}, 
    Encryption: none,  
    transport protocol: websocket,
    websocket path:/${configV2rayWebSocketPath},
    low-level transport protocol:tls,     
    Aliases: give yourself an arbitrary name
}

import link:
vless://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPort}?encryption=none&security=tls&type=ws&host=${configSSLDomain}&path=%2f${configV2rayWebSocketPath}#${configSSLDomain}+WebSocket_tls


=========== Trojan${promptInfoTrojanName}server address: ${configSSLDomain}  port: $configV2rayTrojanPort

password1: ${trojanPassword1}
password2: ${trojanPassword2}
password3: ${trojanPassword3}
password4: ${trojanPassword4}
password5: ${trojanPassword5}
password6: ${trojanPassword6}
password7: ${trojanPassword7}
password8: ${trojanPassword8}
password9: ${trojanPassword9}
password10: ${trojanPassword10}
you specify the prefix A total of 10 passwords: from ${configTrojanPasswordPrefixInput}202201 arrive ${configTrojanPasswordPrefixInput}202210 can be used
E.g: password:${configTrojanPasswordPrefixInput}202202 or password:${configTrojanPasswordPrefixInput}202209 can be used

small rocket link:
trojan://${trojanPassword1}@${configSSLDomain}:${configV2rayTrojanPort}?peer=${configSSLDomain}&sni=${configSSLDomain}#${configSSLDomain}_trojan

QR code Trojan${promptInfoTrojanName}
https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=trojan%3a%2f%2f${trojanPassword1}%40${configSSLDomain}%3a${configV2rayTrojanPort}%3fpeer%3d${configSSLDomain}%26sni%3d${configSSLDomain}%23${configSSLDomain}_trojan

EOF
    fi



    # Set up cron scheduled tasks
    # https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job

    (crontab -l ; echo "10 4 * * 0,1,2,3,4,5,6 rm -f /root/v2ray-*") | sort - | uniq - | crontab -
    (crontab -l ; echo "20 4 * * 0,1,2,3,4,5,6 systemctl restart ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service") | sort - | uniq - | crontab -


    green "======================================================================"
    green "    ${promptInfoXrayInstall} Version: ${promptInfoXrayVersion} Successful installation !"

    if [[ -n ${configInstallNginxMode} ]]; then
        green "    Masquerade site as https://${configSSLDomain}!"
	    green "    The static html content of the fake site is placed in the directory ${configWebsitePath}, You can change the content of the website by yourself!"
    fi
	
	red "    ${promptInfoXrayInstall} server-side configuration path ${configV2rayPath}/config.json !"
	green "    ${promptInfoXrayInstall} access log ${configV2rayAccessLogFilePath} !"
	green "    ${promptInfoXrayInstall} error log ${configV2rayErrorLogFilePath} ! "
	green "    ${promptInfoXrayInstall} View log command: journalctl -n 50 -u ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service "
	green "    ${promptInfoXrayInstall} stop command: systemctl stop ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service  start command: systemctl start ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service "
	green "    ${promptInfoXrayInstall} restart command: systemctl restart ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service"
	green "    ${promptInfoXrayInstall} View running status command:  systemctl status ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service "
	green "    ${promptInfoXrayInstall} The server will automatically restart every day to prevent memory leaks. Run crontab -l Command View timing restart command !"
	green "======================================================================"
	echo ""
	yellow "${promptInfoXrayInstall} The configuration information is as follows, Please copy and save, Choose one of the passwords (password is the user ID or UUID) !!"
	yellow "server address: ${configSSLDomain}  port: ${configV2rayPortShowInfo}"
	yellow "userIDorpassword1: ${v2rayPassword1}"
	yellow "userIDorpassword2: ${v2rayPassword2}"
	yellow "userIDorpassword3: ${v2rayPassword3}"
	yellow "userIDorpassword4: ${v2rayPassword4}"
	yellow "userIDorpassword5: ${v2rayPassword5}"
	yellow "userIDorpassword6: ${v2rayPassword6}"
	yellow "userIDorpassword7: ${v2rayPassword7}"
	yellow "userIDorpassword8: ${v2rayPassword8}"
	yellow "userIDorpassword9: ${v2rayPassword9}"
	yellow "userIDorpassword10: ${v2rayPassword10}"
    echo ""
	cat "${configV2rayPath}/clientConfig.json"
	echo ""
    green "======================================================================"
    green "Please download the corresponding ${promptInfoXrayName} client:"
    yellow "1 Windows clientV2rayN download：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/v2ray-windows.zip"
    yellow "2 MacOS client download：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/v2ray-mac.zip"
    yellow "3 Android client download https://github.com/2dust/v2rayNG/releases"
    #yellow "3 Android client download http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/v2ray-android.zip"
    yellow "4 iOS client Please install small rocket https://shadowsockshelp.github.io/ios/ "
    yellow "  iOS Please install small rocket another address https://lueyingpro.github.io/shadowrocket/index.html "
    yellow "  iOS Install the small rocket and encounter problems with arrival Tutorial https://github.com/shadowrocketHelp/help/ "
    yellow "Summary of client programs on all platforms https://tlanyan.pp.ua/v2ray-clients-download/ "
    yellow "Please see other client programs https://www.v2fly.org/awesome/tools.html "
    green "======================================================================"

    cat >> ${configReadme} <<-EOF


${promptInfoXrayInstall} Version: ${promptInfoXrayVersion} Successful installation ! 
${promptInfoXrayInstall} server-side configuration path ${configV2rayPath}/config.json 

${promptInfoXrayInstall} access log ${configV2rayAccessLogFilePath}
${promptInfoXrayInstall} error log ${configV2rayErrorLogFilePath}

${promptInfoXrayInstall} View log command: journalctl -n 50 -u ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service

${promptInfoXrayInstall} start command: systemctl start ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service  
${promptInfoXrayInstall} stop command: systemctl stop ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service  
${promptInfoXrayInstall} restart command: systemctl restart ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service
${promptInfoXrayInstall} View running status command:  systemctl status ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service 

${promptInfoXrayInstall} The configuration information is as follows, Please copy and save, Choose one of the passwords (password is the user ID or UUID) !

server address: ${configSSLDomain}  
port: ${configV2rayPortShowInfo}
userIDorpassword1: ${v2rayPassword1}
userIDorpassword2: ${v2rayPassword2}
userIDorpassword3: ${v2rayPassword3}
userIDorpassword4: ${v2rayPassword4}
userIDorpassword5: ${v2rayPassword5}
userIDorpassword6: ${v2rayPassword6}
userIDorpassword7: ${v2rayPassword7}
userIDorpassword8: ${v2rayPassword8}
userIDorpassword9: ${v2rayPassword9}
userIDorpassword10: ${v2rayPassword10}

EOF

    cat "${configV2rayPath}/clientConfig.json" >> ${configReadme}
}

function removeV2ray(){

    echo
    read -r -p "Are you sure to uninstall V2ray or Xray? Press Enter to uninstall by default, please enter[Y/n]:" isRemoveV2rayServerInput
    isRemoveV2rayServerInput=${isRemoveV2rayServerInput:-Y}

    if [[ "${isRemoveV2rayServerInput}" == [Yy] ]]; then

        if [[ -f "${configV2rayPath}/xray" || -f "${configV2rayPath}/v2ray" ]]; then

            tempIsXrayService=$(ls ${osSystemMdPath} | grep v2ray- )

            if [ -f "${configV2rayPath}/xray" ]; then
                promptInfoXrayName="xray"
                isXray="yes"
                tempIsXrayService=$(ls ${osSystemMdPath} | grep xray- )
            fi

            if [[ -z "${tempIsXrayService}" ]]; then
                promptInfoXrayNameServiceName=""

            else
                if [ -f "${osSystemMdPath}${promptInfoXrayName}-jin.service" ]; then
                    promptInfoXrayNameServiceName="-jin"
                else
                    tempFilelist=$(ls /usr/lib/systemd/system | grep ${promptInfoXrayName} | awk -F '-' '{ print $2 }' )
                    promptInfoXrayNameServiceName="-${tempFilelist%.*}"
                fi
            fi


            showHeaderRed "Ready to uninstall installed ${promptInfoXrayName}${promptInfoXrayNameServiceName} "


            ${sudoCmd} systemctl stop ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service
            ${sudoCmd} systemctl disable ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service


            rm -rf ${configV2rayPath}
            rm -f ${osSystemMdPath}${promptInfoXrayName}${promptInfoXrayNameServiceName}.service
            rm -f ${configV2rayAccessLogFilePath}
            rm -f ${configV2rayErrorLogFilePath}

            crontab -l | grep -v "rm" | crontab -
            crontab -l | grep -v "${promptInfoXrayName}${promptInfoXrayNameServiceName}" | crontab -


            showHeaderGreen " ${promptInfoXrayName}${promptInfoXrayNameServiceName} Uninstall is complete !"
            
        else
            showHeaderRed " system not installed ${promptInfoXrayName}${promptInfoXrayNameServiceName}, exit uninstall"
        fi
        echo

    fi

}


function upgradeV2ray(){

    if [[ -f "${configV2rayPath}/xray" || -f "${configV2rayPath}/v2ray" ]]; then

        tempIsXrayService=$(ls ${osSystemMdPath} | grep v2ray- )

        if [ -f "${configV2rayPath}/xray" ]; then
            promptInfoXrayName="xray"
            isXray="yes"
            tempIsXrayService=$(ls ${osSystemMdPath} | grep xray- )
        fi

        if [[ -z "${tempIsXrayService}" ]]; then
            promptInfoXrayNameServiceName=""

        else
            if [ -f "${osSystemMdPath}${promptInfoXrayName}-jin.service" ]; then
                promptInfoXrayNameServiceName="-jin"
            else
                tempFilelist=$(ls /usr/lib/systemd/system | grep ${promptInfoXrayName} | awk -F '-' '{ print $2 }' )
                promptInfoXrayNameServiceName="-${tempFilelist%.*}"
            fi
        fi

        
        if [ "$isXray" = "no" ] ; then
            getV2rayVersion "v2ray"
            green " =================================================="
            green "       start the upgrade V2ray Version: ${versionV2ray} !"
            green " =================================================="
        else
            getV2rayVersion "xray"
            green " =================================================="
            green "       start the upgrade Xray Version: ${versionXray} !"
            green " =================================================="
        fi


        ${sudoCmd} systemctl stop ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service

        mkdir -p ${configDownloadTempPath}/upgrade/${promptInfoXrayName}

        downloadV2rayXrayBin "upgrade"

        if [ "$isXray" = "no" ] ; then
            mv -f ${configDownloadTempPath}/upgrade/${promptInfoXrayName}/v2ctl ${configV2rayPath}
        fi

        mv -f ${configDownloadTempPath}/upgrade/${promptInfoXrayName}/${promptInfoXrayName} ${configV2rayPath}
        mv -f ${configDownloadTempPath}/upgrade/${promptInfoXrayName}/geoip.dat ${configV2rayPath}
        mv -f ${configDownloadTempPath}/upgrade/${promptInfoXrayName}/geosite.dat ${configV2rayPath}

        ${sudoCmd} chmod +x ${configV2rayPath}/${promptInfoXrayName}

        systemmdServiceFixV2ray5="run"
        if [[ $versionV2ray == "4.45.2" ]]; then
            systemmdServiceFixV2ray5=""
            sed -i 's/run -config/-config/g' ${osSystemMdPath}${promptInfoXrayName}${promptInfoXrayNameServiceName}.service
        else
            sed -i 's/run -config/-config/g' ${osSystemMdPath}${promptInfoXrayName}${promptInfoXrayNameServiceName}.service
            sed -i 's/-config/run -config/g' ${osSystemMdPath}${promptInfoXrayName}${promptInfoXrayNameServiceName}.service
        fi

        
        ${sudoCmd} systemctl daemon-reload
        ${sudoCmd} systemctl start ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service


        if [ "$isXray" = "no" ] ; then
            green " ================================================== "
            green "     update successed V2ray Version: ${versionV2ray} !"
            green " ================================================== "
        else
            green " =================================================="
            green "     update successed Xray Version: ${versionXray} !"
            green " =================================================="
        fi
                
    else
        red " system not installed ${promptInfoXrayName}${promptInfoXrayNameServiceName}, exit uninstall"
    fi
    echo
}











































function downloadTrojanWebBin(){
    # https://github.com/Jrohy/trojan/releases/download/v2.12.2/trojan-linux-amd64
    # https://github.com/Jrohy/trojan/releases/download/v2.12.2/trojan-linux-arm64
    
    if [[ ${osArchitecture} == "arm" || ${osArchitecture} == "arm64" ]] ; then
        downloadFilenameTrojanWeb="trojan-linux-arm64"
    fi

    if [ -z $1 ]; then
        wget -O ${configTrojanWebPath}/trojan-web --no-check-certificate "https://github.com/Jrohy/trojan/releases/download/v${versionTrojanWeb}/${downloadFilenameTrojanWeb}"
    else
        wget -O ${configDownloadTempPath}/upgrade/trojan-web/trojan-web "https://github.com/Jrohy/trojan/releases/download/v${versionTrojanWeb}/${downloadFilenameTrojanWeb}"
    fi
}

function installTrojanWeb(){
    # wget -O trojan-web_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/Jrohy/trojan/master/install.sh" && chmod +x trojan-web_install.sh && ./trojan-web_install.sh

    if [ -f "${configTrojanWebPath}/trojan-web" ] ; then
        green " =================================================="
        green "  installed Trojan-web Visual management panel, exit the installation !"
        green " =================================================="
        exit
    fi

    stopServiceNginx
    testLinuxPortUsage
    installPackage

    green " ================================================== "
    yellow " please enter Bind the domain name of the arrived VPS E.gwww.xxx.com: (In this step, please close the CDN and install it)"
    green " ================================================== "

    read configSSLDomain
    if compareRealIpWithLocalIp "${configSSLDomain}" ; then

        getV2rayVersion "trojan-web"
        green " =================================================="
        green "    start installation Trojan-web Visual management panel: ${versionTrojanWeb} !"
        green " =================================================="

        mkdir -p ${configTrojanWebPath}
        downloadTrojanWebBin
        chmod +x ${configTrojanWebPath}/trojan-web


        # Add startup script
        cat > ${osSystemMdPath}trojan-web.service <<-EOF
[Unit]
Description=trojan-web
Documentation=https://github.com/Jrohy/trojan
After=network.target network-online.target nss-lookup.target mysql.service mariadb.service mysqld.service docker.service

[Service]
Type=simple
StandardError=journal
ExecStart=${configTrojanWebPath}/trojan-web web -p ${configTrojanWebPort}
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

        ${sudoCmd} systemctl daemon-reload
        ${sudoCmd} systemctl enable trojan-web.service
        ${sudoCmd} systemctl start trojan-web.service

        green " =================================================="
        green " Trojan-web Visual management panel: ${versionTrojanWeb} Successful installation!"
        green " TrojanVisual management paneladdress https://${configSSLDomain}/${configTrojanWebNginxPath}"
        green " start running the command ${configTrojanWebPath}/trojan-web Make initial settings."
        echo
        red " Next installation steps: "
        green " Choose according to the prompt 1. Let's Encrypt certificate, apply for SSL certificate "
        green " After the certificate application is successful. Continue to follow the prompts and select 1. Install the docker version of mysql (mariadb)."
        green " After mysql (mariadb) is successfully started, continue to enter the password of the first trojanuser account according to the prompt, and after pressing Enter, 'Welcome to the trojan management program appears' "
        green "After the 'Welcome to the Trojan Management Program' appears, you need to press Enter without entering a number, so that the installation of nginx will continue until the arrival is completed. "
        echo
        green " nginx Successful installation will show Visual management panel URL, please save it. If the management panel URL is not displayed, the installation failed. "
        green " =================================================="

        read -r -p "Press enter to continue installation. Press enter to continue"

        ${configTrojanWebPath}/trojan-web

        installWebServerNginx

        # command completion environment variables
        echo "export PATH=$PATH:${configTrojanWebPath}" >> ${HOME}/.${osSystemShell}rc

        # (crontab -l ; echo '25 0 * * * "${configSSLAcmeScriptPath}"/acme.sh --cron --home "${configSSLAcmeScriptPath}" > /dev/null') | sort - | uniq - | crontab -
        (crontab -l ; echo "30 4 * * 0,1,2,3,4,5,6 systemctl restart trojan-web.service") | sort - | uniq - | crontab -

    else
        exit
    fi
}

function upgradeTrojanWeb(){
    getV2rayVersion "trojan-web"
    green " =================================================="
    green "    start the upgrade Trojan-web Visual management panel: ${versionTrojanWeb} !"
    green " =================================================="

    ${sudoCmd} systemctl stop trojan-web.service

    mkdir -p ${configDownloadTempPath}/upgrade/trojan-web
    downloadTrojanWebBin "upgrade"
    
    mv -f ${configDownloadTempPath}/upgrade/trojan-web/trojan-web ${configTrojanWebPath}
    chmod +x ${configTrojanWebPath}/trojan-web

    ${sudoCmd} systemctl start trojan-web.service
    ${sudoCmd} systemctl restart trojan.service


    green " ================================================== "
    green "     update successed Trojan-web Visual management panel: ${versionTrojanWeb} !"
    green " ================================================== "
}

function removeTrojanWeb(){
    # wget -O trojan-web_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/Jrohy/trojan/master/install.sh" && chmod +x trojan-web_install.sh && ./trojan-web_install.sh --remove

    green " ================================================== "
    red " Ready to uninstall installed Trojan-web "
    green " ================================================== "

    ${sudoCmd} systemctl stop trojan.service
    ${sudoCmd} systemctl stop trojan-web.service
    ${sudoCmd} systemctl disable trojan-web.service
    

    # 移除trojan
    rm -rf /usr/bin/trojan
    rm -rf /usr/local/etc/trojan
    rm -f ${osSystemMdPath}trojan.service
    rm -f /etc/systemd/system/trojan.service
    rm -f /usr/local/etc/trojan/config.json


    # 移除trojan web 管理程序 
    # rm -f /usr/local/bin/trojan
    rm -rf ${configTrojanWebPath}
    rm -f ${osSystemMdPath}trojan-web.service
    rm -rf /var/lib/trojan-manager

    ${sudoCmd} systemctl daemon-reload


    # 移除trojan的专用数据库
    docker rm -f trojan-mysql
    docker rm -f trojan-mariadb
    rm -rf /home/mysql
    rm -rf /home/mariadb


    # 移除环境变量
    sed -i '/trojan/d' ${HOME}/.${osSystemShell}rc
    # source ${HOME}/.${osSystemShell}rc

    crontab -l | grep -v "trojan-web"  | crontab -

    green " ================================================== "
    green "  Trojan-web Uninstall is complete !"
    green " ================================================== "
}

function runTrojanWebGetSSL(){
    ${sudoCmd} systemctl stop trojan-web.service
    ${sudoCmd} systemctl stop nginx.service
    ${sudoCmd} systemctl stop trojan.service
    ${configTrojanWebPath}/trojan-web tls
    ${sudoCmd} systemctl start trojan-web.service
    ${sudoCmd} systemctl start nginx.service
    ${sudoCmd} systemctl restart trojan.service
}

function runTrojanWebCommand(){
    ${configTrojanWebPath}/trojan-web
}




























function installXUI(){

    stopServiceNginx
    testLinuxPortUsage
    installPackage

    green " ================================================== "
    yellow " please enter Bind the domain name of the arrived VPS E.gwww.xxx.com: (In this step, please close the CDN and install it)"
    green " ================================================== "

    read -r configSSLDomain
    if compareRealIpWithLocalIp "${configSSLDomain}" ; then

        green " =================================================="
        green "    start installation X-UI Visual management panel !"
        green " =================================================="

        # wget -O x_ui_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/sprov065/x-ui/master/install.sh" && chmod +x x_ui_install.sh && ./x_ui_install.sh
        # wget -O x_ui_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh" && chmod +x x_ui_install.sh && ./x_ui_install.sh
        wget -O x_ui_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/kontorol/x-ui/main/install.sh" && chmod +x x_ui_install.sh && ./x_ui_install.sh


        green "X-UI Visual management paneladdress http://${configSSLDomain}:54321"
        green " please ensure 54321 The port has been released, E.g check whether the linux firewall or VPS firewall 54321 port is enabled"
        green "X-UI Visual management panel default administrator user admin password admin, To ensure security, please modify the default as soon as possible after logging in password "
        green " =================================================="

    else
        exit
    fi
}
function removeXUI(){
    green " =================================================="
    /usr/bin/x-ui
}


function installV2rayUI(){

    stopServiceNginx
    testLinuxPortUsage
    installPackage

    green " ================================================== "
    yellow " please enter Bind the domain name of the arrived VPS E.gwww.xxx.com: (In this step, please close the CDN and install it)"
    green " ================================================== "

    read -r configSSLDomain
    if compareRealIpWithLocalIp "${configSSLDomain}" ; then

        green " =================================================="
        green "    start installation V2ray-UI Visual management panel !"
        green " =================================================="

        bash <(curl -Ls https://raw.githubusercontent.com/tszho-t/v2ui/master/v2-ui.sh)

        # wget -O v2_ui_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/sprov065/v2-ui/master/install.sh" && chmod +x v2_ui_install.sh && ./v2_ui_install.sh
        # wget -O v2_ui_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/tszho-t/v2-ui/master/install.sh" && chmod +x v2_ui_install.sh && ./v2_ui_install.sh

        green " V2ray-UI Visual management paneladdress http://${configSSLDomain}:65432"
        green " please ensure 65432 port has been released, E.g check if linux firewall or VPS firewall 65432 port is enabled"
        green " V2ray-UI Visual management panel default administrator user admin password admin, To ensure security, please modify the default as soon as possible after logging in password "
        green " =================================================="

    else
        exit
    fi
}
function removeV2rayUI(){
    green " =================================================="
    /usr/bin/v2-ui
}
function upgradeV2rayUI(){
    green " =================================================="
    /usr/bin/v2-ui
}















































configMosdnsBinPath="/usr/local/bin/mosdns"
configMosdnsPath="/etc/mosdns"
isInstallMosdns="true"
isinstallMosdnsName="mosdns"
downloadFilenameMosdns="mosdns-linux-amd64.zip"
downloadFilenameMosdnsCn="mosdns-cn-linux-amd64.zip"

isUseEasyMosdnsConfig="false"


function downloadMosdns(){

    rm -rf "${configMosdnsBinPath}"
    mkdir -p "${configMosdnsBinPath}"
    cd ${configMosdnsBinPath} || exit



    
    if [[ "${isInstallMosdns}" == "true" ]]; then
        versionMosdns=$(getGithubLatestReleaseVersion "IrineSistiana/mosdns")

        downloadFilenameMosdns="mosdns-linux-amd64.zip"

        # https://github.com/IrineSistiana/mosdns/releases/download/v3.8.0/mosdns-linux-amd64.zip
        # https://github.com/IrineSistiana/mosdns/releases/download/v3.8.0/mosdns-linux-arm64.zip
        # https://github.com/IrineSistiana/mosdns/releases/download/v3.8.0/mosdns-linux-arm-7.zip
        if [[ ${osArchitecture} == "arm" ]] ; then
            downloadFilenameMosdns="mosdns-linux-arm-7.zip"
        fi
        if [[ ${osArchitecture} == "arm64" ]] ; then
            downloadFilenameMosdns="mosdns-linux-arm64.zip"
        fi
        
        downloadAndUnzip "https://github.com/IrineSistiana/mosdns/releases/download/v${versionMosdns}/${downloadFilenameMosdns}" "${configMosdnsBinPath}" "${downloadFilenameMosdns}"
        ${sudoCmd} chmod +x "${configMosdnsBinPath}/mosdns"
    
    else
        versionMosdnsCn=$(getGithubLatestReleaseVersion "IrineSistiana/mosdns-cn")

        downloadFilenameMosdnsCn="mosdns-cn-linux-amd64.zip"

        # https://github.com/IrineSistiana/mosdns-cn/releases/download/v1.2.3/mosdns-cn-linux-amd64.zip
        # https://github.com/IrineSistiana/mosdns-cn/releases/download/v1.2.3/mosdns-cn-linux-arm64.zip
        # https://github.com/IrineSistiana/mosdns-cn/releases/download/v1.2.3/mosdns-cn-linux-arm-7.zip
        if [[ ${osArchitecture} == "arm" ]] ; then
            downloadFilenameMosdnsCn="mosdns-cn-linux-arm-7.zip"
        fi
        if [[ ${osArchitecture} == "arm64" ]] ; then
            downloadFilenameMosdnsCn="mosdns-cn-linux-arm64.zip"
        fi

        downloadAndUnzip "https://github.com/IrineSistiana/mosdns-cn/releases/download/v${versionMosdnsCn}/${downloadFilenameMosdnsCn}" "${configMosdnsBinPath}" "${downloadFilenameMosdnsCn}"
        ${sudoCmd} chmod +x "${configMosdnsBinPath}/mosdns-cn"
    fi

    if [ ! -f "${configMosdnsBinPath}/${isinstallMosdnsName}" ]; then
        echo
        red "Download failed, please check if the network can be accessed normally gitHub.com"
        red "Please check the network and run this script again!"
        echo
        exit 1
    fi 


    rm -rf "${configMosdnsPath}"
    mkdir -p "${configMosdnsPath}"
    cd ${configMosdnsPath} || exit



    if [[ "${isUseEasyMosdnsConfig}" == "false" ]]; then

        echo
        green " Downloading files: cn.dat, geosite.dat, geoip.dat. "
        green " start downloading file: cn.dat, geosite.dat, geoip.dat  and other related documents"
        echo

        # versionV2rayRulesDat=$(getGithubLatestReleaseVersion "Loyalsoldier/v2ray-rules-dat")
        # geositeUrl="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/202205162212/geosite.dat"
        # geoipeUrl="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/202205162212/geoip.dat"
        # cnipUrl="https://github.com/Loyalsoldier/geoip/releases/download/202205120123/cn.dat"

        geositeFilename="geosite.dat"
        geoipFilename="geoip.dat"
        cnipFilename="cn.dat"

        geositeUrl="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
        geoipeUrl="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
        cnipUrl="https://raw.githubusercontent.com/Loyalsoldier/geoip/release/cn.dat"

        wget -O ${configMosdnsPath}/${geositeFilename} ${geositeUrl}
        wget -O ${configMosdnsPath}/${geoipFilename} ${geoipeUrl}
        wget -O ${configMosdnsPath}/${cnipFilename} ${cnipUrl}
    fi


}


function installMosdns(){

    if [ "${osInfo}" = "OpenWrt" ]; then
        echo " ================================================== "
        echo " For Openwrt X86, please use the script below:  "
        echo " against OpenWrt X86 system, Please use the following script to install: "
        echo " wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/dsm/openwrt.sh && chmod +x ./openwrt.sh && ./openwrt.sh "
        echo
        exit
    fi
    
    # https://askubuntu.com/questions/27213/what-is-the-linux-equivalent-to-windows-program-files


    if [ -f "${configMosdnsBinPath}/mosdns" ]; then
        echo
        green " =================================================="
        green " detect arrival mosdns Installed, exit the installation! "
        echo
        exit 1
    fi


    if [ -f "${configMosdnsBinPath}/mosdns-cn" ]; then
        echo
        green " =================================================="
        green " detect arrival mosdns-cn Installed, exit the installation! "
        echo
        exit 1        
    fi

    echo
    green " =================================================="
    green " Please select install Mosdns still Mosdns-cn DNS server:"
    echo
    green " 1. Mosdns Configuration rules are more complicated"
    green " 2. Mosdns-cn, easy to configure, Equivalent to the simplified version of Modbus configuration recommended"
    echo
    read -r -p "please choose MosdnsstillMosdns-cn, Install directly by default Mosdns-cn, please enter pure numbers:" isInstallMosdnsServerInput
    isInstallMosdnsServerInput=${isInstallMosdnsServerInput:-2}
    echo

    if [[ "${isInstallMosdnsServerInput}" == "1" ]]; then
        isInstallMosdns="true"
        isinstallMosdnsName="mosdns"

        echo
        green " =================================================="
        green " use or not easymosdns Configuration, The configuration is more complex Better results"
        green " https://github.com/pmkol/easymosdns"
        echo
        read -r -p "use or noteasymosdns, By default, the carriage return is not used., please enter[y/N]:" isUseEasyConfigInput
        isUseEasyConfigInput=${isUseEasyConfigInput:-n}

        if [[ "$isUseEasyConfigInput" == [Nn] ]]; then
            isUseEasyMosdnsConfig="false" 
        else
            isUseEasyMosdnsConfig="true"
        fi

    else
        isInstallMosdns="false"
        isinstallMosdnsName="mosdns-cn"        
    fi




    echo
    green " ================================================== "
    green "    start installation ${isinstallMosdnsName} !"
    green " ================================================== "
    echo
    


    echo
    green " ================================================== "
    green " please fill in Write cmosdns In progress port No. The default port number is 5335"
    green " DNSserver Commonly used for 53 port, it is recommended to input 53"
    yellow " Soft routing generally has built-in DNSserver, if installed in soft routing, the default is 5335 to avoid conflicts"
    echo
    read -r -p "please fill in Write the port number where moddns is running? The default is 5335, please enter a pure number:" isMosDNSServerPortInput
    isMosDNSServerPortInput=${isMosDNSServerPortInput:-5335}

    mosDNSServerPort="5335"
    reNumber='^[0-9]+$'

    if [[ "${isMosDNSServerPortInput}" =~ ${reNumber} ]] ; then
        mosDNSServerPort="${isMosDNSServerPortInput}"
    fi




    echo
    green " ================================================== "
    green " Whether to add a self-built DNSserver, the default is to press Enter without adding"
    green " Select Yes to add DNSserver, it is recommended to set up DNSserver before running this script"
    green " This script has built-in multiple DNSserver addresses by default"
    echo
    read -r -p "Do you want to add a self-built DNSserver? By default, press Enter to not add it, please enter[y/N]:" isAddNewDNSServerInput
    isAddNewDNSServerInput=${isAddNewDNSServerInput:-n}

    addNewDNSServerIPMosdnsCnText=""
    addNewDNSServerDomainMosdnsCnText=""

    addNewDNSServerIPText=""
    addNewDNSServerDomainText=""
    if [[ "$isAddNewDNSServerInput" == [Nn] ]]; then
        echo 
    else
        echo
        green " ================================================== "
        green " please enter self built DNSserverIP FormatE.g 1.1.1.1"
        green " Please ensure that port53 provides DNS resolution service, if it is non-53portplease fill in write port number, FormatE.g 1.1.1.1:8053"
        echo 
        read -r -p "please enter Self-built DNSserverIPaddress, please enter:" isAddNewDNSServerIPInput

        if [ -n "${isAddNewDNSServerIPInput}" ]; then
            addNewDNSServerIPMosdnsCnText="\"udp://${isAddNewDNSServerIPInput}\", "
            read -r -d '' addNewDNSServerIPText << EOM
        - addr: "udp://${isAddNewDNSServerIPInput}"
          idle_timeout: 500
          trusted: true
EOM

        fi

        echo
        green " ================================================== "
        green " please enter self built DNSserverof domain names used to provide DOH services, FormatE.g www.dns.com"
        green " Please ensure that the server provides DOH services at /dns-query, E.g https://www.dns.com/dns-query"
        echo 
        read -r -p "please enter self built DOHserver domain name, do not enter https://, please enter the domain name directly :" isAddNewDNSServerDomainInput

        if [ -n "${isAddNewDNSServerDomainInput}" ]; then
            addNewDNSServerDomainMosdnsCnText="\"https://${isAddNewDNSServerDomainInput}/dns-query\", "
            read -r -d '' addNewDNSServerDomainText << EOM
        - addr: "https://${isAddNewDNSServerDomainInput}/dns-query"       
          idle_timeout: 400
          trusted: true
EOM
        fi
    fi


    downloadMosdns


    if [[ "${isInstallMosdns}" == "true" ]]; then

        rm -f "${configMosdnsPath}/config.yaml"


        if [[ "${isUseEasyMosdnsConfig}" == "true" ]]; then
            downloadAndUnzip "https://mirror.apad.pro/dns/easymosdns.tar.gz" "${configMosdnsPath}" "easymosdns.tar.gz"
            ${sudoCmd} chmod +x ${configMosdnsPath}/tools/*

            sed -i "s/0\.0\.0\.0:53/0\.0\.0\.0:${mosDNSServerPort}/g" ${configMosdnsPath}/config.yaml

            cd ${configMosdnsBinPath} || exit
            export PATH="$PATH:${configMosdnsBinPath}"

            ${configMosdnsPath}/tools/config-reset

        else
        

            cat > "${configMosdnsPath}/config.yaml" <<-EOF    

log:
  level: info
  file: "${configMosdnsPath}/mosdns.log"

data_providers:
  - tag: geosite
    file: ${configMosdnsPath}/${geositeFilename}
    auto_reload: true
  - tag: geoip
    file: ${configMosdnsPath}/${geoipFilename}
    auto_reload: true

plugins:
  # cache
  - tag: cache
    type: cache
    args:
      size: 2048
      lazy_cache_ttl: 86400 
      cache_everything: true

  # hosts map
  # - tag: map_hosts
  #   type: hosts
  #   args:
  #     hosts:
  #       - 'google.com 0.0.0.0'
  #       - 'api.miwifi.com 127.0.0.1'
  #       - 'www.baidu.com 0.0.0.0'

  # Plugins that forward to the local server
  - tag: forward_local
    type: fast_forward
    args:
      upstream:
        - addr: "udp://223.5.5.5"
          trusted: true
        - addr: "udp://119.29.29.29"
          trusted: true

  # Plugins that forward to remote servers
  - tag: forward_remote
    type: fast_forward
    args:
      upstream:
${addNewDNSServerIPText}
${addNewDNSServerDomainText}
        - addr: "udp://208.67.222.222"
          trusted: true

        - addr: "udp://1.0.0.1"
          trusted: true
        - addr: "https://dns.cloudflare.com/dns-query"
          idle_timeout: 400
          trusted: true


        - addr: "udp://5.2.75.231"
          idle_timeout: 400
          trusted: true

        - addr: "udp://185.121.177.177"
          idle_timeout: 400
          trusted: true        

        - addr: "udp://94.130.180.225"
          idle_timeout: 400
          trusted: true     

        - addr: "udp://78.47.64.161"
          idle_timeout: 400
          trusted: true 

        - addr: "udp://51.38.83.141"          

        - addr: "udp://176.9.93.198"
        - addr: "udp://176.9.1.117"                  

        - addr: "udp://88.198.92.222"                  


  # Plugins that match local domains
  - tag: query_is_local_domain
    type: query_matcher
    args:
      domain:
        - 'provider:geosite:cn'

  - tag: query_is_gfw_domain
    type: query_matcher
    args:
      domain:
        - 'provider:geosite:gfw'

  # Plugins that match non-local domains
  - tag: query_is_non_local_domain
    type: query_matcher
    args:
      domain:
        - 'provider:geosite:geolocation-!cn'

  # Plugins that match ad domains
  - tag: query_is_ad_domain
    type: query_matcher
    args:
      domain:
        - 'provider:geosite:category-ads-all'

  # Plugins that match local IP
  - tag: response_has_local_ip
    type: response_matcher
    args:
      ip:
        - 'provider:geoip:cn'


  # The main run logic plugin
  # sequence plugin called in plugin tag gotta be sequence former definition，
  # Otherwise, the sequence cannot find the corresponding plugin for the arrival.。
  - tag: main_sequence
    type: sequence
    args:
      exec:
        # - map_hosts

        # cache
        - cache

        # Block ad domains ad block
        - if: query_is_ad_domain
          exec:
            - _new_nxdomain_response
            - _return

        # Known local domain names are resolved with the local server
        - if: query_is_local_domain
          exec:
            - forward_local
            - _return

        - if: query_is_gfw_domain
          exec:
            - forward_remote
            - _return

        # Known non-local domain names are resolved by remote server
        - if: query_is_non_local_domain
          exec:
            - _prefer_ipv4
            - forward_remote
            - _return

          # The remaining unknown domain names are shunted by IP.
          # primary from the local server to get the response, discard the result of the non-local IP。
        - primary:
            - forward_local
            - if: "(! response_has_local_ip) && [_response_valid_answer]"
              exec:
                - _drop_response
          secondary:
            - _prefer_ipv4
            - forward_remote
          fast_fallback: 200
          always_standby: true

servers:
  - exec: main_sequence
    listeners:
      - protocol: udp
        addr: ":${mosDNSServerPort}"
      - protocol: tcp
        addr: ":${mosDNSServerPort}"

EOF

        fi

        ${configMosdnsBinPath}/mosdns service install -c "${configMosdnsPath}/config.yaml" -d "${configMosdnsPath}" 
        ${configMosdnsBinPath}/mosdns service start


    else

        rm -f "${configMosdnsPath}/config_mosdns_cn.yaml"

        cat > "${configMosdnsPath}/config_mosdns_cn.yaml" <<-EOF    
server_addr: ":${mosDNSServerPort}"
cache_size: 2048
lazy_cache_ttl: 86400
lazy_cache_reply_ttl: 30
redis_cache: ""
min_ttl: 300
max_ttl: 3600
hosts: []
arbitrary: []
blacklist_domain: []
insecure: false
ca: []
debug: false
log_file: "${configMosdnsPath}/mosdns-cn.log"
upstream: []
local_upstream: ["udp://223.5.5.5", "udp://119.29.29.29"]
local_ip: ["${configMosdnsPath}/${geoipFilename}:cn"]
local_domain: []
local_latency: 50
remote_upstream: [${addNewDNSServerIPMosdnsCnText}  ${addNewDNSServerDomainMosdnsCnText}  "udp://1.0.0.1", "udp://208.67.222.222", "tls://8.8.4.4:853", "udp://5.2.75.231", "udp://172.105.216.54"]
remote_domain: ["${configMosdnsPath}/${geositeFilename}:geolocation-!cn"]
working_dir: "${configMosdnsPath}"
cd2exe: false

EOF

        ${configMosdnsBinPath}/mosdns-cn --service install --config "${configMosdnsPath}/config_mosdns_cn.yaml" --dir "${configMosdnsPath}" 

        ${configMosdnsBinPath}/mosdns-cn --service start
    fi

    echo 
    green " =================================================="
    green " ${isinstallMosdnsName} Successful installation! run port: ${mosDNSServerPort}"
    echo
    green " start up: systemctl start ${isinstallMosdnsName}   stop: systemctl stop ${isinstallMosdnsName}"  
    green " reboot: systemctl restart ${isinstallMosdnsName}"
    green " View status: systemctl status ${isinstallMosdnsName} "
    green " View log: journalctl -n 50 -u ${isinstallMosdnsName} "
    green " view access log: cat  ${configMosdnsPath}/${isinstallMosdnsName}.log"

    # green " start command: ${configMosdnsBinPath}/${isinstallMosdnsName} -s start -dir ${configMosdnsPath} "
    # green " stop command: ${configMosdnsBinPath}/${isinstallMosdnsName} -s stop -dir ${configMosdnsPath} "
    # green " restart command: ${configMosdnsBinPath}/${isinstallMosdnsName} -s restart -dir ${configMosdnsPath} "
    green " =================================================="

}

function removeMosdns(){
    if [[ -f "${configMosdnsBinPath}/mosdns" || -f "${configMosdnsBinPath}/mosdns-cn" ]]; then
        if [[ -f "${configMosdnsBinPath}/mosdns" ]]; then
            isInstallMosdns="true"
            isinstallMosdnsName="mosdns"
        fi

        if [ -f "${configMosdnsBinPath}/mosdns-cn" ]; then
            isInstallMosdns="false"
            isinstallMosdnsName="mosdns-cn"
        fi

        echo
        green " =================================================="
        green " Ready to uninstall installed的 ${isinstallMosdnsName} "
        green " =================================================="
        echo

        if [[ "${isInstallMosdns}" == "true" ]]; then
            ${configMosdnsBinPath}/${isinstallMosdnsName} service stop
            ${configMosdnsBinPath}/${isinstallMosdnsName} service uninstall
        else
            ${configMosdnsBinPath}/mosdns-cn --service stop
            ${configMosdnsBinPath}/mosdns-cn --service uninstall

        fi

        rm -rf "${configMosdnsBinPath}"
        rm -rf "${configMosdnsPath}"

        echo
        green " ================================================== "
        green "  ${isinstallMosdnsName} Uninstall is complete !"
        green " ================================================== "

    else
        echo
        red " system not installed mosdns, exit uninstall"
        echo
    fi

}











configAdGuardPath="/opt/AdGuardHome"

# DNS server 
function installAdGuardHome(){
	wget -qN --no-check-certificate -O ./ad_guard_install.sh https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh && chmod +x ./ad_guard_install.sh && ./ad_guard_install.sh -v
    echo
    if [[ ${configLanguage} == "cn" ]] ; then
        green " To uninstall remove AdGuard Home please run the command ./ad_guard_install.sh -u"
        green " please open the website http://yourip:3000 Complete the initial configuration "
        green " After initialization, Please rerun this script Select 29 to get an SSL certificate. Enable DOH and DOT "
    else
        green " Remove AdGuardHome, pls run ./ad_guard_install.sh -u "
        green " Please open http://yourip:3000 and complete the initialization "
        green " After the initialization, pls rerun this script and choose 29 to get SSL certificate "
    fi
    echo
}

function getAdGuardHomeSSLCertification(){
    if [ -f "${configAdGuardPath}/AdGuardHome" ]; then
        echo
        green " =================================================="
        green " detect arrival AdGuard Home Installed"
        green " Found AdGuard Home have already installed"
        echo
        green " Continue to apply for SSL certificate, Continue to get Free SSL certificate ?"
        read -p "Whether to apply for an SSL certificate, please enter[Y/n]:" isGetAdGuardSSLCertificateInput
        isGetAdGuardSSLCertificateInput=${isGetAdGuardSSLCertificateInput:-Y}

        if [[ "${isGetAdGuardSSLCertificateInput}" == [Yy] ]]; then
            ${configAdGuardPath}/AdGuardHome -s stop
            configSSLCertPath="${configSSLCertPath}/adguardhome"
            renewCertificationWithAcme ""
            replaceAdGuardConfig
        fi
    fi
}

function replaceAdGuardConfig(){

    if [ -f "${configAdGuardPath}/AdGuardHome" ]; then
        
        if [ -f "${configAdGuardPath}/AdGuardHome.yaml" ]; then
            echo
            yellow " Prepare to fill in the SSL certificate that has been applied for arrival AdGuardHome configuration file"
            yellow " prepare to get SSL certificate and replace AdGuardHome config"

            # https://stackoverflow.com/questions/4396974/sed-or-awk-delete-n-lines-following-a-pattern
            sed -i -e '/^tls:/{n;d}' ${configAdGuardPath}/AdGuardHome.yaml
            sed -i "/^tls:/a \  enabled: true" ${configAdGuardPath}/AdGuardHome.yaml
            # sed -i 's/enabled: false/enabled: true/g' ${configAdGuardPath}/AdGuardHome.yaml

            sed -i "s/server_name: .*/server_name: ${configSSLDomain}/g" ${configAdGuardPath}/AdGuardHome.yaml
            sed -i "s|certificate_path: .*|certificate_path: ${configSSLCertPath}/${configSSLCertFullchainFilename}|g" ${configAdGuardPath}/AdGuardHome.yaml
            sed -i "s|private_key_path: .*|private_key_path: ${configSSLCertPath}/${configSSLCertKeyFilename}|g" ${configAdGuardPath}/AdGuardHome.yaml

            # Enable DNS parallel query acceleration
            sed -i 's/all_servers: false/all_servers: true/g' ${configAdGuardPath}/AdGuardHome.yaml


            read -r -d '' adGuardConfigUpstreamDns << EOM
  - 1.0.0.1
  - https://dns.cloudflare.com/dns-query
  - 8.8.8.8
  - https://dns.google/dns-query
  - tls://dns.google
  - 9.9.9.9
  - https://dns.quad9.net/dns-query
  - tls://dns.quad9.net
  - 208.67.222.222
  - https://doh.opendns.com/dns-query
EOM
            TEST1="${adGuardConfigUpstreamDns//\\/\\\\}"
            TEST1="${TEST1//\//\\/}"
            TEST1="${TEST1//&/\\&}"
            TEST1="${TEST1//$'\n'/\\n}"

            sed -i "/upstream_dns:/a \  ${TEST1}" ${configAdGuardPath}/AdGuardHome.yaml


            read -r -d '' adGuardConfigBootstrapDns << EOM
  - 1.0.0.1 
  - 8.8.8.8
  - 8.8.4.4
EOM
            TEST2="${adGuardConfigBootstrapDns//\\/\\\\}"
            TEST2="${TEST2//\//\\/}"
            TEST2="${TEST2//&/\\&}"
            TEST2="${TEST2//$'\n'/\\n}"

            sed -i "/bootstrap_dns:/a \  ${TEST2}" ${configAdGuardPath}/AdGuardHome.yaml


            read -r -d '' adGuardConfigFilters << EOM
- enabled: true
  url: https://anti-ad.net/easylist.txt
  name: 'CHN: anti-AD'
  id: 1652375944
- enabled: true
  url: https://easylist-downloads.adblockplus.org/easylistchina.txt
  name: EasyList China
  id: 1652375945
EOM
            # https://fabianlee.org/2018/10/28/linux-using-sed-to-insert-lines-before-or-after-a-match/

            TEST3="${adGuardConfigFilters//\\/\\\\}"
            TEST3="${TEST3//\//\\/}"
            TEST3="${TEST3//&/\\&}"
            TEST3="${TEST3//$'\n'/\\n}"

            sed -i "/id: 2/a ${TEST3}" ${configAdGuardPath}/AdGuardHome.yaml


            echo
            green " AdGuard Home config updated success: ${configAdGuardPath}/AdGuardHome.yaml "
            green " AdGuard Home Configuration file updated successfully: ${configAdGuardPath}/AdGuardHome.yaml "
            echo
            ${configAdGuardPath}/AdGuardHome -s restart
        else
            red " not yet detect arrivalAdGuardHome configuration file ${configAdGuardPath}/AdGuardHome.yaml, Please complete the initial configuration of AdGuardHome"
            red " ${configAdGuardPath}/AdGuardHome.yaml not found, pls complete the AdGuardHome initialization first!"
        fi 

    else
        red "AdGuard Home not found, Please install AdGuard Home first !"
    fi

}


































function firewallForbiden(){
    # firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 -p tcp -m tcp --dport=25 -j ACCEPT
    # firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 1 -p tcp -m tcp --dport=25 -j REJECT
    # firewall-cmd --reload

    firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 -p tcp -m tcp --dport=25 -j DROP
    firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 1 -j ACCEPT
    firewall-cmd --reload

    # iptables -A OUTPUT -p tcp --dport 25 -j DROP

    # iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 80 -j DROP
    # iptables -A INPUT -p all -j ACCEPT
    # iptables -A OUTPUT -p all -j ACCEPT
}





function startMenuOther(){
    clear

    if [[ ${configLanguage} == "cn" ]] ; then
    
    green " =================================================="
    red " You cannot install trojan or v2ray with this script or other scripts before installing the following 3 Visual management panels! "
    red " If installed trojan or v2ray, please uninstall or redo a clean system first! 3 management panels are installed at the same time by none method"
    echo
    green " 1. Install trojan-web (trojan and trojan-go Visual management panel) and nginx masquerading site"
    green " 2. Upgrade trojan-web arrive to the latest version"
    green " 3. Reapply for a certificate"
    green " 4. View logs, manage users, view configuration and other functions"
    red " 5. uninstall trojan-web and nginx "
    echo
    green " 6. Install V2ray Visual management panel V2-UI, can support trojan at the same time"
    green " 7. Upgrade V2-UI arrive latest version"
    red " 8. Uninstall V2-UI"
    echo
    green " 9. Install Xray Visual management panel X-UI, can support trojan at the same time"
    red " 10. Upgrade or uninstall X-UI"
    echo
    green " =================================================="
    red " The following is a VPS network speed test tool, the script speed test will consume a lot of VPS traffic, please be aware！"
    green " 41. superspeed Three-network pure speed measurement (full speed measurement of some nodes of the three major operators across the country) is recommended "
    green " 42. yet-another-bench-script Comprehensive test (including CPU IO test and network speed test of multiple data nodes in the world) is recommended"
    green " 43. Bench comprehensive test written by teddysun (including system information IO test and network speed test of multiple data nodes in China)"
	green " 44. LemonBench Quick comprehensive test (including CPU memory performance, backhaul, node speed test) "
    green " 45. ZBench Comprehensive network speed test (including node speed test, ping and routing test)"
    green " 46. testrace backhaul routing test by nanqinlang (four network routing Shanghai Telecom Xiamen Telecom Zhejiang Hangzhou Unicom Zhejiang Hangzhou Mobile Beijing Education Network) "
    green " 47. autoBestTrace backhaul routing test (Guangzhou Telecom Shanghai Telecom Xiamen Telecom Chongqing Unicom Chengdu Unicom Shanghai Mobile Chengdu Mobile Chengdu Education Network)"
    green " 48. Backhaul routing test Recommended (Beijing Telecom/Unicom/Mobile Shanghai Telecom/Unicom/Mobile Guangzhou Telecom/Unicom/Mobile)"
    green " 49. Three network backhaul routing test Go language development by zhanghanyun "   
    green " 50. Standalone server testing including system information and I/O testing" 
    echo
    green " =================================================="
    green " 51. Test whether the VPS supports Netflix non-manufactured drama unblocking Supports WARP sock5 test, it is recommended to use "
    green " 52. Test if VPS supports Netflix, Go language version Recommended by sjlleo, Recommended"
    green " 53. Test if VPS supports Netflix, Disney, Hulu and many more streaming platforms, new version by lmc999"
    #green " 54. Test whether the VPS supports Netflix, detect the IP unblocking range and the corresponding region, the original version by CoiaPrant"

    echo
    green " 61. Install the official pagoda panel"
    green " 62. Install Pagoda Panel Pure Edition by hostcli.com"
    green " 63. Install pagoda panel cracked version 7.9 by yu.al"
    echo
    green " 99. Back to previous menu"
    green " 0. exit script"    

    else

    
    green " =================================================="
    red " Install 3 UI admin panel below require clean VPS system. Cannot install if VPS already installed trojan or v2ray "
    red " Pls remove trojan or v2ray if installed. Prefer using clean system to install UI admin panel. "
    red " Trojan and v2ray UI admin panel cannot install at the same time."
    echo
    green " 1. install trojan-web (trojan/trojan-go UI admin panel) with nginx"
    green " 2. upgrade trojan-web to latest version"
    green " 3. redo to request SSL certificate if you got problem with SSL"
    green " 4. Show log and config, manage users, etc."
    red " 5. remove trojan-web and nginx"
    echo
    green " 6. install  V2-UI admin panel, support trojan protocal"
    green " 7. upgrade V2-UI to latest version"
    red " 8. remove V2-UI"
    echo
    green " 9. install X-UI admin panel, support trojan protocal"
    red " 10. upgrade or remove X-UI"
    echo
    green " =================================================="
    red " VPS speedtest tools. Pay attention that speed tests will consume lots of traffic."
    green " 41. superspeed. ( China telecom / China unicom / China mobile node speed test ) "
    green " 42. yet-another-bench-script ( CPU IO Memory Network speed test)"
    green " 43. Bench by teddysun"
	green " 44. LemonBench ( CPU IO Memory Network Traceroute test） "
    green " 45. ZBench "
    green " 46. testrace by nanqinlang (Four-network routing, Shanghai Telecom, Xiamen Telecom, Zhejiang Hangzhou Unicom, Zhejiang Hangzhou Mobile, Beijing Education Network)"
    green " 47. autoBestTrace (Traceroute test Guangzhou Telecom Shanghai Telecom Xiamen Telecom Chongqing Unicom Chengdu Unicom Shanghai Mobile Chengdu Mobile Chengdu Education Network)"
    green " 48. returnroute test (Beijing Telecom/Unicom/Mobile Shanghai Telecom/Unicom/Mobile Guangzhou Telecom/Unicom/Mobile)"
    green " 49. returnroute test by zhanghanyun powered by Go (Three network backhaul routing test) "    
    green " 50. A bench script for dedicated servers "    
    echo
    green " =================================================="
    green " 51. Netflix region and non-self produced drama unlock test, support WARP SOCKS5 proxy and IPv6"
    green " 52. Netflix region and non-self produced drama unlock test by sjlleo using go language."
    green " 53. Netflix, Disney, Hulu etc unlock test by by lmc999"
    #green " 54. Netflix region and non-self produced drama unlock test by CoiaPrant"
    echo
    green " 61. install official bt panel (aa panel)"
    green " 62. install modified bt panel (aa panel) by hostcli.com"
    green " 63. install modified bt panel (aa panel) 7.9 by yu.al"
    echo
    green " 99. Back to main menu"
    green " 0. exit"


    fi


    echo
    read -p "Please input number:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            setLinuxDateZone
            configInstallNginxMode="trojanWeb"
            installTrojanWeb
        ;;
        2 )
            upgradeTrojanWeb
        ;;
        3 )
            runTrojanWebGetSSL
        ;;
        4 )
            runTrojanWebCommand
        ;;
        5 )
            removeNginx
            removeTrojanWeb
        ;;
        6 )
            setLinuxDateZone
            installV2rayUI
        ;;
        7 )
            upgradeV2rayUI
        ;;
        8 )
            removeV2rayUI
        ;;
        9 )
            setLinuxDateZone
            installXUI
        ;;
        10 )
            removeXUI
        ;;                                        
        41 )
            vps_superspeed
        ;;
        42 )
            vps_yabs
        ;;        
        43 )
            vps_bench
        ;;
        44 )
            vps_LemonBench
        ;;
        45 )
            vps_zbench
        ;;
        46 )
            vps_testrace
        ;;
        47 )
            vps_autoBestTrace
        ;;
        48 )
            vps_returnroute
            vps_returnroute2
        ;;
        49 )
            vps_returnroute2
        ;;                
        50 )
            vps_bench_dedicated
        ;;        
        51 )
            vps_netflix_jin
        ;;
        52 )
            vps_netflixgo
        ;;
        53 )
            vps_netflix2
        ;;
        54 )
            vps_netflix2
        ;;
        61 )
            installBTPanel
        ;;
        62 )
            installBTPanelCrackHostcli
        ;;
        63 )
            installBTPanelCrack
        ;;
        81 )
            installBBR
        ;;
        82 )
            installBBR2
        ;;
        99)
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

    green " ===================================================================================================="
    green " Trojan-go V2ray Xray One-click install script | 2022-10-23 | System Support：centos7+ / debian9+ / ubuntu16.04+"
    green " ===================================================================================================="
    green " 1. Install linux kernel bbr plus, install WireGuard, for unblocking Netflix restrictions and avoiding pop-up Google reCAPTCHA CAPTCHA"
    echo
    green " 2. Install trojan/trojan-go and nginx, Support CDN to enable websocket, trojan-go runs on 443port"
    green " 3. Only install trojan/trojan-go to run on 443 or custom port, do not install nginx, easy to integrate with existing website or pagoda panel"
    red " 4. Uninstall trojan/trojan-go and nginx"
    echo
    green " 6. Install Shadowsocks Rust to support Shadowsocks 2022 Encryption, running on a random port"
    green " 7. Install Xray Shadowsocks to support Shadowsocks 2022 Encryption, run on random port"
    red " 8. Uninstall Shadowsocks Rust or Xray "
    echo
    green " 11. Install v2ray or xray and nginx ([Vmess/Vless]-[TCP/WS/gRPC/H2/QUIC]-TLS), Support CDN, nginx running on port 443"
    green " 12. Only install v2ray or xray ([Vmess/Vless]-[TCP/WS/gRPC/H2/QUIC]), noneTLS encryption, easy to integrate with existing website or pagoda panel"
    echo
    green " 13. Install v2ray or xray (VLess-TCP-[TLS/XTLS])+(VMess-TCP-TLS)+(VMess-WS-TLS) Support CDN, optional install nginx, VLess runs on port 443"
    green " 14. Install v2ray or xray (VLess-gRPC-TLS) Support CDN, Optional installation of nginx, VLess runs on port 443"
    green " 15. Install v2ray or xray (VLess-TCP-[TLS/XTLS])+(VLess-WS-TLS) Support CDN, Optional installation of nginx, VLess runs on port 443"
    #green " 16. Install v2ray or xray (VLess-TCP-[TLS/XTLS])+(VLess-WS-TLS)+(VLess-gRPC-TLS) Support CDN, Optional installation of nginx, VLess runs on port 443" 
    green " 17. Install v2ray or xray (VLess-TCP-[TLS/XTLS])+(VLess-WS-TLS)+xray self-contained trojan, Support CDN, Optional installation of nginx, VLess runs on port 443"  
    green " 18. upgrade v2ray or xray arrive The latest version of"
    red " 19. uninstall v2ray or xray and nginx"
    echo
    green " 21. Install at the same time v2ray or xray and trojan-go (VLess-TCP-[TLS/XTLS])+(VLess-WS-TLS)+Trojan, Support CDN, Optional installation of nginx, VLess runs on port 443"  
    green " 22. Install at the same time nginx, v2rayorxray and trojan-go (VLess/Vmess-WS-TLS)+Trojan, Support CDN, trojan-go runs on port 443"  
    green " 23. Install at the same time nginx, v2rayorxray and trojan-go, pass nginx SNI Diversion, Support CDN, Supports coexistence with existing websites, nginx running on port 443 "
    red " 24. uninstall trojan-go, v2rayorxray and nginx"
    echo
    green " 25. View information such as Installed Configuration and userpassword"
    green " 26. Request a free SSL certificate"
    green " 30. Submenu Install trojan and v2ray Visual management panel, VPS speed test tool, Netflix test unlock tool, install pagoda panel, etc."
    green " =================================================="
    green " 31. Install DNSserver AdGuardHome to support de-advertising"
    green " 32. Apply for a free SSL certificate for AdGuardHome, and enable DOH and DOT"    
    green " 33. Install DNS domestic and foreign shunting server mosdns or mosdns-cn"    
    red " 34. uninstall mosdns or mosdns-cn DNSserver "
    echo
    green " 41. Install OhMyZsh and plugins zsh-autosuggestions, Micro editor and other software"
    green " 42. Enable rootuserSSH login. For example, Google Cloud disables root login by default, you can enable this option"
    green " 43. Modify the SSH login port number"
    green " 44. Set the time zone to Tehran time"
    green " 45. Edit authorized_keys file with VI Fill in the public key for SSH password-free login to increase security"
    echo
    green " 88. upgrade script"
    green " 0. exit script"

    else


    green " ===================================================================================================="
    green " Trojan-go V2ray Xray Installation | 2022-10-23 | OS support: centos7+ / debian9+ / ubuntu16.04+"
    green " ===================================================================================================="
    green " 1. Install linux kernel,  bbr plus kernel, WireGuard and Cloudflare WARP. Unlock Netflix geo restriction and avoid Google reCAPTCHA"
    echo
    green " 2. Install trojan/trojan-go with nginx, enable websocket, support CDN acceleration, trojan-go running at 443 port serve TLS"
    green " 3. Install trojan/trojan-go only, trojan-go running at 443(can customize port) serve TLS. Easy integration with existing website"
    red " 4. Remove trojan/trojan-go and nginx"
    echo
    green " 6. Install Shadowsocks Rust"
    green " 7. Install Xray Shadowsocks"
    red " 8. Remove Shadowsocks Rust or Xray"
    echo
    green " 11. Install v2ray/xray with nginx, ([Vmess/Vless]-[TCP/WS/gRPC/H2/QUIC]-TLS), support CDN acceleration, nginx running at 443 port serve TLS"
    green " 12. Install v2ray/xray only. ([Vmess/Vless]-[TCP/WS/gRPC/H2/QUIC]), no TLS encryption. Easy integration with existing website"
    echo
    green " 13. Install v2ray/xray (VLess-TCP-[TLS/XTLS])+(VMess-TCP-TLS)+(VMess-WS-TLS), support CDN, nginx is optional, VLess running at 443 port serve TLS"
    green " 14. Install v2ray/xray (VLess-gRPC-TLS) support CDN, nginx is optional, VLess running at 443 port serve TLS"
    green " 15. Install v2ray/xray (VLess-TCP-[TLS/XTLS])+(VLess-WS-TLS) support CDN, nginx is optional, VLess running at 443 port serve TLS"

    green " 17. Install v2ray/xray (VLess-TCP-[TLS/XTLS])+(VLess-WS-TLS)+(xray's trojan), support CDN, nginx is optional, VLess running at 443 port serve TLS"
    green " 18. Upgrade v2ray/xray to latest version"
    red " 19. Remove v2ray/xray and nginx"
    echo
    green " 21. Install both v2ray/xray and trojan-go (VLess-TCP-[TLS/XTLS])+(VLess-WS-TLS)+Trojan, support CDN, nginx is optional, VLess running at 443 port serve TLS"
    green " 22. Install both v2ray/xray and trojan-go with nginx, (VLess/Vmess-WS-TLS)+Trojan, support CDN, trojan-go running at 443 port serve TLS"
    green " 23. Install both v2ray/xray and trojan-go with nginx. Using nginx SNI distinguish traffic by different domain name, support CDN. Easy integration with existing website. nginx SNI running at 443 port"
    red " 24. Remove trojan-go, v2ray/xray and nginx"
    echo
    green " 25. Show info and password for installed trojan-go and v2ray"
    green " 26. Get a free SSL certificate for one or multiple domains"
    green " 30. Submenu. install trojan and v2ray UI admin panel, VPS speedtest tools, Netflix unlock tools. Miscellaneous tools"
    green " =================================================="
    green " 31. Install AdGuardHome, ads & trackers blocking DNS server "
    green " 32. Get free SSL certificate for AdGuardHome and enable DOH/DOT "
    green " 33. Install DNS server MosDNS/MosDNS-cn"
    red " 34. Remove DNS server MosDNS/MosDNS-cn"

    echo
    green " 41. Install Oh My Zsh and zsh-autosuggestions plugin, Micro editor"
    green " 42. Enable root user login SSH, Some VPS disable root login as default, use this option to enable"
    green " 43. Modify SSH login port number. Secure your VPS"
    green " 44. Set timezone to Beijing time"
    green " 45. Using VI open authorized_keys file, enter your public key. Then save file. In order to login VPS without Password"
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
        2 )
            configInstallNginxMode="noSSL"
            isTrojanGoSupportWebsocket="true"
            installTrojanV2rayWithNginx "trojan_nginx"
        ;;
        3 )
            installTrojanV2rayWithNginx "trojan"
        ;;
        4 )
            removeTrojan
            removeNginx
        ;;
        6 )
            installShadowsocksRust
        ;;
        7 )
            installShadowsocks
        ;;
        8 )
            removeShadowsocks
        ;;
        11 )
            configInstallNginxMode="v2raySSL"
            configV2rayWorkingMode=""
            installTrojanV2rayWithNginx "nginx_v2ray"
        ;;
        12 )
            configInstallNginxMode=""
            configV2rayWorkingMode=""
            installTrojanV2rayWithNginx "v2ray"
        ;;
        13 )
            configInstallNginxMode="noSSL"
            configV2rayWorkingMode="vlessTCPVmessWS"
            installTrojanV2rayWithNginx "v2ray_nginxOptional"
        ;;
        14 )
            configInstallNginxMode="noSSL"
            configV2rayWorkingMode="vlessgRPC"
            installTrojanV2rayWithNginx "v2ray_nginxOptional"
        ;;
        15 )
            configInstallNginxMode="noSSL"
            configV2rayWorkingMode="vlessTCPWS"
            installTrojanV2rayWithNginx "v2ray_nginxOptional"
        ;;
        16 )
            configInstallNginxMode="noSSL"
            configV2rayWorkingMode="vlessTCPWSgRPC"
            installTrojanV2rayWithNginx "v2ray_nginxOptional"
        ;;
        17 )
            configInstallNginxMode="noSSL"
            configV2rayWorkingMode="vlessTCPWSTrojan"
            installTrojanV2rayWithNginx "v2ray_nginxOptional"
        ;; 
        18)
            upgradeV2ray
        ;;
        19 )
            removeV2ray
            removeNginx
        ;;
        21 )
            configInstallNginxMode="noSSL"
            configV2rayWorkingMode="trojan"
            installTrojanV2rayWithNginx "v2ray_nginxOptional"
        ;;
        22 )
            configInstallNginxMode="noSSL"
            configV2rayWorkingMode=""
            configV2rayWorkingNotChangeMode="true"
            installTrojanV2rayWithNginx "trojan_nginx_v2ray"
        ;;
        23 )
            configInstallNginxMode="sni"
            configV2rayWorkingMode="sni"
            installTrojanV2rayWithNginx "nginxSNI_trojan_v2ray"
        ;;
        24 )
            removeV2ray
            removeTrojan
            removeNginx
        ;;
        25 )
            cat "${configReadme}"
        ;;        
        26 )
            installTrojanV2rayWithNginx
        ;;
        30 )
            startMenuOther
        ;;
        31 )
            installAdGuardHome
        ;;
        32 )
            getAdGuardHomeSSLCertification "$@"
        ;;        
        33 )
            installMosdns
        ;;        
        34 )
            removeMosdns
        ;;
        41 )
            setLinuxDateZone
            installPackage
            installSoftEditor
            installSoftOhMyZsh
        ;;
        42 )
            setLinuxRootLogin
            sleep 4s
            start_menu
        ;;
        43 )
            changeLinuxSSHPort
            sleep 10s
            start_menu
        ;;
        44 )
            setLinuxDateZone
            sleep 4s
            start_menu
        ;;
        45 )
            editLinuxLoginWithPublicKey
        ;;


        66 )
            isTrojanMultiPassword="yes"
            echo "isTrojanMultiPassword: yes"
            sleep 3s
            start_menu
        ;;
        76 )
            vps_returnroute
            vps_returnroute2
        ;;
        77 )
            vps_netflixgo
            vps_netflix_jin
        ;;
        80 )
            installPackage
        ;;
        81 )
            installBBR
        ;;
        82 )
            installBBR2
        ;;
        83 )
            installSWAP
        ;;
        84 )
            firewallForbiden
        ;;        
        88 )
            upgradeScript
        ;;
        99 )
            getV2rayVersion "wgcf"
        ;;
        0 )
            exit 1
        ;;
        * )
            clear
            red "please enter正确数字 !"
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
        installPackage
        setLanguage
    fi
}

showMenu
