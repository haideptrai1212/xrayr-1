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
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDS01YlEK8zi/Y/
BEQeyhp1ODZI+FTMXDTILuc+ZQPDzam4QEZ88VWSikrda2L4/iCDvsIEzTffRsGv
NT/w90e7TWW3cBGaLVkWXwVkXRyoxdS1Nh4iYblFlIyh7qKrJG9S8vcUGIM0yDz/
nDtlLKZwQPL6TZn8rbr/3UqUxSPr8dFuaqnnBcYetS6Duy0zb4LENzDJLMOVXDwi
rA1QwZVgDH2pKNCPsVh8MGmPH6CWS1n4Trz0iQLvy7QVzs7daPyT9788tnGn++lD
wx/hSa7+U+/j0shiMjsQtHRCRtPloyqz3eDZY0BYm7DUt6sFs5S9X5JJIxUKUJcq
MZLhm65nAgMBAAECggEANnDreGPQEkwMuSYlXxwKbAWpgvtZjnIrERyHi2WzbK8h
qhoy+ZWqZs5+WaIe6zRYehza5jmGOYqAfnmOOu/oHpZ0c0Olz/3w2OWNs2aV/YEk
lezVKES6/pxHGpPQfshIVQ+3vQE9dHZWxhz2e4BltGwZMoiygHzuYp8m4LbtuUH+
sralTT8y0HDYh3PtJ2AbS2hb13TDbJi0sPtSeCreLBQhg7vHfTPRmQz+BTOBzB15
B2ZgjN2UUxyFGO3AA8zh61uAk6xGWzryUvuDeJJBr/Wj4dgQBFczlEoZEs+DhyOw
wVpRrFbznukFA6RQTXf/l3rUAFD0ucGycDDrN/v+OQKBgQD/OmpRybMQLAoI4Zsr
kwdr7Z4hKrT3PAzsz/cXzzxelQU1FsCyDsDPqt9GmChs1xsxn1I4L0enXlzXGe3a
ypNCsPBibH5XbfIsICCIt2B7mV8IO4NThtVfp/NBLQgaWR9/MqVmPTgNTkvxFmiz
eJpBri0DtsYxDCu1R5nkvRSm+QKBgQDTdowCtbBQpgiEqdsEvufyXAuHrxkwWtnM
vrCkGchXkPly0shHB2XclbVCqvHsQVnYW8dbHW2SGvBalVIYizN8omho/tPNmfIO
jZ/I/3vvbvsYHeCfsp15CgUTdDuoD1QTI3KoFi4uErwuAimqN9ykWgQtmyzHZGNO
4Ee+WFV4XwKBgQC1vZf1s2Wxj1p55oSC68huHx7pySphnr4pZxExQB1h0EWL/y6p
2/2KIseo0jJ/BlFT7Xozjd89G+GKPel0Uam45JvXyh/RC/ZVW28vSz0F5jmYeCBU
uv93hPWfpHxPnsTh42OJwPAH8Yf8HZPisG9Pc8KUEXNhe6QoCttX2Rg6qQKBgEY0
b1te8sBzvxQ8SCiVMPB3uqQ7b8NsBi9Bh+eTX74itY53iGJ8hEbttRYDJvpm3+tC
3TbU2FHPe8i3FmBrppZUXRGuuKbj20cVodzbZUwirl5dXPvoEvviZbkFt+Cd5i3M
cP55Dq/hLHSh5y9KCIjQEd8KS52PKKFBONBrB0VFAoGAc0rMXvKleM1vTIb97V3c
24Sn3iKHaUy+B3ZzjgQzGIYDFS3krk4M8EEjZ9LLHU6bdpMUhzAjM9wqrixVPXR/
rwXEMCiS1rAP/9QSQQd7Z/8H9ALiXUHTzIqIET0o/ll6wl7xDQm4Rk2rKTBekgT7
tcX/RPA+QdcbBAeGMlOxWIw=
-----END PRIVATE KEY-----
EOF
  cat >crt.pem <<EOF
