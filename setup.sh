#!/bin/bash

# ==========================================
# IRE Consultants - Ultimate Mint Setup
# ==========================================

echo "==========================================="
echo "Welcome to the IRE Consultants Mint Setup"
echo "==========================================="
read -p "Do you want to proceed? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# ------------------------------------------
# 1. DEBLOAT THE SYSTEM
# ------------------------------------------
echo "--> Removing bloatware..."
BLOATWARE=("gnome-mines" "gnome-sudoku" "aisleriot" "hexchat" "transmission-gtk" "thunderbird" "hypnotix" "webapp-manager")
for app in "${BLOATWARE[@]}"; do
    if dpkg -l | grep -q "^ii  $app"; then
        sudo apt remove --purge -y "$app" > /dev/null 2>&1
    fi
done
sudo apt autoremove --purge -y > /dev/null 2>&1

# ------------------------------------------
# 2. SYSTEM OPTIMIZATION (SWAPPINESS)
# ------------------------------------------
echo "--> Optimizing system swappiness..."
echo "vm.swappiness=30" | sudo tee /etc/sysctl.d/7-swappiness.conf > /dev/null
sudo sysctl -p /etc/sysctl.d/7-swappiness.conf > /dev/null

# ------------------------------------------
# 3. FIX LIBREOFFICE CTRL+F
# ------------------------------------------
echo "--> Fixing LibreOffice (Resetting user profile)..."
if [ -d "$HOME/.config/libreoffice" ]; then
    mv "$HOME/.config/libreoffice" "$HOME/.config/libreoffice.bak_$(date +%s)"
fi

# ------------------------------------------
# 4. APPLY CUSTOM LIBREOFFICE SHORTCUTS
# ------------------------------------------
echo "--> Applying custom LibreOffice shortcuts..."
cat << 'EOF' > /tmp/apply_lo_shortcuts.py
import xml.etree.ElementTree as ET
import shutil
import os

USER_PROFILE = os.path.expanduser("~/.config/libreoffice/4/user/registrymodifications.xcu")
if os.path.exists(USER_PROFILE):
    shutil.copy(USER_PROFILE, USER_PROFILE + ".bak")

ns_oor = "http://openoffice.org/2001/registry"
ns_xs = "http://www.w3.org/2001/XMLSchema"
ns_xsi = "http://www.w3.org/2001/XMLSchema-instance"
ET.register_namespace('oor', ns_oor)
ET.register_namespace('xs', ns_xs)
ET.register_namespace('xsi', ns_xsi)

if os.path.exists(USER_PROFILE) and os.path.getsize(USER_PROFILE) > 0:
    tree = ET.parse(USER_PROFILE)
    root = tree.getroot()
else:
    root = ET.Element(f"{{{ns_oor}}}items")
    tree = ET.ElementTree(root)

calc_shortcuts = {
    "MOD1+1": ".uno:FormatCellDialog", "MOD1+SHIFT+L": ".uno:DataFilterAutoFilter",
    "F4": ".uno:ToggleRelative", "MOD1+SEMICOLON": ".uno:InsertCurrentDate",
    "MOD1+SHIFT+SEMICOLON": ".uno:InsertCurrentTime", "MOD1+D": ".uno:FillDown",
    "MOD1+R": ".uno:FillRight", "MOD1+SHIFT+EQUAL": ".uno:Insert",
    "MOD1+MINUS": ".uno:Delete", "SHIFT+F11": ".uno:Add",
    "SHIFT+F3": ".uno:FunctionDialog", "F9": ".uno:Calculate",
    "MOD1+K": ".uno:HyperlinkDialog", "SHIFT+F2": ".uno:InsertAnnotation",
    "MOD1+SPACE": ".uno:SelectColumn", "SHIFT+SPACE": ".uno:SelectRow",
    "F12": ".uno:SaveAs", "ALT+EQUAL": ".uno:AutoSum"
}
writer_shortcuts = {
    "MOD1+1": ".uno:FormatParagraphDialog", "F12": ".uno:SaveAs",
    "MOD1+B": ".uno:Bold", "MOD1+I": ".uno:Italic",
    "MOD1+U": ".uno:Underline", "MOD1+SHIFT+L": ".uno:ListBullet"
}

