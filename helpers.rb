module TulipHelpers
  def mb_artist_search_path(artist)
    return '' if artist == nil
    return "https://musicbrainz.org/search?query=#{artist.gsub(/[&?=]/, '')}&type=artist&method=indexed"
  end

  def ms2ts(time)
    ms   = time % 1000
    time = time / 1000
    s    = time % 60
    time = time / 60
    m    = time % 60
    time = time / 60
    h    = time
    msblock = "<span class='msec'>.#{ms/100}</span>"
    if h != 0
      return "#{h}:#{'%02d' % m}:#{'%02d' % s}#{msblock}"
    elsif m != 0
      return "#{m}:#{'%02d' % s}#{msblock}"
    else
      return "0:#{'%02d' % s}#{msblock}"
    end
  end

  def mediainfo(info)
    return nil unless info

    duration = "<span class='duration'>#{ms2ts(info['dur'] || info[:dur])}</span>"

    br_limit = (info['brm'] || info[:brm]) == 'CBR' ? 256 : 220 # Highlight if less than 256CBR or 220VBR
    br_value = (info['br'] || info[:br]).to_i/1000
    bitrate = "<span class='bitrate #{br_value < br_limit ? 'attention': nil}'>#{br_value}#{info['brm'] || info[:brm]}</span>"

    sr_value = ((info['sr'] || info[:sr]).to_i/1000.0).round(3)
    samplerate = "<span class='samplerate' #{sr_value < 44.1 ? 'attention' : nil}>#{sr_value}kHz</span>"

    return "<span class='mediainfo'>#{duration} | #{bitrate} @ #{samplerate}</span>"
  end

  def strip_filename(fln)
    return fln.gsub(/\.mp3$/i, '').gsub(/\.m4a$/i, '').gsub(/^[0-9\-\.]* (- )?/, '')
  end

  def admin?
    session['role'] == 'admin'
  end

  def guest?
    session['role'] == 'guest'
  end

  def protect!
    return if admin?
    halt 401, "Unauthorized"
  end

  def hide!
    return if admin? || guest?
    halt 401, "Unauthorized"
  end
end
