#!/bin/bash
# =====================================================================
#  UDP-ZIVPN (ZipVPN)  -  gestor standalone
#  Desofuscado del panel LACASITAMX. Solo Ubuntu 20+.
#  Auth = usuarios SSH del sistema | Puerto base 5667 | Rango 6000:19999
# =====================================================================
[[ "$(id -u)" != "0" ]] && { echo "Ejecutá como root (sudo -i)"; exit 1; }

VERD='\e[1;32m'; AMA='\e[1;93m'; VERM='\e[1;91m'; AZU='\e[1;36m'; BLA='\e[1;37m'; NC='\e[0m'
BAR='\e[1;30m────────────────────────────────────────────────────────\e[0m'
TIT='\e[91m≋≋≋≋≋≋  U D P - Z I V P N  ≋≋≋≋≋≋\e[0m'
IP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null)

CFG="/etc/zivpn/config.json"
LINKB='https://raw.githubusercontent.com/lacasitamx/BIN/main/BINARIOS/UDP/ZipVPN/udp-x64_v1.bin'
LINKAUTH='https://github.com/lacasitamx/UDP/raw/main/autSSH'

instalaziv(){
  if [[ -e /usr/local/bin/zivpn || -e /bin/ZipVPN ]]; then
    echo -e "${AMA}\tEL SERVICIO UDP ZIPVPN YA ESTA ACTIVO${NC}"; return
  fi
  echo -e "Downloading Service"
  mkdir -p /etc/zivpn

  echo "Generando certificados:"
  openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" \
    -keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt" &>/dev/null

  sysctl -w net.core.rmem_max=16777216 &>/dev/null
  sysctl -w net.core.wmem_max=16777216 &>/dev/null

  echo -e "${AMA}     COMPILANDO BINARIO DE AUTENTIFICACION SSH V2${NC}"
  wget -O /bin/authSSH "$LINKAUTH" &>/dev/null && { chmod +x /bin/authSSH; echo -e "${VERD} OK${NC}"; } \
    || { echo -e "${VERM} FAIL${NC}"; rm -rf /bin/authSSH; }

  echo -e "${AMA}\tDESCARGANDO BIN V2.0${NC}"
  wget -O /bin/ZipVPN "$LINKB" &>/dev/null && { chmod +x /bin/ZipVPN; echo -e "${VERD} OK${NC}"; } \
    || { echo -e "${VERM} FAIL${NC}"; rm -f /bin/ZipVPN; }

  # datos informativos
  {
    echo " IP : $IP"
    echo " Usuarios SSH del sistema !!"
    echo " PUERTO : 5667"
    echo " RANGO DE PUERTO: 6000:19999"
    echo " OBFS: lacasita"
    echo " RECUERDA UTILIZAR USUARIO Y CLAVE SSH"
    echo " FORMATO SSH EN APP : miusuario"
    echo -e " \n \tZipvpn"
  } > /etc/zivpn/data

  echo -e "${AMA}\tDESCARGANDO CONFIG${NC}"
  cat > "$CFG" <<EOF
{
  "listen": ":5667",
   "cert": "/etc/zivpn/zivpn.crt",
   "key": "/etc/zivpn/zivpn.key",
   "obfs":"lacasita",
	"auth": {
    "mode": "external",
    "config": {
      "cmd": "/bin/authSSH"
    }
  }
}
EOF
  chmod +x "$CFG"
  echo -e "${VERD} OK${NC}"

  cat > /etc/systemd/system/zivpn.service <<EOF
[Unit]
Description=ZipVPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/bin/ZipVPN -config /etc/zivpn/config.json server
Restart=always
RestartSec=3
Environment="PATH=/etc/zivpn:/usr/bin:/bin"
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload &>/dev/null
  systemctl enable zivpn  &>/dev/null
  systemctl start  zivpn  &>/dev/null

  # NAT: reenvía rango 6000:19999 al puerto 5667
  IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
  iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
  ufw allow 6000:19999/udp &>/dev/null
  ufw allow 5667/udp &>/dev/null

  clear
  echo -e "$BAR"; echo -e "${AMA}\tCONFIGURACION DE DATOS${NC}\n"
  cat /etc/zivpn/data
  echo -e "$BAR"
  echo -e "${VERD}SERVICIO UDP-ZIPVPN INICIADO EXITOSAMENTE${NC}"
  echo -e "${BLA}RECUERDA CREAR UN USUARIO SSH PARA TU CONEXION!!!${NC}"
}

