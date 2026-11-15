# A Koşusu (Rehbersiz & Ham Koşu) Kanıt Raporu

## 1. Koşu Kimliği ve Ortam Bilgileri
- **Dal (Branch):** `kosu-a`
- **Alt-Ajan Oturum ID (Conversation ID):** `0ba648cc-e02a-45e3-8fce-7fc0b0ee2ec8`
- **Transkript Kaynağı:** `.system_generated/logs/transcript.jsonl` (24 adım / 12 model yanıt turu)
- **Model:** `gemini-4-argon-medium`
- **Verilen İstem (Prompt):**
  > `"Öğrenci devamsızlık kontrolü yap, devamsızlık sınırı %30'dur."`
- **Ortam Durumu:** `AGENTS.md`, `CLAUDE.md`, `test/` ve `bin/kontrol` **bulunmamaktadır** (Rehbersiz/Ham koşu).

---

## 2. Tur Sayısı ve Gerçek Token Ölçümü

Transkript (`transcript.jsonl`) içerisindeki 12 `PLANNER_RESPONSE` adımından alınan kesin token verileri:

| Tur (Turn) | Step Index | Eylem (Tool Call) | Girdi Token (Uncached) | Önbellek Okuma (Cache Read) | Çıktı Token (Output) |
|---|---|---|---|---|---|
| 1 | 1 | `run_command` (Dizin listeleme) | 8.513 | 0 | 102 |
| 2 | 3 | `run_command` (Alt dizinleri listeleme) | 2.417 | 6.459 | 85 |
| 3 | 5 | `run_command` (`git status` / `git log`) | 2.367 | 6.827 | 101 |
| 4 | 7 | `run_command` (`ruby -v` kontrolü) | 2.462 | 7.145 | 205 |
| 5 | 9 | `read_file` (`.ruby-version` okuma) | 2.345 | 7.558 | 49 |
| 6 | 11 | `write_file` (`lib/devamsizlik_kontrol.rb`) | 2.195 | 7.854 | 1.417 |
| 7 | 13 | `write_file` (`bin/devamsizlik_kontrol.rb`) | 2.250 | 9.296 | 434 |
| 8 | 15 | `run_command` (Ruby kurulumunu arama) | 2.563 | 9.497 | 88 |
| 9 | 17 | `run_command` (Betiği çalıştırma denemesi 1) | 2.258 | 10.459 | 101 |
| 10 | 19 | `run_command` (Betiği çalıştırma denemesi 2) | 2.241 | 10.668 | 134 |
| 11 | 21 | `send_message` (Sonuç bildirimi) | 2.273 | 10.860 | 673 |
| 12 | 23 | Final yanıtı | 2.836 | 11.084 | 121 |
| **TOPLAM** | **24 Adım** | **12 Tur (Turns)** | **34.720** | **97.707** | **3.510** |

- **Toplam Tur Sayısı (Turns):** `12`
- **Toplam Girdi Token (Uncached):** `34.720`
- **Toplam Girdi Token (Cache Dahil Brüt):** `132.427`
- **Toplam Çıktı Token (Output):** `3.510`

---

## 3. A Koşusunda Üretilen Kodun Kopyası

### `lib/devamsizlik_kontrol.rb` (`kosu-a` dalında üretilen)
```ruby
# frozen_string_literal: true

# Öğrenci devamsızlık kontrol modülü ve sınıfları
class Ogrenci
  attr_reader :ad, :numara, :toplam_ders_saati, :devamsizlik_saati

  DEVAMSIZLIK_SINIRI_YUZDE = 30.0

  def initialize(ad:, toplam_ders_saati:, devamsizlik_saati:, numara: nil)
    raise ArgumentError, 'Toplam ders saati pozitif olmalıdır.' if toplam_ders_saati.to_f <= 0
    raise ArgumentError, 'Devamsızlık saati negatif olamaz.' if devamsizlik_saati.to_f.negative?
    if devamsizlik_saati.to_f > toplam_ders_saati.to_f
      raise ArgumentError, 'Devamsızlık saati toplam ders saatinden büyük olamaz.'
    end

    @ad = ad
    @numara = numara
    @toplam_ders_saati = toplam_ders_saati.to_f
    @devamsizlik_saati = devamsizlik_saati.to_f
  end

  def devamsizlik_orani
    ((@devamsizlik_saati / @toplam_ders_saati) * 100).round(2)
  end

  def maksimum_devamsizlik_hakki
    (@toplam_ders_saati * (DEVAMSIZLIK_SINIRI_YUZDE / 100.0)).round(2)
  end

  def kalan_devamsizlik_hakki
    kalan = maksimum_devamsizlik_hakki - @devamsizlik_saati
    kalan.positive? ? kalan.round(2) : 0.0
  end

  def kaldi_mi?
    devamsizlik_orani > DEVAMSIZLIK_SINIRI_YUZDE
  end

  def durum_mesaji
    durum = kaldi_mi? ? 'KALDI (Devamsızlık sınırı aşıldı)' : 'GEÇTİ (Devam koşulunu sağlıyor)'
    format(
      '%<ad>s - Toplam: %<toplam>g saat, Devamsızlık: %<devam>g saat (%%%<oran>.2f / Sınır: %%%<sinir>.0f) -> %<durum>s',
      ad: @ad,
      toplam: @toplam_ders_saati,
      devam: @devamsizlik_saati,
      oran: devamsizlik_orani,
      sinir: DEVAMSIZLIK_SINIRI_YUZDE,
      durum: durum
    )
  end
end

class DevamsizlikKontrol
  DEVAMSIZLIK_SINIRI = 30.0

  def self.kontrol_et(ogrenciler)
    ogrenciler.map do |ogrenci|
      {
        ad: ogrenci.ad,
        numara: ogrenci.numara,
        toplam_ders_saati: ogrenci.toplam_ders_saati,
        devamsizlik_saati: ogrenci.devamsizlik_saati,
        devamsizlik_orani: ogrenci.devamsizlik_orani,
        kalan_hak: ogrenci.kalan_devamsizlik_hakki,
        kaldi_mi: ogrenci.kaldi_mi?,
        durum: ogrenci.kaldi_mi? ? 'Devamsızlıktan Kaldı' : 'Devam Koşulunu Sağlıyor',
        mesaj: ogrenci.durum_mesaji
      }
    end
  end

  def self.rapor_yazdir(ogrenciler)
    puts '=' * 75
    puts "ÖĞRENCİ DEVAMSIZLIK KONTROL RAPORU (Devamsızlık Sınırı: %#{DEVAMSIZLIK_SINIRI.to_i})"
    puts '=' * 75
    ogrenciler.each do |ogrenci|
      puts ogrenci.durum_mesaji
    end
    puts '=' * 75
  end
end
```

