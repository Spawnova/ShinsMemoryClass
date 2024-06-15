;example script for risk of rain 2
;this is for the version at the time of 6/15/2024, if a new update comes out it may not work anymore
;this is intended for 16:9 aspect ratio  (1920x1080 , 2560x1440  etc...)

;if using keyboard navigate the menu with arrows keys and enter to select



#NoEnv
#SingleInstance, Force
RunAsAdmin()

SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%


;replace with your own files if they are not in the documents\ahk\lib folder
#include <ShinsOverlayClass>
#include <ShinsMemoryClass>



global _m := new ShinsMemoryClass("ahk_exe Risk of Rain 2.exe")

entry := _m.ba + 0x1D28  ;a place to store the entry address

cave := new HookHelper(_m,entry,0x1000,0,0xCCCCCCCC)
if (cave.address = 0) {
	msgbox % "Problem allocating a cave!`n`nProgram will now exit"
	exitapp
}

hooked := cave.ReserveCache(20)
data := cave.reservecache(256)

overlay := new shinsoverlayclass("ahk_exe Risk of Rain 2.exe")

rect := {x:(832/2560)*overlay.width,y:(272/1440)*overlay.height,w:(896/2560)*overlay.width,h:(896/1440)*overlay.height}
iconPos := {x:(1011/2560)*overlay.width,y:(395/1440)*overlay.height,s:(8/2560)*overlay.width}
icon := {w:(101/2560)*overlay.width,h:(101/1440)*overlay.height}

rect.x2 := rect.x + rect.w
rect.y2 := rect.y + rect.h

onlyHover := 1
items := []
hasItems := 0

fullDesc := 1
colors := [0xFF999999,0xFF64b662,0xFF9c3431,0xFF000000,0xFF002db3,0xFFFF8000]
itemDefs := []


;not all items have a description, only stuff we had access to
itemDefs[12] := {r:1,name:"Repulsion Armor Plate",desc:"Reduce all incoming damage by 5 (+5 per stack). Cannot be reduced below 1."}
itemDefs[15] := {r:1,name:"Mocha",desc:"DLC"}
itemDefs[19] := {r:1,name:"Topaz Brooch",desc:"Gain a temporary barrier on kill for 15 health (+15 per stack)."}
itemDefs[21] := {r:1,name:"Tougher Times",desc:"15% (+15% per stack) chance to block incoming damage. Unaffected by luck."}
itemDefs[25] := {r:1,name:"Tri-Tip Dagger",desc:"10% (+10% per stack) chance to bleed an enemy for 240% base damage."}
itemDefs[33] := {r:1,name:"Armor-Piercing Rounds",desc:"Deal an additional 20% damage (+20% per stack) to bosses."}
itemDefs[45] := {r:1,name:"Lens-Maker's Glasses",desc:"Your attacks have a 10% (+10% per stack) chance to 'Critically Strike', dealing double damage."}
itemDefs[48] := {r:1,name:"Crowbar",desc:"Deal +75% (+75% per stack) damage to enemies above 90% health."}
itemDefs[73] := {r:1,name:"Bundle of Fireworks",desc:"UNLOCK"}
itemDefs[74] := {r:1,name:"Bison Steak",desc:"Increases maximum health by 25 (+25 per stack)."}
itemDefs[76] := {r:1,name:"Delicate Watch",desc:"DLC"}
itemDefs[82] := {r:1,name:"Roll of Pennies",desc:"DLC"}
itemDefs[88] := {r:1,name:"Cautious Slug",desc:"Increases base health regeneration by +3 hp/s (+3 hp/s per stack) while outside of combat."}
itemDefs[89] := {r:1,name:"Power Elixir",desc:"DLC"}
itemDefs[92] := {r:1,name:"Paul's Goat Hoof",desc:"Increases movement speed by 14% (+14% per stack)."}
itemDefs[95] := {r:1,name:"Gasoline",desc:"Killing an enemy ignites all enemies within 12m (+4m per stack) for 150% base damage. Additionally, enemies burn for 150% (+75% per stack) base damage."}
itemDefs[118] := {r:1,name:"Medkit",desc:"2 seconds after getting hurt, heal for 20 plus an additional 5% (+5% per stack) of maximum health."}
itemDefs[128] := {r:1,name:"Bustling Fungus",desc:"After standing still for 1 second, create a zone that heals for 4.5% (+2.25% per stack) of your health every second to all allies within 3m (+1.5m per stack)."}
itemDefs[130] := {r:1,name:"Focus Crystal",desc:"Increase damage to enemies within 13m by 20% (+20% per stack)."}
itemDefs[133] := {r:1,name:"Oddly-shaped Opal",desc:"DLC"}
itemDefs[137] := {r:1,name:"Personal Shield Generator",desc:"Gain a shield equal to 8% (+8% per stack) of your maximum health. Recharges outside of danger."}
itemDefs[157] := {r:1,name:"Backup Magazine",desc:"Add +1 (+1 per stack) charge of your Secondary skill."}
itemDefs[167] := {r:1,name:"Energy Drink",desc:"Sprint speed is improved by 25% (+25% per stack)."}
itemDefs[171] := {r:1,name:"Sticky Bomb",desc:"5% (+5% per stack) chance on hit to attach a bomb to an enemy, detonating for 180% TOTAL damage."}
itemDefs[173] := {r:1,name:"Stun Grenade",desc:"5% (+5% on stack) chance on hit to stun enemies for 2 seconds."}
itemDefs[174] := {r:1,name:"Soldier's Syringe",desc:"Increases attack speed by 15% (+15% per stack)."}
itemDefs[183] := {r:1,name:"Monster Tooth",desc:"Killing an enemy spawns a healing orb that heals for 8 plus an additional 2% (+2% per stack) of maximum health."}
itemDefs[184] := {r:1,name:"Rusted Key",desc:"A hidden cache containing an item (80%/20%) will appear in a random location on each stage. Opening the cache consumes this item."}
itemDefs[192] := {r:1,name:"Warbanner",desc:"On level up or starting the Teleporter event, drop a banner that strengthens all allies within 16m (+8m per stack). Raise attack and movement speed by 30%."}


