#!/bin/bash
# ======================================================
#  Banner CheckUser adaptado a ADMRufu
#  Lee los usuarios de /etc/passwd + /etc/shadow
#  (ADMRufu guarda: GECOS "limite,pass" | "hwid,cliente" | "token,cliente"
#   y la expiración con chage -E)
# ======================================================

# Salir limpio siempre (importante para pam_exec optional)
trap 'exit 0' EXIT

USER_TO_CHECK="${PAM_USER:-$1}"
[[ -z "$USER_TO_CHECK" ]] && exit 0

BANNER_STATIC="/etc/bannerssh"
BANNER_FILE="/etc/ADMcgh/bin/banner.txt"
TMP_FILE="${BANNER_FILE}.$$"

mkdir -p "$(dirname "$BANNER_FILE")" 2>/dev/null
chmod 755 "$(dirname "$BANNER_FILE")" 2>/dev/null || true

PW_LINE=$(getent passwd "$USER_TO_CHECK" 2>/dev/null)
if [[ -z "$PW_LINE" ]]; then
  echo "Usuario $USER_TO_CHECK no existe." > "$BANNER_FILE" 2>/dev/null || true
  exit 0
fi

# ---- Datos del usuario (formato ADMRufu) ----
gecos=$(echo "$PW_LINE" | cut -d: -f5)
campo1=$(echo "$gecos" | cut -d, -f1)
campo2=$(echo "$gecos" | cut -d, -f2)

tipo="ssh"
display_user="$USER_TO_CHECK"
limite=""
case "$campo1" in
  hwid)  tipo="hwid";  display_user="${campo2:-$USER_TO_CHECK}" ;;
  token) tipo="token"; display_user="${campo2:-$USER_TO_CHECK}" ;;
  *)     [[ "$campo1" =~ ^[0-9]+$ ]] && limite="$campo1" ;;
esac

# Expiración: campo 8 de /etc/shadow (días desde 1970)
SH_LINE=$(getent shadow "$USER_TO_CHECK" 2>/dev/null)
exp_dias=$(echo "$SH_LINE" | cut -d: -f8)
bloqueado=0
[[ "$(echo "$SH_LINE" | cut -d: -f2)" == '!'* ]] && bloqueado=1

# Conexiones activas (sshd + dropbear)
conectados=$(ps -u "$USER_TO_CHECK" -o comm= 2>/dev/null | grep -cE 'sshd|dropbear' || true)

# ---- Cálculo de tiempo restante ----
color="green"
mostrar_advertencia=0
fecha_mostrar="Ilimitado"
dias_restantes="Ilimitado"

if [[ "$exp_dias" =~ ^[0-9]+$ ]]; then
  exp_seg=$(( exp_dias * 86400 ))
  ahora=$(date -u +%s)
  fecha_mostrar=$(date -u -d "@$exp_seg" +"%d/%m/%Y")
  if (( exp_seg <= ahora )); then
    dias_restantes="Expirado"; color="red"; mostrar_advertencia=1
  else
    diff=$(( exp_seg - ahora ))
    d=$(( diff / 86400 ))
    if (( d == 0 )); then
      dias_restantes="$(( diff / 3600 ))h $(( (diff % 3600) / 60 ))m"
      color="red"; mostrar_advertencia=1
    else
      dias_restantes="$d días"
      (( d < 3 )) && { color="red"; mostrar_advertencia=1; }
    fi
  fi
fi
(( bloqueado )) && { color="red"; dias_restantes="BLOQUEADO"; }

# ---- Escribir banner (atómico, evita mezclar logins simultáneos) ----
{
  [[ -f "$BANNER_STATIC" ]] && cat "$BANNER_STATIC"
  echo "<br><p style=\"color:#00CED1; text-align:center;\">=======================================</p>"
  case "$tipo" in
    hwid)  echo "<br><p style=\"text-align:center; color:#BF00FF;\"><strong>👤 USUARIO HWID ⬇️</strong></p>" ;;
    token) echo "<br><p style=\"text-align:center; color:#BF00FF;\"><strong>👤 USUARIO TOKEN ⬇️</strong></p>" ;;
    *)     echo "<br><p style=\"text-align:center; color:#BF00FF;\"><strong>👤 USUARIO PREMIUM ⬇️</strong></p>" ;;
  esac
  echo "<br><p style=\"text-align:center;\">🛡️ <span style=\"color:$color;\"><strong>$display_user</strong></span> 🛡️</p>"
  echo "<br><p style=\"text-align:center;\"><strong>DETALLES DE SU USUARIO</strong></p>"
  echo "<br><p style=\"text-align:center;\">• Válido hasta: <strong><span style=\"color:$color;\">$fecha_mostrar</span></strong></p>"
  echo "<br><p style=\"text-align:center;\">• Tiempo restante: <strong><span style=\"color:$color;\">$dias_restantes</span></strong></p>"
  if [[ -n "$limite" ]]; then
    echo "<br><p style=\"text-align:center;\">• Conexiones: <strong>$conectados / $limite</strong></p>"
  fi
  if (( mostrar_advertencia )); then echo "<br><p style=\"text-align:center; color:red;\"><strong>⚠️ ¡Renueve su usuario antes que expire! ⚠️</strong></p>"; fi
} > "$TMP_FILE" 2>/dev/null
mv -f "$TMP_FILE" "$BANNER_FILE" 2>/dev/null

rm -f "$TMP_FILE" 2>/dev/null
exit 0
