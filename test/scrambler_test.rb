require 'test_helper'

class TestScrambler < DbSubsetter::Scrambler
  def scramble_tests row
    'scramble tests called'
  end
end

class ScramblerTest < DbSubsetter::Test
  def test_scramble_returns_row_unless_scramble_method
    scrambler = TestScrambler.new
    assert_equal([], scrambler.scramble('undefined_tests', []))
  end

  def test_scramble_calls_scramble_method
    scrambler = TestScrambler.new
    assert_equal('scramble tests called', scrambler.scramble('tests', []))
  end
end
