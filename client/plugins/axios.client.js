export default ({ $axios }) => {
  const protocol = window.location.protocol
  const host = window.location.hostname
  $axios.setBaseURL(`${protocol}//${host}`)
}