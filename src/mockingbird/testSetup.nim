import std/[strutils, os, macros]
import ./mocker

proc isNimFilePath(path: string): bool = path.endsWith(".nim")

proc handleNimModule(modulePath: string, newPath: string) =
  echo "Parsing: ", modulePath
  var moduleNode = parseStmt(staticRead(modulePath))
  var mockableModuleNode = addMockPragma(moduleNode)
  mockableModuleNode.writeModule(newPath)

proc handleFile(filePath: string, newPath: string) =
  echo "Copying: ", filePath
  cpFile(filePath, newPath)
  

proc copyFiles(srcFolderPath: string, testFolderPath: string) {.compileTime.} =
  ## Go over all sourcecode files
  ## If they are nim files, add mock pragma to them and write them to the testFolderPath
  ## If they aren't nim files, just copy them to the testFolderPath
  var brokenFileHandling: seq[string] = @[]

  for path in srcFolderPath.walkDirRec:
    let relativeFilePath = path.relativePath(srcFolderPath)
    let newPathInTestFolder = testFolderPath & "/" & relativeFilePath
    
    try: 
      if path.isNimFilePath():
        handleNimModule(path, newPathInTestFolder)
      else:
        handleFile(path, newPathInTestFolder)

    except:
      brokenFileHandling.add path

  if brokenFileHandling.len > 0:
    echo $brokenFileHandling.len & " files could not be handled:"
    for filePath in brokenFileHandling:
      echo "  ", filePath

proc copyDirectories(srcFolderPath: static string, testFolderPath: static string) =
  for path in srcFolderPath.walkDirRec:
    for dir in path.parentDirs:
      let relativeFilePath = path.relativePath(srcFolderPath)
      let newFilePath = testFolderPath & "/" & relativeFilePath
      for dir in newFilePath.parentDirs:
        mkDir dir.parentDir()
        break


proc testSetup*(srcDir: string, testDir: string) =
  copyDirectories(srcDir, testDir)
  copyFiles(srcDir, testDir)