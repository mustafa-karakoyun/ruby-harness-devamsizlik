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
