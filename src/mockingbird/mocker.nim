import std/[os, strutils, macros, sets, hashes]
import ./pragma

const pragmaNodeIndex = 4

proc isEmpty(node: NimNode): bool = node.kind == nnkEmpty
proc isPostfixNode(node: NimNode): bool = node.kind == nnkPostfix
proc isMockable(node: NimNode): bool = node.kind in {nnkProcDef, nnkFuncDef}

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

proc addMockPragma(filePath: string) {.compileTime.} =
  let mockPragmaName = "mockable"
  let file = parseStmt(staticRead(filePath))
  var newModule = newStmtList()
  
  var hadMockables = false
  for stmt in file:
    if stmt.isMockable(): ## Add mock pragma
      hadMockables = true
      newModule.add addPragma(stmt, mockPragmaName)
    else:
      newModule.add stmt

  if hadMockables:
    writeFile(filePath, newModule.repr)

proc addMockPragmas(filePaths: seq[string]) {.compileTime.}=
  for path in filePaths:
    addMockPragma(path)

proc addMockToProject*(ignore: seq[string] = @[]) =
  const projectPath = getProjectPath()
  for path in projectPath.walkDirRec:
    if path.endsWith(".nim") and path.extractFileName() notin ignore:
      addMockPragma(path)

proc addMockToModule*(modulePath: string) =
  doAssert modulePath.endsWith(".nim")
  
  addMockPragma(modulePath)