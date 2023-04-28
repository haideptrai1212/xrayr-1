#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Current folder
cur_dir=$(pwd)
# Color
red='\033[0;31m'
green='\033[0;32m'
#yellow='\033[0;33m'
plain='\033[0m'
operation=(Install Update UpdateConfig logs restart delete)
# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] Chưa vào root kìa !, vui lòng xin phép ROOT trước!" && exit 1

#Check system
check_sys() {
  local checkType=$1
  local value=$2
  local release=''
  local systemPackage=''

  if [[ -f /etc/redhat-release ]]; then
    release="centos"
    systemPackage="yum"
  elif grep -Eqi "debian|raspbian" /etc/issue; then
    release="debian"
    systemPackage="apt"
  elif grep -Eqi "ubuntu" /etc/issue; then
    release="ubuntu"
    systemPackage="apt"
  elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
    release="centos"
    systemPackage="yum"
  elif grep -Eqi "debian|raspbian" /proc/version; then
    release="debian"
    systemPackage="apt"
  elif grep -Eqi "ubuntu" /proc/version; then
    release="ubuntu"
    systemPackage="apt"
  elif grep -Eqi "centos|red hat|redhat" /proc/version; then
    release="centos"
    systemPackage="yum"
  fi

  if [[ "${checkType}" == "sysRelease" ]]; then
    if [ "${value}" == "${release}" ]; then
      return 0
    else
      return 1
    fi
  elif [[ "${checkType}" == "packageManager" ]]; then
    if [ "${value}" == "${systemPackage}" ]; then
      return 0
    else
      return 1
    fi
  fi
}

# Get version
getversion() {
  if [[ -s /etc/redhat-release ]]; then
    grep -oE "[0-9.]+" /etc/redhat-release
  else
    grep -oE "[0-9.]+" /etc/issue
  fi
}

