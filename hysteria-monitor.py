#!/usr/bin/env python3
import subprocess, time

MAPPING_FILE = "/etc/hysteria/port_mapping.txt"
INTERVAL = 180 
THRESHOLD_DROP = 0.5 

def get_bytes(chain):
    out = subprocess.check_output(
        ["iptables", "-t", "mangle", "-L", chain, "-vxn"]
    ).decode()
    line = out.splitlines()[2]
    fields = line.split()
    return int(fields[1])

def main():
    old = {}
    with open(MAPPING_FILE) as f:
        for ln in f:
            cfg,_ = ln.strip().split(":",1)
            idx = cfg.split("config")[1]
            old[idx] = get_bytes(f"HYST{idx}")

    while True:
        time.sleep(INTERVAL)
        for ln in open(MAPPING_FILE):
            cfg, _ = ln.strip().split(":",1)
            idx = cfg.split("config")[1]
            chain = f"HYST{idx}"
            new = get_bytes(chain)
            drop = (old[idx] - new) / old[idx] if old[idx] else 0
            if drop > THRESHOLD_DROP:
                subprocess.call(["systemctl","restart",f"hysteria{idx}"])
            old[idx] = new

if __name__=="__main__":
    main()
