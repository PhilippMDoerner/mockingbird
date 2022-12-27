import std/[os, strutils, macros, sets, hashes]
import ./pragma

export macros

const pragmaNodeIndex = 4

proc isEmpty(node: NimNode): bool = node.kind == nnkEmpty
proc isPostfixNode(node: NimNode): bool = node.kind == nnkPostfix
proc isMockable(node: NimNode): bool = 
  node.kind in {nnkProcDef, nnkFuncDef}

proc isExported(procNode: NimNode): bool =
  ## Exported Procs have a "*" symbol in the Postfix Nimnode
  doAssert procNode.isMockable()
  if not procNode[0].isPostfixNode():
    return false

  let postfixNode = procNode[0]
  let hasExportSymbol = postfixNode[0].strVal == "*"
  return hasExportSymbol

proc addPragma(procNode: NimNode, pragmaName: string): NimNode =
  doAssert procNode.isMockable()

  if not isExported(procNode): 
    return procNode # leave non exported procs

  result = procNode.copyNimTree()

  var pragmaNode = procNode[pragmaNodeIndex] # pragma node is always idx 4
  if pragmaNode.isEmpty():
    pragmaNode = newTree(nnkPragma)
  pragmaNode.add ident(pragmaName)

  result[pragmaNodeIndex] = pragmaNode

proc parseModule*(filePath: string): NimNode =
  return parseStmt(staticRead(filePath))

proc writeModule*(moduleNode: NimNode, filePath: string) =
  writeFile(filePath, moduleNode.repr)

proc addMockPragma*(moduleNode: var NimNode): NimNode {.compileTime.} =
  let mockPragmaName = "mockable"
  var newModule = newStmtList()
  
  for stmt in moduleNode:
    if stmt.isMockable(): ## Add mock pragma
      newModule.add addPragma(stmt, mockPragmaName)
    else:
      newModule.add stmt
      
  result = newModule

proc addMockToProject*(ignore: seq[string] = @[]) =
  const projectPath = getProjectPath()
  for path in projectPath.walkDirRec:
    if path.endsWith(".nim") and path.extractFileName() notin ignore:
      var moduleNode = parseModule(path)
      var newModuleNode = addMockPragma(moduleNode)
      writeModule(newModuleNode, path)