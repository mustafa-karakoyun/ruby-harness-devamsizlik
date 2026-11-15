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
├── bin/
│   └── kontrol                # Statik analiz + Minitest doğrulama kancası (pre-commit)
├── lib/
│   ├── ogrenci.rb             # Ogrenci veri modeli (define_method ile durum metotları)
│   └── devamsizlik_kontrol.rb # DevamsizlikKontrol kural motoru (:kaldi, :riskli, :onur_adayi, :normal)
├── test/
│   └── ogrenci_test.rb        # Sınır değer, özgün kural ve güvenlik birim testleri (Sensör Katmanı)
└── logs/
    ├── kosu_a_kanit.md        # A Koşusu (Rehbersiz) transkript ve hata kanıt raporu
    └── kosu_b_kanit.md        # B Koşusu (Harness ile) transkript ve doğrulama kanıt raporu
```

### Doğrulama Kancasının (`./bin/kontrol`) Kullanımı
Proje kök dizininde yer alan `./bin/kontrol` betiği hem manuel olarak hem de `.git/hooks/pre-commit` Git kancası üzerinden otomatik olarak çalışır:

```bash
chmod +x bin/kontrol
./bin/kontrol
```

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

Detaylı ham transkript tabloları [`logs/kosu_a_kanit.md`](logs/kosu_a_kanit.md) ve [`logs/kosu_b_kanit.md`](logs/kosu_b_kanit.md) dosyalarında yer almaktadır.

| Metrik | A Koşusu (Rehbersiz) | B Koşusu (Harness ile) | Fark / Kazanım |
|---|---|---|---|
| **Kod Üretim Tur Sayısı (Turns)** | 7 tur *(Toplam oturum: 12 tur)* | **2 tur** *(Toplam oturum: 11 tur)* | **-%71,4 azalma** (Kod üretim turlarında) |
| **İlk Seferde Hata Sayısı** | **6 kritik hata** | **0 hata** | **%100 hata önleme** |
| **Girdi / Çıktı Token (Kod Üretimi)** | Girdi: 20.299 / Çıktı: 2.393 | Girdi: 14.039 / **Çıktı: 831** | **-%30,8 girdi / -%65,3 çıktı token tasarrufu** |
| **Girdi / Çıktı Token (Tüm Oturum)** | Girdi: 34.720 (Brüt: 132.427) / Çıktı: 3.510 | Girdi: 36.614 (Brüt: 154.711) / **Çıktı: 1.972** | **-%43,8 toplam çıktı token tasarrufu** |
| **Gözlemler** | 1) Tam %30 devamsızlıkta `> 30.0` kullanarak sınır vakayı `"Geçti"` saydı (`>= 3` yerine `>` hatası).<br>2) `lib/ogrenci.rb` dosyasını oluşturmayıp iki sınıfı tek dosyada birleştirdi.<br>3) `define_method` ile `aktif?`, `donduruldu?`, `mezun?` metotlarını üretmedi.<br>4) `0..10` tam sayı oturum sınırını ve `:onur_adayi` özgün kuralını kurgulamadı. | `AGENTS.md` ve `test/ogrenci_test.rb` okunduktan sonra **ilk denemede** `lib/ogrenci.rb` ve `lib/devamsizlik_kontrol.rb` ayrımı, `define_method` kullanımı, `devamsizlik >= 3` (`:riskli`) sınır değeri ve `:onur_adayi` kuralı **0 hata** ile üretildi. | Rehber (`AGENTS.md`) + Sensör (`ogrenci_test.rb`) + Kanca (`bin/kontrol`) üçlüsü belirsizliği tamamen ortadan kaldırdı. |

---

## 3. Yapamadıklarım

Süreç boyunca karşılaşılan kısıtlar, kapsam dışı bırakılan kenar durumlar ve geliştirilmeye açık noktalar aşağıda şeffaf biçimde listelenmiştir:

1. **Windows Sandbox Ortamında MSYS2 / Ruby İkili Dosya Kısıtı (`0xC0000022`):**
   - Geliştirme ortamı Windows üzerinde çalıştığından, ajan sandbox'ı (`Standard Sandbox Mode`) çalışma dizini dışındaki `C:\Ruby40-x64\bin\ruby.exe` ve `C:\Program Files\Git\bin\bash.exe` süreçlerinin Windows adlandırılmış nesnelerine (`\BaseNamedObjects\msys-2.0...`) erişimini `STATUS_ACCESS_DENIED (0xC0000022)` koduyla kısıtlamıştır. Bu nedenle B koşusunda alt-ajan `./bin/kontrol` betiğini sandbox içinden doğrudan tetikleyememiş ve doğrulama adımlarında fazladan 6 tur harcamıştır. POSIX (Linux/macOS) ortamında veya yerel terminalde `./bin/kontrol` doğrudan çalışmaktadır.
2. **Mazeretli / Raporlu Devamsızlık Ayrımının Kapsam Dışı Bırakılması:**
   - Mevcut veri modelinde `devamsizlik` alanı `0..10` aralığında tek bir tam sayı olarak modellenmiştir. Sağlık raporu veya izinli devamsızlık gibi alt kırılımlar, kural motorunun deterministik ve yalın kalması adına kapsam dışı bırakılmıştır.
3. **Çoklu Ders ve Dönem Bazlı Kredi Ağırlıklandırması:**
   - Toplam ders oturumu `10` olarak sabitlenmiştir (`%30` = `3` oturum). Farklı haftalık ders saatlerine sahip dersler için dinamik oturum sayısı hesabı yerine anayasadaki sabit `0..10` oturum modeli uygulanmıştır.
4. **Kalıcı Veri Katmanı (Veritabanı / JSON Serileştirme):**
   - `Ogrenci` ve `DevamsizlikKontrol` sınıfları tamamen bellek içi (in-memory) saf değer/kural nesneleri olarak tasarlanmış; harici veritabanı veya dosya tabanlı kayıt (persistence) katmanı eklenmemiştir.