-----BEGIN CERTIFICATE-----
MIIFJTCCBA2gAwIBAgISA8Uz2MhK/tTwoqarEWm2GvdaMA0GCSqGSIb3DQEBCwUA
MDIxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQD
EwJSMzAeFw0yMzA0MTExMDAyMDRaFw0yMzA3MTAxMDAyMDNaMBQxEjAQBgNVBAMT
CWZhc3Q0Zy5tZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANLTViUQ
rzOL9j8ERB7KGnU4Nkj4VMxcNMgu5z5lA8PNqbhARnzxVZKKSt1rYvj+IIO+wgTN
N99Gwa81P/D3R7tNZbdwEZotWRZfBWRdHKjF1LU2HiJhuUWUjKHuoqskb1Ly9xQY
gzTIPP+cO2UspnBA8vpNmfytuv/dSpTFI+vx0W5qqecFxh61LoO7LTNvgsQ3MMks
w5VcPCKsDVDBlWAMfako0I+xWHwwaY8foJZLWfhOvPSJAu/LtBXOzt1o/JP3vzy2
caf76UPDH+FJrv5T7+PSyGIyOxC0dEJG0+WjKrPd4NljQFibsNS3qwWzlL1fkkkj
FQpQlyoxkuGbrmcCAwEAAaOCAlEwggJNMA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUE
FjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU
GX/+xC2CHf2oUrMIDVciaZ7hXSgwHwYDVR0jBBgwFoAUFC6zF7dYVsuuUAlA5h+v
nYsUwsYwVQYIKwYBBQUHAQEESTBHMCEGCCsGAQUFBzABhhVodHRwOi8vcjMuby5s
ZW5jci5vcmcwIgYIKwYBBQUHMAKGFmh0dHA6Ly9yMy5pLmxlbmNyLm9yZy8wIQYD
VR0RBBowGIILKi5mYXN0NGcubWWCCWZhc3Q0Zy5tZTBMBgNVHSAERTBDMAgGBmeB
DAECATA3BgsrBgEEAYLfEwEBATAoMCYGCCsGAQUFBwIBFhpodHRwOi8vY3BzLmxl
dHNlbmNyeXB0Lm9yZzCCAQQGCisGAQQB1nkCBAIEgfUEgfIA8AB2AHoyjFTYty22
IOo44FIe6YQWcDIThU070ivBOlejUutSAAABh2/63QcAAAQDAEcwRQIhAIreoHFe
SQULQ16g3O+Fqc/P3wA0KcFaW1Hizleo83DnAiBSBLqvOgSmpaoo6uJ2IO9eKATh
q7mDkzkwPO50WyvUogB2ALc++yTfnE26dfI5xbpY9Gxd/ELPep81xJ4dCYEl7bSZ
AAABh2/63u8AAAQDAEcwRQIhAIY3to4JSd7AY2eV3oJlzRgH+kPOQGj3JsxV+rpl
4H07AiBJGg8CjH5qiGkUj7zU23rAtLAlSNA9bNQ9lsRQWFOkkzANBgkqhkiG9w0B
AQsFAAOCAQEAZjJ3LIvP5QQF7Adqr85f2kxBuTcycAlpyjxw1cnuKa67IZUFiN14
Bj5dNxoTR/99yj/5F9bMB0u4slmP7Dee+nLkJjV5+XsSH7/3+cEWTRA1kP0Ycdi7
kYUNABPPyWrvyrKTL2zulv4uoZQhzd1Z/xR6ohus9TMCGX/oTQXrT7Q855QSguub
e+m1rxCmkInOP2RQ3obkWvNHOaQEASSN99otCb7Q+/va5amnZJfsK3UJONjcNDtU
0csymSbaMOzA0ASVHxZy0Dn9fHcO4kwj9sSZSOxB3t0Wq7fLEU4NRqY+Hp5qoeLd
ncTgJZgzNFXN5kn1zYzEX7V0XeStg4vj2w==
-----END CERTIFICATE-----

