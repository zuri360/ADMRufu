#!/bin/bash
# =====================================================================
#  protocolsUDP.sh - Menu independiente de PROTOCOLOS UDP (ADMRufu)
#    [1] udp_custom.sh   -> UDP-CUSTOM (HTTP Custom)
#    [2] udp_hysteria.sh -> UDP-HYSTERIA (APP MOD)
#    [3] udp-zivpn.sh    -> UDP-ZIVPN
#  Si el script no esta en $ADM_inst se descarga de $REPO_URL.
#  Uso: bash protocolsUDP.sh
# =====================================================================

# ---- Configuracion ----
ADM_inst="${ADM_inst:-/etc/ADMRufu/install}"
REPO_URL="${REPO_URL:-https://raw.githubusercontent.com/zuri360/ADMRufu/refs/heads/main/ADMRufu/old}"

# ---- Funciones de pantalla ----
msg(){
  local R='\e[0m' B='\e[1m'
  local RED='\e[31m' GRN='\e[32m' YEL='\e[33m' WHT='\033[1;97m'
  local BAR='======================================================'
  case $1 in
    -ama)   echo -e "${YEL}${B}${2}${R}";;
    -verm2) echo -e "${RED}${B}${2}${R}";;
    -azu)   echo -e "${WHT}${2}${R}";;
    -verd)  echo -e "${GRN}${B}${2}${R}";;
    -bra)   echo -e "\033[1;37m${2}${R}";;
    -bar)   echo -e "${RED}${BAR}${R}";;
    *)      echo -e "$*";;
  esac
}

print_center(){
  local color="-azu" text line plain pad
  if [[ $1 == -* ]]; then color=$1; shift; fi
  text="$*"
  while IFS= read -r line; do
    plain=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
    pad=$(( (54 - ${#plain}) / 2 )); (( pad < 0 )) && pad=0
    msg "$color" "$(printf '%*s' $pad '')$line"
  done <<< "$(echo -e "$text")"
}

title(){
  local color="-ama"
  if [[ $1 == -* ]]; then color=$1; shift; fi
  clear
  msg -bar
  print_center "$color" "$*"
  msg -bar
}

back(){
  msg -bar
  echo -e " $(msg -verd "[0]") $(msg -verm2 ">") $(msg -bra "\033[1;41m VOLVER \033[0m")"
  msg -bar
}

selection_fun(){
  local sel max
  [[ $1 == -* ]] && shift
  max=$1
  while :; do
    echo -ne "\e[33m\e[1m Seleccione una opcion: \e[0m" >&2
    read sel
    if [[ $sel =~ ^[0-9]+$ ]] && (( sel >= 0 && sel <= max )); then
      echo "$sel"; return
    fi
    tput cuu1 >&2; tput dl1 >&2
  done
}

enter(){
  msg -bar
  print_center -ama "►► Presione enter para continuar ◄◄"
  read
}

# ---- Puertos activos ----
mine_port(){
  local data
  data=$(ss -H -tlnp 2>/dev/null | awk '{for(f=1;f<=NF;f++) if($f ~ /:[0-9]+$/){n=split($f,a,":"); port=a[n]; break}; p="?"; if (match($0,/users:\(\("[^"]+"/)) {p=substr($0,RSTART+9,RLENGTH-10)} print p, port}' | sort -u -k1,1 -k2,2n)
  if [[ -z $data ]]; then
    data=$(lsof -V -i tcp -P -n 2>/dev/null | grep LISTEN | awk '{n=split($9,a,":"); print $1, a[n]}' | sort -u -k1,1 -k2,2n)
  fi
  [[ -z $data ]] && print_center -verm2 "SIN PUERTOS ACTIVOS" && return
  print_center -ama "PUERTOS ACTIVOS"
  echo "$data" | awk '{if(!s[$1]++) o[++k]=$1; p[$1]=p[$1] (p[$1]?" ":"") $2} END{for(i=1;i<=k;i++) print o[i], p[o[i]]}' | while read name ports; do
    echo -e " $(msg -verd "$(printf '%-12s' "${name:0:12}")") $(msg -verm2 ">") $(msg -azu "$ports")"
  done
}

# ---- Descarga y ejecuta el script externo ----
udp_script(){
  local f=$1 dir=$ADM_inst
  local url="$REPO_URL/$f"
  if [[ ! -s $dir/$f ]]; then
    msg -bar
    print_center -ama "DESCARGANDO $f..."
    mkdir -p "$dir"
    if wget -q --no-cache -T 20 -t 2 -O "$dir/$f" "$url" 2>/dev/null || curl -fsSL -m 60 -o "$dir/$f" "$url" 2>/dev/null; then
      chmod +x "$dir/$f"
    fi
    if [[ ! -s $dir/$f ]] || head -c 20 "$dir/$f" | grep -qi '404'; then
      rm -f "$dir/$f"
      print_center -verm2 "No se pudo descargar $f"
      msg -bar
      enter
      return 1
    fi
  fi
  # udp_hysteria.sh (PandaScript) sale con "Script no actualizado" si no existe este archivo
  [[ $f = udp_hysteria.sh ]] && { mkdir -p /etc/adm-lite; touch /etc/adm-lite/local.txt; }
  (cd "$dir" && bash "$dir/$f")
  return 1
}

# ---- Menu ----
protocolsUDP(){
  while :; do
    title -ama "INFORMACION DEL SISTEMA Y PUERTOS ACTIVOS"
    mine_port
    msg -bar
    print_center -ama "MENU DE PROTOCOLOS UDP"
    msg -bar
    echo -e " $(msg -verd "[1]") $(msg -verm2 ">") $(msg -azu "INSTALAR UDP-CUSTOM (HTTP Custom)")"
    echo -e " $(msg -verd "[2]") $(msg -verm2 ">") $(msg -azu "INSTALAR UDP-HYSTERIA (APP MOD)")"
    echo -e " $(msg -verd "[3]") $(msg -verm2 ">") $(msg -azu "INSTALAR UDP-ZIVPN")"
    back
    case $(selection_fun 3) in
      1) udp_script udp_custom.sh;;
      2) udp_script udp_hysteria.sh;;
      3) udp_script udp-zivpn.sh;;
      0) return 1;;
    esac
  done
}

[[ $EUID -ne 0 ]] && { echo "Ejecutalo como root."; exit 1; }
protocolsUDP