modificar_puerto(){
  echo -e "$BAR\n${AMA}INGRESE EL NUEVO PUERTO DE SERVICIO${NC}"
  read -p " PUERTO : " _col
  _PA=$(grep 'listen' "$CFG" | cut -d'"' -f4 | cut -d':' -f2)
  [[ ${_col} ]] && {
    sed -i "s/${_PA}/${_col}/" "$CFG"
    sed -i "s/${_PA}/${_col}/" /etc/zivpn/data
    systemctl restart zivpn &>/dev/null
    echo -e "${AMA}\tPUERTO NUEVO: $_col${NC}"
  }
}

modificar_obfs(){
  echo -e "$BAR\n${AMA}INGRESE SU NUEVO OBFS${NC}"
  read -p " OBFS : " _col
  _obfs=$(grep 'obfs' "$CFG" | cut -d'"' -f4)
  [[ ${_col} ]] && {
    sed -i "s/${_obfs}/${_col}/" "$CFG"
    sed -i "s/${_obfs}/${_col}/" /etc/zivpn/data
    systemctl restart zivpn &>/dev/null
    echo -e "${AMA}\tOBFS MODIFICADO: $_col${NC}"
  }
}

detener(){
  systemctl stop    zivpn &>/dev/null
  systemctl disable zivpn &>/dev/null
  rm -rf /etc/systemd/system/zivpn.service /bin/ZipVPN /etc/zivpn
  echo -e "${AMA}\tSERVICIO DETENIDO${NC}"
}

reiniciar(){ systemctl restart zivpn &>/dev/null; echo -e "${AMA}\tSERVICIO Reiniciado${NC}"; }
datos(){ [[ -e /etc/zivpn/data ]] && cat /etc/zivpn/data || echo -e "${VERM}[No Instalado]${NC}"; }

menu_ziv(){
  while true; do
    clear
    echo -e "$TIT"
    [[ $(ps x | grep zivpn | grep -v grep) ]] && ziv="${VERD}[ON]${NC}" || ziv="${VERM}[OFF]${NC}"
    if [[ $(ps x | grep zivpn | grep -v grep) ]]; then
      o=$(sed -n '5 p' /etc/zivpn/data | cut -d':' -f2)
      por=$(sed -n '3 p' /etc/zivpn/data | cut -d':' -f2)
      echo -e "${AMA}  IP: ${VERD}$IP${NC}"
      echo -e "${AMA}  OBFS:${VERD}$o${NC}"
      echo -e "${AMA}  RANGO DE PUERTO:${VERD}6000:19999${NC}"
      echo -e "${AMA}  PUERTO UDP:$por${NC}"
    else
      echo -e "${VERM}  [No Instalado]${NC}"
    fi
    echo -e "$BAR"
    echo -e " ${AMA}[${VERD}1${AMA}]${VERM} > ${VERD} INSTALAR UDP-ZIVPN $ziv${NC}"
    echo -e " ${AMA}[${VERD}2${AMA}]${VERM} > ${AMA} MODIFICAR PUERTO${NC}"
    echo -e " ${AMA}[${VERD}3${AMA}]${VERM} > ${AMA} MODIFICAR OBFS${NC}"
    echo -e "$BAR"
    echo -e " ${AMA}[${VERD}4${AMA}]${VERM} > ${VERM} DETENER UDP-ZIVPN${NC}"
    echo -e " ${AMA}[${VERD}5${AMA}]${VERM} > ${AMA} REINICIAR SERVICIO${NC}"
    echo -e " ${AMA}[${VERD}6${AMA}]${VERM} > ${BLA} DATOS DEL SERVICIO${NC}"
    echo -e "$BAR"
    echo -e " ${AMA}[${VERD}0${AMA}]${VERM} > ${BLA} VOLVER / SALIR${NC}"
    echo -e "$BAR"
    echo -ne "${BLA}Digite Una Opcion: ${NC}"
    read opcao
    case $opcao in
      1) instalaziv ;;
      2) modificar_puerto ;;
      3) modificar_obfs ;;
      4) detener ;;
      5) reiniciar ;;
      6) datos ;;
      0) exit 0 ;;
    esac
    echo -e "\n${BLA}Enter para continuar...${NC}"; read
  done
}
menu_ziv