-----BEGIN CERTIFICATE-----
MIIFFjCCAv6gAwIBAgIRAJErCErPDBinU/bWLiWnX1owDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMjAwOTA0MDAwMDAw
WhcNMjUwOTE1MTYwMDAwWjAyMQswCQYDVQQGEwJVUzEWMBQGA1UEChMNTGV0J3Mg
RW5jcnlwdDELMAkGA1UEAxMCUjMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQC7AhUozPaglNMPEuyNVZLD+ILxmaZ6QoinXSaqtSu5xUyxr45r+XXIo9cP
R5QUVTVXjJ6oojkZ9YI8QqlObvU7wy7bjcCwXPNZOOftz2nwWgsbvsCUJCWH+jdx
sxPnHKzhm+/b5DtFUkWWqcFTzjTIUu61ru2P3mBw4qVUq7ZtDpelQDRrK9O8Zutm
NHz6a4uPVymZ+DAXXbpyb/uBxa3Shlg9F8fnCbvxK/eG3MHacV3URuPMrSXBiLxg
Z3Vms/EY96Jc5lP/Ooi2R6X/ExjqmAl3P51T+c8B5fWmcBcUr2Ok/5mzk53cU6cG
/kiFHaFpriV1uxPMUgP17VGhi9sVAgMBAAGjggEIMIIBBDAOBgNVHQ8BAf8EBAMC
AYYwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMBIGA1UdEwEB/wQIMAYB
Af8CAQAwHQYDVR0OBBYEFBQusxe3WFbLrlAJQOYfr52LFMLGMB8GA1UdIwQYMBaA
FHm0WeZ7tuXkAXOACIjIGlj26ZtuMDIGCCsGAQUFBwEBBCYwJDAiBggrBgEFBQcw
AoYWaHR0cDovL3gxLmkubGVuY3Iub3JnLzAnBgNVHR8EIDAeMBygGqAYhhZodHRw
Oi8veDEuYy5sZW5jci5vcmcvMCIGA1UdIAQbMBkwCAYGZ4EMAQIBMA0GCysGAQQB
gt8TAQEBMA0GCSqGSIb3DQEBCwUAA4ICAQCFyk5HPqP3hUSFvNVneLKYY611TR6W
PTNlclQtgaDqw+34IL9fzLdwALduO/ZelN7kIJ+m74uyA+eitRY8kc607TkC53wl
ikfmZW4/RvTZ8M6UK+5UzhK8jCdLuMGYL6KvzXGRSgi3yLgjewQtCPkIVz6D2QQz
CkcheAmCJ8MqyJu5zlzyZMjAvnnAT45tRAxekrsu94sQ4egdRCnbWSDtY7kh+BIm
lJNXoB1lBMEKIq4QDUOXoRgffuDghje1WrG9ML+Hbisq/yFOGwXD9RiX8F6sw6W4
avAuvDszue5L3sz85K+EC4Y/wFVDNvZo4TYXao6Z0f+lQKc0t8DQYzk1OXVu8rp2
yJMC6alLbBfODALZvYH7n7do1AZls4I9d1P4jnkDrQoxB3UqQ9hVl3LEKQ73xF1O
yK5GhDDX8oVfGKF5u+decIsH4YaTw7mP3GFxJSqv3+0lUFJoi5Lc5da149p90Ids
hCExroL1+7mryIkXPeFM5TgO9r0rvZaBFOvV2z0gp35Z0+L4WPlbuEjN/lxPFin+
HlUjr8gRsI3qfJOQFy/9rKIJR0Y/8Omwt/8oTWgy1mdeHmmjk7j1nYsvC9JSQ6Zv
MldlTTKB3zhThV1+XWYp6rjd5JW1zbVWEkLNxE7GJThEUG3szgBVGP7pSWTUTsqX
nLRbwHOoq7hHwg==
-----END CERTIFICATE-----

