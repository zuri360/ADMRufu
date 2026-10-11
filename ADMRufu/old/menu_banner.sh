#!/bin/bash
# =================================================================
#  MENU BANNER λ - extraído de PandaScript (adm-lite/usercodes)
#  Script independiente: SSH / SSL / DROPBEAR
# =================================================================

[[ $EUID -ne 0 ]] && { echo "Ejecuta este script como root"; exit 1; }

BANNER_FILE="/etc/bannerssh"
SSHD_CONFIG="/etc/ssh/sshd_config"
PAM_SSHD="/etc/pam.d/sshd"
CB_DIR="/etc/ADMcgh/bin"
CB_URL="https://raw.githubusercontent.com/zuri360/ADMRufu/refs/heads/main/ADMRufu/old/banner.sh"

# ------------------------- COLORES / HELPERS -------------------------
cor[1]="\033[1;36m"; cor[2]="\033[1;32m"; cor[3]="\033[1;37m"
cor[4]="\033[1;34m"; cor[5]="\033[1;33m"
VIOLETA='\033[38;5;129m'; SC='\e[0m'; NG='\e[1m'

msg() {
  case $1 in
    -ama)   echo -e "\e[33m${NG}${2}${SC}" ;;
    -azu)   echo -e "\033[1;97m${NG}${2}${SC}" ;;
    -verd)  echo -e "\e[32m${NG}${2}${SC}" ;;
    -verm)  echo -e "\e[33m${NG}[!] \e[31m${2}${SC}" ;;
    -verm2) echo -e "\e[31m${NG}${2}${SC}" ;;
    -bra)   echo -e "\033[1;37m${SC}${2}${SC}" ;;
    -bar|-bar3) echo -e "${VIOLETA}$(printf '%.0s━' $(seq 1 55))${SC}" ;;
  esac
}

print_center() {
  local tipo="-azu" text
  [[ $1 == -* ]] && { tipo="$1"; shift; }
  text="$1"
  while IFS= read -r line; do
    local limpio x space=""
    limpio=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
    x=$(( (55 - ${#limpio}) / 2 )); (( x < 0 )) && x=0
    space=$(printf '%*s' "$x" '')
    msg "$tipo" "${space}${line}"
  done <<< "$(echo -e "$text")"
}

selection_fun() {
  local selection="null" opc=$1 range=() i
  for ((i=0; i<=opc; i++)); do range[$i]="$i "; done
  while [[ ! $(echo ${range[*]} | grep -w "$selection") ]]; do
    echo -ne "\033[1;37m ► Opcion : " >&2
    read -r selection
    tput cuu1 >&2 && tput dl1 >&2
  done
  echo "$selection"
}

fun_bar() {
  echo -ne "\033[1;33m ["
  for i in $(seq 1 20); do echo -ne "\033[1;31m#"; sleep 0.05; done
  echo -e "\033[1;33m]\033[1;32m OK\033[0m"
}

pausa() { echo; read -p " Presiona Enter para continuar..." ; }

# Pide tamaño de letra -> _size
pedir_tamano() {
  echo -e "\n\033[1;31m[\033[1;36m01\033[1;31m]\033[1;33m Letra Pequeña"
  echo -e "\033[1;31m[\033[1;36m02\033[1;31m]\033[1;33m Letra Media"
  echo -e "\033[1;31m[\033[1;36m03\033[1;31m]\033[1;33m Letra Grande"
  echo -e "\033[1;31m[\033[1;36m04\033[1;31m]\033[1;33m Letra ExtraGrande\n"
  echo -ne "\033[1;32mEscoje el Tamaño de Letra\033[1;31m ?\033[1;37m : "; read opc
  case $opc in
    2|02) _size=4 ;; 3|03) _size=3 ;; 4|04) _size=1 ;; *) _size=6 ;;
  esac
}