itemDefs[16] := {r:2,name:"Predatory Instincts",desc:"25% chance to fire chain lightning for 80% TOTAL damage on up to 3 (+2 per stack) targets within 20m (+2m per stack)."}
itemDefs[18] := {r:2,name:"Bandolier",desc:"18% (+10% per stack) chance on kill to drop an ammo pack that resets all skill cooldowns."}
itemDefs[28] := {r:2,name:"Ghor's Tome",desc:"4% (+4% on stack) chance on kill to drop a treasure worth $25. Scales over time."}
itemDefs[37] := {r:2,name:"Ukulele",desc:"25% chance to fire chain lightning for 80% TOTAL damage on up to 3 (+2 per stack) targets within 20m (+2m per stack)."}
itemDefs[51] := {r:2,name:"Death Mark",desc:"Enemies with 4 or more debuffs are marked for death, increasing damage taken by 50% from all sources for 7 (+7 per stack) seconds."}
itemDefs[59] := {r:2,name:"War Horn",desc:"UNLOCK"}
itemDefs[60] := {r:2,name:"Fuel Cell",desc:"Hold an additional equipment charge (+1 per stack). Reduce equipment cooldown by 15% (+15% per stack)."}
itemDefs[62] := {r:2,name:"Old Guillotine",desc:"Instantly kill Elite monsters below 13% (+13% per stack) health."}
itemDefs[63] := {r:2,name:"Will-o'-the-wisp",desc:"On killing an enemy, spawn a lava pillar in a 12m (+2.4m per stack) radius for 350% (+280% per stack) base damage."}
itemDefs[70] := {r:2,name:"Hopoo Feather",desc:"Gain +1 (+1 per stack) maximum jump count."}
itemDefs[71] := {r:2,name:"Kjaro's Band",desc:"Hits that deal more than 400% damage also blasts enemies with a runic flame tornado, dealing 300% (+300% per stack) TOTAL damage over time. Recharges every 10 seconds."}
itemDefs[78] := {r:2,name:"Shipping Request Form",desc:"DLC"}
itemDefs[87] := {r:2,name:"Harvester's Scythe",desc:"UNLOCK"}
itemDefs[93] := {r:2,name:"Runald's Band",desc:"Hits that deal more than 400% damage also blasts enemies with a runic ice blast, slowing them by 80% for 3s (+3s per stack) and dealing 250% (+250% per stack) TOTAL damage. Recharges every 10 seconds."}
itemDefs[99] := {r:2,name:"Infusion",desc:"Killing an enemy increases your health permanently by 1 (+1 per stack), up to a maximum of 100 (+100 per stack) health."}
itemDefs[101] := {r:2,name:"Wax Quail",desc:"Jumping while sprinting boosts you forward by 10m (+10m per stack)."}
itemDefs[122] := {r:2,name:"AtG Missile Mk. 1",desc:"10% chance to fire a missile that deals 300% (+300% per stack) TOTAL damage."}
itemDefs[127] := {r:2,name:"Hunter's Harpoon",desc:"DLC"}
itemDefs[138] := {r:2,name:"Old War Stealthkit",desc:"Falling below 25% health causes you to gain 40% movement speed and invisibility for 5s. Recharges every 30 seconds (-50% per stack)."}
itemDefs[142] := {r:2,name:"Shuriken",desc:"DLC"}
itemDefs[146] := {r:2,name:"Regenerating Scrap",desc:"DLC"}
itemDefs[158] := {r:2,name:"Leeching Seed",desc:"Dealing damage heals you for 1 (+1 per stack) health."}
itemDefs[164] := {r:2,name:"Chronobauble",desc:"Slow enemies on hit for -60% movement speed for 2s (+2s per stack)."}
itemDefs[166] := {r:2,name:"Rose Buckler",desc:"Increase armor by 30 (+30 per stack) while sprinting."}
itemDefs[168] := {r:2,name:"Red Whip",desc:"Leaving combat boosts your movement speed by 30% (+30% per stack)."}
itemDefs[170] := {r:2,name:"Squid Polyp",desc:"Activating an interactable summons a Squid Turret that attacks nearby enemies at 100% (+100% per stack) attack speed. Lasts 30 seconds."}
itemDefs[172] := {r:2,name:"Ignition Tank",desc:"DLC"}
itemDefs[175] := {r:2,name:"Lepton Daisy",desc:"Release a healing nova during the Teleporter event, healing all nearby allies for 50% of their maximum health. Occurs 1 (+1 per stack) times."}
itemDefs[180] := {r:2,name:"Razorwire",desc:"Getting hit causes you to explode in a burst of razors, dealing 160% damage. Hits up to 5 (+2 per stack) targets in a 25m (+10m per stack) radius"}
itemDefs[191] := {r:2,name:"Berzerker's Pauldron",desc:"UNLOCK"}