### `bin/devamsizlik_kontrol.rb` (`kosu-a` dalında üretilen)
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/devamsizlik_kontrol'

if __FILE__ == $PROGRAM_NAME
  ornek_ogrenciler = [
    Ogrenci.new(ad: 'Ahmet Yılmaz', numara: '101', toplam_ders_saati: 40, devamsizlik_saati: 8),   # %20.0 -> Geçti
    Ogrenci.new(ad: 'Ayşe Demir', numara: '102', toplam_ders_saati: 40, devamsizlik_saati: 12),    # %30.0 -> Geçti (Sınırda)
    Ogrenci.new(ad: 'Mehmet Kaya', numara: '103', toplam_ders_saati: 40, devamsizlik_saati: 15),   # %37.5 -> Kaldı
    Ogrenci.new(ad: 'Zeynep Çelik', numara: '104', toplam_ders_saati: 56, devamsizlik_saati: 18)   # %32.14 -> Kaldı
  ]

  DevamsizlikKontrol.rapor_yazdir(ornek_ogrenciler)
end
```

---

## 4. Kritik Hata Analizi

1. **Sınır Değer Hatası (`> 30.0` vs `>= 3`):**
   - Ajan `kaldi_mi?` metodunda `devamsizlik_orani > DEVAMSIZLIK_SINIRI_YUZDE` (`> 30.0`) operatörünü kullanmıştır.
   - `bin/devamsizlik_kontrol.rb` satır 9'da açıkça görüldüğü üzere tam %30 devamsızlıkta (`40` saatte `12` saat, yani 10 oturumda **tam 3 devamsızlık** karşılığı) öğrenciyi `"Geçti"` kabul etmiş ve `:riskli` (`devamsizlik >= 3`) ile `:kaldi` (`devamsizlik >= 4`) kural kademelerini hiç kurmamıştır.
2. **Sınıf ve Dosya Mimarisinin İhlali (`lib/ogrenci.rb` Eksikliği):**
   - `lib/ogrenci.rb` dosyası hiç oluşturulmamıştır. Ajan hem `Ogrenci` hem de `DevamsizlikKontrol` sınıflarını tek bir `lib/devamsizlik_kontrol.rb` dosyası içine koymuştur.
3. **Veri Modeli ve Durum Sorgu Metotları Eksikliği (`define_method` Yok):**
   - `Ogrenci` sınıfında öğrencinin statüsünü tutan `durum` (`:aktif`, `:donduruldu`, `:mezun`) niteliği yoktur.
   - Dolayısıyla `aktif?`, `donduruldu?`, `mezun?` sorgu metotları `define_method` ile tanımlanmamıştır.
   - `devamsizlik` alanı `0..10` tam sayı oturum aralığı yerine `Float` (`toplam_ders_saati`, `devamsizlik_saati`) olarak modellenmiştir; `0..10` dışı tam sayılar için `ArgumentError` kontrolü yoktur.
4. **Özgün 3. Kuralın ve Sembol Çıktılarının Eksikliği:**
   - Kural motoru sembol (`:riskli`, `:kaldi`, `:onur_adayi`, `:normal`) döndürmek yerine metin mesajları üretmiştir.
   - 3. özgün kural (`:onur_adayi` -> `aktif? && devamsizlik == 0`) hiç tanımlanmamıştır.
5. **Birim Testi ve Doğrulama Kancası Eksikliği:**
   - `test/ogrenci_test.rb` altında hiçbir Minitest testi yazılmamıştır ve `bin/kontrol` doğrulama kancası oluşturulmamıştır.

