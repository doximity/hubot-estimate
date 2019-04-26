module.exports = (name, charToRemove) ->
  return name unless name?
  name = name.trim().toLowerCase()
  if name[0] == charToRemove then name.slice(1) else name
