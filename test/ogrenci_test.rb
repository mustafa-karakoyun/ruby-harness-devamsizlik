# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/ogrenci'
require_relative '../lib/devamsizlik_kontrol'

class OgrenciVeDevamsizlikKontrolTest < Minitest::Test
  # 1. SINIR DEĞER TESTLERİ (Tam 3 devamsızlık = %30 sınır vaka)
  def test_tam_3_devamsizlik_risklidir
    ogrenci = Ogrenci.new(ad: 'Ayşe Demir', durum: :aktif, devamsizlik: 3)

    assert DevamsizlikKontrol.riskli?(ogrenci), 'Tam 3 devamsızlık riskli sayılmalıdır (>= 3)'
    assert_equal :riskli, DevamsizlikKontrol.degerlendir(ogrenci)
  end

  def test_2_devamsizlik_riskli_degildir
    ogrenci = Ogrenci.new(ad: 'Ahmet Yılmaz', durum: :aktif, devamsizlik: 2)

    refute DevamsizlikKontrol.riskli?(ogrenci), '2 devamsızlık riskli sayılmamalıdır'
    assert_equal :normal, DevamsizlikKontrol.degerlendir(ogrenci)
  end

  # 2. KALDI TESTLERİ (4 ve üzeri devamsızlık)
  def test_4_ve_uzeri_devamsizlik_kaldi_dondurur
    ogrenci_sinir = Ogrenci.new(ad: 'Mehmet Kaya', durum: :aktif, devamsizlik: 4)
    ogrenci_ust = Ogrenci.new(ad: 'Zeynep Çelik', durum: :aktif, devamsizlik: 10)

    assert DevamsizlikKontrol.kaldi?(ogrenci_sinir)
    assert_equal :kaldi, DevamsizlikKontrol.degerlendir(ogrenci_sinir)
    assert_equal :kaldi, DevamsizlikKontrol.degerlendir(ogrenci_ust)
  end

  # 3. ÖZGÜN KURAL TESTLERİ (:onur_adayi -> aktif? && devamsizlik == 0)
  def test_aktif_ve_sifir_devamsizlik_onur_adayidir
    ogrenci = Ogrenci.new(ad: 'Elif Yıldız', durum: :aktif, devamsizlik: 0)

    assert DevamsizlikKontrol.onur_adayi?(ogrenci)
    assert_equal :onur_adayi, DevamsizlikKontrol.degerlendir(ogrenci)
  end

  def test_onur_adayi_negatif_sinir_durumlari
    aktif_bir_devamsizlik = Ogrenci.new(ad: 'Caner Öz', durum: :aktif, devamsizlik: 1)
    dondurulmus_sifir = Ogrenci.new(ad: 'Selin Ak', durum: :donduruldu, devamsizlik: 0)
    mezun_sifir = Ogrenci.new(ad: 'Burak Koç', durum: :mezun, devamsizlik: 0)

    refute DevamsizlikKontrol.onur_adayi?(aktif_bir_devamsizlik)
    assert_equal :normal, DevamsizlikKontrol.degerlendir(aktif_bir_devamsizlik)

    refute DevamsizlikKontrol.onur_adayi?(dondurulmus_sifir)
    assert_equal :normal, DevamsizlikKontrol.degerlendir(dondurulmus_sifir)

    refute DevamsizlikKontrol.onur_adayi?(mezun_sifir)
    assert_equal :normal, DevamsizlikKontrol.degerlendir(mezun_sifir)
  end

  # 4. METOT ÜRETİMİ (define_method) VE GÜVENLİK (method_missing YASAĞI) TESTLERİ
  def test_durum_sorgu_metotlari_define_method_ile_tanimlidir
    aktif_ogrenci = Ogrenci.new(ad: 'Ali Veli', durum: :aktif, devamsizlik: 1)
    dondurulmus_ogrenci = Ogrenci.new(ad: 'Deniz Su', durum: :donduruldu, devamsizlik: 0)
    mezun_ogrenci = Ogrenci.new(ad: 'Ece Dağ', durum: :mezun, devamsizlik: 0)

    assert_respond_to aktif_ogrenci, :aktif?
    assert_respond_to aktif_ogrenci, :donduruldu?
    assert_respond_to aktif_ogrenci, :mezun?

    assert_includes Ogrenci.instance_methods(false), :aktif?
    assert_includes Ogrenci.instance_methods(false), :donduruldu?
    assert_includes Ogrenci.instance_methods(false), :mezun?

    assert aktif_ogrenci.aktif?
    refute aktif_ogrenci.donduruldu?
    refute aktif_ogrenci.mezun?

    assert dondurulmus_ogrenci.donduruldu?
    assert mezun_ogrenci.mezun?
  end

  def test_bilinmeyen_metot_no_method_error_firlatir_method_missing_kullanilmaz
    ogrenci = Ogrenci.new(ad: 'Kaan Kurt', durum: :aktif, devamsizlik: 0)

    refute_includes Ogrenci.instance_methods(false), :method_missing
    assert_raises(NoMethodError) { ogrenci.askiya_alindi? }
    assert_raises(NoMethodError) { ogrenci.gecersiz_durum? }
  end

  # 5. GEÇERSİZ GİRDİ TESTLERİ (0..10 sınırı, durum ve ad doğrulaması)
  def test_gecersiz_devamsizlik_araligi_argument_error_firlatir
    assert_raises(ArgumentError) { Ogrenci.new(ad: 'Test', durum: :aktif, devamsizlik: -1) }
    assert_raises(ArgumentError) { Ogrenci.new(ad: 'Test', durum: :aktif, devamsizlik: 11) }
    assert_raises(ArgumentError) { Ogrenci.new(ad: 'Test', durum: :aktif, devamsizlik: 3.5) }
  end

  def test_gecersiz_durum_veya_ad_argument_error_firlatir
    assert_raises(ArgumentError) { Ogrenci.new(ad: '', durum: :aktif, devamsizlik: 0) }
    assert_raises(ArgumentError) { Ogrenci.new(ad: 'Test', durum: :pasif, devamsizlik: 0) }
    assert_raises(ArgumentError) { DevamsizlikKontrol.degerlendir('gecersiz_nesne') }
  end
end

