#!/usr/bin/env luajit
local ffi = require 'ffi'
local nc = require 'ffi.netcdf'
local class = require 'ext.class'
local range = require 'ext.range'
local tolua = require 'ext.tolua'

-- assumes the return value is zero on success, nonzero on error
local function ncsafecall(f, ...)
	local retval = nc[f](...)
	if retval ~= 0 then
		error(ffi.string(nc.nc_strerror(retval)))
	end
end

local function nctypename(ncid, xtype)
	local typename = ffi.new('char[?]', nc.NC_MAX_NAME+1)
	typename[ffi.sizeof(typename)-1] = 0
	local typesize = ffi.new('size_t[1]', 0)
	ncsafecall('nc_inq_type', ncid, xtype, typename, typesize)
	return ffi.string(typename)
end

local ctypeForNCType = {
	[nc.NC_BYTE] = 'int8_t',
	[nc.NC_CHAR] = 'char',
	[nc.NC_SHORT] = 'int16_t',
	[nc.NC_INT] = 'int32_t',
	[nc.NC_LONG] = 'int32_t', -- same as NC_INT
	[nc.NC_FLOAT] = 'float',
	[nc.NC_DOUBLE] = 'double',
	[nc.NC_UBYTE] = 'uint8_t',
	[nc.NC_USHORT] = 'uint16_t',
	[nc.NC_UINT] = 'uint32_t',
	[nc.NC_INT64] = 'int64_t',
	[nc.NC_UINT64] = 'uint64_t',
	--[nc.NC_NAT] = not-a-type,
	--[nc.NC_STRING] = string,
}


local function asserttype(v, t)
	assert(type(v) == t)
	return v
end


local NetCDFAttr = class()

function NetCDFAttr:init(args)
	args = args or {}
	for k,v in pairs(args) do
		self[k] = v
	end
	self.var = asserttype(args.var, 'table')
	self.num = asserttype(args.num, 'number')


	local name = ffi.new('char[?]', nc.NC_MAX_NAME+1)
	name[ffi.sizeof(name)-1] = 0
	ncsafecall('nc_inq_attname', self.var.nc.id, self.var.id, self.num, name)
	self.name = ffi.string(name)

	local xtype = ffi.new('nc_type[1]', 0)
	local len = ffi.new('size_t[1]', 0)
	-- inq_att queries attribute by-name ...
	ncsafecall('nc_inq_att', self.var.nc.id, self.var.id, self.name, xtype, len)
	self.type = xtype[0]
	self.len = len[0]

	if self.type == nc.NC_STRING then
		self.value = "<idk how to read strings>"
	else
		local ctype = ctypeForNCType[self.type]
		local value = ffi.new(ctype..'[?]', self.len)
		ncsafecall('nc_get_att', self.var.nc.id, self.var.id, self.name, value)
		-- len of strings, i.e. char[]'s, is just #value
		-- len otherwise? is the value array length
		-- for some reason, attrs could store their strings as strings, but would rather store them as char[]'s
		if self.type == nc.NC_CHAR then
			self.value = range(0,tonumber(self.len)-1):mapi(function(i)
				return string.char(value[i])
			end):concat()
		else
			if self.len == 1 then
				self.value = value[0]
			else
				self.value = range(0,tonumber(self.len)-1):mapi(function(i)
					return value[i]
				end)
			end
		end
	end
--print(' attr num='..attr.num..' name='..attr.name..' type='..nctypename(self.nc.id, attr.type)..' len='..tostring(attr.len)..' value='..tolua(value))


end

function NetCDFAttr:__tostring()
	return 'NetCDFAttr{'
		..'num='..self.num
		..' name="'..self.name..'"'
		..' type='..nctypename(self.var.nc.id, self.type)
		..' len='..tostring(self.len)
		..' value='..tolua(self.value)
	..'}'
end


local NetCDFVar = class()

