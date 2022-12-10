require 'simplify_rb'

class WaveformService
  def self.generate(filename)
    new(filename).generate
  end

  attr_reader :filename

  SAMPLERATE = 500
  HEIGHT = 50 # Height for half of the waveform; Total height = x2
  WIDTH = 600
  SIMPLIFY_TOLERANCE = 1
  DEFAULT_MAX_VALUE = 8000.0

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

    # TODO: Escape 'filename' properly
    IO.popen("ffmpeg -i \"#{filename}\" -ac 1 -filter:a aresample=#{SAMPLERATE} -map 0:a -c:a pcm_s16le -f data -") do |stream|
      # Average 150 points into a single datapoint
      # For 600Hz wave audio, we'll get 4 points per second
      stream.read.unpack('s*').each_slice(150) do |slice|
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
    
    SimplifyRb::Simplifier.new.process(points, SIMPLIFY_TOLERANCE, true).map do |point|
      [point[:x], point[:y]]
    end
    # points.map { |point| [point[:x], point[:y]] }
  end

  private

  def median(ary)
    ary = [0] if ary.empty?
    mid = ary.length / 2
    sorted = ary.sort
    ary.length.odd? ? sorted[mid] : 0.5 * (sorted[mid] + sorted[mid - 1])
  end
end
