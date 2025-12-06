#!/usr/bin/env python3
import subprocess
import time
import os

MAPPING_FILE   = "/etc/hysteria/port_mapping.txt"
INTERVAL       = 20   
THRESHOLD_DROP = 0.5  

def get_bytes(chain: str) -> int:
    """
    Returns the byte-count for the given iptables chain in the mangle table.
    If the chain doesn't exist or has no counters yet, returns 0.
    """
    try:
        out = subprocess.check_output(
            ["iptables", "-t", "mangle", "-L", chain, "-vxn"],
            stderr=subprocess.DEVNULL
        ).decode()
    except subprocess.CalledProcessError:

        return 0

    lines = out.splitlines()
    if len(lines) < 3:

        return 0


    parts = lines[2].split()
    try:
        return int(parts[1])
    except (IndexError, ValueError):
        return 0

def get_all_chain_bytes(chains: list) -> dict:
    """
    Get byte counts for multiple chains in a single iptables call.
    More efficient than calling get_bytes() for each chain individually.
    """
    results = {chain: 0 for chain in chains}
    try:
        # Get all mangle table stats at once
        out = subprocess.check_output(
            ["iptables", "-t", "mangle", "-L", "-vxn"],
            stderr=subprocess.DEVNULL
        ).decode()
        
        current_chain = None
        rule_line_seen = set()
        for line in out.splitlines():
            if line.startswith("Chain "):
                current_chain = line.split()[1]
                rule_line_seen.discard(current_chain)
            elif current_chain in results and line.strip() and current_chain not in rule_line_seen:
                parts = line.split()
                if len(parts) > 1:
                    try:
                        results[current_chain] = int(parts[1])
                        rule_line_seen.add(current_chain)
                    except ValueError:
                        pass
    except subprocess.CalledProcessError:
        pass
    
    return results

def load_mappings() -> dict:
    """
    Load and parse mapping file, return dict of idx -> (service, ports).
    """
    mappings = {}
    try:
        with open(MAPPING_FILE) as f:
            for ln in f:
                ln = ln.strip()
                if not ln or ln.startswith("#"):
                    continue
                parts = ln.split("|")
                if len(parts) != 3:
                    continue
                cfg, service, ports = parts
                idx = cfg.split("config")[-1].split(".")[0]
                mappings[idx] = (service, ports)
    except FileNotFoundError:
        pass
    return mappings

def get_file_mtime() -> float:
    """Get file modification time, returning 0 if file doesn't exist."""
    try:
        return os.path.getmtime(MAPPING_FILE)
    except OSError:
        return 0

def main():
    # Load mappings and initialize counters
    mappings = load_mappings()
    last_mtime = get_file_mtime()
    
    # Build list of chains we're monitoring
    chains = [f"HYST{idx}" for idx in mappings]
    
    # Initialize byte counters - batch query all chains at once
    old = get_all_chain_bytes(chains) if chains else {}

    while True:
        time.sleep(INTERVAL)
        
        # Check if mapping file changed (avoid re-reading if unchanged)
        current_mtime = get_file_mtime()
        if current_mtime != last_mtime:
            mappings = load_mappings()
            chains = [f"HYST{idx}" for idx in mappings]
            last_mtime = current_mtime
        
        if not mappings:
            continue
        
        # Batch query all chains at once (single subprocess call)
        new_bytes = get_all_chain_bytes(chains)
        
        for idx, (service, _) in mappings.items():
            chain = f"HYST{idx}"
            new = new_bytes.get(chain, 0)
            prev = old.get(chain, new)
            drop = (prev - new) / prev if prev else 0

            if drop > THRESHOLD_DROP:
                subprocess.call(["systemctl", "restart", service])

            old[chain] = new

if __name__ == "__main__":
    main()