itemDefs[11] := {r:3,name:"Alien Head",desc:"Reduce skill cooldowns by 25% (+25% per stack)."}
itemDefs[13] := {r:3,name:"Shattering Justice",desc:"After hitting an enemy 5 times, reduce their armor by 60 for 8 (+8 per stack) seconds."}
itemDefs[20] := {r:3,name:"Aegis",desc:"Healing past full grants you a temporary barrier for 50% (+50% per stack) of the amount you healed."}
itemDefs[24] := {r:3,name:"Brilliant Behemoth",desc:"Find this item in the world to unlock this log entry."}
itemDefs[34] := {r:3,name:"Sentient Meat Hook",desc:"Find this item in the world to unlock this log entry."}
itemDefs[39] := {r:3,name:"57 Leaf Clover",desc:"Complete 20 stages in a single run."}
itemDefs[44] := {r:3,name:"Laser Scope",desc:"DLC"}
itemDefs[50] := {r:3,name:"Ceremonial Dagger",desc:"Killing an enemy fires out 3 homing daggers that deal 150% (+150% per stack) base damage."}
itemDefs[53] := {r:3,name:"Spare Drone Parts",desc:"DLC"}
itemDefs[65] := {r:3,name:"Dio's Best Friend",desc:"Upon death, this item will be consumed and you will return to life with 3 seconds of invulnerability."}
itemDefs[69] := {r:3,name:"H3AD-5T v2",desc:"Find this item in the world to unlock this log entry."}
itemDefs[80] := {r:3,name:"Happiest Mask",desc:"Find this item in the world to unlock this log entry."}
itemDefs[86] := {r:3,name:"Wake of Vultures",desc:"Gain the power of any killed elite monster for 8s (+5s per stack)."}
itemDefs[94] := {r:3,name:"Frost Relic",desc:"Find this item in the world to unlock this log entry."}
itemDefs[96] := {r:3,name:"Ben's Raincoat",desc:"DLC"}
itemDefs[97] := {r:3,name:"Rejuvenation Rack",desc:"Heal +100% (+100% per stack) more."}
itemDefs[102] := {r:3,name:"Brainstalks",desc:"Find this item in the world to unlock this log entry."}
itemDefs[104] := {r:3,name:"Resonance Disc",desc:"Killing 4 enemies in 7 seconds charges the Resonance Disc. The disc launches itself toward a target for 300% base damage (+300% per stack), piercing all enemies it doesn't kill, and then explodes for 1000% base damage (+1000% per stack). Returns to the user, striking all enemies along the way for 300% base damage (+300% per stack)."}
itemDefs[126] := {r:3,name:"Pocket I.C.B.M.",desc:"DLC"}
itemDefs[131] := {r:3,name:"N'kuhana's Opinion",desc:"Find this item in the world to unlock this log entry."}
itemDefs[136] := {r:3,name:"Symbiotic Scorpion",desc:"DLC"}
itemDefs[139] := {r:3,name:"Interstellar Desk Plant",desc:"On kill, plant a healing fruit seed that grows into a plant after 5 seconds. The plant heals for 5% of maximum health every 0.5 second to all allies within 10m (+5.0m per stack). Lasts 10 seconds."}
itemDefs[144] := {r:3,name:"Bottled Chaos",desc:"DLC"}
itemDefs[161] := {r:3,name:"Unstable Tesla Coil",desc:"Fire out lightning that hits 3 (+2 per stack) enemies for 200% base damage every 0.5s. The Tesla Coil switches off every 10 seconds."}
itemDefs[176] := {r:3,name:"Soulbound Catalyst",desc:"Discover and activate 8 unique Newt Altars."}
itemDefs[187] := {r:3,name:"Hardlight Afterburner",desc:"Add +2 (+2 per stack) charges of your Utility skill. Reduces Utility skill cooldown by 33%."}


