# Linux Mint Debloat & Fix Script

A simple, automated setup script built for IRE Consultants. 

## What it does:
1. Removes pre-installed bloatware (Games, Hexchat, Thunderbird, etc.).
2. Fixes the LibreOffice `Ctrl + F` search bug by resetting the user profile.
3. Automatically injects custom Excel/Word shortcuts.
4. Sets up Cinnamon global shortcuts (Shutdown, Sleep, Open Calc, etc.).
5. Optimizes system memory (`swappiness`).

## How to use on a new laptop:
Open your terminal and run:

```bash
git clone https://github.com/ireconsultants/mint-ire-setup.git
cd mint-ire-setup
chmod +x setup.sh
./setup.sh
