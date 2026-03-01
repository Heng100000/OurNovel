# 🚀 របៀប Run Project ឱ្យបានត្រឹមត្រូវ (How to Run Correctly)

ដើម្បីកុំឱ្យមានបញ្ហា 404 (ngrok error) និងដើម្បីឱ្យ Telegram Bot ដំណើរការបាន ១០០% រាល់ពេល Restart កុំព្យូទ័រ សូមអនុវត្តតាមជំហានទាំងនេះ៖

---

## ១. ដំណើរការ Laravel Backend (Start Server)
សូមបើក Terminal ក្នុង `svelte_demo` ហើយវាយបញ្ជានេះ (ប្រើ IP `0.0.0.0` ដើម្បីឱ្យ Device ផ្សេងទៀត connect បាន):
```powershell
php artisan serve --host=0.0.0.0 --port=8001
```
> [!NOTE]
> **សំខាន់:** ការប្រើ `--host=0.0.0.0` គឺដើម្បីឱ្យទូរស័ព្ទ (Physical Device) អាចមើលឃើញ Server តាមរយៈ Wi-Fi IP (ឧទាហរណ៍៖ `192.168.18.4`)។ លោកអ្នកអាចរក IP របស់ម៉ាស៊ីនបានដោយវាយ `ipconfig` ក្នុង Terminal។

---

## ២. ដំណើរការ Laravel Reverb (Start WebSocket Server)
សូមបើក Terminal ថ្មីមួយទៀតក្នុង `svelte_demo` ហើយវាយបញ្ជា:
```powershell
php artisan reverb:start --host=127.0.0.1 --port=8080
```
> [!NOTE]
> **សំខាន់:** Reverb ត្រូវការ Run ដើម្បីឱ្យ Real-time Broadcasting (WebSocket) ដំណើរការបាន។ លោកអ្នកអាច Add `--debug` ដើម្បី Debug គ្រប់ Event ដែលបានផ្ញើ:
> ```powershell
> php artisan reverb:start --host=127.0.0.1 --port=8080 --debug
> ```

---

## ៣. ដំណើរការ ngrok (Start Tunnel)
សូមបើក Terminal ថ្មីមួយទៀត ហើយវាយបញ្ជា (指向 127.0.0.1):
```powershell
ngrok http 127.0.0.1:8001
```
បន្ទាប់មក ចម្លង (Copy) URL ថ្មីដែលបានពី ngrok (ឧទាហរណ៍៖ `https://xxxx.ngrok-free.app`)។

---

## ៤. កំណត់ Webhook ឱ្យ Bot (Update Telegram)
រាល់ពេលដែលលោកអ្នកបិទ/បើក ngrok ម្ដងៗ លោកអ្នកនឹងទទួលបាន URL ថ្មី ដូច្នេះត្រូវធ្វើបច្ចុប្បន្នភាព (Update) វាទៅកាន់ Telegram:
```powershell
# ដក YOUR_NEW_URL ចេញ ហើយដាក់ URL ដែលចម្លងបានពី ngrok ចូលជំនួស
php artisan telegram:set-webhook https://YOUR_NEW_URL/api/telegram/webhook
```

---

## ៥. ដំណើរការ Flutter (Run App)
សូមប្រាកដថា `ApiConstants.baseUrl` ក្នុង `lib/core/constants/api_constants.dart` គឺត្រូវជាមួយ IP របស់កុំព្យូទ័រ (ឧទាហរណ៍៖ `192.168.18.4:8001`) បន្ទាប់មក run:
```powershell
flutter run
```

---

### បញ្ហាដែលជួបញឹកញាប់ (Troubleshooting)
- **Error 404 ក្នុង ngrok:** កើតឡើងដោយសារ ngrok ព្យាយាមរក `localhost` តែ server រត់លើ `127.0.0.1`។ (ដំណោះស្រាយ: ប្រើ `ngrok http 127.0.0.1:8001`)
- **Bot មិនឆ្លើយតប:** ពិនិត្យមើល Webhook status ដោយប្រើ command: 
  `php artisan tinker --execute="print_r(app(App\Services\TelegramService::class)->getWebhookInfo());"`
