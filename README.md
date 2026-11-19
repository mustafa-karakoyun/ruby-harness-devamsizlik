# Öğrenci ve Devamsızlık Kural Motoru (Harness & Ratchet Mühendisliği)

Bu proje, yapay zekâ ajanlarının yazılım geliştirme süreçlerinde yaptığı sınır değer, mimari ve metaprogramlama hatalarını **Harness (Koşum Takımı)** ve **Ratchet (Mandal)** mühendisliği ilkeleriyle kalıcı olarak engellemek amacıyla geliştirilmiştir.

---

## 1. Proje Özeti ve Kurulum

### Gereksinimler
- **Ruby Sürümü:** `3.4` (`.ruby-version` dosyasında tanımlıdır).
- **Test Çatısı:** `minitest/autorun` (Ruby standart kütüphanesi).

### Mimari ve Dosya Yapısı
```text
.
├── .ruby-version              # Ruby 3.4 sürüm tanımı
├── AGENTS.md                  # Ajan mühendislik anayasası (Rehber Katmanı)
├── CLAUDE.md -> AGENTS.md     # Sembolik bağ (120000 Git symlink)
├── RATCHET_LOG.md             # A koşusu hatalarından kalıcı kurallara dönüşüm tablosu
├── .claude/
│   └── settings.json          # PostToolUse kancası: ajan her kaydettiğinde bin/kontrol çalışır
├── bin/
│   ├── kontrol                # Statik analiz + Minitest doğrulama kancası
│   └── kanca_kur              # bin/kontrol'ü .git/hooks/pre-commit olarak kurar
├── lib/
│   ├── ogrenci.rb             # Ogrenci veri modeli (define_method ile durum metotları)
│   └── devamsizlik_kontrol.rb # DevamsizlikKontrol kural motoru (:kaldi, :riskli, :onur_adayi, :normal)
├── test/
│   └── ogrenci_test.rb        # Sınır değer, özgün kural ve güvenlik birim testleri (Sensör Katmanı)
└── logs/
    ├── kosu_a_kanit.md        # A Koşusu (Rehbersiz) transkript ve hata kanıt raporu
    ├── kosu_b_kanit.md        # B Koşusu (Harness ile) transkript ve doğrulama kanıt raporu
    └── kanca_kanit.md         # Kancanın kasıtlı ">" regresyonunu yakaladığını gösteren gerçek çıktı
```

### Doğrulama Kancasının (`./bin/kontrol`) Kullanımı
`./bin/kontrol` üç şekilde çalışır:

| Tetikleyici | Ne zaman çalışır? | Nerede tanımlı? |
|---|---|---|
| **Ajan kancası (Claude Code `PostToolUse`)** | Ajan `Write`/`Edit` ile **her dosya kaydettiğinde** otomatik çalışır. Kontrol başarısız olursa çıkış kodu `2` döner ve hata çıktısı **doğrudan ajanın önüne** düşer; ajan düzeltmeden devam edemez. | `.claude/settings.json` (repoya dahil) |
| **Git kancası (`pre-commit`)** | Her `git commit` öncesi çalışır; kırmızı test varsa commit reddedilir. | `.git/hooks/pre-commit` (`./bin/kanca_kur` ile kurulur) |
| **Manuel** | İstenildiği zaman. | — |

```bash
./bin/kanca_kur   # pre-commit kancasını kurar (klonladıktan sonra bir kez)
./bin/kontrol     # manuel çalıştırma
```

`.git/hooks/` klasörü Git tarafından repoya alınmadığı için kanca, sürüm kontrolündeki `bin/kanca_kur` betiğiyle kurulur. Ajan kancası ise `.claude/settings.json` ile repoyla birlikte gelir ve klonlayan herkes için kendiliğinden devreye girer.

`./bin/kontrol` üç aşamalı denetim uygular:
1. **Mimari Dosya Kontrolü:** `lib/ogrenci.rb`, `lib/devamsizlik_kontrol.rb` ve `test/ogrenci_test.rb` dosyalarının varlığını doğrular.
2. **Statik Kod Analizi (`grep`):**
   - `lib/` altında `method_missing` veya `respond_to_missing?` kullanımını tarar (varsa çıkış kodu `1` ile reddeder).
   - Çekirdek sınıflara (`Integer`, `String`, `Object`, `Array`, `Numeric`, `Symbol`, `Kernel`) monkey patch (sınıf açılımı) yapılıp yapılmadığını denetler.
   - `lib/ogrenci.rb` içinde durum sorgu metotlarının `define_method` ile üretildiğini doğrular.
