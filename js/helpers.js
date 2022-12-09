const compareStrings = (a, b) => {
  return a > b ? 1 : b > a ? -1 : 0
}

export const sortStringsArray = (array) => {
  return [...array].sort(compareStrings)
}

export const sortObjectsArray = (array, key) => {
  return [...array].sort((a, b) => compareStrings(a[key], b[key]))
}