function NetCDFVar:init(args)
	assert(args)
	self.id = asserttype(args.id, 'number')
	self.nc = asserttype(args.nc, 'table')	-- parent


	local name = ffi.new('char[?]', nc.NC_MAX_NAME+1)
	name[ffi.sizeof(name)-1] = 0
	ncsafecall('nc_inq_varname', self.nc.id, self.id, name)
	self.name = ffi.string(name)
	
	-- conversely, nc_inq_varid gets the id for the name
	local xtype = ffi.new('nc_type[1]', 0)
	ncsafecall('nc_inq_vartype', self.nc.id, self.id, xtype)
	self.type = xtype[0]
	
	local varndims = ffi.new('int[1]', 0)
	ncsafecall('nc_inq_varndims', self.nc.id, self.id, varndims)
	self.ndims = varndims[0]

	local vardimids = ffi.new('int[1]', 0)
	ncsafecall('nc_inq_vardimid', self.nc.id, self.id, vardimids)
	self.dimids = vardimids[0]	


	self.attrs = {}
	
	local varnatts = ffi.new('int[1]', 0)
	ncsafecall('nc_inq_varnatts', self.nc.id, self.id, varnatts)

	for attnum=0,varnatts[0]-1 do
		local attr = NetCDFAttr{
			var = self,
			num = attnum,
		}	
		table.insert(self.attrs, attr)
	end

	local start = ffi.new('size_t[?]', self.nc.ndims)	-- how big is this? self.ndims it looks like. 
	for i=0,self.nc.ndims-1 do
		start[i] = 0
	end
		
	local count = ffi.new('size_t[?]', self.nc.ndims)	-- what's its extents?  dimptr[i] it looks like.
	for i=0,self.ndims-1 do
		count[i] = self.nc.dimptr[i]
	end

	--[==[
	local value
	if self.type == nc.NC_STRING then
		value = "<idk how to read strings>"
	else
		local ctype = ctypeForNCType[self.type]
		--[=[ after I call this once, I will always get a segfault at the end of my program, even after closing the file
		value = ffi.new(ctype..'[1]', 0)
		ncsafecall('nc_get_var', self.nc.id, self.id, value)
		value = value[0]
		--]=]
		--[=[ I could use this ... but the index vector is an array-of-integers ... BUT WHAT IS THE LENGTH?!?!?!?!
		-- I'm just guessing it's either nc_inq's "ndims" or nc_inq_varndims ... in my file's case the first is 1 and 
		value = ffi.new(ctype..'[1]', 0)
		local index = ffi.new('size_t[1]', 0)
		ncsafecall('nc_get_var1', self.nc.id, self.id, index, value)
		value = value[0]
		--]=]
		-- [=[ so how am I supposed to know how big the array is?
		local values = ffi.new(ctype..'[?]', self.nc.totalcount)	-- I guess this array is the product of count[0]...count[q-1] ?
		ncsafecall('nc_get_vara', self.nc.id, self.id, start, count, values)
		value = range(0,self.nc.totalcount-1):mapi(function(i) 
			return '\t'..tostring(values[i]) 
		end):concat'\n'
		--]=]
	end
	print(' value=\n'..tostring(value))
	--]==]
end

function NetCDFVar:__tostring()
	return 'NetCDFVar{'
		..'id='..self.id
		..' type="'..nctypename(self.nc.id, self.type)..'"'
		..' ndims='..self.ndims
		..' dimids='..self.dimids
		..' natts='..#self.attrs
		..' name='..self.name
	..'}'
end

-- get a single element in the array
function NetCDFVar:get(...)
	assert(select('#', ...) == self.nc.ndims)
	local start = ffi.new('size_t[?]', self.nc.ndims)
	local count = ffi.new('size_t[?]', self.nc.ndims)
	for i=0,self.nc.ndims-1 do
		start[i] = asserttype(select(i+1, ...), 'number')
		count[i] = 1
	end
	
	if self.type == nc.NC_STRING then
		return "<idk how to read strings>"
		--error"<idk how to read strings>"
	else
		local ctype = ctypeForNCType[self.type]
		local values = ffi.new(ctype..'[?]', 1)	-- I guess this array is the product of count[0]...count[q-1] ?
		ncsafecall('nc_get_vara', self.nc.id, self.id, start, count, values)
		return values[0]
	end
