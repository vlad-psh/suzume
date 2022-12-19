require 'simplify_rb'

class WaveformService
  VERSION = 1
  SAMPLERATE = 2000
  AVERAGING_BATCH = 700
  HEIGHT = 50 # Height for half of the waveform; Total height = x2
  WIDTH = 600
  SIMPLIFY_TOLERANCE = 1.5
  DEFAULT_MAX_VALUE = 8000.0

  attr_reader :filename

  def self.generate(filename)
    new(filename).generate
  end

  def initialize(filename)
    @filename = filename
  end

  def generate
    # We will be drawing waveform first using points from first to last
    # from 'positive' array (upper part of the waveform)
    # and then from last to first point for 'negative' array (bottom part of the waveform)
    positive = []
    negative = []
    points = []

    IO.popen(%W{ ffmpeg -i #{filename} -ac 1 -filter:a aresample=#{SAMPLERATE} -map 0:a -c:a pcm_s16le -f data - }) do |stream|
      stream.read.unpack('s*').each_slice(AVERAGING_BATCH) do |slice|
        positive << median(slice.filter { |i| i >= 0 })
        negative << median(slice.filter { |i| i <= 0 })
      end
    end

    max_value = [DEFAULT_MAX_VALUE, positive.max].max.to_f
    
    positive.each_with_index do |v,i|
      x = (i / positive.length.to_f * WIDTH).round(1)
      y = (v / max_value * HEIGHT).round + HEIGHT
      points << { x: x, y: y }
    end

    negative.reverse.each_with_index do |v,i|
      x = ((negative.length - 1 - i) / negative.length.to_f * WIDTH).round(1)
      y = (v / max_value * HEIGHT).round + HEIGHT
      points << { x: x, y: y }
    end
    
    {
      version: VERSION,
      data: simplify_points(points),
    }
  end

  private

  def simplify_points(points_array)
    # SimplifyRB expects an array in following format: [ {x: 0, y: 0}, ...]
    SimplifyRb::Simplifier.new.process(points_array, SIMPLIFY_TOLERANCE, true).map do |point|
      [point[:x], point[:y]]
    end
  end

  def median(ary)
    ary = [0] if ary.empty?
    mid = ary.length / 2
    sorted = ary.sort
    ary.length.odd? ? sorted[mid] : 0.5 * (sorted[mid] + sorted[mid - 1])
  end
end
