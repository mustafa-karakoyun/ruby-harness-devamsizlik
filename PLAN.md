# PROJE UYGULAMA PLANI: Öğrenci ve Devamsızlık Kural Motoru (Harness & Ratchet)

Bu plan, **100 Puan** kriterlerinin tamamını karşılayacak şekilde A Koşusu (Rehbersiz), Ratchet (Mandal) Altyapısı ve B Koşusu (Harness ile) adımlarını sırasıyla yürütmek için hazırlanmıştır.

---

## FAZ 0: Ortam Hazırlığı ve İzolasyon
Ajanın A ve B koşularını birbirini kirletmeden yürütmesi için iki izole çalışma alanı veya iki ayrı Git dalı (`branch`) oluşturulmalıdır.

1. Proje kök dizininde `.ruby-version` dosyasını oluştur ve içine yalnızca `3.4` yaz.
2. Dizin yapısını hazırla:
   - `lib/`
   - `test/`
   - `bin/`
   - `logs/` (100 puan kriteri olan A ve B koşusu kanıt logları için)
3. Git deposunu başlat (`git init`) ve ana dalı `main` olarak ayarla.

---

## FAZ 1: A Koşusu (Rehbersiz & Ham Koşu)
**Amaç:** Ajanın hiçbir kural/rehber (`AGENTS.md`) veya test olmadan, yalnızca genel bir istemle nasıl davrandığını gözlemlemek ve gerçek hatalarını yakalamak.

1. `git checkout -b kosu-a` dalına geç. (Bu dalda `AGENTS.md`, `CLAUDE.md` veya `test/` dosyaları **KESİNLİKLE OLMAMALIDIR**).
2. Ajanı temiz bir oturumda şu tek cümlelik istemle çalıştır:
   > `"Öğrenci devamsızlık kontrolü yap, devamsızlık sınırı %30'dur."`
3. Koşu tamamlandığında şunları kaydet ve `logs/kosu_a_kanit.md` dosyasına yaz:
   - Toplam tur sayısı (Turns) ve tahmini/gerçek girdi-çıktı token miktarı.
   - Üretilen kodun kopyası veya özeti.
   - **Kritik Hata Analizi:**
     - Tam 3 devamsızlıkta (`devamsizlik == 3`) `>= 3` mü kullandı yoksa `> 3` mü?
     - Durum metotlarını (`aktif?`, `mezun?` vb.) nasıl tanımladı? (`define_method` yerine `method_missing` veya çekirdek sınıflara monkey patch yaptı mı?)
     - Sınıf/dosya yapısını (`lib/ogrenci.rb`, `lib/devamsizlik_kontrol.rb`) doğru kurdu mu?
     - Özgün kuralı (3. kural) veya `0..10` oturum sınırını ele aldı mı?
4. Bu daldaki çıktıları sakla ve `git checkout main` ile ana dala dön.

---

## FAZ 2: Ratchet (Mandal) — Hatadan Kalıcı Kurala Dönüşüm
**Amaç:** A koşusunda tespit edilen tüm eksikleri ve hataları kalıcı bir mühendislik altyapısına (Rehber + Sensör + Doğrulama Kancası) dönüştürmek.

### 2.1. Rehber Katmanı (`AGENTS.md` & `CLAUDE.md`)
Kök dizinde gereksiz açıklamalardan arındırılmış, sert ve net anayasa maddelerinden oluşan `AGENTS.md` dosyasını oluştur:
- **Dil & Sürüm:** Ruby 3.4 standartlarına tam uyum.
- **Mimari:** `lib/ogrenci.rb` içinde `Ogrenci` sınıfı, `lib/devamsizlik_kontrol.rb` içinde `DevamsizlikKontrol` sınıfı yer alır.
- **Veri Modeli (`Ogrenci`):** `ad` (String), `durum` (`:aktif`, `:donduruldu`, `:mezun`), `devamsizlik` (`0..10` arası tam sayı; aralık dışı değerlerde `ArgumentError` fırlatır).
- **Metot Üretimi Yasağı:** Durum sorgu metotları (`aktif?`, `donduruldu?`, `mezun?`) yalnızca `define_method` ile tanımlanır. `method_missing` ve standart/çekirdek sınıflara (`Integer`, `String`, `Object` vb.) monkey patch **KESİNLİKLE YASAKTIR** (0 puan sebebidir).
- **İş Kuralları (`DevamsizlikKontrol`):**
  1. `:riskli` -> `devamsizlik >= 3` (Sınır vaka: **tam 3 devamsızlık riskli SAYILIR**).
  2. `:kaldi` -> `devamsizlik >= 4`.
  3. Özgün Kural (`:onur_adayi` veya `:burs_kesilir` vb. birini seç ve net tanımla — örn: `:onur_adayi` -> `durum == :aktif && devamsizlik == 0`, veya `:burs_kesilir` -> `devamsizlik >= 3 && durum == :aktif`).
- Sembolik bağı oluştur: `ln -s AGENTS.md CLAUDE.md`

### 2.2. Sensör Katmanı (`test/ogrenci_test.rb`)
Minitest (`minitest/autorun`) kullanarak şu senaryoları kapsayan test paketini yaz:
- **Sınır Değer Testi:** `devamsizlik = 3` olan öğrencinin `:riskli` döndürdüğünü doğrula (`assert`). `devamsizlik = 2` için riskli olmadığını doğrula (`refute`).
- **Kaldı Testi:** `devamsizlik = 4` ve üzeri için `:kaldi` döndürdüğünü doğrula.
- **Özgün Kural Testi:** Seçilen 3. kuralın hem pozitif hem negatif sınır durumlarını test et.
- **Metot Üretimi & Güvenlik Testi:** `aktif?`, `donduruldu?`, `mezun?` metotlarının `define_method` ile oluştuğunu (`respond_to?`) ve bilinmeyen bir metot çağrıldığında `NoMethodError` fırlattığını (`method_missing` kullanılmadığını) doğrula.
- **Geçersiz Girdi Testi:** `devamsizlik` için `-1` veya `11` verildiğinde hata fırlattığını test et.

