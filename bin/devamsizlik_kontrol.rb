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
