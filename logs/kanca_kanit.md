# Doğrulama Kancası Kanıtı (`bin/kontrol`)

Tarih: 2026-11-19 15:57 · ruby 4.0.7 (2026-09-15 revision 229531a6cf) +PRISM [x64-mingw-ucrt]

Aşağıdaki çıktılar `.claude/settings.json` içindeki `PostToolUse` kanca komutunun birebir çalıştırılmasıyla elde edilmiştir.

## 1. Kasıtlı regresyon: `>= RISK_SINIRI` → `> RISK_SINIRI` (A koşusundaki hatanın tekrarı)

```text
=== [1/3] Mimari Dosya Kontrolü ===
[OK] Zorunlu dosyalar mevcut.
=== [2/3] Statik Kod Analizi (Yasaklı Yapılar) ===
[OK] Statik analiz temiz (method_missing yok, monkey patch yok, define_method mevcut).
=== [3/3] Minitest Birim Testleri ===
Run options: --seed 12362

# Running:

...F.....

Finished in 0.001218s, 7387.9494 runs/s, 32835.3308 assertions/s.

  1) Failure:
OgrenciVeDevamsizlikKontrolTest#test_tam_3_devamsizlik_risklidir [test/ogrenci_test.rb:12]:
Tam 3 devamsızlık riskli sayılmalıdır (>= 3)

9 runs, 40 assertions, 1 failures, 0 errors, 0 skips
[kanca çıkış kodu: 2 → hata ajana geri beslenir]
```

## 2. Düzeltilmiş (mevcut) kod

```text
=== [1/3] Mimari Dosya Kontrolü ===
[OK] Zorunlu dosyalar mevcut.
=== [2/3] Statik Kod Analizi (Yasaklı Yapılar) ===
[OK] Statik analiz temiz (method_missing yok, monkey patch yok, define_method mevcut).
=== [3/3] Minitest Birim Testleri ===
Run options: --seed 13326

# Running:

.........

Finished in 0.001314s, 6849.3151 runs/s, 31202.4353 assertions/s.

9 runs, 41 assertions, 0 failures, 0 errors, 0 skips
=== [BAŞARILI] Tüm kontroller 0 hata ile geçti! ===
[kanca çıkış kodu: 0]
```