# CentOS version
centosversion() {
  if check_sys sysRelease centos; then
    local code=$1
    local version="$(getversion)"
    local main_ver=${version%%.*}
    if [ "$main_ver" == "$code" ]; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

get_char() {
  SAVEDSTTY=$(stty -g)
  stty -echo
  stty cbreak
  dd if=/dev/tty bs=1 count=1 2>/dev/null
  stty -raw
  stty echo
  stty $SAVEDSTTY
}
error_detect_depends() {
  local command=$1
  local depend=$(echo "${command}" | awk '{print $4}')
  echo -e "[${green}Info${plain}] Bắt đầu cài đặt các gói ${depend}"
  ${command} >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "[${red}Error${plain}] Cài đặt gói không thành công ${red}${depend}${plain}"
    exit 1
  fi
}

# Pre-installation settings
pre_install_docker_compose() {
    echo -e "DOCKER 443 - TROJAN FAST4G.ME"
    read -p "Nhập Node ID port 443 :" node_443
    echo -e "Node_80 là : ${node_443}"

    read -p "Nhập CertDomain port443:" CertDomain443
    echo -e "CertDomain port 443 là = ${CertDomain}"
}

# Config docker
config_docker() {
  cd ${cur_dir} || exit
  echo "Bắt đầu cài đặt các gói"
  install_dependencies
  echo "Tải tệp cấu hình DOCKER"
  cat >docker-compose.yml <<EOF
version: '3'
services: 
  xrayr: 
    image: ghcr.io/xrayr-project/xrayr:latest
    volumes:
      - ./config.yml:/etc/XrayR/config.yml
      - ./dns.json:/etc/XrayR/dns.json
      - ./crt.pem:/etc/XrayR/crt.pem
      - ./key.pem:/etc/XrayR/key.pem
    restart: always
    network_mode: host    
EOF
  cat >dns.json <<EOF
{
    "servers": [
        "1.1.1.1",
        "8.8.8.8",
        "localhost"
    ],
    "tag": "dns_inbound"
}
EOF
  cat >key.pem <<EOF
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCtesrnIrIP4vRg
uJj9hYkqEeb+yciBbZtqcSmH8Xkl7N0KvxoPYEGHUVjDzsvmp9RC1NijoSHyEGJo
gBr3z3iO/ZkihFrNOHvMyDjir6ndltJXJ1ZBSzoMSPhRUGJRiSMyKuUC7yq+WkRJ
1a8w4iJFace6TcRtLVolOi/yzS8UbaA1jTLSfzlUA54jVr4uo+JMR6/7m4H8TTzI
+0qWff7Pjiga9DMgFHou+AJ6WgtQg2ycek/zHXX9qQZv9ZgDUbZkycys7yBwxLOd
B2p/Wi9OSu8FfaITzBldkRHLOyVBTS/oqA+CFyiJERVHaf+B5jnF2rjm6NVX957v
MXJ09NwRAgMBAAECggEANm6+hqq0y1ZPjp+tZXMGeFxYqh5/Wtkc+Feci+rBNByv
uMUAtM1jkkV8gCf9g5iqefPWK/WNtKnebuKvU41WSyuYZqO36AeulLFIZBxxRLWj
tzQBFQi5JIyq2bzKtMG+eOnLpNGNjF+/aJlzWHfEABqyUCtBlG40CFVLITivao17
nqt6hDcPAWdWICfTTSXUcjx3ltlnAeAhKJFzTAf/gvep7JL5TVhM9ss7ep8GL4bE
6FS+lZv+ZqFU52u41xs6SNoHLOVnjQHowp4GgaL28xalepPDPKORHUMbrdMHsUaa
h8e6bKG8n5khnPrLY1bpVrmRf8asSzH90dYiF1Jm9wKBgQDzumQW0FrdcvS1JuIA
Dt/pL5sFrWFcaxPAumDy3v9hrHSqaVCf+p2bDtHBSNfkdIpwZY8nDzbgUhmWuJcx
lJNdprajWU97Nt4w3BvxOTRA/jsd+ZgYJwcBND0516IqSXciji6eBKMH9l49htJj
TuwJfDHY2ngBRjseQ1NSS6gTEwKBgQC2Numg3tj1EuHP9plplnxwRnyAVdI/RYGt
ZavqmwnFWtUokCIStbMyX1um/IfWV9lu9TwH84xm9xyioWtOhqUujqbb4YAbHYkL
c8F/44aPlF6c/LfPDO9ZpYZNEyqPw41Gu8F6cvNfvhfvKWdPCXyJRFnpv51D3XiK
weQW99bUywKBgCJNsZikaqWQcHCusFBhx5ICaUc7R+DCEV2m3c5RJJCSvTje6cIa
e+Q/CbaykfBNls6K/ML6mTapV4CnKmCIENW1iS8ketNUvaES2bvx2TDsl1V4s7dy
hsHcoGFrwB9Dh8kNSfJjpK6SNmFigGoJyZ7sI/fph8pmIBv6TdffXiCRAoGAALHw
7jYrabPqvJpaN3blfqAmNW8eYDNprTmoEDsLLH+ONJtoJd4fkt+eP+LSudSX9b5l
vjoFnRbwOwaWnDQTSTwuEsSncnMIZMzKPiymBMIyIjMsmFOaTiM9genCzc2XKl/o
+wiZORJGkRj9VeXZXcSu+x9KAEpF/XGD5zqGzUUCgYA55k3B4twJITJe6oqJgD0R
WWwIUZq9r6rNTjsB0EGC/hqaudzxdZ56Tqqf770ej23K8ienUepZuZHe3RnVzC3N
2fKKsH6gfO9GEN/MhHwYe7Zl6v0uo//5qOCFjuQUzpeC/nLSlVo6rAL1wYIvk7y8
frkvZ7RGwzUQyH2CRyYVaA==
-----END PRIVATE KEY-----
EOF
  cat >crt.pem <<EOF
-----BEGIN CERTIFICATE-----
MIIEnjCCA4agAwIBAgIUVEjwNYpaC+Bu5wY+uQhqyndSldUwDQYJKoZIhvcNAQEL
BQAwgYsxCzAJBgNVBAYTAlVTMRkwFwYDVQQKExBDbG91ZEZsYXJlLCBJbmMuMTQw
MgYDVQQLEytDbG91ZEZsYXJlIE9yaWdpbiBTU0wgQ2VydGlmaWNhdGUgQXV0aG9y
aXR5MRYwFAYDVQQHEw1TYW4gRnJhbmNpc2NvMRMwEQYDVQQIEwpDYWxpZm9ybmlh
MB4XDTIzMDMzMDExNDEwMFoXDTM4MDMyNjExNDEwMFowYjEZMBcGA1UEChMQQ2xv
dWRGbGFyZSwgSW5jLjEdMBsGA1UECxMUQ2xvdWRGbGFyZSBPcmlnaW4gQ0ExJjAk
BgNVBAMTHUNsb3VkRmxhcmUgT3JpZ2luIENlcnRpZmljYXRlMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEArXrK5yKyD+L0YLiY/YWJKhHm/snIgW2banEp
h/F5JezdCr8aD2BBh1FYw87L5qfUQtTYo6Eh8hBiaIAa9894jv2ZIoRazTh7zMg4
4q+p3ZbSVydWQUs6DEj4UVBiUYkjMirlAu8qvlpESdWvMOIiRWnHuk3EbS1aJTov
8s0vFG2gNY0y0n85VAOeI1a+LqPiTEev+5uB/E08yPtKln3+z44oGvQzIBR6LvgC
eloLUINsnHpP8x11/akGb/WYA1G2ZMnMrO8gcMSznQdqf1ovTkrvBX2iE8wZXZER
yzslQU0v6KgPghcoiREVR2n/geY5xdq45ujVV/ee7zFydPTcEQIDAQABo4IBIDCC
ARwwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMCBggrBgEFBQcD
ATAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTO3fKymaOl7XpEkk6vctr6RCGy8TAf
BgNVHSMEGDAWgBQk6FNXXXw0QIep65TbuuEWePwppDBABggrBgEFBQcBAQQ0MDIw
MAYIKwYBBQUHMAGGJGh0dHA6Ly9vY3NwLmNsb3VkZmxhcmUuY29tL29yaWdpbl9j
YTAhBgNVHREEGjAYggsqLnNreXBuLmZ1boIJc2t5cG4uZnVuMDgGA1UdHwQxMC8w
LaAroCmGJ2h0dHA6Ly9jcmwuY2xvdWRmbGFyZS5jb20vb3JpZ2luX2NhLmNybDAN
BgkqhkiG9w0BAQsFAAOCAQEAOmgfjWjkyHaapwFVD+naWYHstwMB0Nk+no+km3+a
/pvovfB/MHztIvmCiKGTA1EDyZwPYP5igRyObycHTGMQNDfi3fqcpEN3QqA8zQn/
1Xruy8zoNsRaeibFt07Iy5xdGXDjYPqCrtZO0KyFt4MuOCpw+hj/nVcNANC1dZon
0UZGf9Um1OA1TRzehLnWUtipHzHuRJLF1v6wm/3ETsVLIWYenFusv71AlrTbP2zC
u+mGEbt+GwOkUZuPZTLyPP41mUFlbbcURzv8vtuQ67mpgpYvth9niGIkV44523u+
o9jVhBiJEm5ojfC2nZYrEX+GdXfe3b9rn8Y6cinUHy42Zw==
-----END CERTIFICATE-----
EOF
  cat >config.yml <<EOF
Log:
  Level: none 
  AccessPath: # ./access.Log
  ErrorPath: # ./error.log
DnsConfigPath: 
ConnetionConfig:
  Handshake: 4 
  ConnIdle: 86400 
  UplinkOnly: 20 
  DownlinkOnly: 40 
  BufferSize: 64 
Nodes:
  -
    PanelType: "V2board" 
    ApiConfig:
      ApiHost: "https://api-khongaibiet.skypn.fun/"
      ApiKey: "adminskypn9810@skypn.fun"
      NodeID: $node_443
      NodeType: Trojan 
      Timeout: 10 
      EnableVless: false 
      EnableXTLS: false 
      SpeedLimit: 0 
      DeviceLimit: 4 
      RuleListPath: 
    ControllerConfig:
      ListenIP: 0.0.0.0 
      SendIP: 0.0.0.0 
      UpdatePeriodic: 60 
      EnableDNS: false 
      DNSType: AsIs 
      DisableUploadTraffic: false 
      DisableGetRule: false 
      DisableIVCheck: false 
      DisableSniffing: true 
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
        CertFile: /etc/XrayR/crt.pem
        KeyFile: /etc/XrayR/key.pem
        Provider: cloudflare 
        Email: test@me.com
        DNSEnv: 
          CLOUDFLARE_EMAIL: aaa
          CLOUDFLARE_API_KEY: bbb         
EOF

}

# Install docker and docker compose
install_docker() {
  echo -e "bắt đầu cài đặt DOCKER "
 sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
systemctl start docker
systemctl enable docker
  echo -e "Bắt đầu cài đặt Docker Compose "
curl -fsSL https://get.docker.com | bash -s docker
curl -L "https://github.com/docker/compose/releases/download/1.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
  echo "Khởi động Docker "
  service docker start
  echo "khởi động Docker-Compose "
  docker-compose up -d
  echo
  echo -e "Đã hoàn tất cài đặt phụ trợ ！"
  echo -e "0 0 */3 * *  cd /root/${cur_dir} && /usr/local/bin/docker-compose pull && /usr/local/bin/docker-compose up -d" >>/etc/crontab
  echo -e "Cài đặt cập nhật thời gian kết thúc đã hoàn tất! hệ thống sẽ update sau [${green}24H${plain}] Từ lúc bạn cài đặt"
}

install_check() {
  if check_sys packageManager yum || check_sys packageManager apt; then
    if centosversion 5; then
      return 1
    fi
    return 0
  else
    return 1
  fi
}

install_dependencies() {
  if check_sys packageManager yum; then
    echo -e "[${green}Info${plain}] Kiểm tra kho EPEL ..."
    if [ ! -f /etc/yum.repos.d/epel.repo ]; then
      yum install -y epel-release >/dev/null 2>&1
    fi
    [ ! -f /etc/yum.repos.d/epel.repo ] && echo -e "[${red}Error${plain}] Không cài đặt được kho EPEL, vui lòng kiểm tra." && exit 1
    [ ! "$(command -v yum-config-manager)" ] && yum install -y yum-utils >/dev/null 2>&1
    [ x"$(yum-config-manager epel | grep -w enabled | awk '{print $3}')" != x"True" ] && yum-config-manager --enable epel >/dev/null 2>&1
    echo -e "[${green}Info${plain}] Kiểm tra xem kho lưu trữ EPEL đã hoàn tất chưa ..."

    yum_depends=(
      curl
    )
    for depend in ${yum_depends[@]}; do
      error_detect_depends "yum -y install ${depend}"
    done
  elif check_sys packageManager apt; then
    apt_depends=(
      curl
    )
    apt-get -y update
    for depend in ${apt_depends[@]}; do
      error_detect_depends "apt-get -y install ${depend}"
    done
  fi
  echo -e "[${green}Info${plain}] Đặt múi giờ thành phố Hà Nội GTM+7"
  ln -sf /usr/share/zoneinfo/Asia/Hanoi  /etc/localtime
  date -s "$(curl -sI g.cn | grep Date | cut -d' ' -f3-6)Z"

}

#update_image
Update_xrayr() {
  cd ${cur_dir}
  echo "Tải Plugin DOCKER"
  docker-compose pull
  echo "Bắt đầu chạy dịch vụ DOCKER"
  docker-compose up -d
}

#show last 100 line log

logs_xrayr() {
  echo "Nhật ký chạy sẽ được hiển thị"
  docker-compose logs --tail 100
}

# Update config
UpdateConfig_xrayr() {
  cd ${cur_dir}
  echo "Đóng dịch vụ hiện tại"
  docker-compose down
  pre_install_docker_compose
  config_docker
  echo "Bắt đầu chạy dịch vụ DOKCER"
  docker-compose up -d
}

restart_xrayr() {
  cd ${cur_dir}
  docker-compose down
  docker-compose up -d
  echo "Khởi động lại thành công!"
}
delete_xrayr() {
  cd ${cur_dir}
  docker-compose down
  cd ~
  rm -Rf ${cur_dir}
  echo "Đã xóa thành công!"
}
# Install xrayr
Install_xrayr() {
  pre_install_docker_compose
  config_docker
  install_docker
}

# Initialization step
clear
while true; do
  echo "Vui lòng nhập một số để Thực Hiện Câu Lệnh:"
  for ((i = 1; i <= ${#operation[@]}; i++)); do
    hint="${operation[$i - 1]}"
    echo -e "${green}${i}${plain}) ${hint}"
  done
  read -p "Vui lòng chọn một số và nhấn Enter (Enter theo mặc định ${operation[0]}):" selected
  [ -z "${selected}" ] && selected="1"
  case "${selected}" in
  1 | 2 | 3 | 4 | 5 | 6 | 7)
    echo
    echo "Bắt Đầu : ${operation[${selected} - 1]}"
    echo
    ${operation[${selected} - 1]}_xrayr
    break
    ;;
  *)
    echo -e "[${red}Error${plain}] Vui lòng nhập số chính xác [1-6]"
    ;;
  esac

done
