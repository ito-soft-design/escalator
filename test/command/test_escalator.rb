require 'test/unit'
require 'escalator'
require 'stringio'

class TestEscalator < Test::Unit::TestCase

  def test_nop
    source = StringIO.new <<EOB
NOP
EOB
    asm = Escalator::Asm.new source
    assert_equal [0x00], asm.codes
  end

  def test_ld
    source = StringIO.new <<EOB
LD X0
EOB
    asm = Escalator::Asm.new source
    assert_equal [0x10, 0x80, 0x00], asm.codes
  end

  def test_y
    source = StringIO.new <<EOB
LD Y0
EOB
    asm = Escalator::Asm.new source
    assert_equal [0x10, 0x81, 0x00], asm.codes
  end

  def test_m
    source = StringIO.new <<EOB
LD M0
EOB
    asm = Escalator::Asm.new source
    assert_equal [0x10, 0x82, 0x00], asm.codes
  end

  def test_c
    source = StringIO.new <<EOB
LD C0
EOB
    asm = Escalator::Asm.new source
    assert_equal [0x10, 0x84, 0x00], asm.codes
  end

  def test_d
    source = StringIO.new <<EOB
LD D0
EOB
    asm = Escalator::Asm.new source
    assert_equal [0x10, 0xaa, 0x00], asm.codes
  end

  def test_d256
    source = StringIO.new <<EOB
LD D256
EOB
    asm = Escalator::Asm.new source
    assert_equal [0x10, 0xba, 0x00, 0x01], asm.codes
  end

  def test_d256_with_bigendian
    source = StringIO.new <<EOB
LD D256
EOB
    asm = Escalator::Asm.new source, Escalator::Asm::BIG_ENDIAN
    assert_equal [0x10, 0xba, 0x01, 0x00], asm.codes
  end

end
