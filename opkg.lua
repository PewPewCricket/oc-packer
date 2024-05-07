-- Declare Vars
local shell = require("shell")
local fs = require("filesystem")
local ts = require("tools/transfer")
local errOK, ocz = pcall(require, "ocz")
if not errOK then
  io.stderr:write("ERROR: OCZ not present!")
  io.stderr:write("ERROR: " .. ocz)
  os.exit()
end

local args, ops = shell.parse(...)

-- Functions
local function handleError(err)
  io.stderr:write("ERROR: " .. err .. "!")
  os.exit()
end

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

local function getDeps(f)
  local i = 0
  local deps = {}
  local input = ""
  if f then
    deps = fileToArray(fpath)
  else
  print("please type in dependancies line by line by their package name, end with 'EOF'")
    while input ~= "EOF" do
      input = io.read()
      i = i + 1
      deps[i] = input
    end
  end
  return deps
end

-- Start
print("OpenPackage 0.1.0")

if ops.c and ops.x then
  handleError("conflicting flags")
elseif ops.c then

  -- Set args
  local path = shell.resolve(args[1])
  local name = args[2]
  local ver = args[3]
  local destdir = shell.resolve(args[4])
  if ops.f then
    fpath = shell.resolve(args[5])
  end
  local pkgdir = "/usr/pkg/pkgbuild/" .. name .. "-" .. ver
  local pkgtar = "/usr/pkg/pkgtars/" .. name .. ".tar"

  if ops.v then
    print("PATH: " .. path)
    print("NAME: " .. name)
    print("VERSION: " .. ver)
    print("DESTDIR: " .. destdir)
    print("PKGDIR: " .. pkgdir)
    print("PKGTAR: " .. pkgtar)
    if ops.f then
      print("FPATH: " .. fpath)
    end
  end

  -- Check for errors
  if not fs.exists(path) then
    handleError(path .. " is an invalid path")
  elseif not fs.exists(destdir) then
    handleError(destdir .. " is an invalid path")
  elseif not fs.exists("/bin/tar.lua") then
    handleError("tar is not installed")
  end

  -- Get Dependancies of package
  local deps = getDeps(ops.f)

  -- Generate Package Information
  print("building package structure...")

  fs.makeDirectory("/usr/pkg")
  fs.makeDirectory("/usr/pkg/pkgbuild")
  fs.makeDirectory("/usr/pkg/pkgtars")
  fs.makeDirectory(pkgdir)

  print("generating package information...")

  local file = io.open(pkgdir .. "/pkginfo", "w")
  file:write(name .. "\n" .. ver)
  file:close()

  local file = io.open(pkgdir .. "/deps", "w")
  local i = #deps - 1
  while i > 0 do
    file:write(deps[i] .. "\n")
    i = i - 1
  end

  -- copy data from PATH to temp dir
  print("copying package data into build dir...")

  local bops =
  {
    cmd = "cp",
    i = false,
    f = false,
    n = false,
    r = true,
    u = false,
    P = false,
    v = ops.v,
    x = false,
    skip = {},
  }

  local bargs = {}
  bargs[1] = path
  bargs[2] = pkgdir .. "/pkg"

  ts.batch(bargs, bops)

  -- create tar archive
  print("creating tar archive...")

  local lastdir = shell.getWorkingDirectory()
  shell.setWorkingDirectory(pkgdir)
  if ops.v then
     shell.execute("tar -cvf " .. pkgtar .. " " .. pkgdir .. "/")
  else
     shell.execute("tar -cf " .. pkgtar .. " " .. pkgdir .. "/")
  end
  shell.setWorkingDirectory(destdir)

  -- Compress tar archive
  print("compressing tar archive...")

  shell.execute("ocz -a compress " .. pkgtar .. " " .. destdir .. "/" .. name .. ".tar.ocz")

  -- Remove temp data
  print("removing temp data...")

  fs.remove(pkgdir)
  fs.remove(pkgtar)
  fs.remove("/usr/pkg/pkgbuild/" .. name .. "-" .. ver)
elseif ops.x then
  --stuff
else
  --stuff
end