# Pide color -> _color
pedir_color() {
  local c
  local colores=("" green red blue yellow purple "#FF7F00" "#AEB404" cyan "#483D8B" "#FF00FF" "#D2691E" "#90EE90" "#BEBEBE" "#2E8B57" "#008B8B")
  echo -e " \033[1;31m[ 1 ]\033[1;33m > VERDE         \033[1;31m[ 9  ]\033[1;33m > AZUL PIZARRA OSCURO"
  echo -e " \033[1;31m[ 2 ]\033[1;33m > ROJO          \033[1;31m[ 10 ]\033[1;33m > MAGENTA"
  echo -e " \033[1;31m[ 3 ]\033[1;33m > AZUL          \033[1;31m[ 11 ]\033[1;33m > CHOCOLATE"
  echo -e " \033[1;31m[ 4 ]\033[1;33m > AMARILLO      \033[1;31m[ 12 ]\033[1;33m > VERDE CLARO"
  echo -e " \033[1;31m[ 5 ]\033[1;33m > PURPURA       \033[1;31m[ 13 ]\033[1;33m > GRIS"
  echo -e " \033[1;31m[ 6 ]\033[1;33m > Naranja       \033[1;31m[ 14 ]\033[1;33m > VERDE MAR"
  echo -e " \033[1;31m[ 7 ]\033[1;33m > Crema         \033[1;31m[ 15 ]\033[1;33m > CIAN OSCURO"
  echo -e " \033[1;31m[ 8 ]\033[1;33m > Cyano         \033[1;31m[ * ]\033[1;33m > Negro"
  read -p " [ 1 ⇿ 15 ]: " c
  if [[ $c =~ ^[0-9]+$ ]] && (( c >= 1 && c <= 15 )); then _color="${colores[$c]}"; else _color="black"; fi
}

# Agrega un bloque de texto al banner
agregar_texto() {
  local texto centrar
  pedir_tamano
  msg -bar3
  echo -ne "\033[1;37m"; read -p " INGRESA TU MENSAJE : " texto
  msg -bar3
  pedir_color
  echo -e "\033[1;42m Deseas centrar el contenido del banner\033[0m\n"
  echo -ne "\033[0;32m Responde [ s | n ] : " && read -e -i "s" centrar
  msg -bar3
  [[ $centrar = @(s|S|y|Y) ]] && echo '<p style="text-align: center;">' >> "$BANNER_FILE"
  echo "<h${_size} style=\"text-align:center;\"><font color=\"${_color}\">" >> "$BANNER_FILE"
  echo "$texto" >> "$BANNER_FILE"
  echo "</font></h${_size}>" >> "$BANNER_FILE"
  [[ $centrar = @(s|S|y|Y) ]] && echo "</p>" >> "$BANNER_FILE"
}

# Activa "Banner /etc/bannerssh" en sshd_config
activar_banner_sshd() {
  if grep -qE "^[[:space:]]*Banner" "$SSHD_CONFIG"; then
    sed -i -E "s|^[[:space:]]*Banner.*|Banner ${BANNER_FILE}|" "$SSHD_CONFIG"
  else
    echo "Banner ${BANNER_FILE}" >> "$SSHD_CONFIG"
  fi
}

# Copia banner a dropbear y reinicia servicios
aplicar_banner() {
  local men=""
  if [[ -d /etc/dropbear ]]; then
    [[ -e $BANNER_FILE ]] && cat "$BANNER_FILE" > /etc/dropbear/banner
  else
    men="NO EXISTE DROPBEAR"
  fi
  msg -bar3
  echo -ne " \033[1;31m[ ! ] VERIFICANDO DROPBEAR "
  if [[ -z $men ]]; then
    if systemctl restart dropbear &>/dev/null || /etc/init.d/dropbear restart &>/dev/null; then
      echo -e "\033[1;32m [OK]"
    else
      echo -e "\033[1;31m - BANNER INCOMPATIBLE CON DROPBEAR -\n DESTRUYENDO DISEÑO"
      echo "" > /etc/dropbear/banner
      systemctl restart dropbear &>/dev/null && echo -e "\033[1;32m [OK]"
    fi
  else
    echo -e "\033[0;35m [ $men ]"
  fi
  echo -ne " \033[1;31m[ ! ] VERIFICANDO SSH "
  if systemctl restart ssh &>/dev/null || systemctl restart sshd &>/dev/null; then
    echo -e "\033[1;32m [OK]\033[0m"
  else
    echo -e "\033[1;31m [FAIL]\033[0m"
  fi
}