def add_shortcuts(app_name, shortcuts_dict):
    path = f"/org.openoffice.Office.Accelerators/Accelerators/{app_name}"
    for item in list(root.findall(f"{{{ns_oor}}}item")):
        if item.get(f"{{{ns_oor}}}path") == path:
            root.remove(item)
    item = ET.SubElement(root, f"{{{ns_oor}}}item")
    item.set(f"{{{ns_oor}}}path", path)
    for key, command in shortcuts_dict.items():
        node = ET.SubElement(item, f"{{{ns_oor}}}node")
        node.set(f"{{{ns_oor}}}name", key)
        prop = ET.SubElement(node, f"{{{ns_oor}}}prop")
        prop.set(f"{{{ns_oor}}}name", "Command")
        value = ET.SubElement(prop, f"{{{ns_oor}}}value")
        value.text = command

add_shortcuts("Calc", calc_shortcuts)
add_shortcuts("Writer", writer_shortcuts)
tree.write(USER_PROFILE, encoding='UTF-8', xml_declaration=True)
EOF
python3 /tmp/apply_lo_shortcuts.py
rm /tmp/apply_lo_shortcuts.py

# ------------------------------------------
# 5. APPLY CINNAMON GLOBAL SHORTCUTS
# ------------------------------------------
echo "--> Applying Cinnamon global shortcuts..."
cat << 'EOF' > /tmp/add_global_shortcuts.py
import subprocess
import ast

SHORTCUTS = {
    "Shutdown": {"command": "systemctl poweroff", "binding": "<Primary><Alt>Delete"},
    "Sleep": {"command": "systemctl suspend", "binding": "<Primary><Alt>s"},
    "Lock Screen": {"command": "cinnamon-screensaver-command --lock", "binding": "<Super>l"},
    "Open Calc": {"command": "libreoffice --calc", "binding": "<Primary><Alt>c"},
    "Open Writer": {"command": "libreoffice --writer", "binding": "<Primary><Alt>w"},
}

def run_gsettings(args):
    subprocess.run(["gsettings"] + args, check=True, capture_output=True, text=True)

result = subprocess.run(["gsettings", "get", "org.cinnamon.desktop.keybindings", "custom-list"], capture_output=True, text=True)
current_list_str = result.stdout.strip()

if current_list_str == "@as []" or not current_list_str:
    existing_shortcuts = []
else:
    try:
        existing_shortcuts = ast.literal_eval(current_list_str)
    except:
        existing_shortcuts = []

new_ids = []
start_index = len(existing_shortcuts)

for i, (name, details) in enumerate(SHORTCUTS.items()):
    shortcut_id = f"custom{start_index + i}"
    new_ids.append(shortcut_id)
    base_path = f"org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/{shortcut_id}/"
    run_gsettings(["set", base_path, "name", f"'{name}'"])
    run_gsettings(["set", base_path, "command", f"'{details['command']}'"])
    run_gsettings(["set", base_path, "binding", f"['{details['binding']}']"])

all_ids = existing_shortcuts + new_ids
list_variant = str(all_ids).replace('"', "'")
run_gsettings(["set", "org.cinnamon.desktop.keybindings", "custom-list", list_variant])
EOF
python3 /tmp/add_global_shortcuts.py
rm /tmp/add_global_shortcuts.py

# ------------------------------------------
# DISABLE SUPER KEY (Looking Glass)
# ------------------------------------------
gsettings set org.cinnamon.desktop.keybindings looking-glass-keybinding "[]"
gsettings set org.cinnamon.desktop.keybindings.wm move-to-workspace-up "[]"
gsettings set org.cinnamon.desktop.keybindings.wm move-to-workspace-down "[]"

echo "==========================================="
echo "SUCCESS! Setup is complete."
echo "Please restart your laptop for all changes to take effect."
echo "==========================================="