### 2.3. Otomatik Doğrulama Kancası (`bin/kontrol`)
1. `bin/kontrol` dosyasını oluştur ve çalıştırılabilir yap (`chmod +x bin/kontrol`).
2. İçeriğine şunları ekle:
   - Kod içinde `method_missing` veya çekirdek sınıf (`class Integer`, `class String`, `class Object`, `class Array`) açılımı olup olmadığını `grep` ile tarayan statik kontrol (varsa çıkış kodu `1` ile reddet).
   - `ruby -Ilib:test test/ogrenci_test.rb` komutunu çalıştıran test koşucusu.
3. Git `pre-commit` veya arka plan dosya izleme kancası olarak `.git/hooks/pre-commit` içine `./bin/kontrol` çağrısını bağla ve `README.md` içinde nasıl çalıştığını belgele.

### 2.4. Ratchet Günlüğü (`RATCHET_LOG.md`)
A koşusundan çıkan gerçek hataları aşağıdaki tablo formatında `RATCHET_LOG.md` dosyasına işle:

| # | A Koşusunda Karşılaşılan Hata | Kalıcı Kural / Test Çözümü | Katman (Rehber / Sensör / Kanca) |
|---|---|---|---|
| 1 | *(Örn: Tam 3 devamsızlıkta `> 3` kullanıldı)* | *(`AGENTS.md` Madde 5 ve `test_tam_3_devamsizlik_risklidir` eklendi)* | Rehber + Sensör |
| 2 | *(A koşusundaki gerçek 2. hata)* | *(Çözüm)* | ... |

---

## FAZ 3: B Koşusu (Harness ile Koşu) ve Ölçüm
**Amaç:** Hazırlanan `AGENTS.md`, `test/ogrenci_test.rb` ve `bin/kontrol` kancası aktifken ajana aynı görevi sıfırdan yaptırmak ve verimliliği ölçmek.

1. `AGENTS.md`, `CLAUDE.md`, `test/ogrenci_test.rb`, `bin/kontrol` ve `RATCHET_LOG.md` dosyalarının mevcut olduğundan emin ol. (`lib/` klasörünü boş bırak).
2. Yeni ve temiz bir ajan oturumu başlat. Ajanın `AGENTS.md` dosyasını okumasını ve her değişiklikten sonra `./bin/kontrol` çalıştırmasını sağla.
3. Aynı görevi ver: `"Öğrenci ve devamsızlık kural motorunu geliştir."`
4. Koşu bittiğinde `./bin/kontrol` çıktısının tamamen yeşil (0 hata) olduğunu doğrula.
5. Tüm terminal çıktılarını, tur sayısını ve token kullanımını `logs/kosu_b_kanit.md` dosyasına kaydet.

---

## FAZ 4: Dokümantasyon ve Son Teslim Kontrolü (`README.md`)
`README.md` dosyasını aşağıdaki bölümleri içerecek şekilde oluştur:

1. **Proje Özeti ve Kurulum:** Ruby 3.4 gereksinimi ve `./bin/kontrol` doğrulama kancasının kullanımı.
2. **A/B Koşusu ve Ölçüm Raporu:** `logs/kosu_a_kanit.md` ve `logs/kosu_b_kanit.md` verilerine dayanan net sayısal karşılaştırma tablosu:

| Metrik | A Koşusu (Rehbersiz) | B Koşusu (Harness ile) | Fark / Kazanım |
|---|---|---|---|
| **Tur Sayısı (Turns)** | *X tur* | *Y tur* | *-%Z azalma* |
| **İlk Seferde Hata Sayısı** | *X hata* | *0 hata* | *%100 önlendi* |
| **Girdi / Çıktı Token** | *Girdi: X / Çıktı: Y* | *Girdi: A / Çıktı: B* | *Toplam token analizi* |
| **Gözlemler** | *(Sınır değer ve mimari hataları)* | *(İlk turda temiz, testlerden geçmiş kod)* | - |

3. **Yapamadıklarım:** Süreç boyunca karşılaşılan kısıtlar, kapsam dışı bırakılan kenar durumlar veya geliştirilmeye açık noktalar (Hocanın zorunlu tuttuğu bölüm).

---

## TESLİM ÖNCESİ KONTROL LİSTESİ (0 Puan Risklerini Sıfırlama)
- [ ] GitHub deposu **Public** durumda mı?
- [ ] `.ruby-version` dosyası `3.4` içeriyor mu?
- [ ] `lib/ogrenci.rb` ve `lib/devamsizlik_kontrol.rb` temiz ve çalışıyor mu?
- [ ] `method_missing` ve monkey patch kesinlikle **YOK** mu?
- [ ] `AGENTS.md` ve `CLAUDE.md` (sembolik bağ) mevcut mu?
- [ ] `test/ogrenci_test.rb` içinde tam 3 devamsızlık (`>= 3`) testi var mı ve yeşil mi?
- [ ] `bin/kontrol` çalışır ve belgelenmiş durumda mı?
- [ ] `RATCHET_LOG.md` gerçek A koşusu hatalarını içeriyor mu?
- [ ] `logs/` klasöründe A ve B koşularının kanıt çıktıları var mı?
- [ ] `README.md` içinde A/B tablosu ve **Yapamadıklarım** başlığı yer alıyor mu?