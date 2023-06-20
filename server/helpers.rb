require 'mime-types'

module TulipHelpers
  def protect!
    return if current_user
    halt 401, "Unauthorized"
  end

  def current_user
    return nil unless session['username'].present?

    @current_user ||= {username: session['username']}
    return @current_user
  end

  def get_mime(filename)
    MIME::Types.type_for(File.extname(filename)).first.to_s || 'application/octet-stream'
  end
end
