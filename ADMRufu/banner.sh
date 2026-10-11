#!/bin/bash

# ======================================================
#  PandaScript - Banner CheckUser (Versión Robusta)
#  Evita errores de PAM "unknown status"
# ======================================================

# Salir limpio siempre (importante para pam_exec optional)
trap 'exit 0' EXIT ERR

# Verificar existencia de archivos requeridos del panel
if [[ ! -f "/etc/adm-lite/local.txt" || ! -f "/etc/adm-lite/v-local.log" ]]; then
  exit 0
fi

USER_TO_CHECK="${PAM_USER:-$1}"
BANNER_STATIC="/etc/bannerssh"
USER_FILE="/etc/adm-lite/userDIR/$USER_TO_CHECK"
BANNER_FILE="/etc/ADMcgh/bin/banner.txt"

# Crear directorio si no existe (evita fallos de redirección)
mkdir -p "$(dirname "$BANNER_FILE")" 2>/dev/null
chmod 755 "$(dirname "$BANNER_FILE")" 2>/dev/null || true

if [[ ! -f "$USER_FILE" ]]; then
  echo "Usuario $USER_TO_CHECK no existe." > "$BANNER_FILE" 2>/dev/null || true
  exit 0
fi

# Leer datos del usuario (con defaults seguros)
limite=$(grep '^limite:' "$USER_FILE" 2>/dev/null | cut -d' ' -f2- | tr -d '\r')
senha=$(grep '^senha:' "$USER_FILE" 2>/dev/null | cut -d' ' -f2- | tr -d '\r')
fecha_expira=$(grep '^data:' "$USER_FILE" 2>/dev/null | cut -d' ' -f2- | tr -d '\r')
tipo=$(grep '^tipo:' "$USER_FILE" 2>/dev/null | cut -d' ' -f2- | tr -d '\r')

# Defaults
[[ -z "$limite" ]] && limite=""
[[ -z "$senha" ]] && senha="$USER_TO_CHECK"
[[ -z "$fecha_expira" ]] && fecha_expira=""
[[ -z "$tipo" ]] && tipo=""

# Determinar si es temporal
is_temporal=false
if [[ "$limite" == "HWID_TEMPORAL" || "$tipo" == "ssh temporal" ]]; then
  is_temporal=true
fi

# Lógica de nombre a mostrar
if [[ "$limite" == "HWID" || "$limite" == "HWID_TEMPORAL" ]]; then
  display_user="$senha"
elif [[ "$tipo" == "ssh temporal" ]]; then
  display_user="$USER_TO_CHECK"
else
  display_user="$USER_TO_CHECK"
fi

# === Cálculo de tiempo restante (más seguro) ===
dias_restantes=""
color="green"
mostrar_advertencia=0

if [[ "$is_temporal" == false ]]; then
  fecha_actual=$(date -u +%s 2>/dev/null || echo 0)

  fecha_expira_segundos=""
  if [[ -n "$fecha_expira" ]]; then
    fecha_expira_segundos=$(date -u -d "$fecha_expira" +%s 2>/dev/null || echo "")
  fi

  # Validación fuerte antes de aritmética
  if [[ -z "$fecha_expira_segundos" || ! "$fecha_expira_segundos" =~ ^-?[0-9]+$ ]]; then
    dias_restantes="Fecha inválida"
    color="red"
  elif (( fecha_expira_segundos < fecha_actual )); then
    dias_restantes="Expirado"
    color="red"
    mostrar_advertencia=1
  else
    diff_segundos=$((fecha_expira_segundos - fecha_actual))
    diff_dias=$((diff_segundos / 86400))

    if (( diff_dias == 0 )); then
      horas=$((diff_segundos / 3600))
      minutos=$(((diff_segundos % 3600) / 60))
      dias_restantes="${horas}h ${minutos}m"
      color="red"
      mostrar_advertencia=1
    else
      dias_restantes="$diff_dias días"
      if (( diff_dias < 3 )); then
        color="red"
        mostrar_advertencia=1
      fi
    fi
  fi
fi

# Formatear fecha para mostrar
fecha_expira_para_mostrar="$fecha_expira"
if [[ "$is_temporal" == false && -n "$fecha_expira_segundos" && "$fecha_expira_segundos" =~ ^-?[0-9]+$ ]]; then
  fecha_expira_para_mostrar=$(date -d "$fecha_expira -1 day" +"%Y-%m-%d" 2>/dev/null || echo "$fecha_expira")
fi

# Escribir banner (con protección)
> "$BANNER_FILE" 2>/dev/null || true

if [[ -f "$BANNER_STATIC" ]]; then
  cp "$BANNER_STATIC" "$BANNER_FILE" 2>/dev/null || true
fi

{
  echo "<br><p style=\"color:#00CED1; text-align:center;\">=======================================</p>"
  
  if [[ "$is_temporal" == true ]]; then
    echo "<br><p style=\"text-align:center; color:#BF00FF;\"><strong>👤 USUARIO TEMPORAL ⬇️</strong></p>"
  else
    echo "<br><p style=\"text-align:center; color:#BF00FF;\"><strong>👤 USUARIO PREMIUM ⬇️</strong></p>"
  fi

  echo "<br><p style=\"text-align:center;\">🛡️ <span style=\"color:$color;\"><strong>$display_user</strong></span> 🛡️</p>"
  
  if [[ "$is_temporal" == false ]]; then
    echo "<br><p style=\"text-align:center;\"><strong>DETALLES DE SU USUARIO</strong></p>"
    echo "<br><p style=\"text-align:center;\">• Válido hasta: <strong><span style=\"color:$color;\">$fecha_expira_para_mostrar</span></strong></p>"
    echo "<br><p style=\"text-align:center;\">• Tiempo restante: <strong><span style=\"color:$color;\">$dias_restantes</span></strong></p>"
  fi

  if [[ "$mostrar_advertencia" == "1" ]]; then
    echo "<br><p style=\"text-align:center; color:red;\"><strong>⚠️ ¡Renueve su usuario antes que expire! ⚠️</strong></p>"
  fi
} >> "$BANNER_FILE" 2>/dev/null || true

exit 0