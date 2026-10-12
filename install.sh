#!/bin/bash
# macOS-style eww widgets: date, brightness/volume, music player, to-do list.
# Installs files into ~/.config/eww. Read it before you run it.
set -e

echo "Checking requirements..."
missing=""
for c in eww playerctl brightnessctl wpctl zenity flock curl; do
  command -v "$c" >/dev/null 2>&1 || missing="$missing $c"
done
if [ -n "$missing" ]; then
  echo
  echo "Missing:$missing"
  echo "  Debian/Ubuntu: sudo apt install playerctl brightnessctl wireplumber zenity util-linux curl"
  echo "  Arch:          sudo pacman -S playerctl brightnessctl wireplumber zenity util-linux curl"
  echo "  Fedora:        sudo dnf install playerctl brightnessctl wireplumber zenity util-linux curl"
  echo "  eww itself:    see https://elkowar.github.io/eww/ (build with the x11 feature for GNOME)"
  echo "Installing the files anyway; the widgets will work once these are installed."
  echo
fi

pkill -9 eww 2>/dev/null || true
mkdir -p "$HOME/.config/eww/scripts"
cat > "$HOME/.config/eww/eww.yuck" <<'EWW_EOF'
(defpoll weekday :interval "10m" `date +%a | tr a-z A-Z`)
(defpoll day     :interval "10m" `date +%-d`)
(defpoll month   :interval "10m" `date +%B`)
(defpoll clock   :interval "10s" `date +%-I:%M`)
(defpoll ampm    :interval "10s" `date +%p`)

(defpoll volume     :interval "3s"  `~/.config/eww/scripts/mac.sh vol`)
(defpoll brightness :interval "3s"  `~/.config/eww/scripts/mac.sh bri`)
(defpoll battery    :interval "30s" `~/.config/eww/scripts/mac.sh bat`)

(defpoll m_title  :interval "2s" `~/.config/eww/scripts/music.sh title`)
(defpoll m_artist :interval "2s" `~/.config/eww/scripts/music.sh artist`)
(defpoll m_status :interval "2s" `~/.config/eww/scripts/music.sh status`)
(defpoll m_pos    :interval "1s" `~/.config/eww/scripts/music.sh pos`)
(defpoll m_art    :interval "3s" `~/.config/eww/scripts/music.sh art`)

(defpoll todos :interval "2s" :initial "[]" `~/.config/eww/scripts/todo.sh json`)

(defwidget date-tile []
  (box :class "tile date-tile" :orientation "v" :space-evenly false :valign "fill"
    (label :class "weekday" :halign "start" :text weekday)
    (label :class "daynum" :halign "start" :text day)
    (box :vexpand true)
    (label :class "month" :halign "start" :text month)
    (box :orientation "h" :space-evenly false :halign "start"
      (label :class "clock" :text clock)
      (label :class "ampm" :text ampm))))

(defwidget slider-row [icon value cmd]
  (overlay
    (scale :class "pill" :min 0 :max 100 :value value :timeout "2s" :onchange cmd)
    (label :class "pill-icon" :halign "start" :text icon)))

(defwidget control-tile []
  (box :class "tile control-tile" :orientation "v" :space-evenly false :spacing 12
    (box :orientation "h" :space-evenly false
      (label :class "ctl-title" :halign "start" :hexpand true :text "Display & Sound")
      (label :class "battery" :halign "end" :text "${battery}%"))
    (slider-row :icon "☀" :value brightness :cmd "~/.config/eww/scripts/mac.sh bri {}")
    (slider-row :icon "♪" :value volume     :cmd "~/.config/eww/scripts/mac.sh vol {}")))

(defwidget music-tile []
  (box :class "tile music-tile" :orientation "v" :space-evenly false :spacing 10
    (box :orientation "h" :space-evenly false :spacing 14
      (box :class "art" :style "background-image: url('${m_art}');" :width 64 :height 64 :valign "center")
      (box :orientation "v" :space-evenly false :hexpand true :valign "center" :spacing 2
        (label :class "m-title" :halign "start" :limit-width 18 :text m_title)
        (label :class "m-artist" :halign "start" :limit-width 22 :text m_artist)
        (box :class "m-controls" :orientation "h" :space-evenly false :halign "start" :spacing 6
          (button :class "m-btn" :onclick "playerctl previous" "⏮")
          (button :class "m-btn" :onclick "playerctl play-pause" {m_status == "Playing" ? "⏸" : "▶"})
          (button :class "m-btn" :onclick "playerctl next" "⏭"))))
    (scale :class "seek" :min 0 :max 100 :value m_pos :timeout "2s" :onchange "~/.config/eww/scripts/mac.sh seek {}")))

(defwidget calendar-tile []
  (box :class "tile cal-tile"
    (calendar :show-details false :show-week-numbers false)))