itemDefs[193] := {r:6,name:"Preon Accumulator",desc:"Loot item in world to unlock."}
itemDefs[194] := {r:6,name:"Primordial Cube",desc:"Fire a black hole that draws enemies within 30m into its center. Lasts 10 seconds"}
itemDefs[195] := {r:6,name:"Trophy Hunter's Tricorn",desc:"DLC"}
itemDefs[198] := {r:6,name:"Blast Shower",desc:"Cleanse all negative effects. Includes debuffs, damage over time, and nearby projectiles."}
itemDefs[199] := {r:6,name:"Disposable Missile Launcher",desc:"Fire a swarm of 12 missiles that deal 12x300% damage."}
itemDefs[201] := {r:6,name:"Ocular HUD",desc:"Gain +100% Critical Strike Chance for 8 seconds."}
itemDefs[202] := {r:6,name:"Forgive Me Please",desc:"Throw a cursed doll out that triggers any On-Kill effects you have every 1 second for 8 seconds."}
itemDefs[203] := {r:6,name:"The Back-up",desc:"Call 4 Strike Drones to fight for you. Lasts 25 seconds."}
itemDefs[216] := {r:6,name:"Volcanic Egg",desc:"Turn into a draconic fireball for 5 seconds. Deal 500% damage on impact. Detonates at the end for 800% damage."}
itemDefs[217] := {r:6,name:"Foreign Fruit",desc:"Instantly heal for 50% of your maximum health."}
itemDefs[218] := {r:6,name:"Jade Elephant",desc:"Gain 500 armor for 5 seconds."}
itemDefs[219] := {r:6,name:"Eccentric Vase",desc:"Loot item in world to unlock."}
itemDefs[221] := {r:6,name:"The Crowdfunder",desc:"Fires a continuous barrage that deals 100% damage per bullet. Costs $1 per bullet. Cost increases over time."}
itemDefs[222] := {r:6,name:"Goobo Jr.",desc:"DLC"}
itemDefs[224] := {r:6,name:"Milky Chrysalis",desc:"Sprout wings and fly for 15 seconds. Gain +20% movement speed for the duration."}
itemDefs[225] := {r:6,name:"Super Massive Leech",desc:"Heal for 20% of the damage you deal. Lasts 8 seconds."}
itemDefs[226] := {r:6,name:"Royal Capacitor",desc:"Call down a lightning strike on a targeted monster, dealing 3000% damage and stunning nearby monsters."}
itemDefs[230] := {r:6,name:"Molotov (6-Pack)",desc:"DLC"}
itemDefs[231] := {r:6,name:"Executive Card",desc:"DLC"}
itemDefs[234] := {r:6,name:"Gnarled Woodsprite",desc:"Gain a Woodsprite follower that heals for 1.5% of your maximum health/second. Can be sent to an ally to heal them for 10% of their maximum health."}
itemDefs[236] := {r:6,name:"Recycler",desc:"Transform an Item or Equipment into a different one. Can only be converted into the same tier one time."}
itemDefs[237] := {r:6,name:"Sawmerang",desc:"Throw three large saw blades that slice through enemies for 3x400% damage. Also deals an additional 3x100% damage per second while bleeding enemies. Can strike enemies again on the way back."}
itemDefs[238] := {r:6,name:"Radar Scanner",desc:"Reveal all interactables within 500m for 10 seconds."}
itemDefs[241] := {r:6,name:"Gorag's Opus",desc:"All allies enter a frenzy for 7 seconds. Increases movement speed by 50% and attack speed by 100%."}
itemDefs[243] := {r:6,name:"Remote Caffeinator",desc:"DLC"}


