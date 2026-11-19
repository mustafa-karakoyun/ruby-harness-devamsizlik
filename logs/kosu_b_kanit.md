# B Koşusu (Harness ile Koşu) Kanıt Raporu

## 1. Koşu Kimliği ve Ortam Bilgileri
- **Dal (Branch):** `main`
- **Alt-Ajan Oturum ID (Conversation ID):** `f15fda38-6afa-4738-8a48-9617fbbe5413`
- **Transkript Kaynağı:** `.system_generated/logs/transcript.jsonl`
- **Model:** `gemini-4-argon-medium`
- **Verilen İstem (Prompt):**
  > `"Önce AGENTS.md ve test/ogrenci_test.rb dosyalarını oku, ardından kurallara tam uyarak öğrenci ve devamsızlık kural motorunu geliştir (lib/ogrenci.rb ve lib/devamsizlik_kontrol.rb)."`
- **Aktif Harness Bileşenleri:**
  - Rehber Katmanı: `AGENTS.md` ve `CLAUDE.md` (sembolik bağ)
  - Sensör Katmanı: `test/ogrenci_test.rb` (Minitest sınır değer, özgün kural ve güvenlik testleri)
  - Doğrulama Kancası: `bin/kontrol` ve `.git/hooks/pre-commit`
  - Mandal Günlüğü: `RATCHET_LOG.md`

---

## 2. Tur Sayısı ve Gerçek Token Ölçümü

### 2.1. Kod Üretimi Tamamlanana Kadar (Çekirdek Geliştirme Fazı)
Ajan, `AGENTS.md`, `test/ogrenci_test.rb` ve `bin/kontrol` dosyalarını tek turda paralel okuyup **2. turda** (`step_index: 7`) hem `lib/ogrenci.rb` hem `lib/devamsizlik_kontrol.rb` dosyalarını **sıfır hata ile tek seferde** üretmiştir:

| Tur (Turn) | Step Index | Eylem (Tool Call) | Girdi Token (Uncached) | Önbellek Okuma (Cache Read) | Çıktı Token (Output) |
|---|---|---|---|---|---|
| 1 | 1 | `read_file` x5 (`AGENTS.md`, `test/ogrenci_test.rb`, `bin/kontrol`) | 9.803 | 0 | 188 |
| 2 | 7 | `write_file` x2 (`lib/ogrenci.rb`, `lib/devamsizlik_kontrol.rb`) | 4.236 | 9.804 | 643 |
| **Kod Üretim Toplamı** | **9 Adım** | **2 Tur (Turns)** | **14.039** | **9.804** | **831** |

### 2.2. Doğrulama ve Raporlama Dahil Tüm Oturum
Kod yazımı sonrasında Windows Sandbox (`0xC0000022`) ortamında doğrulama ve raporlama adımları dahil tam transkript dökümü:

| Tur (Turn) | Step Index | Eylem (Tool Call) | Girdi Token (Uncached) | Önbellek Okuma (Cache Read) | Çıktı Token (Output) |
|---|---|---|---|---|---|
| 1 | 1 | `read_file` (`AGENTS.md`, `test/ogrenci_test.rb`, `bin/kontrol`) | 9.803 | 0 | 188 |
| 2 | 7 | `write_file` (`lib/ogrenci.rb`, `lib/devamsizlik_kontrol.rb`) | 4.236 | 9.804 | 643 |
| 3 | 10 | `run_command` (`./bin/kontrol` çalıştırma) | 2.852 | 11.991 | 46 |
| 4 | 12 | `run_command` (Git Bash ile `./bin/kontrol`) | 2.300 | 12.794 | 63 |
| 5 | 14 | `run_command` (`ruby -Ilib -Itest test/ogrenci_test.rb`) | 2.280 | 13.045 | 59 |
| 6 | 16 | `run_command` (Ruby ortam kontrolü) | 2.199 | 13.276 | 68 |
| 7 | 18 | `run_command` (Ruby çıkış kodu kontrolü) | 2.571 | 13.426 | 71 |
| 8 | 20 | `run_command` (`./bin/kontrol` sandbox dışı istek) | 2.221 | 13.948 | 69 |
| 9 | 22 | `read_file` (`lib/ogrenci.rb`, `lib/devamsizlik_kontrol.rb` son kontrol) | 2.277 | 14.120 | 81 |
| 10 | 25 | `send_message` (Üst ajana raporlama) | 3.046 | 14.348 | 666 |
| 11 | 27 | Final yanıtı | 2.829 | 15.345 | 18 |
| **Oturum Toplamı** | **28 Adım** | **11 Tur (Kod Üretimi: 2 Tur)** | **36.614** | **132.097** | **1.972** |

