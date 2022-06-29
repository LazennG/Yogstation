
/obj/effect/proc_holder/spell/targeted/wire_snatch
	name = "Wire Snatch"
	desc = "Extend a wire from the right arm to reel in foes from a distance. Anchored targets that are hit will pull you towards them instead."
	invocation_type = "none"
	include_user = TRUE
	range = -1
	charge_max = 1
	clothes_req = FALSE
	cooldown_min = 10
	action_icon = 'icons/mob/actions/humble/actions_humble.dmi'
	action_icon_state = "bolt_action"
	var/summon_path = /obj/item/gun/magic/wire

/obj/effect/proc_holder/spell/targeted/wire_snatch/cast(list/targets, mob/user)
	for(var/obj/item/gun/magic/wire/T in user)
		qdel(T)
		to_chat(user, span_notice("The wire returns into your shoulder."))
		return
	for(var/mob/living/carbon/C in targets)
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
			H.put_in_hands(I)
			I.visible_message(span_danger("[I] is pulled by [H]'s wire!"))
			return
		zip(H, target)
	if(isliving(target))
		var/mob/L = target
		if(!L.anchored)
			if(istype(H))
				L.visible_message(span_danger("[L] is pulled by [H]'s wire!"),span_userdanger("A wire grabs you and pulls you towards [H]!"))
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
	for(var/obj/item/bodypart/r_arm/B in C.bodyparts)
		B.dismember()
		qdel(B)
		C.visible_message(span_danger("[C]'s arm explodes, launching them back on their feet!"))
		C.uncuff() //they lose an arm but this is for bolas
		C.SetStun(0)
		C.SetKnockdown(0)
		C.SetImmobilized(0)
		C.SetParalyzed(0)
		new /obj/effect/temp_visual/explosion(get_turf(C))
	. = ..()

/obj/effect/proc_holder/spell/targeted/battery
	name = "Battery"
	desc = "Let out a burst of energy from your arm, shocking those in front of you and knocking them back."
	charge_max = 10
	clothes_req = FALSE
	invocation_type = "none"
	sound = 'sound/magic/lightningshock.ogg'
	action_icon = 'icons/mob/actions/humble/actions_humble.dmi'
	action_icon_state = "shield"
	range = -1
	include_user = TRUE
	cooldown_min = 20
	var/shootie = /obj/item/projectile/battery

/obj/item/projectile/battery
	name = "arm blast"
	damage = 30
	damage_type = BURN
	range = 2
	icon_state = "plasma"

/obj/item/projectile/battery/on_hit(atom/target)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		var/atom/throw_target = get_edge_target_turf(target, get_dir(src, get_step_away(target, src)))
		L.safe_throw_at(throw_target, 2, 2, force = MOVE_FORCE_VERY_STRONG)

/obj/effect/proc_holder/spell/targeted/battery/cast(list/targets,mob/user)
	message_admins("message")
	if(..())
		return TRUE
	new /obj/effect/temp_visual/bsa_splash(user, dir)
	var/list/shooties = list()
	shooties += new shootie(get_turf(user))
	if(user.dir == SOUTH || user.dir == NORTH)
		shooties += new shootie(get_step(user, EAST))
		shooties += new shootie(get_step(user, WEST))
	else
		shooties += new shootie(get_step(user, NORTH))
		shooties += new shootie(get_step(user, SOUTH))
	for(var/S in shooties)
		var/obj/item/projectile/wing/shooted = S
		shooted.firer = user
		shooted.fire(dir2angle(user.dir))

/obj/effect/proc_holder/spell/targeted/exploder
	name = "Exploder"
	desc = "Overload the energy inside Overture to turn it into a bomb. Shove it into an enemy and it explodes after a set amount of time."
	invocation_type = "none"
	include_user = TRUE
	range = -1
	charge_max = 1
	clothes_req = FALSE
	cooldown_min = 10
	action_icon = 'icons/mob/actions/humble/actions_humble.dmi'
	action_icon_state = "bolt_action"
	var/summon_path = /obj/item/exploder

/obj/effect/proc_holder/spell/targeted/exploder/cast(list/targets, mob/user)
	for(var/obj/item/exploder/T in user)
		qdel(T)
		to_chat(user, span_notice("The energy in the arm winds down."))
		return
	for(var/mob/living/carbon/C in targets)
		var/ARM = new summon_path
		C.put_in_hands(ARM)
/obj/item/exploder/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, NOBLUDGEON)
	if(ismob(loc))
		loc.visible_message(span_warning("[loc.name]'s arm starts crackling with energy!"), span_warning("You start overloading the arm with power!"))

/obj/item/exploder
	name = "overloaded overture"
	desc = "A crackling mechanical arm that will plant itself in the next opponent it makes contact with, causing an explosion 3 seconds later. Landing a hit with this costs the user their breaker."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "bloodyknuckle"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	item_state = "knuckles"
	item_flags = DROPDEL
	force = 0

/obj/item/exploder/afterattack(mob/target, mob/user, proximity)
	. = ..()
	var/mob/living/carbon/human/H = user
	var/mob/living/L = target
	for(var/obj/item/bodypart/r_arm/B in H.bodyparts)
		if(!proximity || L == H || !ismob(L))
			return
		qdel(src)
		B.dismember()
		qdel(B)
		L.apply_status_effect(STATUS_EFFECT_BOUTTABLOW)
		L.visible_message(span_danger("[H] embeds their arm inside [L]!"))
		to_chat(L, span_userdanger("[H]'s arm embeds itself in you and starts beeping ominously!"))
		playsound(src, 'sound/weapons/armbomb.ogg', 100, 1)
		. = ..()
		return 

/obj/effect/proc_holder/spell/aimed/boostknuckle
	name = "Boost Knuckle"
	desc = "Fire your fist which will explode after hitting a wall or flying for 10 meters, knocking over anyone in the way."
	school = "evocation"
	charge_max = 60
	clothes_req = FALSE
	invocation = "ONI SOMA"
	invocation_type = "shout"
	range = 10
	cooldown_min = 20 //10 deciseconds reduction per rank
	projectile_type = /obj/item/projectile/boostknuckle
	action_icon = 'icons/mob/actions/humble/actions_humble.dmi'
	base_icon_state = "fireball"
	action_icon_state = "fireball0"
	sound = 'sound/magic/fireball.ogg'
	active_msg = "You prepare to cast your fireball spell!"
	deactive_msg = "You extinguish your fireball... for now."
	active = FALSE

/obj/item/projectile/boostknuckle
	name = "bolt of fireball"
	icon_state = "fireball"
	damage = 40
	damage_type = BRUTE
	nodamage = FALSE

/obj/item/projectile/boostknuckle/on_hit(atom/target)
	. = ..()
	var/mob/living/carbon/human/H = firer
	var/atom/throw_target = get_edge_target_turf(target, H.dir)
	if(ismob(target))
		var/mob/L = target
		L.throw_at(throw_target, 2, 4, H, 3)

/obj/item/projectile/boostknuckle/Destroy()
	explosion(src, -1, 3, 5, 1)
	qdel(src)
	return ..()


