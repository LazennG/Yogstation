
/obj/item/bodypart/r_arm/robot/breaker
	name = "breaker"
	desc = "baseline for the wire grapple."

/obj/item/bodypart/r_arm/robot/breaker/attach_limb(mob/living/carbon/C, special)
	. = ..()
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/wire_snatch)
	C.AddSpell (new /obj/effect/proc_holder/spell/aoe_turf/repulse/breakaway)

/obj/item/bodypart/r_arm/robot/breaker/drop_limb(mob/living/carbon/C, special)
	C.RemoveSpell (new /obj/effect/proc_holder/spell/targeted/wire_snatch)
	C.RemoveSpell (new /obj/effect/proc_holder/spell/aoe_turf/repulse/breakaway)
	. = ..()