3. **Birim Test Koşucusu:** `ruby -Ilib:test test/ogrenci_test.rb` komutunu çalıştırarak tüm Minitest senaryolarının `0` hata ile geçtiğini teyit eder.

---

## 2. A/B Koşusu ve Ölçüm Raporu

Aynı görev için iki izole ajan oturumu yürütülmüştür:
- **A Koşusu (`kosu-a` dalı, Oturum `0ba648cc-e02a-45e3-8fce-7fc0b0ee2ec8`):** Hiçbir rehber (`AGENTS.md`), birim testi (`test/ogrenci_test.rb`) veya doğrulama kancası (`bin/kontrol`) olmadan `"Öğrenci devamsızlık kontrolü yap, devamsızlık sınırı %30'dur."` istemiyle çalıştırılmıştır.
- **B Koşusu (`main` dalı, Oturum `f15fda38-6afa-4738-8a48-9617fbbe5413`):** Ratchet mekanizmasıyla oluşturulan `AGENTS.md`, `test/ogrenci_test.rb` ve `bin/kontrol` altyapısı aktifken çalıştırılmıştır.

Transkriptlerden çıkarılan tur tur token tabloları [`logs/kosu_a_kanit.md`](logs/kosu_a_kanit.md) ve [`logs/kosu_b_kanit.md`](logs/kosu_b_kanit.md) dosyalarında yer almaktadır. A koşusunda ajanın ürettiği hatalı kodun kendisi [`kosu-a`](https://github.com/mustafa-karakoyun/ruby-harness-devamsizlik/tree/kosu-a) dalında korunmaktadır (bkz. `lib/devamsizlik_kontrol.rb:36` → `devamsizlik_orani > DEVAMSIZLIK_SINIRI_YUZDE`). Hataların tam listesi ve kalıcı kurallara dönüşümü: [`RATCHET_LOG.md`](RATCHET_LOG.md).

| Metrik | A Koşusu (Rehbersiz) | B Koşusu (Harness ile) | Fark / Kazanım |
|---|---|---|---|
| **Kod Üretim Tur Sayısı (Turns)** | 7 tur *(Toplam oturum: 12 tur)* | **2 tur** *(Toplam oturum: 11 tur)* | **-%71,4 azalma** (Kod üretim turlarında) |
| **İlk Seferde Hata Sayısı** | **6 kritik hata** | **0 hata** | **%100 hata önleme** |
| **Girdi / Çıktı Token (Kod Üretimi, A: tur 1–7, B: tur 1–2)** | Girdi: 22.549 (Brüt: 67.688) / Çıktı: 2.393 | Girdi: 14.039 (Brüt: 23.843) / **Çıktı: 831** | **-%37,7 girdi (brüt -%64,8) / -%65,3 çıktı** |
| **Girdi / Çıktı Token (Tüm Oturum)** | Girdi: 34.720 (Brüt: 132.427) / Çıktı: 3.510 | Girdi: 36.614 (Brüt: 168.711) / **Çıktı: 1.972** | **+%5,5 girdi (brüt +%27,4) / -%43,8 çıktı** |
| **Gözlemler** | 1) Tam %30 devamsızlıkta `> 30.0` kullanarak sınır vakayı `"Geçti"` saydı (`>= 3` yerine `>` hatası).<br>2) `lib/ogrenci.rb` dosyasını oluşturmayıp iki sınıfı tek dosyada birleştirdi.<br>3) `define_method` ile `aktif?`, `donduruldu?`, `mezun?` metotlarını üretmedi.<br>4) `0..10` tam sayı oturum sınırını ve `:onur_adayi` özgün kuralını kurgulamadı. | `AGENTS.md` ve `test/ogrenci_test.rb` okunduktan sonra **ilk denemede** `lib/ogrenci.rb` ve `lib/devamsizlik_kontrol.rb` ayrımı, `define_method` kullanımı, `devamsizlik >= 3` (`:riskli`) sınır değeri ve `:onur_adayi` kuralı **0 hata** ile üretildi. | Rehber (`AGENTS.md`) + Sensör (`ogrenci_test.rb`) + Kanca (`bin/kontrol`) üçlüsü belirsizliği tamamen ortadan kaldırdı. |

> **Brüt** = önbelleksiz girdi + önbellekten okunan girdi. Tüm değerler `logs/` altındaki tur tablolarının satır toplamlarıdır.

### Token Analizi: Rehber girdi tokenını artırdı mı, toplamda kazandırdı mı?

