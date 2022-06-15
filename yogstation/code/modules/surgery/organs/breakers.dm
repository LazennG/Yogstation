
/obj/effect/proc_holder/spell/targeted/wire_snatch
	name = "Wire Snatch"
	desc = "Extend a wire from the right arm to reel in foes from a distance. Large or heavy enemies cannot be pulled in"
	invocation_type = "none"
	include_user = TRUE
	range = -1
	school = "conjuration"
	charge_max = 1
	clothes_req = FALSE
	cooldown_min = 10
	action_icon = 'icons/mob/actions/humble/actions_humble.dmi'
	action_icon_state = "bolt_action"
	var/summon_path = /obj/item/gun/magic/wire

/obj/effect/proc_holder/spell/targeted/wire_snatch/cast(list/targets, mob/user)
	for((var/obj/item/gun/magic/wire/T in user))
		qdel(T)
		to_chat(user, span_notice("The wire rewinds into your arm."))
		return
	for(var/mob/living/carbon/C in targets)
		C.drop_all_held_items()
		var/GUN = new summon_path
		C.put_in_hands(GUN)

/obj/item/gun/magic/wire/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, NOBLUDGEON)
	if(ismob(loc))
		loc.visible_message(span_warning("A long cable comes out from [loc.name]'s arm!"), span_warning("You extend the breaker's wire from your arm."))

/obj/item/gun/magic/wire
	name = "grappling wire"
	desc = "A combat-ready cable usable for closing the distance, bringing you to walls and heavy enemies you hit or bringing lighter ones to you."
	ammo_type = /obj/item/ammo_casing/magic/wire
	icon_state = "hook"
	item_state = "chain"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	fire_sound = 'sound/weapons/batonextend.ogg'
	max_charges = 1
	item_flags = NEEDS_PERMIT | DROPDEL
	force = 0

/obj/item/ammo_casing/magic/wire
	name = "hook"
	desc = "A hook."
	projectile_type = /obj/item/projectile/wire
	caliber = "hook"
	icon_state = "hook"

/obj/item/projectile/wire
	name = "hook"
	icon_state = "hook"
	icon = 'icons/obj/lavaland/artefacts.dmi'
	pass_flags = PASSTABLE
	damage = 0
	armour_penetration = 100
	damage_type = BRUTE
	range = 8
	hitsound = 'sound/effects/splat.ogg'
	knockdown = 0
	var/wire

/obj/item/projectile/wire/fire(setAngle)
	if(firer)
		wire = firer.Beam(src, icon_state = "chain", time = INFINITY, maxdistance = INFINITY)
	..()
	
/obj/item/projectile/wire/proc/zip(mob/living/user, turf/open/target)
	to_chat(user, span_warning("You pull yourself towards [target]."))
	playsound(user, 'sound/magic/tail_swing.ogg', 10, TRUE)
	user.throw_at(get_step_towards(target,user), 8, 4)

/obj/item/projectile/wire/on_hit(atom/target)
	var/mob/living/carbon/human/H = firer
	if(isobj(target))
		var/obj/item/I = target
		if(!I?.anchored)
			I.throw_at(get_step_towards(H,I), 8, 2)
			I.visible_message(span_danger("[I] is pulled by [H]'s wire!"))
			return
		zip(H, target)
	if(isliving(target))
		var/mob/L = target
		if(!L.anchored)
			if(istype(H))
				L.visible_message(span_danger("[L] is pulled by [H]'s wire!"),span_userdanger("A tentacle grabs you and pulls you towards [H]!"))
				L.throw_at(get_step_towards(H,L), 8, 4)
	if(iswallturf(target))
		var/turf/W = target
		zip(H, W)

/obj/item/gun/magic/wire/process_chamber()
	. = ..()
	if(charges == 0)
		qdel(src)

/obj/item/projectile/wire/Destroy()
	qdel(wire)
	return ..()

/obj/effect/proc_holder/spell/aoe_turf/repulse/breakaway
	name = "Break Away"
	desc = "Destroys your current breaker to negate currently active stuns and knocks back your surroundings."
	charge_max = 1 SECONDS
	clothes_req = FALSE
	range = 2
	invocation_type = "none"
	sparkle_path = /obj/effect/temp_visual/love_heart/invisible
	cooldown_min = 150
	sound = 'sound/magic/mm_hit.ogg'
	action_icon_state = "repulse"

/obj/effect/proc_holder/spell/aoe_turf/repulse/breakaway/cast(list/targets,mob/user = usr)
	var/mob/living/carbon/C = user
	for(var/obj/item/bodypart/r_arm/robot/breaker/B in C.bodyparts)
		B.dismember()
		qdel(B)
		C.visible_message(span_danger("[C]'s arm explodes, launching them back on their feet!"))
		C.uncuff() //they lose an arm but this is for bolas
		C.SetStun(0)
		C.SetKnockdown(0)
		C.SetImmobilized(0)
		C.SetParalyzed(0)
		new /obj/effect/temp_visual/explosion(get_turf(C))
	..(targets, user, 0)