itemDefs[17] := {r:5,name:"Gesture of the Drowned",desc:"Reduce Equipment cooldown by 50% (+15% per stack). Forces your Equipment to activate whenever it is off cooldown.",cond:"Kill 20 Hermit Crabs by chasing them off the edge of the map."}
itemDefs[75] := {r:5,name:"Focused Convergence",desc:"Teleporters charge 30% (+30% per stack) faster, but the size of the Teleporter zone is 50% (-50% per stack) smaller.",cond:"Find this item in the world to unlock this log entry."}
itemDefs[81] := {r:5,name:"Brittle Crown",desc:"30% chance on hit to gain 2 (+2 per stack) gold. Scales over time.`nLose gold on taking damage equal to 100% (+100% per stack) of the maximum health percentage you lost.",cond:"Find this item in the world to unlock this log entry."}
itemDefs[84] := {r:5,name:"Light Flux Pauldron",desc:"DLC"}
itemDefs[85] := {r:5,name:"Stone Flux Pauldron",desc:"DLC"}
itemDefs[108] := {r:5,name:"Purity",desc:"All skill cooldowns are reduced by 2 (+1 per stack) seconds. All random effects are rolled +1 (+1 per stack) times for an unfavorable outcome.",cond:"Escape the moon on Monsoon difficulty."}
itemDefs[109] := {r:5,name:"Shaped Glass",desc:"Increase base damage by 100% (+100% per stack). Reduce maximum health by 50% (+50% per stack).",cond:"Find this item in the world to unlock this log entry."}
itemDefs[110] := {r:5,name:"Visions of Heresy",desc:"Replace your Primary Skill with Hungering Gaze.`nFire a flurry of tracking shards that detonate after a delay, dealing 120% base damage. Hold up to 12 charges (+12 per stack) that reload after 2 seconds (+2 per stack)."}
itemDefs[111] := {r:5,name:"Hooks of Heresy",desc:"Replace your Secondary Skill with Slicing Maelstrom.`nCharge up a projectile that deals 875% damage per second to nearby enemies, exploding after 3 seconds to deal 700% damage and root enemies for 3 (+3 per stack) seconds. Recharges after 5 (+5 per stack) seconds.",cond:"Find this item in the world to unlock this log entry."}
itemDefs[112] := {r:5,name:"Essence of Heresy",desc:"Replace your Special Skill with Ruin.`nDealing damage adds a stack of Ruin for 10 (+10 per stack) seconds. Activating the skill detonates all Ruin stacks at unlimited range, dealing 300% damage plus 120% damage per stack of Ruin. Recharges after 8 (+8 per stack) seconds.",cond:"Find this item in the world to unlock this log entry."}
itemDefs[113] := {r:5,name:"Egocentrism",desc:"DLC"}
itemDefs[114] := {r:5,name:"Beads of Fealty",desc:"Celestial portal to another location"}
itemDefs[115] := {r:5,name:"Strides of Heresy",desc:"Replace your Utility Skill with Shadowfade.`nFade away, becoming intangible and gaining +30% movement speed. Heal for 18.2% (+18.2% per stack) of your maximum health. Lasts 3 (+3 per stack) seconds.",cond:"Find this item in the world to unlock this log entry."}
itemDefs[125] := {r:5,name:"Defiant Gouge",desc:"Using a Shrine summons enemies (stronger per stack) nearby. Scales over time.",cond:"Find this item in the world to unlock this log entry."}
itemDefs[143] := {r:5,name:"Mercurial Rachis",desc:"Creates a Ward of Power in a random location nearby that buffs both enemies and allies within 16m (+50% per stack), causing them to deal +50% damage."}
itemDefs[145] := {r:5,name:"Eulogy Zero",desc:"DLC"}
itemDefs[148] := {r:5,name:"Corpsebloom",desc:"Heal +100% (+100% per stack) more. All healing is applied over time. Can heal for a maximum of 10% (-50% per stack) of your health per second."}
itemDefs[159] := {r:5,name:"Transcendence",desc:"Convert all but 1 health into regenerating shields. Gain 50% (+25% per stack) maximum health."}


