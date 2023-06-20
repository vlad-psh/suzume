export default (context) => {
  const { redirect, route, $auth } = context

  if (['login'].includes(route.name)) {
    if ($auth.loggedIn()) redirect('/')
  } else if (!$auth.loggedIn()) redirect('/login')
}
