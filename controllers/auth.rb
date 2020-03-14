paths \
  login: '/login',
  logout: '/logout'

get :login do
  if admin? || guest?
    flash[:notice] = "Already logged in"
    redirect path_to(:index)
  else
    slim :login
  end
end

post :login do
  if params['username'].blank? || params['password'].blank?
    flash[:error] = "Incorrect username or password :("
    redirect path_to(:login)
  elsif $config['admins'] && $config['admins'][params['username']] == params['password']
    flash[:notice] = "Successfully logged in as admin!"
    session['role'] = 'admin'
    redirect path_to(:index)
  elsif $config['guests'] && $config['guests'][params['username']] == params['password']
    flash[:notice] = "Successfully logged in as spectator!"
    session['role'] = 'guest'
    redirect path_to(:index)
  else
    flash[:error] = "Incorrect username or password :("
    redirect path_to(:login)
  end
end

delete :logout do
  session.delete('role')
  flash[:notice] = "Successfully logged out"
  redirect path_to(:index)
end
