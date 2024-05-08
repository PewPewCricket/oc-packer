-- Declare Vars
local shell = require("shell")
local fs = require("filesystem")
local ts = require("tools/transfer")
local errOK, ocz = pcall(require, "ocz")

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
  print("please type in deps line by line by their package name, end with 'EOF'")
    while input ~= "EOF" do
      input = io.read()
      i = i + 1
      deps[i] = input
    end
  end
  return deps
end

-- Needed Checks
if not fs.exists("/bin/tar.lua") then
  io.stdout:write("Tar is not installed, would you like to install it? (y/n): ")
  local user = io.read()
  if user == "y" then
    print("installing tar...")
    shell.execute("wget 'https://raw.githubusercontent.com/mpmxyz/ocprograms/master/bin/tar.lua' /bin/tar.lua")
    shell.execute("wget 'https://raw.githubusercontent.com/mpmxyz/ocprograms/master/usr/man/tar.man /usr/man/tar.man'")
  else
  handleError("tar is not installed")
  end
end

if not errOK then
  io.stdout:write("OCZip is not installed, would you like to install it? (y/n): ")
  user = io.read()
  if user == "y" then
    print("installing OCZip...")
    fs.makeDirectory("/lib/ocz")
    shell.execute("wget https://raw.githubusercontent.com/BallOfEnergy1/OCZ/master/ocz.lua /bin/ocz.lua")
    shell.execute("wget https://raw.githubusercontent.com/BallOfEnergy1/OCZ/master/init.lua /lib/ocz/init.lua")
    shell.execute("wget https://raw.githubusercontent.com/BallOfEnergy1/OCZ/master/crc32.lua /lib/ocz/crc32.lua")
    shell.execute("wget https://raw.githubusercontent.com/BallOfEnergy1/OCZ/master/lualzw.lua /lib/ocz/lualzw.lua")
    shell.execute("wget https://raw.githubusercontent.com/BallOfEnergy1/OCZ/master/md5.lua /lib/ocz/md5.lua")
  else
  handleError("OCZip is not installed")
  end
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
