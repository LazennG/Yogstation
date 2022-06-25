
/obj/item/bodypart/r_arm/robot/breaker
	name = "breaker"
	desc = "baseline for the wire grapple."

/obj/item/bodypart/r_arm/robot/breaker/attach_limb(mob/living/carbon/C)
	. = ..()
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/wire_snatch)
	C.AddSpell (new /obj/effect/proc_holder/spell/aoe_turf/repulse/breakaway)

/obj/item/bodypart/r_arm/robot/breaker/drop_limb(mob/living/carbon/C)
	C.RemoveSpell (new /obj/effect/proc_holder/spell/aoe_turf/repulse/breakaway)
	. = ..()

/obj/item/bodypart/r_arm/robot/breaker/overture
	name = "Breaker: Overture"
	desc = "An robotic right arm that can generate large amounts of power and output it to knock foes back."

/obj/item/bodypart/r_arm/robot/breaker/overture/attach_limb(mob/living/carbon/C)
	. = ..()
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/battery)
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/exploder)

/obj/item/bodypart/r_arm/robot/breaker/overture/drop_limb(mob/living/carbon/C)
	C.RemoveSpell (new /obj/effect/proc_holder/spell/targeted/exploder)
	C.RemoveSpell (new /obj/effect/proc_holder/spell/targeted/battery)
	. = ..()
