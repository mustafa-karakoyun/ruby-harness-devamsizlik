# AGENTS.md — Mühendislik Anayasası (Harness Kuralları)

Bu depoda çalışan tüm ajanlar aşağıdaki kurallara **istisnasız** uymak zorundadır.

## 1. Dil ve Sürüm
- **Ruby Sürümü:** `3.4` (`.ruby-version`).
- Tüm Ruby dosyaları `# frozen_string_literal: true` direktifi ile başlamalıdır.

## 2. Mimari ve Dosya Yapısı
- `lib/ogrenci.rb`: Yalnızca `Ogrenci` sınıfını içerir.
- `lib/devamsizlik_kontrol.rb`: `require_relative 'ogrenci'` ile öğrenci modelini yükler ve yalnızca `DevamsizlikKontrol` sınıfını içerir.
- İki sınıfı tek dosyada birleştirmek **YASAKTIR**.

## 3. Veri Modeli (`Ogrenci` — `lib/ogrenci.rb`)
- **Sabitler:**
  - `GECERLI_DURUMLAR = %i[aktif donduruldu mezun].freeze`
  - `DEVAMSIZLIK_ARALIGI = (0..10)`
- **Nitelikler (`attr_reader`):** `:ad`, `:durum`, `:devamsizlik`
- **Kurucu (`initialize(ad:, durum: :aktif, devamsizlik: 0)`):**
  - `ad`: Boş olmayan `String` olmalıdır (`!ad.is_a?(String) || ad.strip.empty?` durumunda `ArgumentError` fırlatır).
  - `durum`: `:aktif`, `:donduruldu` veya `:mezun` sembollerinden biri olmalıdır; aksi halde `ArgumentError` fırlatır.
  - `devamsizlik`: `Integer` tipinde ve `0..10` aralığında (`0 <= devamsizlik <= 10`) olmalıdır; `-1`, `11`, `Float` veya `nil` gibi geçersiz değerlerde `ArgumentError` fırlatır.

## 4. Metot Üretimi ve Yasaklar (0 Puan Kırmızı Çizgisi)
- Durum sorgu metotları (`aktif?`, `donduruldu?`, `mezun?`) `GECERLI_DURUMLAR` üzerinden **yalnızca `define_method`** ile dinamik olarak üretilir.
- **`method_missing` ve `respond_to_missing?` kullanımı KESİNLİKLE YASAKTIR.** Tanımsız metot çağrıları doğrudan `NoMethodError` fırlatmalıdır.
- Standart/çekirdek sınıflara (`Integer`, `String`, `Object`, `Array`, `Numeric`, `Symbol`, `Kernel`) **monkey patch (sınıf açılımı) yapmak KESİNLİKLE YASAKTIR.**

## 5. İş Kuralları (`DevamsizlikKontrol` — `lib/devamsizlik_kontrol.rb`)
Toplam ders oturumu `10`, devamsızlık sınırı `%30` (3 oturum) olarak sabitlenmiştir:
- `RISK_SINIRI = 3`
- `KALMA_SINIRI = 4`
- **Sinıf Metotları:**
  1. `DevamsizlikKontrol.degerlendir(ogrenci)` (`Ogrenci` nesnesi değilse `ArgumentError` fırlatır):
     - **Kural 1 (`:kaldi`):** `ogrenci.devamsizlik >= 4` ise `:kaldi` döner.
     - **Kural 2 (`:riskli` — Sınır Vaka):** `ogrenci.devamsizlik >= 3` (yani `devamsizlik == 3`) ise `:riskli` döner. **Tam 3 devamsızlık (`%30`) riskli SAYILIR (`>= 3` kullanılmalı, `> 3` KULLANILMAMALIDIR).**
     - **Kural 3 (`:onur_adayi` — Özgün Kural):** `ogrenci.aktif? && ogrenci.devamsizlik == 0` ise `:onur_adayi` döner. (Dondurulmuş veya mezun öğrenciler `0` devamsızlık olsa bile `:onur_adayi` olamaz).
     - **Varsayılan (`:normal`):** Yukarıdaki koşullara girmeyen geçerli durumlarda `:normal` döner.
  2. Yardımcı Sorgu Metotları:
     - `DevamsizlikKontrol.riskli?(ogrenci)`: `ogrenci.devamsizlik >= 3` (`devamsizlik == 3` için `true`, `devamsizlik == 2` için `false`).
     - `DevamsizlikKontrol.kaldi?(ogrenci)`: `ogrenci.devamsizlik >= 4`.
     - `DevamsizlikKontrol.onur_adayi?(ogrenci)`: `ogrenci.aktif? && ogrenci.devamsizlik == 0`.

## 6. Doğrulama Zorunluluğu
- Yapılan her kod değişikliğinden sonra `./bin/kontrol` çalıştırılmalı ve tüm statik analiz + Minitest kontrollerinin `0` hata ile geçtiği doğrulanmalıdır.

