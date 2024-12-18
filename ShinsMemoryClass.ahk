; ##########################################################
; ##                                                      ##
; ##    AutoHotkey memory class by Spawnova - 6/6/2024    ##
; ##                                                      ##
; ##########################################################
;
; To be used in conjunction with ShinsMemoryClass32.dll and ShinsMemoryClass64.dll
;
; dll implementation for increased speed, including multi threaded aob scans
;
; For an overview and basic usage see -> www.youtube.com/watch?v=7OUDVem7AcA
;
; Version 1.1.4 - 12/18/2024
;

class ShinsMemoryClass {

	__New(programIdentifier, access := "all", dllFolder:="") {
		;a=all, r=read, w=write, o=operation, s=suspend/resume, t=thread, q=query, l=limited query
		static _access := {all:0x1F0FFF,a:0x1F0FFF,r:0x10,w:0x20,o:0x8,s:0x800,t:0x2,q:0x400,l:0x1000} ;combine for access enums:   "rwq" = Read+write+Query,   "tsl" = thread+suspend/resume+limited query  etc
		
		this.version := "1.1.4"
	
		if (!hwnd := WinExist(programIdentifier)) {
			msgbox % "Could not find a window with the identifer: " programIdentifier
			return
		}
		WinGet, pid, pid, % programIdentifier
		if (pid = 0) {
			msgbox % "Could not find pid for the identifier: " programIdentifier
			return
		}
		this.pid := pid

		
		if (access = "all" or access = 0) {
			this.access := _access.all
		} else {
			this.access := 0
			loop,parse,access
			{
				if (_access.haskey(a_loopfield))
					this.access |= _access[a_loopfield]
			}
		}
		this.hProcess := this.OpenProcess(pid,this.access)
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

		ifexist, C:\Users\Shin\source\repos\ShinsMemoryClass\x64\Release
			this.LoadLib("C:\Users\Shin\source\repos\ShinsMemoryClass\x64\Release\ShinsMemoryClass" this.bitStr ".dll")
		else
			this.LoadLib((dllFolder = "" ? "" : RegExMatch(dllFolder,"\\$|\/$") ? dllFolder : dllFolder "\") "ShinsMemoryClass" this.bitStr ".dll")

		this.InitFuncs()
		this.baseAddress := this.ba := this.GetBaseAddress()
	}
	
	;basically just reads the ptr type of the process, so 64bit would be int64, 32bit is uint, not an ahk pointer, 64 bit ahk reading a 32 bit pointer would return 32 bit
	ReadPtr(address,offsets*) {
		c := offsets.count()
		address:=(c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets))
		if (!this.processBits)
			return this.ReadUint_no(address)
		return this.ReadInt64_no(address)
	}
	WritePtr(address,value,offsets*) {
		c := offsets.count()
		address:=(c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets))
		if (!this.processBits)
			return this.Writeint_no(address,value)
		return this.WriteInt64_no(address,value)
	}

	;writing values doesn't really need to specify unsigned, it's the same regardless, i have seperate functions mostly for consistency/readability