- **Toplam Girdi Token (Uncached):** `36.614`
- **Toplam Girdi Token (Cache Dahil Brüt):** `168.711`
- **Toplam Çıktı Token (Output):** `1.972`
- **Kod Üretimi Tur Sayısı:** `2` tur (A koşusundaki `7` tura kıyasla **%71,4 azalma**)
- **Kod Üretimi Çıktı Token:** `831` token (A koşusunun kod üretim fazındaki (tur 1–7) `2.393` çıktı tokenına kıyasla **%65,3 tasarruf**; tüm oturum bazında `3.510` → `1.972` ile **%43,8 tasarruf**)
- **İlk Seferde Hata Sayısı:** `0` hata (Sınır değer `>= 3`, `define_method`, `0..10` aralığı, `:onur_adayi` ve dosya ayrımı ilk turda %100 doğru üretildi).

---

## 3. B Koşusunda Üretilen Kodun Kopyası

### `lib/ogrenci.rb`
```ruby
# frozen_string_literal: true

class Ogrenci
  GECERLI_DURUMLAR = %i[aktif donduruldu mezun].freeze
  DEVAMSIZLIK_ARALIGI = (0..10)

  attr_reader :ad, :durum, :devamsizlik

  def initialize(ad:, durum: :aktif, devamsizlik: 0)
    raise ArgumentError, 'Geçersiz ad' if !ad.is_a?(String) || ad.strip.empty?
    raise ArgumentError, 'Geçersiz durum' unless GECERLI_DURUMLAR.include?(durum)
    raise ArgumentError, 'Geçersiz devamsızlık' unless devamsizlik.is_a?(Integer) && DEVAMSIZLIK_ARALIGI.cover?(devamsizlik)

    @ad = ad
    @durum = durum
    @devamsizlik = devamsizlik
  end

  GECERLI_DURUMLAR.each do |durum_adi|
    define_method(:"#{durum_adi}?") do
      @durum == durum_adi
    end
  end
end
```

### `lib/devamsizlik_kontrol.rb`
```ruby
# frozen_string_literal: true

require_relative 'ogrenci'

class DevamsizlikKontrol
  RISK_SINIRI = 3
  KALMA_SINIRI = 4

  def self.degerlendir(ogrenci)
    dogrula!(ogrenci)

    return :kaldi if kaldi?(ogrenci)
    return :riskli if riskli?(ogrenci)
    return :onur_adayi if onur_adayi?(ogrenci)

    :normal
  end

  def self.riskli?(ogrenci)
    dogrula!(ogrenci)
    ogrenci.devamsizlik >= RISK_SINIRI
  end

  def self.kaldi?(ogrenci)
    dogrula!(ogrenci)
    ogrenci.devamsizlik >= KALMA_SINIRI
  end

  def self.onur_adayi?(ogrenci)
    dogrula!(ogrenci)
    ogrenci.aktif? && ogrenci.devamsizlik == 0
  end

  def self.dogrula!(ogrenci)
    raise ArgumentError, 'Ogrenci nesnesi bekleniyor' unless ogrenci.is_a?(Ogrenci)
  end
  private_class_method :dogrula!
end
```

---

## 4. `./bin/kontrol` ve Birim Testi Doğrulama Çıktısı

```text
=== [1/3] Mimari Dosya Kontrolü ===
[OK] Zorunlu dosyalar mevcut.
=== [2/3] Statik Kod Analizi (Yasaklı Yapılar) ===
[OK] Statik analiz temiz (method_missing yok, monkey patch yok, define_method mevcut).
=== [3/3] Minitest Birim Testleri ===
Run options: --seed 42198

# Running:

.........

Finished in 0.004120s, 2184.4660 runs/s, 6310.6796 assertions/s.
9 runs, 26 assertions, 0 failures, 0 errors, 0 skips
=== [BAŞARILI] Tüm kontroller 0 hata ile geçti! ===
```

> **Not (assertion sayısı farkı):** Yukarıdaki çıktı B koşusu sırasında alınmıştır ve `26 assertions` gösterir. Test sayısı (`9 runs`) aynı kalmakla birlikte, `test/ogrenci_test.rb` dosyası B koşusundan sonra, repoya ilk kez commit edilmeden (`275908f`) önce mevcut testlere ek `assert`/`refute` satırları eklenerek genişletilmiştir. Bu nedenle `275908f` sürümü `9 runs, 39 assertions`, `nil` ve `3.0` girdi testlerinin eklendiği `cd8e28d` sürümü ise `9 runs, 41 assertions` verir. Güncel test dosyasıyla alınmış kanca çıktısı için bkz. [`kanca_kanit.md`](kanca_kanit.md).

