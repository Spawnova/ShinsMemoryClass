;AutoHotkey memory class by Spawnova - 6/6/2024
;
;to be used in conjunction with ShinsMemoryClass32.dll and ShinsMemoryClass64.dll
;dll implementation for increased speed, including multi threaded aob scans
;
;
; version 1.0.0 - 6/6/2024
;

class ShinsMemoryClass {

	__New(programIdentifier, access := "all", dllFolder:="") {
		;r=read, w=write, o=operation, s=suspend/resume, t=thread, q=query, l=limited query
		static _access := {all:0x1F0FFF,r:0x10,w:0x20,o:0x8,s:0x800,t:0x2,q:0x400,l:0x1000} ;combine for access enums:   "rwq" = Read+write+Query,   "tsl" = thread+suspend/resume+limited query  etc
		
		this.version := "1.0.0"
	
		if (!hwnd := WinExist(programIdentifier)) {
			msgbox % "Could not find a window the the identifer: " programIdentifier
			return
		}
		WinGet, pid, pid, % programIdent
		if (pid = 0) {
			msgbox % "Could not find pid for the identifier: " programIdentifer
			return
		}
		this.pid := pid

		
		if (access = "all") {
			this.access := _access.all
		} else {
			this.access := 0
			loop,parse,access
			{
				if (_access.haskey(a_loopfield))
					this.access |= _access[a_loopfield]
			}
		}
		this.hProcess := DllCall("OpenProcess", "UInt", this.access, "Int", 0, "UInt", pid)
		if (!this.hProcess) {
			msgbox % "Problem getting a handle to the process"
			return
		}
		
		this.bits := (a_ptrsize == 8)
		this.processBits := (this.bits ? this.GetProcessBits() : 0)
		this.bitStr := (this.bits ? "64" : "32")
		this.ppSize := (this.processBits ? 8 : 4)
		this.ppType := (this.processBits ? "Int64" : "UInt")
		this.lens := {char:1,uchar:1,short:2,ushort:2,int:4,uint:4,float:4,double:8,int64:8,uint64:8,ptr:a_ptrsize}
		this.bPtr := this.SetVarCapacity("_buff",0x1000)
		this.uniStr := (A_IsUnicode = 1 ? 1 : 0)

		this.LoadLib(dllFolder "ShinsMemoryClass" this.bitStr ".dll")
		this.InitFuncs()
		this.baseAddress := this.ba := this.GetBaseAddress()
	}
	
	;basically just reads the ptr type of the process, so 64bit would be int64, 32bit is uint, not an ahk pointer, 64 bit ahk reading a 32 bit pointer would return 32 bit
	ReadPtr(address,offsets*) {
		address := (offsets.count() = 0 ? address : this.GetPtr(address,offsets))
		if (!this.processBits)
			return this.ReadUint_no(address)
		return this.ReadInt64_no(address)
	}
	WritePtr(address,value,offsets*) {
		address := (offsets.count() = 0 ? address : this.GetPtr(address,offsets))
		if (!this.processBits)
			return this.Writeint_no(address,value)
		return this.WriteInt64_no(address,value)
	}

	;writing values doesn't really need to specify unsigned, it's the same regardless, i have seperate functions mostly for consistency/readability