mmenu := new _modmenu("RoR2 - Menu",overlay,_m)
mmenu.RegisterEntry("test1","Item Hover Overlay",Func("MainPatch"))
mmenu.RegisterEntry("test2","Inf Money",Func("MoneyPatch"))

if (_m.readchar(hooked)) {
	mmenu.entries["test1"].text := "Main patch applied"
	mmenu.entries["test1"].color := mmenu.colors.good
}
if (_m.readchar(hooked+2)) {
	mmenu.entries["test2"].color := mmenu.colors.good
}

_m.writeint(data,0x1337)

loop {
	if (overlay.begindraw()) {

		mmenu.update()


			if (_m.readint(data) != 0x1337) {
				if (!hasItems) {
					items := []
					hasItems := 1
				}
				overlay.drawrectangle(rect.x,rect.y,rect.w,rect.h,0xFFFF0000,5)

				count := _m.readuint(data+0x20)
				
				;str := "Count: " count "`n`n"
				i := 0x28
				loop % count {
					key := _m.readuint(data+i)
					if (!items.haskey(key)) {
						items[key] := {u:_m.readuint(data+i+4),set:0}
					}
					;str .= "U: " _m.readuint(data+i+4) " - ID: " _m.readuint(data+i) "`n"
					i+=8
				}
				;overlay.drawtext("picker open`n" str,150,50,30)

				overlay.GetMousePos(mx,my)

				x := iconPos.x
				y := iconPos.y
				i := 1
				th := icon.h * 1 ;0.3
				for k,v in items {
					if (!v.set) {
						ss := iconpos.s / 2
						v.x := x - ss
						v.y := y - ss
						v.x2 := x + icon.w + ss
						v.y2 := y + icon.h + ss
						v.set := 1
					}

				
					overlay.drawrectangle(v.x,v.y,v.x2-v.x,v.y2-v.y,0xFF7AA9B7)

					if (v.u != 99 and (!onlyHover or (mx >= v.x and my >= v.y and mx <= v.x2 and my <= v.y2) or itemdefs[k].desc = "DLC")) {
						if (ItemDefs[k].desc = "DLC") {
							overlay.drawtext("DLC",x,y+icon.h/3,round((40/1440)*overlay.height),0x77FF97CF,"Comic Sans","bold acenter w" icon.w " olFF000000")
						} else if (fullDesc) {
							iw := icon.w * 7
							ih := icon.h * 1.5
							ix := mx
							iy := my-ih
							overlay.fillrectangle(ix,iy,iw,ih,0xCC271F1F)
							overlay.fillrectangle(ix,iy,iw,ih*0.3,colors[itemDefs[k].r])
							overlay.drawtext(itemDefs[k].name, ix+2,iy-6,round((34/1440)*overlay.height),0xFFFFFFFF,"Aptos","bold olFF000000")
							overlay.drawtext(itemDefs[k].desc, ix+2,iy + ih * 0.33,round((20/1440)*overlay.height),0xFFFFFFFF,"Arial","w" iw " olFF000000")
							overlay.drawrectangle(ix,iy,iw,ih,0xFF7AA9B7)
						} else {
							overlay.fillrectangle(x,y,icon.w,th,0x88271F1F)
							overlay.drawtext(v.i ": " v.u,x,y,20,0xFFFFFFFF,"Arial","acenter w" icon.w " olFF000000")
							overlay.drawrectangle(x,y,icon.w,th,0xFFACABAB)
						}
					}

					i++
					if (i > 5) {
						i := 1
						x := iconpos.x
						y += icon.h + iconpos.s
					} else {
						x += icon.w + iconpos.s
					}
						
					
				}

			} else if (hasItems) {
				items := []
				hasItems := 0
			}
		
		overlay.enddraw()
	}
}

