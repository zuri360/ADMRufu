#!/bin/bash
# =================================================================
#  MENU BANNER λ - extraído de PandaScript (adm-lite/usercodes)
#  Script independiente: SSH / SSL / DROPBEAR
# =================================================================

[[ $EUID -ne 0 ]] && { echo "Ejecuta este script como root"; exit 1; }

BANNER_FILE="/etc/bannerssh"
SSHD_CONFIG="/etc/ssh/sshd_config"

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
    -bar|-bar2) echo -e "\e[31m======================================================\e[0m" ;;
    -bar3)      echo -e "\e[31m------------------------------------------------------\e[0m" ;;
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
# Instalador Dropbear (dropbear.sh integrado). Corre en un subshell
# para que sus "exit" no cierren el menú. Si ya está instalado, lo remueve.
op_instalar_dropbear() { (
# ---------- colores / msg (reemplaza la dependencia de Otros/msg) ----------
ROJO='\e[31m'; VERDE='\e[32m'; AMARILLO='\e[33m'; BLANCO='\033[1;37m'
VIOLETA='\033[38;5;129m'; NEG='\e[1m'; SC='\e[0m'

msg() {
  case $1 in
    -ne)    echo -ne "${ROJO}${NEG}${2}${SC}" ;;
    -ama)   echo -e  "${AMARILLO}${NEG}${2}${SC}" ;;
    -verm2) echo -e  "${ROJO}${NEG}${2}${SC}" ;;
    -verd)  echo -e  "${VERDE}${NEG}${2}${SC}" ;;
    -bra)   echo -e  "${BLANCO}${2}${SC}" ;;
    -bar)   echo -e  "\e[31m======================================================\e[0m" ;;
    *)      echo -e  "$2" ;;
  esac
}

# ---------- requisitos ----------
[[ $EUID -ne 0 ]] && { msg -verm2 "Ejecuta este script como root."; exit 1; }

# ---------- banner ----------
create_banner() {
  # Sin banner por defecto: si ya creaste uno en el menú de banners
  # (/etc/bannerssh) se reutiliza; si no, queda vacío.
  mkdir -p /etc/dropbear
  if [[ -s "$BANNER_FILE" ]]; then
    cat "$BANNER_FILE" > /etc/dropbear/banner
  else
    : > /etc/dropbear/banner
  fi
}

# ---------- /etc/shells (parte útil de fun_log) ----------
# Dropbear rechaza usuarios cuyo shell no está en /etc/shells,
# y los usuarios VPN suelen tener /bin/false o /usr/sbin/nologin.
fix_shells() {
  grep -qx "/bin/false" /etc/shells        || echo "/bin/false"        >> /etc/shells
  grep -qx "/usr/sbin/nologin" /etc/shells || echo "/usr/sbin/nologin" >> /etc/shells
}

# ---------- desinstalar ----------
remover_dropbear() {
  clear
  msg -bar
  msg -verd "REMOVIENDO DROPBEAR"
  systemctl stop dropbear &>/dev/null
  systemctl disable dropbear &>/dev/null
  apt-get remove dropbear -y &>/dev/null
  rm -f /etc/systemd/system/dropbear.service /etc/default/dropbear /etc/default/dadd
  rm -f /usr/local/sbin/dropbear /usr/local/bin/dropbearkey /usr/local/bin/dropbearconvert /usr/local/bin/dbclient /usr/local/bin/scp 2>/dev/null
  rm -rf /etc/dropbear
  systemctl daemon-reload &>/dev/null
  msg -verd "Dropbear Removido"
  msg -bar
  exit 0
}

[[ -e /etc/default/dropbear ]] && remover_dropbear

# ---------- pedir puerto ----------
clear
msg -bar
msg -ama "=== INSTALADOR DROPBEAR ==="
msg -bar
msg -verd "INSTALADOR DROPBEAR"
while true; do
  msg -ne "Digite un Puerto: "
  read -r DPORT
  if ! [[ "$DPORT" =~ ^[0-9]+$ ]] || (( DPORT < 1 || DPORT > 65535 )); then
    msg -verm2 "Puerto inválido. Ingrese un número entre 1 y 65535."
  elif [[ "$DPORT" == "22" ]]; then
    msg -verm2 "El puerto 22 no está permitido. Ingrese otro puerto."
  elif ss -tnlp | grep -qE ":${DPORT}\b"; then
    msg -verm2 "[ ! ] El puerto $DPORT ya está en uso. Elija otro."
  else
    break
  fi
done

# Mostrar puertos SSH activos
for port in $(ss -tnlp | grep sshd | awk '{print $4}' | awk -F: '{print $NF}' | sort -u); do
  echo -e "${AMARILLO}${NEG}Puerto SSH Activo: ${VERDE}${port}${SC}"
done

create_banner &>/dev/null
read -rp "Presiona Enter para Continuar"
clear
msg -bar
msg -bra "› Preparando Instalación, Espere un Momento"
fix_shells

# ---------- compilar Dropbear 2019.78 ----------
msg -bra "› Instalando Dropbear 2019.78"
apt-get update &>/dev/null
apt-get install -y build-essential zlib1g-dev wget bzip2 &>/dev/null \
  || { msg -verm2 "[FAIL] No se pudieron instalar dependencias"; exit 1; }
