template onFailure*(destroyExpr: typed, body: untyped) =
  try:
    body
  except:
    destroyExpr
    raise