end




ffi.cdef[[
typedef struct netcdf_file_ncid_t {
	int id[1];
} netcdf_file_ncid_t;
]]
local netcdf_file_ncid_t = ffi.metatype('netcdf_file_ncid_t', {
	__gc = function(self)
		if self.id[0] ~= 0 then
			ncsafecall('nc_close', self.id[0])
			self.id[0] = 0
		end
	end,
})


local NetCDF = class()

function NetCDF:init(args)
	args = args or {}
	if args.filename then

		self.idptr = ffi.new'netcdf_file_ncid_t'
		ncsafecall('nc_open', args.filename, nc.NC_NOWRITE, self.idptr.id)
		self.id = self.idptr.id[0]
print('ncid', self.id)

		local ndims = ffi.new('int[1]', 0)
		local nvars = ffi.new('int[1]', 0)
		local unlimdimid = ffi.new('int[1]', 0)
		ncsafecall('nc_inq', self.id, ndims, nvars, ngatts, unlimdimid)
		self.ndims = ndims[0]
		self.nvars = nvars[0]
		self.unlimdimid = unlimdimid[0]
print('ndims', self.ndims)
print('nvars', self.nvars)
print('unlimdimid', self.unlimdimid)

		-- so I guess 'ndims' is some global thing .... bleh ... why not just .... smh ....
print('dims:')
		self.dimptr = ffi.new('size_t[?]', self.ndims)
		self.dims = {}	-- 1..ndims, holds .name and .size
		for dimid=0,self.ndims-1 do
			local name = ffi.new('char[?]', nc.NC_MAX_NAME+1)
			name[ffi.sizeof(name)-1] = 0
			ncsafecall('ncdiminq', self.id, dimid, name, self.dimptr + dimid)
			name = ffi.string(name)
print(' dim id='..dimid..' size='..tostring(self.dimptr[dimid])..' name='..name)
			table.insert(self.dims, {
				name = name,
				size = self.dimptr[dimid],
			})
		end
		-- now our indexs into vara are going to have 'self.ndims' elements, and dimptr[i] max length, for 0-based i

		self.totalcount = 1
		for i=0,self.ndims-1 do
			if self.dimptr[i] ~= 0 then
				self.totalcount = self.totalcount * tonumber(self.dimptr[i])
			else
				assert(i == self.unlimdimid)
			end
		end

--print('vars:')
		self.vars = {}
		local varids = ffi.new('int[?]', self.nvars)
		ncsafecall('nc_inq_varids', self.id, nvars, varids)
		for i=0,self.nvars-1 do
			local varid = varids[i]

		
			local var = NetCDFVar{
				nc = self,
				id = varid,	-- 0-based ...
			}
			table.insert(self.vars, var)	-- 1-based ...
--print('var id='..varid..' type='..nctypename(self.id, var.type)..' ndims='..var.ndims..' dimids='..var.dimids..' natts='..#var.attrs..' name='..var.name)

		--[[ documentation would be nice.  this looks more concise ... but ... causes errors when getting "status" var: "Operation not permitted", because it's a string I guess, ... so ...
			ncsafecall('ncvarinq', self.id, varid, name, xtype, varndims, vardimids, varnatts)
			print('var id', varid, 'type', xtype[0], 'ndims', varndims[0], 'dimids', vardimids[0], 'natts', varnatts[0], 'name', ffi.string(name))
		--]]

		end
	end
end


local fn = 'sci_xrsf-l2-flsum_g16_d20211026_v2-1-0.nc'
local netcdf = NetCDF{filename=fn}

for _,var in ipairs(netcdf.vars) do
	print(var)
	for _,attr in ipairs(var.attrs) do
		print('', attr)
	end
end

-- TODO vector iterator
print'values:'
for i=0,tonumber(netcdf.dimptr[0])-1 do
	for _,var in ipairs(netcdf.vars) do
		io.write('\t', tostring(var:get(i)))
	end
	print()
end


print'done'