(defwidget todo-tile []
  (box :class "tile todo-tile" :orientation "v" :space-evenly false :spacing 8
    (box :orientation "h" :space-evenly false :spacing 6
      (label :class "ctl-title" :halign "start" :hexpand true :text "To-Do")
      (button :class "t-clear" :onclick "~/.config/eww/scripts/todo.sh clear" "Clear done")
      (button :class "t-add" :onclick "~/.config/eww/scripts/todo.sh new" "＋"))
    (label :class "empty" :visible {arraylength(todos) == 0} :halign "start" :text "All clear. Tap ＋ to add a task.")
    (scroll :vscroll true :hscroll false :height 130
      (box :orientation "v" :space-evenly false :spacing 4
        (for t in todos
          (button :class "todo ${t.done ? 'done' : ''}" :onclick "~/.config/eww/scripts/todo.sh toggle ${t.i}"
            (box :orientation "h" :space-evenly false :spacing 8
              (label :class "check" :text {t.done ? "●" : "○"})
              (label :class "t-text" :halign "start" :limit-width 28 :text {t.text}))))))))

(defwindow macos
  :monitor 0
  :geometry (geometry :x "-32px" :y "48px" :width "340px" :anchor "top right")
  :stacking "bg"
  :windowtype "desktop"
  (box :class "dash" :orientation "v" :space-evenly false :spacing 14
    (date-tile)
    (control-tile)
    (music-tile)))

(defwindow macos-left
  :monitor 0
  :geometry (geometry :x "-386px" :y "48px" :width "340px" :anchor "top right")
  :stacking "bg"
  :windowtype "desktop"
  (box :class "dash" :orientation "v" :space-evenly false :spacing 14
    (todo-tile)))
EWW_EOF
cat > "$HOME/.config/eww/eww.scss" <<'EWW_EOF'
* { all: unset; font-family: "SF Pro Display", "Inter", "Helvetica Neue", sans-serif; }

$text:   #ffffff;
$dim:    rgba(255,255,255,.55);
$tile:   rgba(30,30,34,.40);
$stroke: rgba(255,255,255,.10);
$red:    #ff453a;

.tile {
  background-color: $tile;
  border: 1px solid $stroke;
  border-radius: 22px;
  padding: 16px;
  color: $text;
}

.date-tile { min-height: 148px; }
.weekday { color: $red; font-size: 13px; font-weight: 700; }
.daynum  { font-size: 54px; font-weight: 300; margin-top: -6px; }
.month   { color: $dim; font-size: 13px; font-weight: 500; }
.clock   { font-size: 15px; font-weight: 600; }
.ampm    { color: $dim; font-size: 11px; font-weight: 600; margin: 4px 0 0 3px; }

.ctl-title { font-size: 13px; font-weight: 600; color: $text; }
.battery   { color: $dim; font-size: 12px; font-weight: 500; }

scale.pill trough { min-height: 30px; border-radius: 15px; background-color: rgba(255,255,255,.14); }
scale.pill highlight { border-radius: 15px; background-color: #f5f5f7; }
scale.pill slider { min-width: 0; min-height: 0; background-color: transparent; }
.pill-icon { color: #3a3a3c; font-size: 14px; margin-left: 11px; }

.art {
  min-width: 64px; min-height: 64px;
  border-radius: 12px;
  background-color: rgba(255,255,255,.12);
  background-size: cover;
  background-position: center;
}
.m-title  { font-size: 14px; font-weight: 600; color: $text; }
.m-artist { font-size: 12px; color: $dim; }
.m-btn { font-size: 17px; color: $text; padding: 2px 9px; border-radius: 12px; }
.m-btn:hover { background-color: rgba(255,255,255,.14); }

scale.seek trough { min-height: 8px; margin: 8px 0; border-radius: 4px; background-color: rgba(255,255,255,.18); }
scale.seek highlight { border-radius: 4px; background-color: #f5f5f7; }
scale.seek slider { min-width: 0; min-height: 0; background-color: transparent; }

calendar { color: $text; font-size: 13px; padding: 2px; min-width: 250px; min-height: 190px; }
calendar.header { color: $text; font-weight: 600; }
calendar.button { color: $red; padding: 0 8px; }
calendar.highlight { color: $dim; font-size: 11px; }
calendar:selected { background-color: $red; color: #fff; border-radius: 14px; }
calendar:indeterminate { color: rgba(255,255,255,.25); }

.t-add { color: $red; font-size: 20px; font-weight: 600; padding: 0 6px; }
.t-clear { color: $dim; font-size: 12px; padding: 3px 8px; border-radius: 10px; }
.t-clear:hover, .t-add:hover { background-color: rgba(255,255,255,.12); }
.empty { color: $dim; font-size: 12px; }
.todo { padding: 5px 4px; border-radius: 10px; color: $text; }
.todo:hover { background-color: rgba(255,255,255,.08); }
.todo .check { color: $red; font-size: 15px; }
.todo .t-text { font-size: 13px; }
.todo.done .check { color: $dim; }
.todo.done .t-text { color: $dim; }
EWW_EOF
cat > "$HOME/.config/eww/scripts/mac.sh" <<'EWW_EOF'
#!/bin/sh
# usage: mac.sh vol|bri|seek [value]   |   mac.sh bat
apply_vol()  { wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ "$(printf '%.0f' "$1")%"; }
apply_bri()  { p=$(printf '%.0f' "$1"); [ "$p" -lt 5 ] && p=5; brightnessctl -q set "${p}%"; }
apply_seek() {
  l=$(playerctl metadata mpris:length 2>/dev/null)
  [ -n "$l" ] && playerctl position "$(awk -v l="$l" -v pc="$1" 'BEGIN{printf "%.2f", l/1000000*pc/100}')"
}

# Runs only one worker at a time and always applies the latest value (no floods)
throttled() {
  name=$1; echo "$2" > "/tmp/eww-$name.val"
  (
    flock -n 9 || exit 0
    last=""
    while :; do
      v=$(cat "/tmp/eww-$name.val")
      [ "$v" = "$last" ] && break
      last=$v
      "apply_$name" "$v"
      sleep 0.15
    done
  ) 9>"/tmp/eww-$name.lock" >/dev/null 2>&1 </dev/null &
}

case "$1" in
  vol)  if [ -n "$2" ]; then throttled vol "$2"; else wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%d", $2*100}'; fi ;;
  bri)  if [ -n "$2" ]; then throttled bri "$2"; else brightnessctl -m | cut -d, -f4 | tr -d '%'; fi ;;
  seek) throttled seek "$2" ;;
  bat)  cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 ;;
