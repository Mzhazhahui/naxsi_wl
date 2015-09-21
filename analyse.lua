---------------------------
-- IMPORTANT configurs
---------------------------

--the naxsi log identifier
local head_string = 'ASFEP_FMT:'

--where the new rule files to be placed
local rule_dir = '/opt/GLAWAsfep/conf/white_lists'

--naxsi error log file
local log_file = '/opt/GLAWAsfep/logs/err.log'




---------------------------
--		CODES		--
---------------------------
--important keys
--old_cpath = package.path
--package.cpath = old_cpath .. ";/opt/GLAWAsfep/lua_dir/plugin/?.so"

local zone_base = 'zone'
local id_base = 'id'
local var_name_base = 'var_name'

--simple rules
local rule_list = {}
--unic rules
local unic_list = {}
--file for different server
local file_list={}



local RET = {OK = 0, ERROR = -1}






--analyse line to simple rule
function analyse_line(line)
	local head
	local tail

	local now_head = 0
	local now_id = 0
	local learn_mode = false

	local zone_string = ''
	local id_string = ''
	local var_name_string = ''

	local value = ''
	local cap_str = ''

	local zone_value = ''
	local id_value = ''
	local var_name_value = ''

	local client = ''
	local host = ''
	local url = ''

	head, tail = string.find(line, head_string)

	if(nil == head) then
		return RET.ERROR
	end

	if(nil == tail) then
		return RET.ERROR
	end

	now_head = tail

	_, _, learn_mode = string.find(line, 'learning=(%d)')

	if(nil == learn_mode) then
		return RET.ERROR
	end

	if('0' == learn_mode) then
		return RET.ERROR
	end

	_, _, url = string.find(line, 'uri=([%w%_%+%-%_%/%.]*)')
	if(nil == url)	then
		return RET.ERROR
	end

	--print(url)

	_, _, client = string.find(line, 'client:%s*([%d%.]*)')
    if(nil == client)  then
        return RET.ERROR
    end

	--print(client)

	_, _, server = string.find(line, 'server:%s*([%w%_%+%-%_%/%.]*)')
    if(nil == server)  then
        return RET.ERROR
    end

    --print(server)


	while 1 do
	zone_string = zone_base .. now_id
	id_string = id_base .. now_id
	var_name_string = var_name_base .. now_id

	cap_str = zone_string .. '=' .. '([%w|]*)'
	value = ''
	_, tail,  value = string.find(line, cap_str, now_head)
	zone_value = value

	if nil == value then
		break
	end

	now_head = tail

	cap_str = id_string .. '=' .. '(%w*)'
    value = ''
    _, tail,  value = string.find(line, cap_str, now_head)
    id_value = value

	if nil ~= value then
		now_head = tail
	end

	now_head = tail

	cap_str = var_name_string .. '=' .. '([%w%_%+%-%%]*)'
    value = ''
    _, tail,  value = string.find(line, cap_str, now_head)
	if value == nil then
		value = ''
	end

    var_name_value = value

	if nil ~= value then
		now_head = tail
	end

	table.insert(rule_list, {client=client, host=server, url=url, zone=zone_value, id=id_value, var_name=var_name_value})

	now_id = now_id + 1

	end

	return RET.OK
end





--make rule to a configur line
function get_rule_line(record)
	local str

	if("URL" == record.zone) then
        str = 'BasicRule wl:' .. record.id .. ' "mz:$URL:' .. record.url .. '|URL";'
    elseif(record.var_name == nil or record.var_name == '') then
        str = 'BasicRule wl:' .. record.id .. ' "mz:$URL:' .. record.url .. '|' .. record.zone .. '";'
    else
        str = 'BasicRule wl:' .. record.id .. ' "mz:$URL:' .. record.url ..'|$' .. record.zone 
		.. '_VAR:' .. record.var_name .. '";'
    end

	return str
end




--分server生成功能
function make_rule_file_by_server(list)
	local k
	local file
	local path

	for k, v in pairs(list) do
		if(v.host == nil or v.host == '') then
			print('too short host name.')
			--continue
		end

		file = file_list[v.host]

		if(nil == file) then
			path = rule_dir .. '/' .. v.host .. '.rule'
			file = io.open(path, "w")
			if(nil == file) then
				print("cannot create rule file.")
				return RET.ERROR
			end
			file:write("#GLA\n")

			file_list[v.host] = file
		end

		file:write(get_rule_line(v) .. '\n')
	end

	for k in pairs(file_list) do
		file = file_list[k]
		if(nil ~= file) then
			print('* rule file: ' .. rule_dir .. '/' .. k .. '.rule') 
			file:close();
			file_list[k] = nil
		end
	end

	return RET.OK
end



--相同规则合并功能
function unic_rule(tab)
	local new = {}
	for i,v in pairs(tab) do
		local host
		local url
		local zone
		local var
		local str

		host = v.host
		url  = v.url
		zone = v.zone
		id   = v.id
		var  = v.var_name

		if(nil == host) then host = '' end
		if(nil == url ) then url = '' end
		if(nil == zone) then zone = '' end
		if(nil == var ) then var = '' end

		str = host .. url .. zone .. var

		if(nil == new[str]) then
			new[str] = v
		else
			if(v.host == new[str].host
			and v.url == new[str].url
			and v.zone == new[str].zone
			and v.var == new[str].var) then
				local offset = string.find(new[str].id, v.id)
				if(nil == offset) then
					new[str].id = new[str].id .. ',' .. v.id
				end
			end
		end

		str = nil
		host = nil 
        url  = nil
        zone = nil
        id   = nil
        var  = nil

	end

	return new
end




---------------------------
-- CODES Main here
---------------------------


file = io.open(log_file)
if nil == file	then
	print('can not open file')
	return RET.ERROR
end


while 1 do

	line = file:read()
	if(nil == line) then
		break
	end

	analyse_line(line) 
end


unic_list = unic_rule(rule_list)
if(nil ~= unic_list) then
	make_rule_file_by_server(unic_list)
	print('OK!')
	file:close()
	return RET.OK
else
	print('Failed!')
	file:close()
	return RET.ERROR
end

