requireInjector(getfenv(1))

local Crypto   = require('crypto')
local Security = require('security')
local SHA1     = require('sha1')
local Socket   = require('socket')
local Terminal = require('terminal')

local remoteId
local args = { ... }

if #args == 1 then
  remoteId = tonumber(args[1])
else
  print('Enter host ID')
  remoteId = tonumber(read())
end

if not remoteId then
  error('Syntax: trust <host ID>')
end

local password = Terminal.readPassword('Enter password: ')

if not password then
  error('Invalid password')
end

print('connecting...')
local socket = Socket.connect(remoteId, 19)

if not socket then
  error('Unable to connect to ' .. remoteId .. ' on port 19')
end

local publicKey = Security.getPublicKey()
local password = SHA1.sha1(password)

socket:write(Crypto.encrypt({ pk = publicKey, dh = os.getComputerID() }, password))

local data = socket:read(2)
socket:close()

if data and data.success then
  print(data.msg)
elseif data then
  error(data.msg)
else
  error('No response')
end