MainPatch(o,d) {
	global hooked
	if (_m.readchar(hooked))
		return
	e := o.entries[o.order[o.index]]
	if (d = 1) {
		e.note := "Patching..."
		e.color := o.colors.middle
		settimer,MainPatch2,-1
	}
}
MainPatch2:
if (_m.readchar(hooked) != 1) {
	panelKill := _m.AoB("41 FF D3 48 8B 55 E8 48 8B 46 50 48 8B C8 83 38 00 48 8D 64 24 00 49 BB")
	itemUpdate := _m.AoB("0F 8C 18 00 00 00 48 C7 85 D0 FD FF FF 00 00 00 00 48 C7 85 E0 FD FF FF 00 00 00 00 EB 29 48 63 85 D8 FD FF FF 48 63 C8 48 8B 85 E0 FD FF FF")

	if (panelKill < 0x1000 or itemUpdate < 0x1000) {
		mmenu.entries["test1"].color := mmenu.colors.bad
		mmenu.entries["test1"].note := "AoB error"
		return
	} else {
		panelKill -= 0x40
		itemUpdate := (itemUpdate - 0x7F9) + 0xB5
	}

	str := "56"  ;push rsi
	str .= " 57"  ;push rdi
	str .= " 51"  ;push rcx
	str .= " 50"  ;push rax
	str .= " 48 8B F5"  ;mov rsi,rbp
	str .= " 48 81 EE 48 02 00 00"  ;sub rsi,00000248
	str .= " 48 8B 36"  ;mov rsi,[rsi]
	str .= " 48 B8 REPLE64"  ;mov rax,000000C920D10000
	str .= " 48 89 30"  ;mov [rax],rsi
	str .= " 48 8D 78 08"  ;lea rdi,[rax+08]
	str .= " 48 8B 4E 18"  ;mov rcx,[rsi+18]
	str .= " 48 83 C1 10"  ;add rcx,10
	str .= " F3 48 A5"  ;repe movsq
	str .= " 58"  ;pop rax
	str .= " 59"  ;pop rcx
	str .= " 5F"  ;pop rdi
	str .= " 5E"  ;pop rsi
	str .= " 48 8B 8D B8 FD FF FF"  ;mov rcx,[rbp-00000248]
	str .= " 48 63 51 18"  ;movsxd  rdx,dword ptr [rcx+18]
	str .= " 48 8B C8"  ;mov rcx,rax
	str .= " FF 25 00 00 00 00 REPLE64"  ;jmp 2321D93B210

	_f := cave.Writeasm(str,data,itemUpdate+0xE)
	cave.hook64(itemUpdate,_f)

	str := "48 89 75 F8"  ;mov [rbp-08],rsi
	str .= " 48 8B F1"  ;mov rsi,rcx
	str .= " 48 B8 REPLE64"  ;mov rax,00000CD28A928374
	str .= " C7 00 37 13 00 00"  ;mov [rax],00001337
	str .= " 48 8B 46 50"  ;mov rax,[rsi+50]
	str .= " 48 8B C8"  ;mov rcx,rax
	str .= " FF 25 00 00 00 00 REPLE64"  ;jmp 2321D93CE16
	_f := cave.Writeasm(str,data,panelKill+0xE)
	cave.hook64(panelKill,_f)
	_m.writeint(data,0x1337)

	_m.writechar(hooked,1)
	_m.writechar(hooked+1,1)
}
mmenu.entries["test1"].color := mmenu.colors.good
mmenu.entries["test1"].note := tohex(cave.pmem)
return

joy9::
f1::
mmenu.visible := !mmenu.visible
return

