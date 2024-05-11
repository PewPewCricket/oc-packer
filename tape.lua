-- Declare Vars
local shell = require("shell")
local fs = require("filesystem")
local ts = require("tools/transfer")
local ocz = require, "ocz")

local lib = {}

-- Local Functions
local function fileToArray(filename)
  if fs.exists(filename) == false then
    handleError("file " .. filename .. " not found")
  end
  local file = io.open(filename, "r");
  local arr = {}
  for line in file:lines() do
    table.insert(arr, line);
  end
  file:close()
  return arr
end

-- Functions
function lib.makePkg(path, deps, name, ver, destdir)
  -- Declare Vars
  local pkgdir = "/usr/pkg/build"
  local tar = "/usr/pkg/tars/" .. name .. ".tar"

  -- Generate Package Information
  fs.makeDirectory("/usr/pkg")
  fs.makeDirectory("/usr/pkg/tars")
  fs.makeDirectory(pkgdir)

  local infofile = io.open(pkgdir .. "/pkginfo", "w")
  local depsfile = io.open(pkgdir .. "/deps", "w")
  
  infofile:write(name .. "\n" .. ver)
  local i = #deps - 1
  while i > 0 do
    depsfile:write(deps[i] .. "\n")
    i = i - 1
  end
  
  infofile:close()
  depsfile:close()

  -- Copy data from PATH to temp dir
  local cops =
  {
    cmd = "cp",
    i = false,
    f = false,
    n = false,
    r = true,
    u = false,
    P = false,
    v = false,
    x = false,
    skip = {},
  }

  local cargs = {}
  cargs[1] = path
  cargs[2] = pkgdir .. "/pkg"

  ts.batch(cargs, cops)

  -- Create tar archive
  shell.setWorkingDirectory(pkgdir)
     shell.execute("tar -cf " .. tar .. " " .. pkgdir .. "/")
  shell.setWorkingDirectory(destdir)

  -- Compress tar archive
  ocz.compressFile(tar, destdir .. "/" .. name .. ".tar.ocz")

  -- Remove temp data
  fs.remove(pkgdir)
  fs.remove(tar)
  fs.remove("/usr/pkg/pkgbuild/" .. name .. "-" .. ver)
end

function lib.installPkg(path, destdir) 
  -- Declare Vars
  local pkgdir = "/usr/pkg/extract"
  local tardir = "/usr/pkg/tars"
  
  -- Decompress Archive
  ocz.decompressFile(path, tardir .. "/package.tar")

  -- Untar Archive
  shell.execute("tar -xf " .. tardir .. "/package.tar " .. pkgdir)

  -- Copy files to final location
  
end

return lib