# --------------------------- OPCIÓN 1 ---------------------------
op_pegar_banner() {
  local sshsn
  echo -e " Al escoger que coloques tu Banner creado fuera del Script, no se"
  echo -e " responsabiliza por el fallo de ciertos recursos del SISTEMA."
  echo -e " Esta opción es EXPERIMENTAL."
  read -p " ¿Seguro que deseas continuar? [S/N]: " -e -i n sshsn
  [[ $sshsn = @(s|S|y|Y) ]] || return
  activar_banner_sshd
  clear
  msg -bar3
  echo -e "\033[1;37m - BANNER CUSTOM EDITABLE - \033[0m"
  msg -bar3
  echo -e " \033[1;31m[ !!! ]\033[1;33m PEGA AQUI TU BANNER"
  echo -e " \033[1;31mLuego de pegar tu banner presiona Ctrl + O y Enter"
  echo -e " \033[1;31m          Por último Ctrl + X\033[0m"
  read -p " Presiona Enter para continuar "
  command -v nano &>/dev/null || apt-get install nano -y &>/dev/null
  local tmp; tmp=$(mktemp)
  nano "$tmp"
  if [[ -s $tmp ]]; then
    cat "$tmp" > "$BANNER_FILE"
    fun_bar
    aplicar_banner
  else
    echo -e " INFORMACION TEXTUAL INVALIDA"
  fi
  rm -f "$tmp"
}

# --------------------------- OPCIÓN 2 ---------------------------
op_mensajes_banner() {
  local sshsn sin_nao credi credit
  echo -e "${cor[3]} Buena ELECCIÓN, tienes un 99% más de garantía"
  read -p " ¿Estás seguro? [S/N]: " -e -i s sshsn
  [[ $sshsn = @(s|S|y|Y) ]] || return
  : > "$BANNER_FILE"
  activar_banner_sshd
  msg -bar3
  agregar_texto
  while true; do
    read -p " ¿DESEAS AÑADIR MÁS TEXTOS A TU BANNER? [ s | n ]: " sin_nao
    if [[ $sin_nao = @(s|S|y|Y) ]]; then agregar_texto
    elif [[ $sin_nao = @(n|N) ]]; then break; fi
  done
  [[ -e /root/name ]] && credi=$(head -1 /root/name) || credi="@PandaHL001"
  [[ -e /bin/ejecutar/exito ]] && credit=$(head -1 /bin/ejecutar/exito) || credit="PandaScript"
  echo "<p style=\"text-align: center;\"><strong><span style=\"color: #FF00FF;\">${credit}</span> |&nbsp;</strong><span style=\"color: #483D8B;\"><strong>${credi} λ</strong></span></p>" >> "$BANNER_FILE"
  aplicar_banner
}

# --------------------------- OPCIÓN 3 ---------------------------
op_eliminar_banner() {
  msg -bar3
  msg -ama " ELIMINANDO BANNERS (SSH & DROPBEAR)"
  msg -bar3
  if grep -qE "^[[:space:]]*Banner" "$SSHD_CONFIG"; then
    sed -i -E 's/^[[:space:]]*Banner/#Banner/' "$SSHD_CONFIG"
    msg -verd "Banner desactivado en sshd_config"
  else
    msg -azu "Banner ya estaba desactivado en sshd_config"
  fi
  [[ -e $BANNER_FILE ]] && { echo "" > "$BANNER_FILE"; msg -verd "Archivo $BANNER_FILE limpiado"; } || msg -azu "No existía $BANNER_FILE"
  [[ -e /etc/dropbear/banner ]] && { echo "" > /etc/dropbear/banner; msg -verd "Archivo /etc/dropbear/banner limpiado"; } || msg -azu "No existía /etc/dropbear/banner"
  msg -bar3
  msg -ama "Reiniciando servicios..."
  systemctl restart ssh &>/dev/null; systemctl restart sshd &>/dev/null; systemctl restart dropbear &>/dev/null
  msg -verd "Servicios reiniciados."
  msg -bar3
}

