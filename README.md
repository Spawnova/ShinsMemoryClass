# ShinsMemoryClass
An Autohotkey class for reading, writing and interacting with memory
Featuring custom built DLLs specifically to integrate with AutoHotkey for maximum speed (or atleast as fast as I was able to code them lol)



# YouTube overview and examples
[![Video](https://img.youtube.com/vi/7OUDVem7AcA/default.jpg)](https://www.youtube.com/watch?v=7OUDVem7AcA)

## Functions
```ruby
AoB(byteStr,multiThread:=1)  ..............................  #Performs an Array of Byte scan on the entire process returning an address if the AoB was found

ReadPtr(address,offsets*)  ...............................  #Reads an address as the ptr type of the process, 64 bit process returns 64 bit, 32 bit returns UInt
WritePtr(address,value,offsets*)  ........................  #Writes a ptr type

ReadUInt64(address,offsets*)  ............................  #Reads an unsigned 64 bit value at a specified address
ReadInt64(address,offsets*)  .............................  #Reads a signed 64 bit value at a specified address
WriteInt64(address,value,offsets*)  ......................  #Writes a 64 bit value at a specified address
WriteUInt64(address,value,offsets*)  .....................  #Writes a 64 bit value at a specified address
ReadFloat(address,offsets*)  .............................  #Reads a float value at a specified address
WriteFloat(address,value,offsets*)  ......................  #Writes a float value at a specified address
ReadDouble(address,offsets*)  ............................  #Reads a double value at a specified address
WriteDouble(address,value,offsets*)  .....................  #Writes a double value at a specified address
ReadUInt(address,offsets*)  ..............................  #Reads an unsigned 32 bit value at a specified address
ReadInt(address,offsets*)  ...............................  #Reads a 32 bit value at a specified address
WriteUInt(address,value,offsets*)  .......................  #Writes a 32 bit value at a specified address
WriteInt(address,value,offsets*)  ........................  #Writes a 32 bit value at a specified address
ReadUShort(address,offsets*)  ............................  #Reads an unsigned 16 bit value at a specified address
ReadShort(address,offsets*)  .............................  #Reads a 16 bit value at a specified address
WriteUShort(address,value,offsets*)  .....................  #Writes a 16 bit value at a specified address
WriteShort(address,value,offsets*)  ......................  #Writes a 16 bit value at a specified address
ReadUChar(address,offsets*)  .............................  #Reads an unsigned 8 bit value at a specified address
ReadChar(address,offsets*)  ..............................  #Reads an 8 bit value at a specified address
WriteUChar(address,value,offsets*)  ......................  #Writes an 8 bit value at a specified address
WriteChar(address,value,offsets*)  .......................  #Writes an 8 bit value at a specified address

ReadRaw(address,byref buffer, bytes, offsets*)  ..........  #Reads X amount of bytes into a buffer
WriteRaw(address, byref buffer, bytes, offsets*)  ........  #Writes X amount of bytes at an address

ReadString(address,len:=0,unicode:=0, offsets*)  .........  #Read a string at an address
WriteString(address,str,unicode:=0, offsets*)  ...........  #Write a string to an address WITHOUT a null terminator
WriteStringNT(address,str,unicode:=0, offsets*)  .........  #Write a string to an address WITH a null terminator

Read(address, type := "UInt", offsets*)  .................  #Read a value from an address, the type can be specified as the second param
Write(address, value, type:="UInt", offsets*)  ...........  #Write a value to an address, the type can be specified as the second param

WriteByteString(address, bytes)  .........................  #Converts a string of hex bytes into a buffer of bytes and writes to an address

GetPointer(address,offsets*)  ............................  #Convert an address plus an array of offsets into a pointer

GetModuleBaseAddress(moduleStr)  .........................  #Get the base address of a specified module

Nop(address,bytes)  ......................................  #Nop x amount of bytes at a specified address

FindFreeMemory(bytes:=0x1000)  .........................................  #Find a free memory region, anywhere in the process
FindFreeMemoryClosest(address,bytes:=0x1000,maxDist:=0x7FFFFFF0)  ......  #Find a free memory region closest to a specified address, within x dist
FindFreeMemoryNearby(address,bytes:=0x1000,maxDist:=0x7FFFFFF0)  .......  #Find a memory region nearby a specified address, within X dist
Alloc(bytes:=0x1000, address:=0, access:="rwe", topDown:=0)  ...........  #Allocs a specified region for x amount of bytes, if no address is supplied with find a random region
Free(address)  .........................................................  #Frees a region previously committed

writeProt(address, value, type := "Uint", offsets*)  ...................  #Performs a single write at a specified address, before writing alters protection for write access, after writing restores old protect
Unprotect(address,sz:=4)  ..............................................  #Sets the protection of a specified region to read+write+execute and returns the old protect
Protect(address,prot,sz:=4)  ...........................................  #Sets the protection of a specified region to a specified value

Suspend()  .............................................................  #Suspends the process (pauses it)
Resume()  ..............................................................  #Resumes the process
```

## Notes

* **V2 not currently supported.**
*
* I've only tested on my end and can confirm it works for me using 32/64 bit AHK_L (AHK V1.1) on Windows 10.
* If it doesn't work for you let me know, I may be able to help, or maybe not, just depends.

### Donations

Thanks for stopping by! If you really enjoy my code and want to make a <ins>small</ins> donation, then here's a link! https://www.buymeacoffee.com/Spawnova
