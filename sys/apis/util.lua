local Util = { }

function Util.tryTimed(timeout, f, ...)
  local c = os.clock()
  repeat
    local ret = f(...)
    if ret then
      return ret
    end
  until os.clock()-c >= timeout
end

function Util.tryTimes(attempts, f, ...)
  local result
  for i = 1, attempts do
    result = { f(...) }
    if result[1] then
      return unpack(result)
    end
  end
  return unpack(result)
end

function Util.throttle(fn)
  local ts = os.clock()
  local timeout = .095
  return function(...)
    local nts = os.clock()
    if nts > ts + timeout then
      os.sleep(0)
      ts = os.clock()
      if fn then
        fn(...)
      end
    end
  end
end

function Util.tostring(pattern, ...)

  local function serialize(tbl, width)
    local str = '{\n'
    for k, v in pairs(tbl) do
      local value
      if type(v) == 'table' then
        value = string.format('table: %d', Util.size(v))
      else
        value = tostring(v)
      end
      str = str .. string.format(' %s: %s\n', k, value)
    end
    if #str < width then
      str = str:gsub('\n', '') .. ' }'
    else
      str = str .. '}'
    end
    return str
  end

  if type(pattern) == 'string' then
    return string.format(pattern, ...)
  elseif type(pattern) == 'table' then
    return serialize(pattern, term.current().getSize())
  end
  return tostring(pattern)
end

function Util.print(pattern, ...)
  print(Util.tostring(pattern, ...))
end

function Util.getVersion()
  local version

  if _CC_VERSION then
    version = tonumber(_CC_VERSION:gmatch('[%d]+%.?[%d][%d]', '%1')())
  end
  if not version and _HOST then
    version = tonumber(_HOST:gmatch('[%d]+%.?[%d][%d]', '%1')())
  end

  return version or 1.7
end

-- http://lua-users.org/wiki/SimpleRound
function Util.round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function Util.random(max, min)
  min = min or 0
  return math.random(0, max-min) + min
end

--[[ Table functions ]] --
function Util.clear(t)
  local keys = Util.keys(t)
  for _,k in pairs(keys) do
    t[k] = nil
  end
end

function Util.empty(t)
  return not next(t)
end

function Util.key(t, value)
  for k,v in pairs(t) do
    if v == value then
      return k
    end
  end
end

