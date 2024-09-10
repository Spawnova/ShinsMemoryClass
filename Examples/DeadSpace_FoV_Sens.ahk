;dead space FoV and Sensitivity changer example


#include <ShinsMemoryClass>
setbatchlines,-1
RunAsAdmin()
settitlematchmode,2


if (!WinExist("ahk_exe Dead Space.exe")) {
	msgbox % "Dead space should be running already"
	exitapp
}

rightButtonDown := 0

sensAiming := 0.5
sensNormal := 0.8

minFov := 45
maxFov := 70
fov := maxFov
	
_m := new ShinsMemoryClass("ahk_exe Dead Space.exe")
if (_m.ConvertCEString()) {
	msgbox % "converted string"
}
	
FovHook := new HookHelper(_m,_m.BaseAddress+0x1003934,0x1000,_m.BaseAddress+0x1003B64) ;main hook

minFovAddress := FovHook.reserveCache(4), 	_m.writeFloat(minFovAddress,minFov)
maxFovAddress := FovHook.reserveCache(4), 	_m.writeFloat(maxFovAddress,maxFov)
fovAddress := FovHook.reserveCache(4), 		_m.writeFloat(fovAddress,maxFov)

str := "0F 10 42 60"  ;movups xmm0,[rdx+60]
str .= " 3B 05 " FovHook.REL(minFovAddress,2)  ;cmp eax,[minfov]
str .= " 0F 8C 12 00 00 00"  ;jl 13FFF0022
str .= " 3B 05 " FovHook.REL(maxFovAddress,2)  ;cmp eax,[maxfov]
str .= " 0F 8F 06 00 00 00"  ;jg 13FFF0022
str .= " 8B 05 " FovHook.REL(fovAddress,2)  ;mov eax,[fov]
str .= " 89 41 50"  ;mov [rcx+50],eax
str .= " E9 " FovHook.JUMP(_m.BaseAddress + 0x1003B6B)  ;jmp "Dead Space.exe"+1003B6B

fovFunction := FovHook.WriteASM(str)
FovHook.hook(_m.BaseAddress + 0x1003B64,fovFunction)


;updated address, old one was invalid
SensHook := new HookHelper(_m,_m.BaseAddress+0x1A711F4,0x1000,_m.BaseAddress+0x1A727F0) ;main hook

SensAddress := SensHook.reserveCache(4),	_m.writeFloat(SensAddress,sensNormal)

str := "F3 0F 10 05 " SensHook.REL(sensAddress,4)  ;movss xmm0,[sens]
str .= " F3 41 0F 5E C0"  ;divss xmm0,xmm8
str .= " E9 " SensHook.JUMP(_m.BaseAddress+0x1A727F5)  ;jmp "Dead Space.exe"+1A727F5

SensFunction := SensHook.WriteASM(str)
SensHook.hook(_m.BaseAddress + 0x1A727F0,SensFunction)




loop {
	if (rightButtonDown) {
		if (fov > minFov) {
			fov -= 1
			if (fov < minFov)
				fov := minFov
			_m.writefloat(fovAddress,fov)
		}
	} else if (fov < maxFov) {
		fov += 1
		if (fov > maxFov)
			fov := maxFov
		_m.writefloat(fovAddress,fov)
	}
	sleep 10
}
return


f9::reload


#ifwinactive,Dead Space
xbutton1::c
xbutton2::f

~rbutton::
rightButtonDown := 1
_m.writefloat(sensAddress,sensAiming)
return

~rbutton up::
rightButtonDown := 0
_m.writefloat(sensAddress,sensNormal)
return