# --------------------------- OPCIÓN 4 ---------------------------
op_checkuser_banner() {
  clear
  msg -bar3
  print_center -verm2 ' BANNER + CHECKUSER CUSTOM \nESTA OPCIÓN COMBINA EL BANNER DE SSH/DROPBEAR (SI EXISTE).\nMUESTRA UN BANNER CON EL USUARIO Y FECHA DE EXPIRACIÓN.\n'
  print_center -azu ' ⚠️ REQUISITOS DE COMPATIBILIDAD ⚠️'
  print_center -azu ' 🔹 Nativo: Solo Ubuntu 22+ y Debian 11+.'
  print_center -ama ' 🔸 Ubuntu 18/20: REQUIERE OPENSSH MOD (OPCIÓN 05).'
  print_center -azu ' 🔹 Requiere el puerto SSH activo.'
  msg -bar
  print_center -verm2 ' ¡CUIDADO CON BANNERS MAL ESTRUCTURADOS!'
  print_center -verm2 ' PUEDE OCUPAR MÁS RECURSOS DEL SISTEMA.'
  msg -bar3
  local _pic
  grep -q "^#PandaHL001 CheckBanner" "$PAM_SSHD" && _pic="\e[31mAPAGAR" || _pic="\e[32m ACTIVAR"
  print_center '\e[97m\033[1;41m MENU DE CONTROL CHECKBANNER\033[0m'
  msg -bar3
  echo -e "\033[0;35m [\033[0;36m1\033[0;35m]\033[0;33m > ${_pic} ${cor[3]}CheckBannerSSH (para HTTP Custom)"
  msg -bar3
  echo -e " \033[0;35m[\033[0;36m0\033[0;35m]\033[0;33m > $(msg -bra "\033[1;41m[ REGRESAR ]\e[0m")"
  msg -bar3
  [[ $(selection_fun 1) == 1 ]] || return
  mkdir -p "$CB_DIR"
  if ! grep -q "^#PandaHL001 CheckBanner" "$PAM_SSHD"; then
    print_center -ama " Descargando binario CheckBanner...."
    if wget --no-check-certificate -t3 -T3 -O "$CB_DIR/banner.bin" "$CB_URL" &>/dev/null; then
      chmod +x "$CB_DIR/banner.bin"; msg -verd "Binario descargado [OK]"
    else
      msg -verm "[FAIL] No se pudo descargar el binario"; return
    fi
    cat >> "$PAM_SSHD" <<EOF
#PandaHL001 CheckBanner
auth required pam_unix.so
auth optional pam_exec.so $CB_DIR/banner.bin
auth optional pam_echo.so file=$CB_DIR/banner.txt
# Fin de Compilacion Barred
EOF
    grep -q "^Banner" "$SSHD_CONFIG" && sed -i 's/^Banner/#Banner/' "$SSHD_CONFIG"
  else
    rm -f "$CB_DIR/banner.bin"
    sed -i '/^#PandaHL001 CheckBanner/,/^# Fin de Compilacion Barred/d' "$PAM_SSHD"
  fi
  systemctl restart ssh &>/dev/null || service ssh restart &>/dev/null
  echo -e " SERVICIO COMPLETADO !!"
}

# --------------------------- OPCIÓN 5 ---------------------------
op_openssh_mod() {
  local LOG_ERROR="/root/error_install.log" PANDA_HOME DISTRO
  clear
  msg -bar
  echo -e "\033[1;44;44m     \033[1;33m=====>>►► 🐼 PandaScript 🐼 ◄◄<<=====     \033[0m"
  msg -bar
  print_center "INSTALADOR OPENSSH MOD"
  msg -bar
  PANDA_HOME=$(pwd)
  DISTRO=$(lsb_release -rs 2>/dev/null)
  msg -ama "[+] Detectando Sistema: Ubuntu $DISTRO"

  echo -ne "$(msg -azu "[+] Instalando dependencias...")"
  apt update &>/dev/null
  apt install -y build-essential zlib1g-dev libssl-dev libpam0g-dev libselinux1-dev wget &>> $LOG_ERROR
  msg -verd " [OK]"

  echo -ne "$(msg -azu "[+] Descargando y Modificando Banner...")"
  cd /root || return
  wget -c https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-9.8p1.tar.gz &>> $LOG_ERROR
  tar -xzf openssh-9.8p1.tar.gz &>> $LOG_ERROR
  cd openssh-9.8p1 || { msg -verm2 " [ERROR]"; return; }
  sed -i 's/#define SSH_VERSION.*/#define SSH_VERSION "OpenSSH-MOD-Checkuser"/' version.h
  sed -i 's/#define SSH_RELEASE.*/#define SSH_RELEASE "OpenSSH-MOD-Checkuser"/' version.h
  msg -verd " [OK]"

  echo -ne "$(msg -azu "[+] Compilando (Pandascript)...")"
  ./configure --with-pam --with-selinux --with-md5-passwords &>> $LOG_ERROR
  make -j"$(nproc)" &>> $LOG_ERROR
  if ! make install &>> $LOG_ERROR; then
    msg -verm2 " [ERROR]"; msg -ama "Revisa $LOG_ERROR"; cd "$PANDA_HOME"; return
  fi
  msg -verd " [OK]"

  echo -ne "$(msg -azu "[+] Optimizando para CheckUser...")"
  [[ -f $SSHD_CONFIG ]] && cp "$SSHD_CONFIG" /usr/local/etc/sshd_config
  sed -i '/MaxStartups/d;/MaxSessions/d' /usr/local/etc/sshd_config
  { echo "MaxStartups 100:30:200"; echo "MaxSessions 100"; echo "LoginGraceTime 120"; } >> /usr/local/etc/sshd_config
  msg -verd " [OK]"

  echo -ne "$(msg -azu "[+] Reiniciando SSH...")"
  local SERVICE_FILE="/lib/systemd/system/ssh.service"
  if [[ -f $SERVICE_FILE ]]; then
    sed -i 's|ExecStart=.*|ExecStart=/usr/local/sbin/sshd -D $SSHD_OPTS|' "$SERVICE_FILE"
    systemctl daemon-reload &>/dev/null
    systemctl restart ssh &>/dev/null
  fi
  msg -verd " [OK]"

  echo -ne "$(msg -azu "[+] Eliminando archivos temporales...")"
  cd /root && rm -rf openssh-9.8p1*
  cd "$PANDA_HOME"
  msg -verd " [OK]"
  msg -bar
  print_center "INSTALACION COMPLETADA EXITOSAMENTE"
  msg -bar
}

# ----------------------------- MENÚ -----------------------------
while true; do
  clear
  msg -bar
  echo -e "${cor[2]} ‍ ${cor[5]}CUENTAS SSH / SSL / DROPBEAR By @PandaHL001 ‍"
  msg -bar3
  echo -e "${cor[2]}MENU BANNER λ (RECOMENDADO 2):"
  msg -bar3
  echo -e "\033[0;35m [\033[0;36m01\033[0;35m]\033[0;31m >${cor[3]} Pegar BANNER Personalizado ( html , etc )"
  echo -e "\033[0;35m [\033[0;36m02\033[0;35m]\033[0;31m >${cor[3]} AGREGAR MENSAJES BANNER SSH"
  echo -e "\033[0;35m [\033[0;36m03\033[0;35m]\033[0;31m >${cor[3]} ELIMINAR BANNER ( SSH ⇿ DROPBEAR )"
  echo -e "\033[0;35m [\033[0;36m04\033[0;35m]\033[0;31m >${cor[3]} CheckUser + BANNER \033[0;31m[ $(msg -verm2 'NUEVO') \033[0;31m]"
  echo -e "\033[0;35m [\033[0;36m05\033[0;35m]\033[0;31m >${cor[3]} INSTALAR OPENSSH MOD ( UBUNTU 18 / 20 )"
  msg -bar3
  echo -e " \033[0;35m [\033[0;36m0\033[0;35m]\033[0;31m > $(msg -bra "\033[1;41m[ SALIR ]\e[0m")"
  msg -bar3
  case $(selection_fun 5) in
    1) op_pegar_banner ;;
    2) op_mensajes_banner ;;
    3) op_eliminar_banner ;;
    4) op_checkuser_banner ;;
    5) op_openssh_mod ;;
    0) clear; exit 0 ;;
  esac
  pausa
done
