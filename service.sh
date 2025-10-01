#!/system/bin/sh
#
# Magisk service script - runs at late_start service (boot finished)
#
# This script sets the renderers to "skiagl", crashes SystemUI (intentional),
# then force-stops other packages. Runs in background and detaches.
#

LOGFILE="/data/local/tmp/magisk-skiagl.log"

# Log helper
log() {
  echo "$(date +%F\ %T) - $*" >> "$LOGFILE"
}

# Run main in background so Magisk boot isn't blocked
main() {
  log "magisk-skiagl: starting"

  # set renderer props (changed skiavk -> skiagl)
  /system/bin/setprop debug.hwui.renderer skiagl 2>>"$LOGFILE"
  /system/bin/setprop debug.renderengine.backend skiagl 2>>"$LOGFILE"
  log "magisk-skiagl: setprop done"

  # Crash SystemUI to force a restart (dangerous on some devices)
  /system/bin/am crash com.android.systemui 2>>"$LOGFILE" || log "am crash returned $? (non-fatal)"

  # short pause
  /system/bin/sleep 1

  # Force-stop other packages (skip packages containing "ia.mo")
  /system/bin/pm list packages | /system/bin/grep -v ia.mo | /system/bin/cut -f2 -d: | while read -r pkg; do
    if [ -n "$pkg" ]; then
      /system/bin/am force-stop "$pkg" >/dev/null 2>&1 &
    fi
  done

  log "magisk-skiagl: done"
}

# detach so Magisk doesn't block; redirect output
main >/dev/null 2>&1 &
exit 0