MoneyPatch(o,d) {
	global hooked
	if (_m.readchar(hooked+2))
		return
	e := o.entries[o.order[o.index]]
	if (d = 1) {
		e.note := "Patching..."
		e.color := 0xFFFF0000
		settimer,MoneyPatch2,-1
	}
}
MoneyPatch2:
if (setGold := _m.Aob("8B 87 B4 00 00 00 3B F0 74 0F 8B 47 20 83 C8 02 89 47 20 89 B7 B4 00 00 00")) {

	SetGold += 0xA

	str := "8B 47 20"  ;mov eax,[rdi+20]
	str .= " 83 C8 02"  ;or eax,02
	str .= " 89 47 20"  ;mov [rdi+20],eax
	str .= " C7 87 B4 00 00 00 0F 27 00 00"  ;mov [rdi+000000B4],0000270F
	str .= " FF 25 00 00 00 00 REPLE64"  ;jmp 15BCDFA5C5C
	_f := cave.Writeasm(str,setGold+0xF)
	cave.hook64(setGold,_f,0,1)

	mmenu.entries["test2"].note := ""
	mmenu.entries["test2"].color := mmenu.colors.good
	_m.writechar(hooked+2,1)
} else {
	mmenu.entries["test2"].note := "AoB_Error"
	mmenu.entries["test2"].color := mmenu.colors.bad
}
return

f8::exitapp
f9::reload






;very simple menu class
class _modmenu {
	__New(text,overlay,mem) {
		this._m := mem
		this.overlay := overlay
		this.entries := []
		this.order := []
		this.fontSize := 20
		this.font := "Arial"
		this.colorIndex := 0
		this.visible := 0
		this.text := text
		this.index := 1
		this.x := 50
		this.y := 50
		this.lastInput := 0
		this.colorAlp := 127
		this.colorDir := 0.1
		this.lastjoy := -1
		this.colors := {good:0xFF00FF00,bad:0xFFFF0000,middle:0xFFFF5151}

	}
	RegisterEntry(key,text,func) {
		this.entries[key] := {text:text,func:func,color:0xFFFFFF00,note:""}
		this.order.push(key)
	}

	Update() {
		if (!this.visible) {
			this.overlay.drawtext("Left Thumbstick / F1 - Menu",5,5,16)
			return
		}
		if (a_tickcount > this.lastInput) {
			pov := GetKeyState("JoyPOV")
			if (pov = -1) {
				pov := (GetKeyState("left") ? 27000 : GetKeyState("Right") ? 9000 : GetKeyState("Up") ? 0 : GetKeyState("Down") ? 18000 : -1)
			}
			abb := (GetKeyState("Joy1") or GetKeyState("Enter"))
			if (abb)
				pov := 7
		
			if (pov != this.lastJoy) {
				Switch POV {
					Case -1:
					Case 7: this.entries[this.order[this.index]].func.call(this,1), this.lastInput := a_tickcount + 50
					Case 0: this.index := max(1,this.index-1), this.lastInput := a_tickcount + 50
					Case 27000: this.entries[this.order[this.index]].func.call(this,2), this.lastInput := a_tickcount + 50
					case 9000: this.entries[this.order[this.index]].func.call(this,3), this.lastInput := a_tickcount + 50
					case 18000: this.index := min(this.entries.count(),this.index+1), this.lastInput := a_tickcount + 50
				}
				this.lastJoy := pov
			}
		}

		this.overlay.drawtext(this.text,this.x,this.y,30,0xFFFFFFFF,"Arial","bold")
		yoff := 50
		for k,v in this.order {
			o := this.entries[v]
			c := o.color
			
			if (this.index = k) {
				this.colorAlp += this.colorDir
				rrc := round(this.colorAlp)
				if (rrc = 0xFE or rrc = 0x60) {
					this.colorDir *= -1
				}
				this.overlay.drawtext(" > " o.text (o.note != "" ? " - " o.note : ""),this.x,this.y+yoff,this.fontSize,c,this.font,(this.index = k ? "bold" :""))
				this.overlay.drawtext(" > " o.text (o.note != "" ? " - " o.note : ""),this.x,this.y+yoff,this.fontSize,(rrc<<24) + 0xFFFFFF,this.font,(this.index = k ? "bold" :""))
			} else {
				this.overlay.drawtext(o.text (o.note != "" ? " - " o.note : ""),this.x,this.y+yoff,this.fontSize,c,this.font,(this.index = k ? "bold" :""))
			}
			yoff+=30
		}
	}
}