function Util.keys(t)
  local keys = {}
  for k in pairs(t) do
    keys[#keys+1] = k
  end
  return keys
end

function Util.merge(obj, args)
  if args then
    for k,v in pairs(args) do
      obj[k] = v
    end
  end
end

function Util.deepMerge(obj, args)
  if args then
    for k,v in pairs(args) do
      if type(v) == 'table' then
        if not obj[k] then
          obj[k] = { }
        end
        Util.deepMerge(obj[k], v)
      else
        obj[k] = v
      end
    end
  end
end

function Util.transpose(t)
  local tt = { }
  for k,v in pairs(t) do
    tt[v] = k
  end
  return tt
end

function Util.find(t, name, value)
  for k,v in pairs(t) do
    if v[name] == value then
      return v, k
    end
  end
end

function Util.findAll(t, name, value)
  local rt = { }
  for k,v in pairs(t) do
    if v[name] == value then
      table.insert(rt, v)
    end
  end
  return rt
end

function Util.shallowCopy(t)
  local t2 = { }
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

function Util.deepCopy(t)
  if type(t) ~= 'table' then
    return t
  end
  --local mt = getmetatable(t)
  local res = {}
  for k,v in pairs(t) do
    if type(v) == 'table' then
      v = Util.deepCopy(v)
    end
    res[k] = v
  end
  --setmetatable(res,mt)
  return res
end

-- http://snippets.luacode.org/?p=snippets/Filter_a_table_in-place_119
function Util.filterInplace(t, predicate)
  local j = 1

  for i = 1,#t do
    local v = t[i]
    if predicate(v) then
      t[j] = v
      j = j + 1
    end
  end

  while t[j] ~= nil do
    t[j] = nil
    j = j + 1
  end

  return t
end

function Util.filter(it, f)
  local ot = { }
  for k,v in pairs(it) do
    if f(k, v) then
      ot[k] = v
    end
  end
  return ot
end

function Util.size(list)
  if type(list) == 'table' then
    local length = 0
    table.foreach(list, function() length = length + 1 end)
    return length
  end
  return 0
end

function Util.removeByValue(t, e)
  for k,v in pairs(t) do
    if v == e then
      table.remove(t, k)
      break
    end
  end
end

function Util.each(list, func)
  for index, value in pairs(list) do
    func(value, index, list)
  end
end

-- http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
function Util.spairs(t, order)
  local keys = Util.keys(t)

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys 
  if order then
    table.sort(keys, function(a,b) return order(t[a], t[b]) end)
  else
    table.sort(keys)
  end

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

function Util.first(t, order)
  local keys = Util.keys(t)
  if order then
    table.sort(keys, function(a,b) return order(t[a], t[b]) end)
  else
    table.sort(keys)
  end
  return keys[1], t[keys[1]]
end

--[[ File functions ]]--
function Util.readFile(fname)
  local f = fs.open(fname, "r")
  if f then
    local t = f.readAll()
    f.close()
    return t
  end
end

function Util.writeFile(fname, data)
  local file = io.open(fname, "w")
  if not file then
    error('Unable to open ' .. fname, 2)
  end
  file:write(data)
  file:close()
end

function Util.readLines(fname)
  local file = fs.open(fname, "r")
  if file then
    local t = {}
    local line = file.readLine()
    while line do
      table.insert(t, line)
      line = file.readLine()
    end
    file.close()
    return t
  end
end

function Util.writeLines(fname, lines)
  local file = fs.open(fname, 'w')
  if file then
    for _,line in ipairs(lines) do
      line = file.writeLine(line)
    end
    file.close()
    return true
  end
end

function Util.readTable(fname)
  local t = Util.readFile(fname)
  if t then
    return textutils.unserialize(t)
  end
end

function Util.writeTable(fname, data)
  Util.writeFile(fname, textutils.serialize(data))
end

function Util.loadTable(fname)
  local fc = Util.readFile(fname)
  if not fc then
    return false, 'Unable to read file'
  end
  local s, m = loadstring('return ' .. fc, fname)
  if s then
    s, m = pcall(s)
    if s then
      return m
    end
  end
  return s, m
end

--[[ loading and running functions ]] --
function Util.download(url, filename)
  local h = http.get(url)
  if not h then
    error('Failed to download ' .. url)
  end
  local contents = h.readAll()
  h.close()
  if not contents then
    error('Failed to download ' .. url)
  end

  if filename then
    Util.writeFile(filename, contents)
  end
  return contents
end

function Util.loadUrl(url, env)  -- loadfile equivalent
  local s, m = pcall(function()
    local c = Util.download(url)
    return load(c, url, nil, env)
  end)

  if s then
    return m
  end
  return s, m
end

function Util.runUrl(env, url, ...)   -- os.run equivalent
  setmetatable(env, { __index = _G })
  local fn, m = Util.loadUrl(url, env)
  if fn then
    local args = { ... }
    return pcall(function() return fn(table.unpack(args)) end)
  end
  return fn, m
end

function Util.run(env, path, ...)
  setmetatable(env, { __index = _G })
  local fn, m = loadfile(path, env)
  if fn then
    local args = { ... }
    return pcall(function() return fn(table.unpack(args)) end)
  end
  return fn, m
end

function Util.runFunction(env, fn, ...)
  setfenv(fn, env)
  setmetatable(env, { __index = _G })

  local args = { ... }
  return pcall(function() return fn(table.unpack(args)) end)
end

--[[ String functions ]] --
function Util.toBytes(n)
  if n >= 1000000 or n <= -1000000 then
    return string.format('%sM', Util.round(n/1000000, 1))
  elseif n >= 1000 or n <= -1000 then
    return string.format('%sK', Util.round(n/1000, 1))
  end
  return tostring(n)
end

function Util.insertString(os, is, pos)
  return os:sub(1, pos - 1) .. is .. os:sub(pos)
end

function Util.split(str, pattern)
  pattern = pattern or "(.-)\n"
  local t = {}
  local function helper(line) table.insert(t, line) return "" end
  helper((str:gsub(pattern, helper))) 
  return t
end

function Util.matches(str, pattern)
  pattern = pattern or '%S+'
  local t = { }
  for s in str:gmatch(pattern) do
     table.insert(t, s)
  end
  return t
end

function Util.startsWidth(s, match)
  return string.sub(s, 1, #match) == match
end

function Util.widthify(s, len)
  s = s or ''
  local slen = #s
  if slen < len then
    s = s .. string.rep(' ', len - #s)
  elseif slen > len then
    s = s:sub(1, len)
  end
  return s
end

-- http://snippets.luacode.org/?p=snippets/trim_whitespace_from_string_76
function Util.trim(s)
  return s:find'^%s*$' and '' or s:match'^%s*(.*%S)'
end
 
-- trim whitespace from left end of string
function Util.triml(s)
  return s:match'^%s*(.*)'
end
 
-- trim whitespace from right end of string
function Util.trimr(s)
  return s:find'^%s*$' and '' or s:match'^(.*%S)'
end
-- end http://snippets.luacode.org/?p=snippets/trim_whitespace_from_string_76

-- word wrapping based on:
-- https://www.rosettacode.org/wiki/Word_wrap#Lua and
-- http://lua-users.org/wiki/StringRecipes
local function paragraphwrap(text, linewidth, res)
  linewidth = linewidth or 75
  local spaceleft = linewidth
  local line = { }

  for word in text:gmatch("%S+") do
    local len = #word + 1

    --if colorMode then
    --  word:gsub('()@([@%d])', function(pos, c) len = len - 2 end)
    --end

    if len > spaceleft then
      table.insert(res, table.concat(line, ' '))
      line = { word }
      spaceleft = linewidth - len - 1
    else
      table.insert(line, word)
      spaceleft = spaceleft - len
    end
  end

  table.insert(res, table.concat(line, ' '))
  return table.concat(res, '\n')
end
-- end word wrapping

function Util.wordWrap(str, limit)

  local longLines = Util.split(str)
  local lines = { }

  for _,line in ipairs(longLines) do
    paragraphwrap(line, limit, lines)
  end

  return lines
end

-- http://lua-users.org/wiki/AlternativeGetOpt
local function getopt( arg, options )
  local tab = {}
  for k, v in ipairs(arg) do
    if type(v) == 'string' then
      if string.sub( v, 1, 2) == "--" then
        local x = string.find( v, "=", 1, true )
        if x then tab[ string.sub( v, 3, x-1 ) ] = string.sub( v, x+1 )
        else      tab[ string.sub( v, 3 ) ] = true
        end
      elseif string.sub( v, 1, 1 ) == "-" then
        local y = 2
        local l = string.len(v)
        local jopt
        while ( y <= l ) do
          jopt = string.sub( v, y, y )
          if string.find( options, jopt, 1, true ) then
            if y < l then
              tab[ jopt ] = string.sub( v, y+1 )
              y = l
            else
              tab[ jopt ] = arg[ k + 1 ]
            end
          else
            tab[ jopt ] = true
          end
          y = y + 1
        end
      end
    end
  end
  return tab
end

function Util.showOptions(options)
  print('Arguments: ')
  for k, v in pairs(options) do
    print(string.format('-%s  %s', v.arg, v.desc))
  end
end

function Util.getOptions(options, args, ignoreInvalid)
  local argLetters = ''
  for _,o in pairs(options) do
    if o.type ~= 'flag' then
      argLetters = argLetters .. o.arg
    end
  end
  local rawOptions = getopt(args, argLetters)
  local argCount = 0

  for k,ro in pairs(rawOptions) do
    local found = false
    for _,o in pairs(options) do
      if o.arg == k then
        found = true
        if o.type == 'number' then
          o.value = tonumber(ro)
        elseif o.type == 'help' then
          Util.showOptions(options)
          return false
        else
          o.value = ro
        end
      end
    end
    if not found and not ignoreInvalid then
      print('Invalid argument')
      Util.showOptions(options)
      return false
    end
  end
  return true, Util.size(rawOptions)

end

return Util
