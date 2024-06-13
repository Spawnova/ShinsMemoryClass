;youtube video regarding this example - 


;infinite ammo and time scale editing for the game Prey (2017)
;this was based on the GoG version

#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%


;if memory class is in your ahk library folder
#include <ShinsMemoryClass>
#include <ShinsOverlayClass>

;if the class is somewhere else, point to it
;#include Resources\ShinsMemoryClass.ahk

overlay := new ShinsOverlayClass("ahk_exe prey.exe")
_m := new ShinsMemoryClass("Prey",,"res")

PreyDLL := _m.GetModuleBaseAddress("PreyDll.dll")

infAmmoState := 0

;create a new region or get a pointer to an existing one
logTimeScale := new HookHelper(_m, _m.BaseAddress+0x1E04,,PreyDLL+0xDDf3F4)

speedPtr := logTimeScale.ReserveCache(8) ;gives this variable an address within the process, we can now write and read it

;convert and write the asm string to our new region
str := "50"  ;push rax
str .= " 48 8D 87 52 FE FF FF"  ;lea rax,[rdi-000001AE]
str .= " 48 A3 REPLE64"  ;mov [speed],rax
str .= " 58"  ;pop rax
str .= " F3 0F 59 9F 52 FE FF FF"  ;mulss xmm3,[rdi-000001AE]
str .= " E9 JUMP"  ;jmp PreyDll.dll+DDF3FC
logHookAddress := logTimeScale.WriteASM(str, speedPtr, PreyDLL+0xDDF3FC) ;write the asm to our code region, and return the start of the hook address
logTimeScale.hook(PreyDLL+0xDDF3F4,logHookAddress,0,3) ;hook the existing function to jump to our new code, then jump back


loop {

	if (overlay.Begindraw()) {

		
		overlay.DrawText("alt+F1:: Infinite ammo is " (infAmmoState ? "ON" : "OFF"), 10, 10, 32)

		overlay.DrawText("alt+F2:: Set Timescale = " _m.ReadFloat(speedPtr,0x0), 10, 40, 32)
		

		overlay.enddraw()
	}

}

return

!f1::
infAmmoState := !infAmmoState
if (infAmmoState) {
	_m.Nop(PreyDLL+0x10B91FD,3)
	_m.Nop(PreyDLL+0x162959A,6)
} else {
	_m.WriteByteString(PreyDLL+0x10B91FD,"89 7B 54")
	_m.WriteByteString(PreyDLL+0x162959A,"89 91 84040000")
}
return



!f2::
if (!speedPtr)
	return
inputbox,newSpeed,Enter New Speed,Enter New Speed
if (newSpeed > 0.001 and newSpeed < 10) {
	_m.WriteFloat(speedPtr,newSpeed,0x0)
}
return



f8::exitapp
f9::reload