esac
EWW_EOF
cat > "$HOME/.config/eww/scripts/music.sh" <<'EWW_EOF'
#!/bin/sh
case "$1" in
  title)  t=$(playerctl metadata title 2>/dev/null);  echo "${t:-Not playing}" ;;
  artist) a=$(playerctl metadata artist 2>/dev/null); echo "${a:-Open Spotify or a video}" ;;
  status) s=$(playerctl status 2>/dev/null);          echo "${s:-Stopped}" ;;
  pos)
    p=$(playerctl position 2>/dev/null); l=$(playerctl metadata mpris:length 2>/dev/null)
    if [ -n "$p" ] && [ -n "$l" ] && [ "$l" -gt 0 ] 2>/dev/null; then
      awk -v p="$p" -v l="$l" 'BEGIN{printf "%d", p*1000000/l*100}'
    else
      echo 0
    fi ;;
  art)
    url=$(playerctl metadata mpris:artUrl 2>/dev/null)
    [ -z "$url" ] && { echo /tmp/eww-noart; exit 0; }
    case "$url" in
      file://*) echo "${url#file://}" ;;
      *) f="/tmp/eww-art-$(printf '%s' "$url" | md5sum | cut -c1-10).jpg"
         [ -f "$f" ] || curl -sL "$url" -o "$f"
         echo "$f" ;;
    esac ;;
esac
EWW_EOF
cat > "$HOME/.config/eww/scripts/todo.sh" <<'EWW_EOF'
#!/bin/sh
F="$HOME/.config/eww/todo.txt"
[ -f "$F" ] || : > "$F"
case "$1" in
  json)
    awk 'BEGIN{printf "["} { d=substr($0,1,1); t=substr($0,3);
      printf "%s{\"i\":%d,\"done\":%s,\"text\":\"%s\"}", (NR>1?",":""), NR, (d=="1"?"true":"false"), t } END{print "]"}' "$F" ;;
  add)
    shift; t=$(printf '%s' "$*" | tr -d '"\\' | tr -d '\n')
    [ -n "$t" ] && printf '0|%s\n' "$t" >> "$F" ;;
  toggle)
    awk -v n="$2" 'NR==n { $0 = (substr($0,1,1)=="1" ? "0" : "1") substr($0,2) } {print}' "$F" > "$F.tmp" && mv "$F.tmp" "$F" ;;
  clear)
    grep -v '^1|' "$F" > "$F.tmp"; mv "$F.tmp" "$F" ;;
  new)
    t=$(zenity --entry --title="New to-do" --text="What needs doing?" 2>/dev/null) && "$0" add "$t" ;;
esac
EWW_EOF
cat > "$HOME/.config/eww/run.sh" <<'EWW_EOF'
#!/bin/sh
# Start (or restart) the widgets. GDK_BACKEND=x11 makes it work on GNOME Wayland too.
export GDK_BACKEND=x11
eww kill >/dev/null 2>&1
eww daemon
sleep 1
eww open-many macos macos-left
EWW_EOF
chmod +x "$HOME/.config/eww/scripts/"*.sh "$HOME/.config/eww/run.sh"
echo
echo "Installed to ~/.config/eww"
echo "Start the widgets with:  ~/.config/eww/run.sh"
echo "Stop them with:          eww close-all"
