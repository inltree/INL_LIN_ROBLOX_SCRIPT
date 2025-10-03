--[[
如何用自己的另一个账号加入服务器：
将 setclipboard 放在下面脚本的末尾！！setclipboard(accessCode)
完成上述操作后，运行脚本，它会将访问代码复制到剪贴板，然后使用下面的小脚本加入自己（首先在 local accessCode = "" 处添加你的访问代码）

传送到自己的脚本
local accesscode = "" -- 在此处粘贴你的访问代码
local placeid = game.PlaceId

game.RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(placeid, "", accesscode)

]]
local md5 = {}
local hmac = {}
local base64 = {}
do
	do
		local T = {
			3614090360,
			3905402710,
			606105819,
			3250441966,
			4118548399,
			1200080426,
			2821735955,
			4249261313,
			1770035416,
			2336552879,
			4294925233,
			2304563134,
			1804603682,
			4254626195,
			2792965006,
			1236535329,
			4129170786,
			3225465664,
			643717713,
			3921069994,
			3593408605,
			38016083,
			3634488961,
			3889429448,
			568446438,
			3275163606,
			4107603335,
			1163531501,
			2850285829,
			4243563512,
			1735328473,
			2368359562,
			4294588738,
			2272392833,
			1839030562,
			4259657740,
			2763975236,
			1272893353,
			4139469664,
			3200236656,
			681279174,
			3936430074,
			3572445317,
			76029189,
			3654602809,
			3873151461,
			530742520,
			3299628645,
			4096336452,
			1126891415,
			2878612391,
			4237533241,
			1700485571,
			2399980690,
			4293915773,
			2240044497,
			1873313359,
			4264355552,
			2734768916,
			1309151649,
			4149444226,
			3174756917,
			718787259,
			3951481745
		}
		local function add(a, b)
			local lsw = bit32.band(a, 65535) + bit32.band(b, 65535)
			local msw = bit32.rshift(a, 16) + bit32.rshift(b, 16) + bit32.rshift(lsw, 16)
			return bit32.bor(bit32.lshift(msw, 16), bit32.band(lsw, 65535))
		end;
		local function rol(x, n)
			return bit32.bor(bit32.lshift(x, n), bit32.rshift(x, 32 - n))
		end;
		local function F(x, y, z)
			return bit32.bor(bit32.band(x, y), bit32.band(bit32.bnot(x), z))
		end;
		local function G(x, y, z)
			return bit32.bor(bit32.band(x, z), bit32.band(y, bit32.bnot(z)))
		end;
		local function H(x, y, z)
			return bit32.bxor(x, bit32.bxor(y, z))
		end;
		local function I(x, y, z)
			return bit32.bxor(y, bit32.bor(x, bit32.bnot(z)))
		end;
		function md5.sum(message)
			local a, b, c, d = 1732584193, 4023233417, 2562383102, 271733878;
			local message_len = #message;
			local padded_message = message .. "\128"
			while #padded_message % 64 ~= 56 do
				padded_message = padded_message .. "\0"
			end;
			local len_bytes = ""
			local len_bits = message_len * 8;
			for i = 0, 7 do
				len_bytes ..= string.char(bit32.band(bit32.rshift(len_bits, i * 8), 255))
			end;
			padded_message ..= len_bytes;
			for i = 1, #padded_message, 64 do
				local chunk = padded_message:sub(i, i + 63)
				local X = {}
				for j = 0, 15 do
					local b1, b2, b3, b4 = chunk:byte(j * 4 + 1, j * 4 + 4)
					X[j] = bit32.bor(b1, bit32.lshift(b2, 8), bit32.lshift(b3, 16), bit32.lshift(b4, 24))
				end;
				local aa, bb, cc, dd = a, b, c, d;
				local s = {
					7,
					12,
					17,
					22,
					5,
					9,
					14,
					20,
					4,
					11,
					16,
					23,
					6,
					10,
					15,
					21
				}
				for j = 0, 63 do
					local f, k, shift_index;
					if j < 16 then
						f = F(b, c, d)
						k = j;
						shift_index = j % 4
					elseif j < 32 then
						f = G(b, c, d)
						k = (1 + 5 * j) % 16;
						shift_index = 4 + (j % 4)
					elseif j < 48 then
						f = H(b, c, d)
						k = (5 + 3 * j) % 16;
						shift_index = 8 + (j % 4)
					else
						f = I(b, c, d)
						k = (7 * j) % 16;
						shift_index = 12 + (j % 4)
					end;
					local temp = add(a, f)
					temp = add(temp, X[k])
					temp = add(temp, T[j + 1])
					temp = rol(temp, s[shift_index + 1])
					local new_b = add(b, temp)
					a, b, c, d = d, new_b, b, c
				end;
				a = add(a, aa)
				b = add(b, bb)
				c = add(c, cc)
				d = add(d, dd)
			end;
			local function to_le_hex(n)
				local s = ""
				for i = 0, 3 do
					s ..= string.char(bit32.band(bit32.rshift(n, i * 8), 255))
				end;
				return s
			end;
			return to_le_hex(a) .. to_le_hex(b) .. to_le_hex(c) .. to_le_hex(d)
		end
	end;
	do
		function hmac.new(key, msg, hash_func)
			if #key > 64 then
				key = hash_func(key)
			end;
			local o_key_pad = ""
			local i_key_pad = ""
			for i = 1, 64 do
				local byte = (i <= #key and string.byte(key, i)) or 0;
				o_key_pad ..= string.char(bit32.bxor(byte, 92))
				i_key_pad ..= string.char(bit32.bxor(byte, 54))
			end;
			return hash_func(o_key_pad .. hash_func(i_key_pad .. msg))
		end
	end;
	do
		local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
		function base64.encode(data)
			return ((data:gsub(".", function(x)
				local r, b_val = "", x:byte()
				for i = 8, 1, -1 do
					r = r .. (b_val % 2 ^ i - b_val % 2 ^ (i - 1) > 0 and "1" or "0")
				end;
				return r
			end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
				if #x < 6 then
					return ""
				end;
				local c = 0;
				for i = 1, 6 do
					c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
				end;
				return b:sub(c + 1, c + 1)
			end) .. ({
				"",
				"==",
				"="
			})[#data % 3 + 1])
		end
	end
end;
local function GenerateReservedServerCode(placeId)
	local uuid = {}
	for i = 1, 16 do
		uuid[i] = math.random(0, 255)
	end;
	uuid[7] = bit32.bor(bit32.band(uuid[7], 15), 64)
	uuid[9] = bit32.bor(bit32.band(uuid[9], 63), 128)
	local firstBytes = ""
	for i = 1, 16 do
		firstBytes ..= string.char(uuid[i])
	end;
	local gameCode = string.format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x", table.unpack(uuid))
	local placeIdBytes = ""
	local pIdRec = placeId;
	for _ = 1, 8 do
		placeIdBytes ..= string.char(pIdRec % 256)
		pIdRec = math.floor(pIdRec / 256)
	end;
	local content = firstBytes .. placeIdBytes;
	local SUPERDUPERSECRETROBLOXKEYTHATTHEYDIDNTCHANGEEVERSINCEFOREVER = "e4Yn8ckbCJtw2sv7qmbg"
	local signature = hmac.new(SUPERDUPERSECRETROBLOXKEYTHATTHEYDIDNTCHANGEEVERSINCEFOREVER, content, md5.sum)
	local accessCodeBytes = signature .. content;
	local accessCode = base64.encode(accessCodeBytes)
	accessCode = accessCode:gsub("+", "-"):gsub("/", "_")
	local pdding = 0;
	accessCode, _ = accessCode:gsub("=", function()
		pdding += 1;
		return ""
	end)
	accessCode ..= tostring(pdding)
	return accessCode, gameCode
end;
local accessCode, _ = GenerateReservedServerCode(game.PlaceId)
setclipboard(`game.RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer({game.PlaceId}, "", "{accessCode}")`)
game.RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(game.PlaceId, "", accessCode)
