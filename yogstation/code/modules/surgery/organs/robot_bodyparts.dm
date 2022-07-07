
/obj/item/bodypart/r_arm/robot/breaker
	name = "breaker"
	desc = "baseline for the wire grapple."

/obj/item/bodypart/r_arm/robot/breaker/attach_limb(mob/living/carbon/C)
	. = ..()
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/wire_snatch)
	C.AddSpell (new /obj/effect/proc_holder/spell/aoe_turf/repulse/breakaway)

/obj/item/bodypart/r_arm/robot/breaker/drop_limb(mob/living/carbon/C)
	var/obj/effect/proc_holder/spell/aoe_turf/repulse/breakaway
	if(breakaway)
		C.RemoveSpell (breakaway)
	. = ..()

/obj/item/bodypart/r_arm/robot/breaker/overture
	name = "Breaker: Overture"
	desc = "An robotic right arm that can generate large amounts of power and output it to knock foes back."

/obj/item/bodypart/r_arm/robot/breaker/overture/attach_limb(mob/living/carbon/C)
	. = ..()
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/battery)
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/exploder)

/obj/item/bodypart/r_arm/robot/breaker/overture/drop_limb(mob/living/carbon/C)
	var/obj/effect/proc_holder/spell/targeted/battery
	var/obj/effect/proc_holder/spell/targeted/exploder
	if(exploder)
		C.RemoveSpell (new /obj/effect/proc_holder/spell/targeted/exploder)
	if(battery)
		C.RemoveSpell (new /obj/effect/proc_holder/spell/targeted/battery)
	. = ..()

/obj/item/bodypart/r_arm/robot/breaker/punchline
	name = "Breaker: Punch Line"
	desc = "An robotic right arm that can detach itself and fly outwards with jets to deliver heavy impacts."

/obj/item/bodypart/r_arm/robot/breaker/punchline/attach_limb(mob/living/carbon/C)
	. = ..()
	C.faction |= "cuhrazy"
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/boostknuckle)
	C.AddSpell (new /obj/effect/proc_holder/spell/aimed/jetgadget)	

/obj/item/bodypart/r_arm/robot/breaker/punchline/drop_limb(mob/living/carbon/C)
	var/obj/effect/proc_holder/spell/targeted/boostknuckle
	var/obj/effect/proc_holder/spell/aimed/jetgadget
	if(boostknuckle)
		C.RemoveSpell (new /obj/effect/proc_holder/spell/targeted/boostknuckle)
	if(jetgadget)
		C.RemoveSpell (new /obj/effect/proc_holder/spell/aimed/jetgadget)
	. = ..()
