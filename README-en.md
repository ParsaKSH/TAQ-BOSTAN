

<div align="center">
<img src="https://github.com/user-attachments/assets/acc27110-4275-4751-937b-cdc63704164f" width="300" />
</div>

<div align="center">
  
[![release](https://img.shields.io/badge/release-v2.0.2-%23006400)](#)
[![sponsor](https://img.shields.io/badge/sponsor-DigitalVPS.ir-%23FF0000)](https://client.digitalvps.ir/aff.php?aff=52)
[![license](https://img.shields.io/badge/license-Apache2-%23006400)](#)
[![club](https://img.shields.io/badge/club-OPIRAN-%234B0082)](https://t.me/OPIranClub)

</div>

---

[فارسی](https://github.com/ParsaKSH/TAQ-BOSTAN/blob/main/README.md)

# 🚀 TAQ-BOSTAN Project
###  A powerful and stealthy tunneling system designed to bypass advanced censorship and DPI.

---

Script execution command:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/ParsaKSH/TAQ-BOSTAN/main/script.sh)
```

🌟 Project Introduction

TAQ-BOSTAN is a comprehensive solution for creating secure internet tunnels and local IPv6. This project consists of three main parts:

🔒 Creating a highly secure and fast tunnel with Hysteria2

🌐 Creating local IPv6 using SIT

🛡 Creating local IPv6 using WireGuard



---

<details>
<summary>📌 Important Notes</summary>Please enter the port carefully. The Hysteria port is used for communication between two servers and must be the same on both the Iranian and foreign servers. This port must be free and not used by any other service. It is different from the port to be forwarded.

It is recommended to use port 443 or other common HTTPS ports for Hysteria to make the traffic look more normal.

Please, please, please use TLS on your client-side configs. This is vital to protect your server against censorship and access detection.


</details>

---

<details>
<summary>✅ Usage Instructions</summary>
  
---
🔒 Part 1: Secure & Fast Tunnel with Hysteria2

<details>
<summary>✅ Usage Instructions</summary>📌 Benefits:

TLS 1.3 + QUIC encrypted tunnel

All traffic transferred over a single UDP connection

Prevents server from being flagged or blocked

Traffic behavior mimics normal HTTPS (unidentifiable)

No need for a domain (self-signed SSL)

Extremely fast

Built-in speed test for bandwidth between tunneled servers


🚀 Easy Installation:

<details>
<summary>Foreign Server</summary>
1- Run the script on the server and enter 1
  
2- Enter 1 to run the Hysteria script.

3- Type "Foreign".

4- Enter the Hysteria port. (It must not be used by any other service; port 443 is recommended.)

5- Enter a password for Hysteria inbound.

Foreign server config is done.


</details><details>
<summary>Iran Server</summary>
1- Run the script on the server and enter 1.

2- Type "Iran".

3- Choose whether to use IPv6 or IPv4 (if your servers support stable IPv6, it's recommended; Afranet and Respina DigitalVPS offer good IPv6).

4- Enter the number of foreign servers to be tunneled to the Iranian server.

5- Enter the IP, Hysteria port, and password for each.

6- Provide your desired SNI (e.g., google.com — no need for your own domain).

7- Enter the number of ports you want to forward.

8- Enter the ports one by one.

9- Iran server config is done, and all settings will be shown.

10- To test bandwidth between the two servers, rerun the script and enter 7.

11- Enter the server number you wish to test (e.g., 1).

12- Bandwidth between the two servers (post encryption) will be shown. The better the CPU and hosting bandwidth, the faster the connection. DigitalVPS servers perform excellently due to high resources (assuming the foreign server is also good).

</details></details>

---

🌐 Part 2: Local IPv6 with SIT

<details>
<summary>✅ Usage Instructions</summary>📌 Benefits:

Very fast and lightweight (no extra encryption)

Directly supported by Linux kernel

Easy setup


On Iran Server:

Choose server type IRAN

Enter Iranian IP and number of foreign servers

Enter foreign IPs and reboot


On Foreign Server:

Choose server type FOREIGN

Enter foreign and Iranian IP

Enter the foreign server number (matching IRAN server)

Reboot the server


</details>

---

🛡 Part 3: Local IPv6 with WireGuard

<details>
<summary>✅ Usage Instructions</summary>📌 Benefits:

Strong encryption and security

All traffic tunneled via a single UDP connection

Usable even on filtered servers

Choose server type (Iran or Foreign)

Enter public IPs and WireGuard public key

Config files are auto-generated, and the service is activated

Reboot the server


</details></details>

---

📞 Support & Help

<details>
<summary>Contact</summary>
For any questions or issues, ask in the OP-Iran group.💬 
OP-Iran Group:

[OPIranClub](https://t.me/opiranclub)


</details>

---

<img src="https://client.digitalvps.ir/templates/lagom2/assets/img/logo/logo_big.1066038415.png" width="34" /> Buy high-quality Iran & international servers with 10Gb/s port
-

If you need a powerful, stable, and affordable server for tunneling or internet infrastructure, DigitalVPS is the perfect choice.

🔹 VPS in Iran from trusted providers (exclusive, high-quality links):

**Respina** <img src="https://client.digitalvps.ir/templates/lagom2/assets/img/page-manager/Respina-Logo.png" width="34" /> (Recommended by the developer)

Shatel <img src="https://client.digitalvps.ir/templates/lagom2/assets/img/page-manager/shatel1.png" width="24" />

Mobinnet <img src="https://client.digitalvps.ir/Logo/MobinNetLog.png" width="24" />


🔹 International VPS from Skylink datacenter:

Netherlands VPS <img src="https://client.digitalvps.ir/templates/lagom2/assets/img/nilogo.png" width="24" />

Germany VPS <img src="https://client.digitalvps.ir/templates/lagom2/assets/img/page-manager/GB.svg" width="24" />


✨ Features:

Low ping to Turkey & Europe

Stable IPv6

Very high quality and low cost 💰

99.9% uptime


🎯 Build your project on a reliable infrastructure with peace of mind.

📎 Register & buy using the link below:
👉 [https://client.digitalvps.ir/aff.php?aff=52](https://client.digitalvps.ir/aff.php?aff=52)


---

❤️ Support the Project


<summary>Wallet Addresses</summary>If this project was useful to you, you can support it using the wallets below:


 | Currency | Wallet Address |
 |---------|----------------|
 | **Tron** | `TD3vY9Drpo3eLi8z2LtGT9Vp4ESuF2AEgo` |
 | **USDT(ERC20)** | `0x800680F566A394935547578bc5599D98B139Ea22` |
 | **TON** | `UQAm3obHuD5kWf4eE4JmAO_5rkQdZPhaEpmRWs6Rk8vGQJog` |
 | **BTC** | `bc1qaquv5vg35ua7qnd3wlueytw0fugpn8qkkuq9r2` |

<div align="right">
 <a href="https://nowpayments.io/donation?api_key=FH429FA-35N4AGZ-MFMRQ3Q-2H4BF98" target="_blank" rel="noreferrer noopener">
    <img src="https://nowpayments.io/images/embeds/donation-button-white.svg" width="200" alt="Crypto donation button by NOWPayments">
</a>
</div>

Thank you for your support ❤️


---

📝 Project License

<details>
<summary>Details</summary>
TAQ-BOSTAN is released under the Apache license.  
You are free to use, modify, and share it, but please credit my name (Parsa) and link to the project.
</details>

---

⭐️ Give the Project a Star

If you found this project helpful, consider giving it a star. It helps more people discover and benefit from it.


---

Wishing for a proud and prosperous Iran...
Good luck on your journey! 🚀✨


![image](https://github.com/user-attachments/assets/f9f4e79a-0dd4-47ca-862a-8af8504a355a)
Iran, Kermanshah


[![Stargazers over time](https://starchart.cc/ParsaKSH/TAQ-BOSTAN.svg?background=%23333333&axis=%23ffffff&line=%2329f400)](https://starchart.cc/ParsaKSH/TAQ-BOSTAN)
