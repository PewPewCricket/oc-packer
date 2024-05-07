-- Declare Vars
local shell = require("shell")
local fs = require("filesystem")
local errOK, ocz = pcall(require, "ocz")
if not errOK then
  io.stderr:write("ERROR: OCZ not present!")
  io.stderr:write("ERROR: " .. ocz)
  os.exit()
end

local args, ops = shell.parse(...)

print("OpenPackage 0.1.0")
local path = args[1]
local name = args[2]
local ver = args[3]
local destdir = args[4]
if ops.f then
  fpath = args[5]
end

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

-- Code
if ops.v then
  print("PATH: " .. path)
  print("NAME: " .. name)
  print("VERSION: " .. ver)
  print("DESTDIR: " .. destdir)
  if ops.f then
    print("FPATH: " .. fpath)
  end
end

-- Get Dependancies of package
local deps = getDeps(ops.f)

-- Generate Package Information
print("building package structure...")
if ops.v then
  print("generating package information...")
end
fs.makeDirectory("/tmp/pkgbuild")
fs.makeDirectory("/tmp/pkgbuild/" .. name .. "-" .. ver)
fs.makeDirectory("/tmp/pkgbuild/" .. name .. "-" .. ver .. "/pkg")
local file = io.open("/tmp/pkgbuild/" .. name .. "-" .. ver .. "/pkginfo", "w")
file:write(name .. "\n" .. ver)
file:close()

local file = io.open("/tmp/pkgbuild/" .. name .. "-" .. ver .. "/deps", "w")
local i = #deps - 1
while i > 0 do
  file:write(deps[i] .. "\n")
  i = i - 1
end

-- copy data from PATH to temp dir
if ops.v then
  print("copying package data into build dir...")
end
if fs.exists(path) == false then
  handleError("invalid path " .. path)
end
shell.execute("cp -r " .. path .. "/* /tmp/pkgbuild/" .. name .. "-" .. ver .. "/pkg/")