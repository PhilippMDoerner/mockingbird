import std/[genasts, macros]

macro mockable*(p: typed): untyped =
  when defined(mock):
    let
      pName = ident($p[0])
      newName = ident($p[0] & "Base")
      oldPrc = p.copyNimTree

    oldPrc[0] = newName
    result = genast(pName, oldPrc, newName):
      oldPrc
      var pName* = newName
  else:
    result = p