- **Kod üretim fazında net kazanç var.** B, rehberi ve testleri ilk turda okuduğu için ilk tur girdisi A'dan büyük (9.803'e karşı 8.513). Buna rağmen doğru kodu 2. turda yazdığı için kod üretim fazının toplam girdisi 22.549'dan 14.039'a (-%37,7), çıktısı 2.393'ten 831'e (-%65,3) düştü.
- **Tüm oturumda girdi tokenı arttı.** B'nin toplam girdisi 34.720'den 36.614'e (+%5,5), brüt girdisi 132.427'den 168.711'e (+%27,4) çıktı. Sebep: kod 2. turda bitmesine rağmen ajan, Windows sandbox kısıtı (`0xC0000022`) yüzünden `bin/kontrol`'ü çalıştırmak için 6 tur daha harcadı (tur 3–8). Toplam tur sayısı bu yüzden yalnızca 12'den 11'e indi.
- **Çıktı tokenı her iki ölçekte de azaldı** (tüm oturumda -%43,8). Ajan deneme-yanılma ile kod üretmek yerine kurala uygun kodu tek seferde yazdı.
- **Sonuç:** Rehber, kod üretimini ucuzlattı ve ilk seferdeki hatayı 6'dan 0'a indirdi. Tüm oturumdaki girdi artışı rehberden değil doğrulama ortamındaki kısıttan kaynaklanıyor; sandbox engeli olmasaydı oturum 3 turda (oku → yaz → `bin/kontrol`) bitebilirdi. Bu son cümle ölçüm değil tahmindir.

---

## 3. Yapamadıklarım

Süreç boyunca karşılaşılan kısıtlar, kapsam dışı bırakılan kenar durumlar ve geliştirilmeye açık noktalar aşağıda şeffaf biçimde listelenmiştir:

1. **Windows Sandbox Ortamında MSYS2 / Ruby İkili Dosya Kısıtı (`0xC0000022`):**
   - Geliştirme ortamı Windows üzerinde çalıştığından, ajan sandbox'ı (`Standard Sandbox Mode`) çalışma dizini dışındaki `C:\Ruby40-x64\bin\ruby.exe` ve `C:\Program Files\Git\bin\bash.exe` süreçlerinin Windows adlandırılmış nesnelerine (`\BaseNamedObjects\msys-2.0...`) erişimini `STATUS_ACCESS_DENIED (0xC0000022)` koduyla kısıtlamıştır. Bu nedenle B koşusunda alt-ajan `./bin/kontrol` betiğini sandbox içinden doğrudan tetikleyememiş ve doğrulama adımlarında fazladan 6 tur harcamıştır. POSIX (Linux/macOS) ortamında veya yerel terminalde `./bin/kontrol` doğrudan çalışmaktadır.
2. **Mazeretli / Raporlu Devamsızlık Ayrımının Kapsam Dışı Bırakılması:**
   - Mevcut veri modelinde `devamsizlik` alanı `0..10` aralığında tek bir tam sayı olarak modellenmiştir. Sağlık raporu veya izinli devamsızlık gibi alt kırılımlar, kural motorunun deterministik ve yalın kalması adına kapsam dışı bırakılmıştır.
3. **Çoklu Ders ve Dönem Bazlı Kredi Ağırlıklandırması:**
   - Toplam ders oturumu `10` olarak sabitlenmiştir (`%30` = `3` oturum). Farklı haftalık ders saatlerine sahip dersler için dinamik oturum sayısı hesabı yerine anayasadaki sabit `0..10` oturum modeli uygulanmıştır.
4. **Ajan kancası (`PostToolUse`) B koşusundan sonra eklendi:**
   - B koşusu sırasında harness'te `bin/kontrol` ve `pre-commit` kancası vardı, ancak "her kaydettiğinde çalışan" `.claude/settings.json` kancası yoktu; ajan `bin/kontrol`'ü elle çağırmak zorunda kaldı. Bu kanca sonradan eklendi ve yalnızca kasıtlı regresyon simülasyonuyla doğrulandı ([`logs/kanca_kanit.md`](logs/kanca_kanit.md)); kancayla yeni bir B koşusu yapılmadı.
5. **Ruby sürümü:**
   - `.ruby-version` `3.4` olarak tanımlıdır, ancak yerel geliştirme makinesinde Ruby `4.0.7` kuruludur ve testler bu sürümle koşturulmuştur. Kod sürüme özgü bir özellik kullanmamaktadır; 3.4 ile ayrıca test edilmemiştir.
6. **Kalıcı Veri Katmanı (Veritabanı / JSON Serileştirme):**
   - `Ogrenci` ve `DevamsizlikKontrol` sınıfları tamamen bellek içi (in-memory) saf değer/kural nesneleri olarak tasarlanmış; harici veritabanı veya dosya tabanlı kayıt (persistence) katmanı eklenmemiştir.

