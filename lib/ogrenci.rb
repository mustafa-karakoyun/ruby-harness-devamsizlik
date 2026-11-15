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