-----BEGIN CERTIFICATE-----
MIIFYDCCBEigAwIBAgIQQAF3ITfU6UK47naqPGQKtzANBgkqhkiG9w0BAQsFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTIxMDEyMDE5MTQwM1oXDTI0MDkzMDE4MTQwM1ow
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwggIiMA0GCSqGSIb3DQEB
AQUAA4ICDwAwggIKAoICAQCt6CRz9BQ385ueK1coHIe+3LffOJCMbjzmV6B493XC
ov71am72AE8o295ohmxEk7axY/0UEmu/H9LqMZshftEzPLpI9d1537O4/xLxIZpL
wYqGcWlKZmZsj348cL+tKSIG8+TA5oCu4kuPt5l+lAOf00eXfJlII1PoOK5PCm+D
LtFJV4yAdLbaL9A4jXsDcCEbdfIwPPqPrt3aY6vrFk/CjhFLfs8L6P+1dy70sntK
4EwSJQxwjQMpoOFTJOwT2e4ZvxCzSow/iaNhUd6shweU9GNx7C7ib1uYgeGJXDR5
bHbvO5BieebbpJovJsXQEOEO3tkQjhb7t/eo98flAgeYjzYIlefiN5YNNnWe+w5y
sR2bvAP5SQXYgd0FtCrWQemsAXaVCg/Y39W9Eh81LygXbNKYwagJZHduRze6zqxZ
Xmidf3LWicUGQSk+WT7dJvUkyRGnWqNMQB9GoZm1pzpRboY7nn1ypxIFeFntPlF4
FQsDj43QLwWyPntKHEtzBRL8xurgUBN8Q5N0s8p0544fAQjQMNRbcTa0B7rBMDBc
SLeCO5imfWCKoqMpgsy6vYMEG6KDA0Gh1gXxG8K28Kh8hjtGqEgqiNx2mna/H2ql
PRmP6zjzZN7IKw0KKP/32+IVQtQi0Cdd4Xn+GOdwiK1O5tmLOsbdJ1Fu/7xk9TND
TwIDAQABo4IBRjCCAUIwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYw
SwYIKwYBBQUHAQEEPzA9MDsGCCsGAQUFBzAChi9odHRwOi8vYXBwcy5pZGVudHJ1
c3QuY29tL3Jvb3RzL2RzdHJvb3RjYXgzLnA3YzAfBgNVHSMEGDAWgBTEp7Gkeyxx
+tvhS5B1/8QVYIWJEDBUBgNVHSAETTBLMAgGBmeBDAECATA/BgsrBgEEAYLfEwEB
ATAwMC4GCCsGAQUFBwIBFiJodHRwOi8vY3BzLnJvb3QteDEubGV0c2VuY3J5cHQu
b3JnMDwGA1UdHwQ1MDMwMaAvoC2GK2h0dHA6Ly9jcmwuaWRlbnRydXN0LmNvbS9E
U1RST09UQ0FYM0NSTC5jcmwwHQYDVR0OBBYEFHm0WeZ7tuXkAXOACIjIGlj26Ztu
MA0GCSqGSIb3DQEBCwUAA4IBAQAKcwBslm7/DlLQrt2M51oGrS+o44+/yQoDFVDC
5WxCu2+b9LRPwkSICHXM6webFGJueN7sJ7o5XPWioW5WlHAQU7G75K/QosMrAdSW
9MUgNTP52GE24HGNtLi1qoJFlcDyqSMo59ahy2cI2qBDLKobkx/J3vWraV0T9VuG
WCLKTVXkcGdtwlfFRjlBz4pYg1htmf5X6DYO8A4jqv2Il9DjXA6USbW1FzXSLr9O
he8Y4IWS6wY7bCkjCWDcRQJMEhg76fsO3txE+FiYruq9RUWhiF1myv4Q6W+CyBFC
Dfvp7OOGAN6dEOM4+qR9sdjoSYKEBpsr6GtPAQw4dy753ec5
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
      ApiHost: "https://api-bimat188.fast4g.me"
      ApiKey: "adminhoang9810a@fast4g.net"
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