	;ahk doesn't support unsigned int64 according to docs, function here just for consistency
	ReadUInt64(address,offsets*) {
		c := offsets.count()
		return DllCall(this._ReadInt64, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Int64")
	}
	ReadInt64(address,offsets*) {
		c := offsets.count()
		return DllCall(this._ReadInt64, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Int64")
	}
	WriteInt64(address,value,offsets*) {
		c := offsets.count()
		return DllCall(this._WriteInt64, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Int64",value, "Int")
	}
	WriteUInt64(address,value,offsets*) {
		c := offsets.count()
		return DllCall(this._WriteInt64, "Ptr", this.hProcess , "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Int64",value, "Int")
	}


	ReadFloat(address,offsets*) {
		c := offsets.count()
		return DllCall(this._ReadFloat, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Float")
	}
	WriteFloat(address,value,offsets*) {
		c := offsets.count()
		return DllCall(this._WriteFloat, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Float", value , "Int")
	}

	ReadDouble(address,offsets*) {
		c := offsets.count()
		return DllCall(this._ReadDouble, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Double")
	}
	WriteDouble(address,value,offsets*) {
		c := offsets.count()
		return DllCall(this._WriteDouble, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Double", value, "Int")
	}

	ReadUInt(address,offsets*) {
		c := offsets.count()
		return DllCall(this._ReadInt32, "Ptr", this.hProcess, "Ptr", (c==0?address:c==1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "UInt")
	}
	ReadInt(address,offsets*) {
		c := offsets.count()
		return DllCall(this._ReadInt32, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Int")
	}
	WriteUInt(address,value,offsets*) {
		c := offsets.count()
		return DllCall(this._WriteInt32, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "UInt",value , "Int")
	}
	WriteInt(address,value,offsets*) {
		c := offsets.count()
		return DllCall(this._WriteInt32, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Int", value,  "Int")
	}


	ReadUShort(address,offsets*) {
		c := offsets.count()
		return DllCall(this._ReadInt16, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "UShort")
	}
	ReadShort(address,offsets*) {
		c := offsets.count()
		return DllCall(this._ReadInt16, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Short")
	}
	WriteUShort(address,value,offsets*) {
		c := offsets.count()
		return DllCall(this._WriteInt16, "Ptr", this.hProcess , "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "UShort",value, "Int")
	}
	WriteShort(address,value,offsets*) {
		c := offsets.count()
		return DllCall(this._WriteInt16, "Ptr", this.hProcess , "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Short",value, "Int")
	}


	ReadUChar(address,offsets*) {
		c := offsets.count()
		return DllCall(this._ReadInt8, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "UChar")
	}
	ReadChar(address,offsets*) {
		c := offsets.count()
		return DllCall(this._ReadInt8, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Char")
	}
	WriteUChar(address,value,offsets*) {
		c := offsets.count()
		return DllCall(this._WriteInt8, "Ptr", this.hProcess , "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "UChar", value, "Int")
	}
	WriteChar(address,value,offsets*) {
		c := offsets.count()
		return DllCall(this._WriteInt8, "Ptr", this.hProcess , "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Char", value, "Int")
	}


	ReadRaw(address,byref buffer, bytes, offsets*) {
		c := offsets.count()
		varsetcapacity(buffer,bytes)
		return DllCall(this._ReadRaw, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Ptr", &buffer, "Int", bytes, "Int")
	}
	WriteRaw(address, byref buffer, bytes, offsets*) {
		c := offsets.count()
		return DllCall(this._WriteRaw, "Ptr", this.hProcess, "Ptr", (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets)), "Ptr", &buffer, "Int", bytes, "Int")
	}

	;write a string of hex bytes
	;WriteByteString(address,"50 51 E9 FF023194 C3")
	WriteByteString(address, bytes) {
		c := offsets.count()
		address := (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets))
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
		c := offsets.count()
		address := (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets))
		DllCall(this._read, "Ptr",  this.hProcess, "Ptr", address , "Ptr", this.bPtr, "UInt", this.lens[type])
		return numget(this.bPtr,0,type)
	}

	;general purpose function for writing, these are slower than calling dedicated writes, but only by a tiny fraction
	Write(address, value, type:="UInt", offsets*) {
		c := offsets.count()
		address := (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets))
		numput(value,this.bPtr,0,type)
		return DllCall(this._WriteRaw, "Ptr", this.hProcess, "Ptr", address, "Ptr", this.bPtr, "UInt", this.lens[type], "Int")
	}

	;get pointer based on address + offsets[]
	GetPointer(address,offsets*) {
		varsetcapacity(bptr,1024,0)
		i := 0
		if (this.processBits) {
			for k,v in offsets {
				numput(v,bPtr,i,"int64"), i += 8
			}
			return DllCall(this._GetPtr64, "Ptr", this.hProcess, "int64", address, "Ptr",&bPtr, "UInt", offsets.count(), "int64")
		} else {
			for k,v in offsets {
				numput(v,bPtr,i,"uint"), i += 4
			}
			return DllCall(this._GetPtr32, "Ptr", this.hProcess, "uint", address, "Ptr",&bPtr, "UInt", offsets.count(), "uint")
		}
	}

	ReadString(address,len:=0,unicode:=0, offsets*) {
		c := offsets.count()
		address := (c == 0 ? address : c == 1 ? this.ReadPtr(address+offsets[1]) : this.GetPtr2(address,offsets))
		if (len <= 0)
			len := this.StrLen(address,unicode)
		if (len <= 0) {
			return ""
		}
		if (unicode) {
			len*=2
			enc := "utf-16"
		} else {
			enc := "utf-8"
		}
		VarSetCapacity(buffer,len)
		if (DllCall(this._ReadRaw, "Ptr", this.hProcess, "Ptr", address, "Ptr", &buffer, "UInt", len, "Int")) {
			return StrGet(&buffer,len,enc)
		}
		return ""
	}
	WriteString(address,str,unicode:=0, offsets*) {
		c := offsets.count()
		address := (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets))
		return DllCall(this._WriteString, "Ptr", this.hProcess, "Ptr", address, "Ptr", &str, "Int", 0, "Int", unicode, "int", this.uniStr, "Int")
	}

	;null terminate
	WriteStringNT(address,str,unicode:=0, offsets*) {
		c := offsets.count()
		address := (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets))
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

	OpenProcess(pid,access) {
		return DllCall("Kernel32.dll\OpenProcess", "UInt", access, "Int", 0, "UInt", pid)
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

	AoBModule(module,byteStr) {
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
		return DllCall(this._AoB_Module, "Ptr", this.hProcess, "Ptr", module, "Ptr", &bytes, "Ptr", &mask, "UInt", s.count(), "Ptr")
	}

	AoBAll(byteStr, byref ptrs) {
		varsetcapacity(ptrs,4096,0)
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
		return DllCall(this._AoBall, "Ptr", this.hProcess, "Ptr", &bytes, "Ptr", &mask, "UInt", s.count(), "Ptr", &ptrs, "Ptr")
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
	;returns the base address of allocation if successfull, < 0 otherwise
	Alloc(bytes:=0x1000, address:=0, access:="rwe", topDown:=0) {
		return DllCall(this._AllocMemory, "Ptr", this.hProcess, "Ptr", address, "UInt", bytes, "AStr", access, "UInt", topDown, "Ptr")
	}

	;frees memory that was allocated, need to specify the allocation base address
	Free(address) {
		return DllCall("Kernel32.dll\VirtualFreeEx", "Ptr", this.hProcess, "Ptr", address, "Ptr", 0, "UInt", 0x8000, "UInt")
	}

	;simple wrapper function for making a single protected call
	writeProt(address, value, type := "Uint", offsets*) {
		c := offsets.count()
		address := (c=0?address:c=1?this.ReadPtr(address+offsets[1]):this.GetPtr2(address,offsets))
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
		return DllCall("ntdll.dll\NtSuspendProcess", "Ptr", this.hProcess)
	}  
	;resume the process
	Resume() {
		return DllCall("ntdll.dll\NtResumeProcess", "Ptr", this.hProcess)
	} 

	;create a thread and execute code at a specified address
	Execute(address) {
		if (hThread := this.CreateThread(address)) {
			this.WaitThread(hThread, 5000)
			this.CloseThread(hThread)
		}
	}

	
	
	CreateThread(address,suspended:=0) {
		return DllCall("Kernel32\CreateRemoteThread", "Ptr", this.hProcess, "Ptr", 0, "Ptr", 0, "Ptr", address, "Ptr", 0, "UInt", (suspended?0x4:0x0), "Ptr*", 0, "Ptr")
	}
	CloseThread(hThread) {
		DllCall("Kernel32.dll\CloseHandle", "Ptr", hThread, "UInt")
	}
	;0xFFFFFFFF = infite wait, 0 = no wait
	WaitThread(hThread,timeout:=0xFFFFFFFF) {
		return DllCall("Kernel32\WaitForSingleObject", "Ptr", hThread, "UInt", timeout, "UInt")
	}
	ResumeThread(hThread) {
		return DllCall("Kernel32\ResumeThread", "Ptr", hThread, "UInt")
	}

	
	;helper function to convert asm string copied from cheat engine to ahk template
	ConvertCEString() {
		if (RegExMatch(clipboard,"\S\S\S\S\S\S\S\S - ")) {
			str := ""
			loop,parse,% clipboard,`n,`r
			{
				s := regexreplace(a_loopfield,"\{[^\}]+\}","")
				s := strsplit(s,"-","",3)
				if (s.count() < 3)
					continue

				s2 := RegExReplace(s[2],"^ |\s+$","")
				s3 := RegExReplace(s[3],"^ |\s+$","")
				ln := s2
				if (RegExMatch(s2,"(\S\S)(\S\S)(\S\S)(\S\S)",mm)) {
					be := mm4 mm3 mm2 mm1
					le := mm1 mm2 mm3 mm4
					if (!instr(s3,be)) {
						if (RegExMatch(s3,"dll\+|\[........]|exe\+|\[........]")) {
							if (RegExMatch(s3,"jmp |jne |jg |je |jl |jng |jge |jle |je |jb |ja "))
								ln := StrReplace(ln,le,"+")
							else if (InStr(s2,"call "))
								ln := StrReplace(ln,le,"@")
							else
								ln := StrReplace(ln,le,"!")
						}
					}
				}
				nn := 0
				while(RegExMatch(ln,"(\S\S)\S",mm)) {
					ln := RegExReplace(ln,mm1 "(\S)",mm1 " $1",nn,1)
				}
				ln := StrReplace(ln,"!","REPLE")
				ln := StrReplace(ln,"+","JUMP")
				ln := StrReplace(ln,"@","CALL")
				str .= (str = "" ? "str := " """": "`nstr .= " """" " ") ln """" "  `;" s3
			}
			clipboard := str
			return 1
		}
		return 0
	}




	;internal funcs used by class, not meant to be called by user
	__delete() {
		DllCall("Kernel32.dll\CloseHandle", "Ptr", this.hProcess)
	}
	LoadLib(lib*) {
		for k,v in lib {
			if (!DllCall("Kernel32.dll\GetModuleHandle", "Str", v, "Ptr")) {
				hm := DllCall("Kernel32.dll\LoadLibrary", "Str", v)
				if (hm = 0) {
					msgbox % "Unable to load module: " v
				}
			}
		}
	}
	SetVarCapacity(key,size,fill=0) {
		this.SetCapacity(key,size)
		DllCall("Kernel32.dll\RtlFillMemory","Ptr",this.GetAddress(key),"Ptr",size,"UChar",fill)
		return this.GetAddress(key)
	}
	GetProcessBits() {
		if (this.access & (0x400 | 0x1000)) {
			if DllCall("Kernel32.dll\IsWow64Process", "Ptr", this.hProcess, "Int*", wow64)
				return !wow64
		} else {
			tHandle := this.OpenProcess(this.pid,0x1000)
			v := DllCall("Kernel32.dll\IsWow64Process", "Ptr", this.hProcess, "Int*", wow64)
			DllCall("Kernel32.dll\CloseHandle", "Ptr", tHandle)
			if (v)
				return !wow64
		}
		return 1
	}
	GetPtr2(address,offsets) {
		varsetcapacity(bptr,1024)
		i := 0
		if (this.processBits) {
			for k,v in offsets {
				numput(v,bPtr,i,"int64"), i += 8
			}
			return DllCall(this._GetPtr64, "Ptr", this.hProcess, "int64", address, "Ptr",&bPtr, "UInt", offsets.count(), "int64")
		} else {
			for k,v in offsets {
				numput(v,bPtr,i,"uint"), i += 4
			}
			return DllCall(this._GetPtr32, "Ptr", this.hProcess, "uint", address, "Ptr",&bPtr, "UInt", offsets.count(), "uint")
		}
	}
	InitFuncs() {
		if (!mdl := DllCall("Kernel32.dll\GetModuleHandle", "str", "ShinsMemoryClass" this.bitStr, "Ptr")) {
			msgbox % "Dll is not loaded!"
			return
		}
		this._GetBaseAddress := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "GetBaseAddress", "Ptr")
		this._GetPtr := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "GetPointer", "Ptr")
		this._GetPtr32 := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "GetPtr32", "Ptr")
		this._GetPtr64 := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "GetPtr64", "Ptr")
		this._ReadDouble := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "ReadDouble", "Ptr")
		this._ReadFloat := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "ReadFloat", "Ptr")
		this._ReadInt32 := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "ReadInt32", "Ptr")
		this._ReadInt64 := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "ReadInt64", "Ptr")
		this._ReadInt16 := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "ReadInt16", "Ptr")
		this._ReadInt8 := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "ReadInt16", "Ptr")
		this._StrLen := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "StrLen", "Ptr")
		this._AoBScan := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "AoBScan", "Ptr")
		this._AoBScanMT := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "AoBScanMT", "Ptr")
		this._ReadRaw := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "ReadRawBytes", "Ptr")
		this._WriteDouble := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "WriteDouble", "Ptr")
		this._WriteFloat := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "WriteFloat", "Ptr")
		this._WriteInt32 := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "WriteInt32", "Ptr")
		this._WriteInt64 := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "WriteInt64", "Ptr")
		this._WriteInt16 := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "WriteInt16", "Ptr")
		this._WriteInt8 := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "WriteInt8", "Ptr")
		this._WriteRaw := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "WriteRawBytes", "Ptr")
		this._GetModuleBaseAddress := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "GetModuleBaseAddress", "Ptr")
		this._AoB_Module := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "AoB_Module", "Ptr")
		this._AllocMemory := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "AllocMemory", "Ptr")
		this._FindClosestFreeMemory := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "FindClosestFreeMemory", "Ptr")
		this._FindFreeMemory := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "FindFreeMemory", "Ptr")
		this._FindFreeMemoryNearby := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "FindFreeMemoryNearby", "Ptr")
		this._Read := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "rRead", "Ptr")
		this._WriteString := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "WriteString", "Ptr")
		this._ExplodeHex := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "ExplodeHex", "Ptr")
		this._ExplodeHex64 := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "ExplodeHex64", "Ptr")
		this._RelBytes := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "RelOffset", "Ptr")
		this._RelBytes64 := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "RelOffset64", "Ptr")
		this._ToHex := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "ToHex", "Ptr")
		this._ToHex64 := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "ToHex64", "Ptr")
		this._aoball := DllCall("Kernel32.dll\GetProcAddress", "Ptr", mdl, "AStr", "AoBScanAll", "Ptr")
	}
	ToHex(val,prefix:=1,bits:=0) {
		if (bits) {
			len := DllCall(this._ToHex64,"Ptr",this.bPtr,"Int64",val,"UInt",prefix)
			return StrGet(this.bPtr,len,"utf-8")
		}
		len := DllCall(this._ToHex,"Ptr",this.bPtr,"UInt",val,"UInt",prefix)
		return StrGet(this.bPtr,len,"utf-8")
	}
	FormatAoBBytes(byteStr) {
		byteStr := RegExReplace(byteStr,"\s\s+"," ")
		byteStr := RegExReplace(byteStr,"^\s+|\s+$","")
		while RegExMatch(byteStr," (\S\S)(\S)")
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
	ExplodeHex(val,bits:=0,swap:=0) {
		if (bits) {
			DllCall(this._ExplodeHex64,"Ptr",this.bPtr,"Int64",val,"UInt",swap)
			return StrGet(this.bPtr,23,"utf-8")
		} else {
			DllCall(this._ExplodeHex,"Ptr",this.bPtr,"UInt",val,"UInt",swap)
			return StrGet(this.bPtr,11,"utf-8")
		}
	}
	RelBytes(from,to,bits:=0) {
		if (bits)
			return DllCall(this._RelBytes64,"Int64",from,"Int64",to)
		return DllCall(this._RelBytes,"UInt",from,"UInt",to)
	}
}






;simple helper class for writing asm, commits a region and half is reserved for code execution, the other half for storage
class HookHelper {
	__New(mem, storeAddress, size:=0x1000, start:=0, init:=0xCCCCCCCC, maxDist:=0x7FFFFFF0) {
		this.bits := mem.bits
		this.size := Max(Ceil(size/0x1000),1) * 0x1000
		this.mem := mem
		this.address := 0
		this.pcache := 0
		this.current := 0
		this.currentCache := 0
		this.temp := 0


		if (!pmem := this.RegionPtr(storeAddress,size,start,init)) {
			msgbox % "Problem allocating a region to store at " mem.ToHex(storeAddress,1,mem.processBits)
		}
	}
	
	;helper function that checks a static address for a ptr to a commited region and return it
	;or if no ptr is found, create a new region and store it's address into the static address
	;if the value at address equals INIT, then create a new region with SIZE bytes, located near START, within MAXDIST
	;should only be called if the initial call fails when instantiating the class
	RegionPtr(address,size:=0x1000,start:=0,init:=0xCCCCCCCC,maxDist:=0x7FFFFFF0) {
		if (this.mem.ReadUInt(address) = init) {
			if (start <= 0) {
				pmem := this.mem.Alloc(size)
			} else {
				
				start := this.mem.FindFreeMemoryNearby(start,size,maxDist)
				if (start = -1) {
					msgbox % "RegionPtr Error:`nFailed to find free memory close to " this.mem.ToHex(start,1,this.mem.processBits)
					return 0
				}
				pmem := this.mem.Alloc(size,start)
			}
			
			if (pmem < 0) {
				msgbox % "RegionPtr Error:`nFailed to alloc - " dllcall("Kernel32.dll\GetLastError") " (" this.mem.ToHex(DllCall("ntdll.dll\RtlGetLastNtStatus"),1) ")"
				return 0
			}

			olp := this.mem.unprotect(address,8)
			this.mem.writeptr(address,pmem)
			this.mem.protect(address,olp,8)

		} else {
			pmem := this.mem.readptr(address)
		}
		
		this.size := size
		this.address := pmem
		this.pcache := this.address + round(this.size/2)
		this.current := this.address
		this.currentCache := this.pcache
		this.temp := this.pcache+4

		return pmem
	}

	

	;replace special instructions with args
	WriteAsm(str,args*) {
		s := strsplit(str," ")
		out := ""
		i := 1
		start := this.current
		for k,v in s
		{
			out .= (a_index=1 ? "" : " ") 
			if (v = "REPLE") {
				out .= this.mem.ExplodeHex(args[i],0,1)
				this.current+=4,i++
			} else if (v = "REPLE64") {
				out .= this.mem.ExplodeHex(args[i],1,1)
				this.current+=8,i++
			} else if (v = "REP") {
				out .= this.mem.ExplodeHex(args[i])
				this.current+=4,i++
			} else if (v = "REP64") {
				out .= this.mem.ExplodeHex(args[i],1)
				this.current+=8,i++
			} else if (v = "CALL") {
				out .= this.RelSwapStr(this.current+4,args[i])
				this.current+=4,i++
			} else if (v = "JUMP") {
				out .= this.RelSwapStr(this.current+4,args[i])
				this.current+=4,i++
			} else if (v = "JUMP2") {
				diff := args[i]-this.current
				if (abs(diff) > 127) {
					out .= "E9 " this.RelSwapStr(this.current+5,args[i])
					this.current+=5,i++
				} else {
					if (diff > 0)
						out .= "EB " tohex(diff-1)
					else
						out .= "EB " tohex(255+(diff-1))
					this.current+=2,i++
				}
			} else if (v = "JNE") {
				diff := args[i]-this.current
				if (abs(diff) > 127) {
					out .= "0F 85 " this.RelSwapStr(this.current+6,args[i])
					this.current+=6,i++
				} else {
					if (diff > 0)
						out .= "75 " tohex(diff-1)
					else
						out .= "75 " tohex(255+(diff-1))
					this.current+=2,i++
				}
			} else if (RegExMatch(v,"REL_([^_]+)_([^_]+)_(\d)",mm)) {
				out .= (mm3 ? this.RelSwapStr64(this.current+8,mm2) : this.RelSwapStr(this.current+4,mm2))
				this.current+=(mm3?8:4),i += mm1
			} else {
				this.current++
				out .= v
			}
		}

		loop 5 {
			if (a_index > 1 and mod(this.current,4) = 0)
				break
			out .= (out = "" ? "" : " ")  "90"
			this.current++
		}
		
		this.mem.WriteByteString(start,out)
		return start
	}
	ToAsmCall(start,func,hex:=1,bigE:=0) {
		if (func > start) {
			diff := func - start - 1
			return (bigE ? diff : this.ToLittleEndian(diff,hex))
		} else {
			diff := 0xFFFFFFFF - (start-func)
			return (bigE ? diff : this.ToLittleEndian(diff,hex))
		}
	}
	ToLittleEndian(n,hex:=1) {
		a := (n&0xFF000000) >> 24
		b := (n&0xFF0000) >> 16
		c := (n&0xFF00) >> 8
		d := (n&0xFF)
		v := (d<<24)+(c<<16)+(b<<8)+a
		return (hex ? this.mem.ExplodeHex(v,0,1) : v)
   }
	;hook with a 32 bit relative jump
	Hook(fromAddress,toAddress,force:=0,nops:=0) {
		if (!force and this.mem.readuchar(fromAddress) = 0xE9) {
			return
		}
	
		asm := "E9 " this.RelSwapStr(fromAddress+5,toAddress)
		loop % nops
			asm .= " 90"

		prot := this.mem.unprotect(fromAddress)
		this.mem.WriteByteString(fromAddress,asm)
		this.mem.protect(fromAddress,prot)
	}

	;hook with a 64 bit absolute jump
	Hook64(fromAddress,toAddress,force:=0,nops:=0) {
		if (!force and this.mem.readushort(fromAddress) = 0x25FF) {
			return
		}
		asm := "FF 25 00 00 00 00 " this.mem.ExplodeHex(toAddress,1,1)
		loop % nops
			asm .= " 90"
		;this.Pause()
		prot := this.mem.unprotect(fromAddress)
		this.mem.WriteByteString(fromAddress, asm)
		this.mem.protect(fromAddress,prot)
		;this.Resume()
	}
	
	RelSwapStr(from,to) {
		return this.mem.ExplodeHex(this.mem.RelBytes(from,to))
	}
	RelSwapStr64(from,to) {
		return this.mem.ExplodeHex64(this.mem.RelBytes64(from,to))
	}

	;helper function, find a free address in our region and move the index forward x bytes
	ReserveCache(size) {
		s := this.currentCache
		this.currentCache += size
		this.currentCache += mod(this.currentCache,4) ;always be 4 byte aligned
		this.temp := this.currentCache
		return s
	}

	REL(address,ops:=1,bits:=0) {
		return "REL_" ops "_" this.mem.tohex(address,1,bits) "_" bits
	}
	REPLE(var,bits:=0) {
		return this.mem.explodehex(var,bits,1)
	}
	JUMP(address,bits:=0) {
		return "REL_1_" this.mem.tohex(address,1,bits) "_" bits
	}
}

