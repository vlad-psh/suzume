module TulipHelpers
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

  def get_mime(filename)
    MIME::Types.type_for(File.extname(filename)).first.to_s || 'application/octet-stream'
  end
end
