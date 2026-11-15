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