wget -q https://matt.ucc.asn.au/dropbear/releases/dropbear-2019.78.tar.bz2 -O /tmp/dropbear-2019.78.tar.bz2 \
  || { msg -verm2 "[FAIL] No se pudo descargar Dropbear"; exit 1; }
tar xjf /tmp/dropbear-2019.78.tar.bz2 -C /tmp
if ! ( cd /tmp/dropbear-2019.78 && ./configure --enable-wtmp --enable-utmp &>/dev/null && make &>/dev/null && make install &>/dev/null ); then
  msg -verm2 "[FAIL] Error al compilar Dropbear"
  rm -rf /tmp/dropbear-2019.78 /tmp/dropbear-2019.78.tar.bz2
  exit 1
fi
rm -rf /tmp/dropbear-2019.78 /tmp/dropbear-2019.78.tar.bz2

# ---------- claves ----------
msg -bra "› Generando claves para Dropbear"
mkdir -p /etc/dropbear
for t in rsa dss ecdsa; do
  [[ -e /etc/dropbear/dropbear_${t}_host_key ]] || dropbearkey -t $t -f /etc/dropbear/dropbear_${t}_host_key &>/dev/null
done

# ---------- configuración ----------
echo "$DPORT" > /etc/default/dadd
cat > /etc/default/dropbear <<EOF
NO_START=0
# the TCP port that Dropbear listens on
DROPBEAR_PORT=$DPORT
DROPBEAR_EXTRA_ARGS="-p $DPORT"
DROPBEAR_BANNER="/etc/dropbear/banner"
DROPBEAR_RECEIVE_WINDOW=65536
EOF

cat > /etc/systemd/system/dropbear.service <<EOF
[Unit]
Description=Dropbear SSH Server
After=network.target

[Service]
ExecStart=/usr/local/sbin/dropbear -F -E -p $DPORT -b /etc/dropbear/banner
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# ---------- iniciar ----------
msg -bra "› Iniciando Dropbear"
systemctl daemon-reload
systemctl enable dropbear &>/dev/null
systemctl restart dropbear &>/dev/null
sleep 2

dropbearports=$(ss -tnlp | grep dropbear | awk '{print $4}' | awk -F: '{print $NF}' | sort -u | paste -sd,)
msg -bar
if [[ -z "$dropbearports" ]]; then
  msg -verm2 "[FAIL] Dropbear no se inició correctamente"
  msg -bra "Ejecuta manualmente: /usr/local/sbin/dropbear -F -E -p $DPORT -b /etc/dropbear/banner"
  msg -bra "Revisa errores con: journalctl -u dropbear"
else
  msg -verd "Port Dropbear configurado [ $dropbearports ]"
fi
msg -bar
) }

# --------------------------- OPCIÓN 2 ---------------------------
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

# --------------------------- OPCIÓN 3 ---------------------------
op_mensajes_banner() {
  local sshsn sin_nao
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
  aplicar_banner
}

# --------------------------- OPCIÓN 4 ---------------------------
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

# Estado de Dropbear para mostrar en el menú
db_estado() {
  if systemctl is-active --quiet dropbear 2>/dev/null; then
    echo -e "\033[1;32m[ ON: $(cat /etc/default/dadd 2>/dev/null) ]\e[0m"
  elif [[ -e /etc/default/dropbear ]]; then
    echo -e "\033[1;31m[ OFF ]\e[0m"
  fi
}

# ----------------------------- MENÚ -----------------------------
while true; do
  clear
  msg -bar
  echo -e "${cor[2]} ‍ ${cor[5]}CUENTAS SSH / SSL / DROPBEAR"
  msg -bar3
  echo -e "${cor[2]}MENU BANNER DROPBEAR (RECOMENDADO 3):"
  msg -bar3
  echo -e "\033[0;35m [\033[0;36m01\033[0;35m]\033[0;31m >${cor[3]} INSTALAR Y DESINSTALAR DROPBEAR $(db_estado)"
  echo -e "\033[0;35m [\033[0;36m02\033[0;35m]\033[0;31m >${cor[3]} PEGAR BANNER PERSONALIZADO ( HTML , ETC )"
  echo -e "\033[0;35m [\033[0;36m03\033[0;35m]\033[0;31m >${cor[3]} AGREGAR MENSAJES BANNER SSH"
  echo -e "\033[0;35m [\033[0;36m04\033[0;35m]\033[0;31m >${cor[3]} ELIMINAR BANNER ( SSH ⇿ DROPBEAR )"
  msg -bar3
  echo -e " \033[0;35m [\033[0;36m0\033[0;35m]\033[0;31m > $(msg -bra "\033[1;41m[ SALIR ]\e[0m")"
  msg -bar3
  case $(selection_fun 4) in
    1) op_instalar_dropbear ;;
    2) op_pegar_banner ;;
    3) op_mensajes_banner ;;
    4) op_eliminar_banner ;;
    0) clear; exit 0 ;;
  esac
  pausa
done
