/obj/item/kinetic_blade/proc/shock(mob/living/user, mob/living/target, damage = 15)
	var/obj/item/bodypart/limb_to_hit = target.get_bodypart(user.zone_selected)
	var/armor = target.run_armor_check(limb_to_hit, MELEE, armour_penetration = 0)
	target.apply_damage(damage, BURN, limb_to_hit, armor, wound_bonus=CANT_WOUND)

/obj/item/kinetic_blade
	icon = 'icons/obj/mining.dmi'
	icon_state = "shovel"
	name = "proto-kinetic crusher"
	desc = "A sword."
	force = 0 
	w_class = WEIGHT_CLASS_BULKY
	obj_flags = UNIQUE_RENAME | UNIQUE_REDESC
	slot_flags = ITEM_SLOT_BACK
	throwforce = 5
	throw_speed = 4
	light_range = 5
	light_power = 1
	light_system = MOVABLE_LIGHT
	armour_penetration = 10
	materials = list(/datum/material/iron=1150, /datum/material/glass=2075)
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("sliced", "cut", "cleaved", "slashed")
	sharpness = SHARP_EDGED
	resistance_flags = LAVA_PROOF | FIRE_PROOF
	var/heavyattack = FALSE
	var/charge = 0
	var/chargedup = FALSE

/obj/item/kinetic_blade/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 60, 110)

/obj/item/kinetic_blade/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(isliving(target))
		var/mob/living/T = target
		if(T.stat != DEAD && (charge < 100))
			charge = (charge + 15)
			if(charge > 100)
				charge = 100
		if(chargedup)
			addtimer(CALLBACK(src, PROC_REF(zap), user, T), 1.5 SECONDS)

/obj/item/kinetic_blade/proc/zap(mob/user, mob/target, second = FALSE)
	shock(user, target)
	//lightning or electric visual here, maybe buzz sound too
	if(second)
		return
	addtimer(CALLBACK(src, PROC_REF(zap), target, TRUE), 0.5 SECONDS)



/obj/item/kinetic_shield
	icon = 'icons/obj/mining.dmi'
	icon_state = "bone_3"
	name = "kinetic shield"
	desc = "A shield."
	force = 8
	w_class = WEIGHT_CLASS_BULKY
	obj_flags = UNIQUE_RENAME | UNIQUE_REDESC
	slot_flags = ITEM_SLOT_BACK
	throwforce = 5
	throw_speed = 4
	light_range = 5
	light_power = 1
	light_system = MOVABLE_LIGHT
	materials = list(/datum/material/iron=1150, /datum/material/glass=2075)
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("bashed", "crushed", "pulped")
	resistance_flags = LAVA_PROOF | FIRE_PROOF
	var/obj/item/kinetic_blade/sword = null

/obj/item/kinetic_shield/attackby(obj/item/I, mob/living/user)
	if(istype(I, /obj/item/kinetic_blade))
		sword = I
		I.forceMove(src) //update sprite after when you have it 
	return ..()

/obj/item/kinetic_shield/attack_self(mob/user)
	. = ..()
	if(sword)
		user.put_in_hands(sword)
		sword = null
	return


	//hunker down status effect, 2 second standstill for 60% damage reduction? why would people wanna stand still instead of running? think about it mayhaps \
	especially when you were originally making it deal a bit of stamina damage per blocked attack or something like what could be the tradeoff? the charged shield\
	damage probably isnt gonna be enough to warrant it. maybe it should be higher or just total? not excluding the stamina damage tho 

	//should emptying the phials be a shield action or a sword action? maybe a sword action while the shield is in hand?
