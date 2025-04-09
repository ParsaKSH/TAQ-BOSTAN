

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

[English](https://github.com/ParsaKSH/TAQ-BOSTAN/blob/main/README-en.md)


# 🚀 پروژه‌ی طاق‌بستان (TAQ-BOSTAN)
### غیرقابل شناسایی ترین تونل برای دور زدن فیلترینگ

---

دستور اجرای اسکریپت:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Shellgate/TAQ-BOSTAN/main/script.sh)
```
## 🌟 معرفی پروژه
پروژه‌ی **طاق‌بستان** یک راهکار جامع برای ایجاد تونل‌های امن اینترنتی و IPv6 لوکال است. این پروژه شامل سه بخش اصلی می‌شود:

- 🔒 ساخت تونل بسیار امن و سریع با Hysteria2
- 🌐 ایجاد IPv6 لوکال با SIT
- 🛡 ایجاد IPv6 لوکال با WireGuard

---
<details>
<summary>📌 نکات بسیار مهم</summary>
   
- لطفا در وارد کردن پورت دقت کنید، پورت هیستریا برای ارتباط بین دو سرور هست و باید در سرور ایران و سرور خارج یک مقدار وارد شود، این پورت باید در سرور آزاد باشد و هیچ سرویس دیگری از آن استفاده نکند، این پورت با پورتی که باید فوروارد شود متفاوت است.
- پیشنهاد می‌کنم برای هیستریا از پورت 443 یا دیگر پورت های Https در جهت عادی جلوه دادن بیشتر ارتباط استفاده کنید.
- لطفا لطفا لطفا کانفیگ های سمت کاربر خودتون رو tls دار کنید. این موضوع برای حفاظت از سرور شما در برابر فیلترینگ و اکسسی بسیار حیاتی است.
    
  
</details>

---

<details>
<summary>✅ مشاهده توضیحات و آموزش استفاده</summary>

## 🔒 بخش اول: تونل امن و سریع با Hysteria2
<details>
<summary>✅ مشاهده توضیحات و آموزش استفاده</summary>

### 📌 مزایا:
- تونل رمزنگاری‌شده **TLS 1.3 + QUIC**
- انتقال تمام ترافیک از طریق یک کانکشن واحد UDP
- جلوگیری کامل از مشکوک شدن سرور و ایران اکسس شدن
- رفتار ترافیک مشابه HTTPS عادی (بدون ریسک شناسایی)
- بدون نیاز به دامنه (استفاده از SSL خودامضا)
- بسیار سریع
- دارای اسپیدتست داخلی برای تست پهنای باند هیستریا بین دو سرور تونل شده

### 🚀 نصب آسان:

<details>
<summary>سرور خارج</summary>

1-اسکریپت را روی سرور اجرا کنید و شماره1 را وارد کنید.

2-عدد 1 را وارد کنید تا اسکریپت هیستریا اجرا شود.

3-کلمه "Foreign" را وارد کنید.

4-پورت هیستریا را وارد کنید.(طبق توضیحات بالا، این پورت نباید توسط هیچ سرویس دیگری در هیچیک از سرور های شما استفاده شده باشد؛ پیشنهاد می‌کنم از پورت 443 استفاده کنید.)

5-یک رمز دلخواه برای اینباند هیستریا وارد کنید.

-کانفیگ سرور خارج به پایان رسید.
  
</details>

<details>
<summary>سرور ایران</summary>

1-اسکریپت را روی سرور اجرا کنید و شماره1 را وارد کنید.

2-کلمه "Iran" را وارد کنید.

3-انتخاب کنید که می‌خواهید از IPv6 استفاده کنید یا IPv4(اگر سرور های شما آیپی6 خوبی دارند، پیشنهاد می‌شود از آیپی6 استفاده کنید. سرورهای افرانت و رسپینا DigitalVPS آیپی6 بسیار خوب و پایداری دارند.)

4-تعداد سرور های خارج خود که قصد تانل کردن آنها به سرور ایران را دارید وارد کنید.

5-به ترتیب آیپی، پورت هیستریا و رمز تنظیم شده در آنها را وارد کنید.

6-در این فیلد، SNI دلخواه خود را بگذارید، مثلا google.com (نیاز به استفاده از دامنه خودتان نیست.)

7-تعداد پورت هایی که قصد فوروارد کردن را در این سرور خارج دارید وارد کنید.

8-به ترتیب پورت ها را وارد کنید.


9-کانفیگ سرور ایران تمام شد، سرور ها و اطلاعات کانفیگ آنها به شما نمایش داده شده.

10-حالا برای انجام تست سرعت و پهنای باند بین دو سرور می‌توانید اسکریپت را دوباره اجرا کنید و شماره7 را وارد کنید.

11-از شما شماره سرور می‌خواهد که هرکدام از سرور های خارجی که به سرور ایران متصل کرده باشید را می‌توانید مورد تست قرار دهید، مثلا سرور اول(عدد 1 را وارد کنید.)

12-پهنای باند بین دو سرور شما بعد از رمزنگاری ها و پردازش های هیستریا مشخص می‌شود.(هرچه پردازشگر سرور شما قدرتمند تر باشد، و هاستینگ پهنای باند بیشتری را در اختیار شما قرار داده باشد، سرعت بین دو سرور نیز بیشتر خواهد بود. سرور های DigitalVPS به دلیل برخورداری از منابع سخت افزاری بالا، نتیجه بسیار خوبی به شما هدیه خواهند کرد.(اگر سخت افزار سرور خارج شما هم کافی باشد.))

</details>


</details>

---

## 🌐 بخش دوم: ایجاد IPv6 لوکال با SIT
<details>
<summary>✅ مشاهده توضیحات و آموزش استفاده</summary>

### 📌 مزایا:
- بسیار سریع و سبک (بدون رمزنگاری اضافی)
- پشتیبانی مستقیم توسط هسته لینوکس (کرنل)
- نصب و راه‌اندازی آسان

**نحوه اجرا روی سرور ایران:**
- نوع سرور را **IRAN** انتخاب کنید.
- IP سرور ایران و تعداد سرورهای خارجی را وارد کنید.
- به‌ترتیب IP سرورهای خارجی را وارد کرده و سرور را ریبوت کنید.

**نحوه اجرا روی سرور خارجی:**
- نوع سرور را **FOREIGN** انتخاب کنید.
- IP سرور خارجی و IP سرور ایران را وارد کنید.
- شماره سرور خارجی (که در سرور ایران وارد کردید) را مشخص کنید.
- سرور را ریبوت کنید.

</details>

---

## 🛡 بخش سوم: ایجاد IPv6 لوکال با WireGuard
<details>
<summary>✅ مشاهده توضیحات و آموزش استفاده</summary>

### 📌 مزایا:
- امنیت بالا و رمزنگاری قوی
- تونل کردن همه ترافیک‌ها در یک کانکشن واحد UDP
- قابل استفاده روی سرورهای فیلتر شده


- نوع سرور (ایران یا خارجی) را مشخص کنید.
- IP عمومی سرورها و کلید عمومی WireGuard را وارد کنید.
- فایل‌های کانفیگ خودکار ساخته شده و سرویس فعال می‌شود.
- سرور را ریبوت کنید.

</details>

</details>

---

## 📞 پشتیبانی و راهنمایی
<details>
<summary>راه های ارتباطی</summary>
هرگونه سؤال یا مشکل خود را در گروه اپ‌ایران مطرح کنید.

- 💬 **گروه اپ‌ایران:** [OPIranClub](https://t.me/OPIranClub)
</details>

---
## <img src="https://client.digitalvps.ir/templates/lagom2/assets/img/logo/logo_big.1066038415.png" width="34" /> خرید سرور ایران و خارج با کیفیت بالا و پورت 10Gb/s

اگر برای راه‌اندازی تونل‌ها و زیرساخت‌های اینترنتی به یک سرور قدرتمند، پایدار و به‌صرفه نیاز دارید، **DigitalVPS** انتخابی شایسته است.

🔹 ارائه سرورهای مجازی ایران از شرکت‌های معتبر(لینک اختصاصی و با کیفیت):
- **افرانت**<img src="https://client.digitalvps.ir/Logo/afranettttt.png" width="74" /> (پیشنهاد توسعه‌دهنده)
- رسپینا <img src="https://client.digitalvps.ir/templates/lagom2/assets/img/page-manager/Respina-Logo.png" width="34" />
-  شاتل <img src="https://client.digitalvps.ir/templates/lagom2/assets/img/page-manager/shatel1.png" width="24" />
-  مبین‌نت <img src="https://client.digitalvps.ir/Logo/MobinNetLog.png" width="24" />

🔹 سرور های مجازی خارج از دیتاسنتر ***Skylink***

- سرور مجازی هلند <img src="https://client.digitalvps.ir/templates/lagom2/assets/img/nilogo.png" width="24" />
- سرور مجازی آلمان <img src="https://client.digitalvps.ir/templates/lagom2/assets/img/page-manager/GB.svg" width="24" />

✨ ویژگی‌ها:
- **پینگ پایین به ترکیه و اروپا**
- **IPv6 استیبل**
- کیفیت بسیار بالا و قیمت پایین 💰
- آپتایم 99.9%

🎯 با خیال آسوده پروژه‌ی خود را روی زیرساختی مطمئن بنا کنید.

📎 می‌توانید از طریق لینک زیر اقدام به ثبت نام و خرید کنید:  
👉 [https://client.digitalvps.ir/aff.php?aff=52](https://client.digitalvps.ir/aff.php?aff=52)

---


 ## ❤️حمایت مالی از پروژه
  <summary>آدرس ولت‌ها</summary>

اگر پروژه برای شما مفید بود، برای حمایت مالی می‌توانید از آدرس‌های زیر استفاده کنید:

| ارز | آدرس والت |
|-------|------------|
| **Tron** | `TD3vY9Drpo3eLi8z2LtGT9Vp4ESuF2AEgo` |
| **USDT(ERC20)** | `0x800680F566A394935547578bc5599D98B139Ea22` |
| **TON** | `UQAm3obHuD5kWf4eE4JmAO_5rkQdZPhaEpmRWs6Rk8vGQJog` |
| **BTC** | `bc1qaquv5vg35ua7qnd3wlueytw0fugpn8qkkuq9r2` |

<a href="https://nowpayments.io/donation?api_key=FH429FA-35N4AGZ-MFMRQ3Q-2H4BF98" target="_blank" rel="noreferrer noopener">
    <img src="https://nowpayments.io/images/embeds/donation-button-white.svg" width="200" alt="Crypto donation button by NOWPayments">
</a>

از حمایت شما ممنونم ❤️


---

## 📝 لایسنس پروژه
<details>
<summary>توضیحات</summary>
پروژه‌ی طاق‌بستان تحت لایسنس Apache منتشر شده است.  
می‌توانید آزادانه از آن استفاده کنید، تغییر دهید و منتشر کنید؛ اما لطفا نام من (Parsa) و لینک پروژه را ذکر نمایید.
</details>

---

## ⭐️ ستاره دادن به پروژه

اگر این پروژه برایتان مفید بود، خوشحال می‌شوم به آن ستاره بدهید. این باعث می‌شود افراد بیشتری از آن استفاده کنند.

---

به امید سربلندی ایران آباد... 
با آرزوی موفقیت برای شما 🚀✨



![image](https://github.com/user-attachments/assets/f9f4e79a-0dd4-47ca-862a-8af8504a355a)
ایران، کرمانشاه



[![Stargazers over time](https://starchart.cc/Shellgate/TAQ-BOSTAN.svg?background=%23333333&axis=%23ffffff&line=%2329f400)](https://starchart.cc/Shellgate/TAQ-BOSTAN)
