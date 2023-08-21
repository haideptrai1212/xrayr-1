#!/binstall

# azz
red() {
	echo -e "\033[31m\033[01m$1\033[0m"
}

green() {
	echo -e "\033[32m\033[01m$1\033[0m"
}

yellow() {
	echo -e "\033[33m\033[01m$1\033[0m"
}

# azz
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Alpine")
PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "apk add -f")
PACKAGE_REMOVE=("apt -y remove" "apt -y remove" "yum -y remove" "yum -y remove")

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
	SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
	[[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && red "ẻ e" && exit 1

archAffix() {
	case "$(uname -m)" in
  x86_64 | x64 | amd64) return 0 ;;
	aarch64 | arm64) return 0 ;;
	*) red "ẻ e k việt sub！" ;;
	esac

	return 0
}

install() {
	install_XrayR
	clear
	makeConfig
	makeConfig2
}

install_XrayR() {
	[[ -z $(type -P curl) ]] && ${PACKAGE_UPDATE[int]} && ${PACKAGE_INSTALL[int]} curl
	[[ -z $(type -P socat) ]] && ${PACKAGE_UPDATE[int]} && ${PACKAGE_INSTALL[int]} socat
	bash <(curl -Ls https://raw.githubusercontent.com/longyi8/XrayR/master/install.sh)
}

makeConfig() {
    echo "------  XRAYR THƯỜNG 80 + 443 ---------"
	read -p "Loại website của bạn: V2board"
	echo "---------------"
	read -p "Link website: " Webname
 	echo -e "Link web là: ${Webname}"
	echo "---------------"
	read -p "API key của web: " Apikey
  	echo -e "API key là: ${Apikey}"
	echo "---------------"
	read -p "Node ID 80: " NodeID80
	echo -e "Node 80 là: ${NodeID80}"
	echo "---------------"
	read -p "Nhập CertDomain port 80: " CertDomain80
    	echo -e "CertDomain là: ${CertDomain80}"
    	echo "---------------"
	read -p "Node ID 443: " NodeID443
	echo -e "Node 80 là: ${NodeID443}"
	echo "---------------"
    	read -p "Nhập CertDomain port 443: " CertDomain443
    	echo -e "CertDomain là: ${CertDomain443}"
	echo "---------------"
	rm -f /etc/XrayR/config.yml
	if [[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]]; then
		curl https://get.acme.sh | sh -s email=script@github.com
		source ~/.bashrc
		bash ~/.acme.sh/acme.sh --upgrade --auto-upgrade
	fi
         cat <<EOF >/etc/XrayR/config.yml
Log:
  Level: none 
  AccessPath: # /etc/XrayR/access.Log
  ErrorPath: # /etc/XrayR/error.log
DnsConfigPath: # /etc/XrayR/dns.json
InboundConfigPath: # /etc/XrayR/custom_inbound.json
RouteConfigPath: # /etc/XrayR/route.json
OutboundConfigPath: # /etc/XrayR/custom_outbound.json
ConnetionConfig:
  Handshake: 4 
  ConnIdle: 30 
  UplinkOnly: 2 
  DownlinkOnly: 4 
  BufferSize: 64 
Nodes:
  -
    PanelType: "V2board" 
    ApiConfig:
      ApiHost: "$Webname"
      ApiKey: "$Apikey"
      NodeID: $NodeID80
      NodeType: V2ray 
      Timeout: 30 
      EnableVless: false 
      EnableXTLS: false 
      SpeedLimit: 0 
      DeviceLimit: 3 
      RuleListPath: # /etc/XrayR/rulelist
    ControllerConfig:
      DisableSniffing: True
      ListenIP: 0.0.0.0 
      SendIP: 0.0.0.0 
      UpdatePeriodic: 60 
      EnableDNS: false 
      DNSType: AsIs 
      EnableProxyProtocol: false 
      EnableFallback: false 
      FallBackConfigs:  
        -
          SNI: 
          Path: 
          Dest: 80 
          ProxyProtocolVer: 0 
      CertConfig:
        CertMode: http
        CertDomain: "$CertDomain80" 
        CertFile: /etc/XrayR/ssl/crt.crt
        KeyFile: /etc/XrayR/ssl/key.key
        Provider: alidns 
        Email: test@me.com
        DNSEnv: 
          ALICLOUD_ACCESS_KEY: aaa
          ALICLOUD_SECRET_KEY: bbb
  -
    PanelType: "V2board" 
    ApiConfig:
      ApiHost: "$Webname"
      ApiKey: "$Apikey"
      NodeID: $NodeID443
      NodeType: Trojan 
      Timeout: 30 
      EnableVless: false 
      EnableXTLS: false 
      SpeedLimit: 0 
      DeviceLimit: 3 
      RuleListPath: # /etc/XrayR/rulelist
    ControllerConfig:
      DisableSniffing: True
      ListenIP: 0.0.0.0 
      SendIP: 0.0.0.0 
      UpdatePeriodic: 60 
      EnableDNS: false 
      DNSType: AsIs 
      EnableProxyProtocol: false 
      EnableFallback: false 
      FallBackConfigs:  
        -
          SNI: 
          Path: 
          Dest: 80 
          ProxyProtocolVer: 0 
      CertConfig:
        CertMode: file 
        CertDomain: "$CertDomain443"
        CertFile: /etc/XrayR/ssl/crt.crt
        KeyFile: /etc/XrayR/ssl/key.key
        Provider: cloudflare 
        Email: test@me.com
        DNSEnv: 
          CLOUDFLARE_EMAIL: 
          CLOUDFLARE_API_KEY: 

EOF
	cd /etc/XrayR
	git clone https://github.com/chaomynhan/ssl.git
	XrayR restart
	green "Đã xong, reboot nếu k thành công！"
	exit 1
}

install