	;ahk doesn't support unsigned int64 according to docs, function here just for consistency
	ReadUInt64(address,offsets*) {
		return DllCall(this._ReadInt64, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Int64")
	}
	ReadInt64(address,offsets*) {
		return DllCall(this._ReadInt64, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Int64")
	}
	WriteInt64(address,value,offsets*) {
		return DllCall(this._WriteInt64, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Int64",value, "Int")
	}
	WriteUInt64(address,value,offsets*) {
		return DllCall(this._WriteInt64, "Ptr", this.hProcess , "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Int64",value, "Int")
	}


	ReadFloat(address,offsets*) {
		return DllCall(this._ReadFloat, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Float")
	}
	WriteFloat(address,value,offsets*) {
		return DllCall(this._WriteFloat, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Float", value , "Int")
	}

	ReadDouble(address,offsets*) {
		return DllCall(this._ReadDouble, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Double")
	}
	WriteDouble(address,value,offsets*) {
		return DllCall(this._WriteDouble, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Double", value, "Int")
	}

	ReadUInt(address,offsets*) {
		return DllCall(this._ReadInt32, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "UInt")
	}
	ReadInt(address,offsets*) {
		return DllCall(this._ReadInt32, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Int")
	}
	WriteUInt(address,value,offsets*) {
		return DllCall(this._WriteInt32, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "UInt",value , "Int")
	}
	WriteInt(address,value,offsets*) {
		return DllCall(this._WriteInt32, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Int", value,  "Int")
	}


	ReadUShort(address,offsets*) {
		return DllCall(this._ReadInt16, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "UShort")
	}
	ReadShort(address,offsets*) {
		return DllCall(this._ReadInt16, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Short")
	}
	WriteUShort(address,value,offsets*) {
		return DllCall(this._WriteInt16, "Ptr", this.hProcess , "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "UShort",value, "Int")
	}
	WriteShort(address,value,offsets*) {
		return DllCall(this._WriteInt16, "Ptr", this.hProcess , "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Short",value, "Int")
	}


	ReadUChar(address,offsets*) {
		return DllCall(this._ReadInt8, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "UChar")
	}
	ReadChar(address,offsets*) {
		return DllCall(this._ReadInt8, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Char")
	}
	WriteUChar(address,value,offsets*) {
		return DllCall(this._WriteInt8, "Ptr", this.hProcess , "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "UChar", value, "Int")
	}
	WriteChar(address,value,offsets*) {
		return DllCall(this._WriteInt8, "Ptr", this.hProcess , "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Char", value, "Int")
	}


	ReadRaw(address,byref buffer, bytes, offsets*) {
		varsetcapacity(buffer,bytes)
		return DllCall(this._ReadRaw, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Ptr", &buffer, "Int", bytes, "Int")
	}
	WriteRaw(address, byref buffer, bytes, offsets*) {
		return DllCall(this._WriteRaw, "Ptr", this.hProcess, "Ptr", (offsets.count() = 0 ? address : this.GetPtr(address,offsets)), "Ptr", &buffer, "Int", bytes, "Int")
	}

	;write a string of hex bytes
	;WriteByteString(address,"50 51 E9 FF023194 C3")
	WriteByteString(address, bytes) {
		address := (offsets.count() = 0 ? address : this.GetPtr(address,offsets))
		bytes := this.FormatAoBBytes(bytes)
		s := strsplit(bytes," ")
		varsetcapacity(buf,s.count())
		for k,v in s {
			if (RegExMatch(v,"[a-fA-F0-9]{2}",mm)) {
				val := "0x" mm
				numput(val,buf,a_index-1,"uchar")
			}
		}
		return DllCall(this._WriteRaw, "Ptr", this.hProcess, "Ptr", address, "Ptr", &buf, "Int", s.count(), "Int")
	}

	;general purpose function for reading, these are slower than calling dedicated reads, but only by a tiny fraction
	Read(address, type := "UInt", offsets*) {
		address := (offsets.count() = 0 ? address : this.GetPtr(address,offsets))
		DllCall(this._read, "Ptr",  this.hProcess, "Ptr", address , "Ptr", this.bPtr, "UInt", this.lens[type])
		return numget(this.bPtr,0,type)
	}

	;general purpose function for writing, these are slower than calling dedicated writes, but only by a tiny fraction
	Write(address, value, type:="UInt", offsets*) {
		address := (offsets.count() = 0 ? address : this.GetPtr(address,offsets))
		numput(value,this.bPtr,0,type)
		return DllCall(this._WriteRaw, "Ptr", this.hProcess, "Ptr", address, "Ptr", this.bPtr, "UInt", this.lens[type], "Int")
	}

	;get pointer based on address + offsets[]
	GetPointer(address,offsets*) {
		i := 0
		for k,v in offsets {
			numput(v,this.bPtr,i,"Ptr")
			i += a_ptrsize
		}
		return DllCall(this._GetPtr, "Ptr", this.hProcess, "Ptr", address, "Ptr", this.bPtr, "UInt", offsets.count(), "UInt", this.ppSize, this.ppType)
	}

	ReadString(address,len:=0,unicode:=0, offsets*) {
		if (len <= 0)
			len := this.StrLen(address,unicode)
		if (len <= 0)
			return ""
		if (unicode)
			len*=2, enc := "utf-16"
		else
			enc := "utf-8"
		
		address := (offsets.count() = 0 ? address : this.GetPtr(address,offsets))
		VarSetCapacity(buffer,len)
		if (DllCall(this._ReadRaw, "Ptr", this.hProcess, "Ptr", address, "Ptr", &buffer, "UInt", len, "Int")) {
			return StrGet(&buffer,len,enc)
		}
		return ""
	}
	WriteString(address,str,unicode:=0, offsets*) {
		address := (offsets.count() = 0 ? address : this.GetPtr(address,offsets))
		return DllCall(this._WriteString, "Ptr", this.hProcess, "Ptr", address, "Ptr", &str, "Int", 0, "Int", unicode, "int", this.uniStr, "Int")
	}

	;null terminate
	WriteStringNT(address,str,unicode:=0, offsets*) {
		address := (offsets.count() = 0 ? address : this.GetPtr(address,offsets))
		return DllCall(this._WriteString, "Ptr", this.hProcess, "Ptr", address, "Ptr", &str, "Int", 1, "Int", unicode, "int", this.uniStr, "Int")
	}
	
	;get base address of a specified module
	GetModuleBaseAddress(moduleStr) {
		return DllCall(this._GetModuleBaseAddress, "Ptr", this.hProcess, "AStr", moduleStr, "Ptr")
	}

	Nop(address,bytes) {
		varsetcapacity(buf,bytes,0x90)
		this.WriteRaw(address,buf,bytes)
	}
	
	;scans the entire process memory for an array of bytes, multithreading should only be disabled if it doesn't work for some reason
	;wildcards can be anything that isn't hex ?? ? * ** - . etc. all valid
	;HEX is REQUIRED, decimal values not supported, 0x prefix NOT REQUIRED
	;example string:    FF 00 E9 12345678 00 9F ?? ?? ?? ?? EFF871E9B11A9D C3
	AoB(byteStr,multiThread:=1) {
		bStr := this.FormatAoBBytes(byteStr)
		s := strsplit(bStr," ")
		varsetcapacity(bytes,s.count())
		varsetcapacity(mask,s.count())
		for k,v in s {
			if (RegExMatch(v,"[a-fA-F0-9]{2}",mm)) {
				val := "0x" mm
				numput(val,bytes,a_index-1,"uchar")
				numput(0,mask,a_index-1,"uchar")
			} else {
				numput(1,mask,a_index-1,"uchar")
			}
		}
		return DllCall((multiThread ? this._AobScanMT : this._AoBScan), "Ptr", this.hProcess, "Ptr", &bytes, "Ptr", &mask, "UInt", s.count(), "Ptr")
	}

	;returns an address where there is uncommited memory with a specified byte size
	FindFreeMemory(bytes:=0x1000) {
		return DllCall(this._FindFreeMemory, "Ptr", this.hProcess, "UInt", bytes, "Ptr")
	}

	;returns an address where there is uncommited memory with a specified byte size but closest to a given address
	;if the closest address is further than maxdist returns -1
	FindFreeMemoryClosest(address,bytes:=0x1000,maxDist:=0x7FFFFFF0) {
		return DllCall(this._FindClosestFreeMemory, "Ptr", this.hProcess, "Ptr", address, "UInt", bytes, "Ptr", maxDist, "Ptr")
	}

	;returns an address where there is uncommited memory with a specified byte size but nearby a given address
	;if no address is within range returns -1
	FindFreeMemoryNearby(address,bytes:=0x1000,maxDist:=0x7FFFFFF0) {
		return DllCall(this._FindFreeMemoryNearby, "Ptr", this.hProcess, "Ptr", address, "UInt", bytes, "Ptr", maxDist, "Ptr")
	}

	;if address is 0, it will find the first available region
	;access: r=read, w=write, e=execute    (mix and match, default 0x40 execute-read-write)
	;combine with FindClosestFreeMemory() to alloc near specific addresses
	;returns the base address of allocation if successfull, 0 otherwise
	Alloc(bytes:=0x1000, address:=0, access:="rwe", topDown:=0) {
		return DllCall(this._AllocMemory, "Ptr", this.hProcess, "Ptr", address, "UInt", bytes, "AStr", access, "UInt", topDown, "Ptr")
	}

	;frees memory that was allocated, need to specify the allocation base address
	Free(address) {
		return DllCall("VirtualFreeEx", "Ptr", this.hProcess, "Ptr", address, "Ptr", 0, "UInt", 0x8000, "UInt")
	}

	;simple wrapper function for making a single protected call
	writeProt(address, value, type := "Uint", offsets*) {
		address := (offsets.count() = 0 ? address : this.GetPtr(address,offsets))
		if (!old := this.Unprotect(address))
			return 0
		v := this.Write(address,value,type)
		this.protect(address,old)
		return v
	}

	;unprotect a region of memory, giving it read+write+execute
	Unprotect(address,sz:=4) {
		if (!DllCall("Kernel32.dll\VirtualProtectEx", "Ptr", _m.hProcess, "Ptr", address, "UInt", sz, "UInt", 0x40, "Ptr*", lpflOldProtect))
			return 0
		return lpflOldProtect
	}
	;sets a new protection, use the return value of Unprotect to restore the old protection
	Protect(address,prot,sz:=4) {
		if (!DllCall("Kernel32.dll\VirtualProtectEx", "Ptr", _m.hProcess, "Ptr", address, "UInt", sz, "UInt", prot, "Ptr*", 0))
			return 0
		return 1
	}

	;suspends the process, pausing it essentially
	Suspend() {
		return DllCall("ntdll\NtSuspendProcess", "UInt", this.hProcess)
	}  
	;resume the process
	Resume() {
		return DllCall("ntdll\NtResumeProcess", "UInt", this.hProcess)
	} 








	;internal funcs used by class, not meant to be called by user
	__delete() {
		DllCall("CloseHandle", "Ptr", this.hProcess)
	}
	LoadLib(lib*) {
		for k,v in lib {
			if (!DllCall("GetModuleHandle", "str", v, "Ptr")) {
				hm := DllCall("LoadLibrary", "Str", v)
				if (hm = 0) {
					msgbox % "Unable to load module: " v
				}
			}
		}
	}
	SetVarCapacity(key,size,fill=0) {
		this.SetCapacity(key,size)
		DllCall("RtlFillMemory","Ptr",this.GetAddress(key),"Ptr",size,"uchar",fill)
		return this.GetAddress(key)
	}
	GetProcessBits() {
		if (this.access & (0x400 | 0x1000)) {
			if DllCall("IsWow64Process", "Ptr", this.hProcess, "Int*", wow64)
				return !wow64
		} else {
			tHandle := DllCall("OpenProcess", "UInt", 0x1000, "Int", 0, "UInt", this.pid)
			v := DllCall("IsWow64Process", "Ptr", this.hProcess, "Int*", wow64)
			DllCall("CloseHandle", "Ptr", tHandle)
			if (v)
				return !wow64
		}
		return 1
	}
	GetPtr(address,offsets) {
		i := 0
		for k,v in offsets {
			numput(v,this.bPtr,i,"Ptr")
			i += a_ptrsize
		}
		return DllCall(this._GetPtr, "Ptr", this.hProcess, "Ptr", address, "Ptr", this.bPtr, "UInt", offsets.count(), "UInt", this.ppSize, this.ppType)
	}
	InitFuncs() {
		if (!mdl := DllCall("GetModuleHandle", "str", "ShinsMemoryClass" this.bitStr, "Ptr")) {
			msgbox % "Dll is not loaded!"
			return
		}
		this._GetBaseAddress := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "GetBaseAddress", "Ptr")
		this._GetPtr := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "GetPointer", "Ptr")
		this._ReadDouble := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "ReadDouble", "Ptr")
		this._ReadFloat := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "ReadFloat", "Ptr")
		this._ReadInt32 := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "ReadInt32", "Ptr")
		this._ReadInt64 := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "ReadInt64", "Ptr")
		this._ReadInt16 := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "ReadInt16", "Ptr")
		this._ReadInt8 := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "ReadInt16", "Ptr")
		this._StrLen := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "StrLen", "Ptr")
		this._AoBScan := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "AoBScan", "Ptr")
		this._AoBScanMT := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "AoBScanMT", "Ptr")
		this._ReadRaw := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "ReadRawBytes", "Ptr")
		this._WriteDouble := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "WriteDouble", "Ptr")
		this._WriteFloat := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "WriteFloat", "Ptr")
		this._WriteInt32 := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "WriteInt32", "Ptr")
		this._WriteInt64 := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "WriteInt64", "Ptr")
		this._WriteInt16 := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "WriteInt16", "Ptr")
		this._WriteInt8 := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "WriteInt8", "Ptr")
		this._WriteRaw := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "WriteRawBytes", "Ptr")
		this._GetModuleBaseAddress := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "GetModuleBaseAddress", "Ptr")
		this._AoB_Module := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "AoB_Module", "Ptr")
		this._AllocMemory := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "AllocMemory", "Ptr")
		this._FindClosestFreeMemory := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "FindClosestFreeMemory", "Ptr")
		this._FindFreeMemory := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "FindFreeMemory", "Ptr")
		this._FindFreeMemoryNearby := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "FindFreeMemoryNearby", "Ptr")
		this._Read := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "rRead", "Ptr")
		this._WriteString := DllCall("GetProcAddress", "Ptr", mdl, "AStr", "WriteString", "Ptr")
	}
	FormatAoBBytes(byteStr) {
		byteStr := RegExReplace(byteStr,"\s\s+"," ")
		byteStr := RegExReplace(byteStr,"^\s+|\s+$","")
		while RegExMatch(byteStr," (\S\S)(\S))")
			byteStr := RegExReplace(byteStr," (\S\S)(\S)"," $1 $2")
		while RegExMatch(byteStr,"(\S)(\S\S) ")
			byteStr := RegExReplace(byteStr,"(\S)(\S\S) ","$1 $2 ")
		return byteStr
	}
	GetBaseAddress() {
		return DllCall(this._GetBaseAddress, "Ptr", this.hProcess, "Ptr")
	}
	StrLen(address,unicode:=0) {
		return DllCall(this._StrLen, "Ptr", this.hProcess, "Ptr", address, "Int", unicode, "UInt")
	}
	ReadInt64_no(address) {
		return DllCall(this._ReadInt64, "Ptr", this.hProcess, "Ptr", address, "Int64")
	}
	WriteInt64_no(address,value) {
		return DllCall(this._WriteInt64, "Ptr", this.hProcess, "Ptr", address, "Int64",value, "Int")
	}
	ReadUInt_no(address) {
		return DllCall(this._ReadInt32, "Ptr", this.hProcess, "Ptr", address, "UInt")
	}
	WriteInt_no(address,value) {
		return DllCall(this._WriteInt32, "Ptr", this.hProcess, "Ptr", address, "Int", value,  "Int")
	}
}