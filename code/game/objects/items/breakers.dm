
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
		B.drop_limb()
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
	var/spark = /obj/item/projectile/battery

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
	if(..())
		return TRUE
	var/list/sparks = list()
	sparks += new spark(get_turf(user))
	if(user.dir == SOUTH || user.dir == NORTH)
		sparks += new spark(get_step(user, EAST))
		sparks += new spark(get_step(user, WEST))
	else
		sparks += new spark(get_step(user, NORTH))
		sparks += new spark(get_step(user, SOUTH))
	for(var/S in sparks)
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
	var/atom/throw_target = get_edge_target_turf(L, H.dir)
	for(var/obj/item/bodypart/r_arm/B in H.bodyparts)
		if(!proximity || L == H || !ismob(L))
			return
		B.drop_limb()
		qdel(B)
		L.apply_status_effect(STATUS_EFFECT_BOUTTABLOW)
		L.throw_at(throw_target, 2, 4, src, 3)
		L.visible_message(span_danger("[H] embeds their arm inside [L]!"))
		to_chat(L, span_userdanger("[H]'s arm embeds itself in you and starts beeping ominously!"))
		playsound(src, 'sound/weapons/armbomb.ogg', 100, 1)
		qdel(src)
		. = ..()

/obj/effect/proc_holder/spell/aimed/boostknuckle
	name = "Boost Knuckle"
	desc = "Fire your fist which will explode after hitting a wall or flying for 10 meters, pulverising anything and anyone in its way."
	clothes_req = FALSE
	human_req = FALSE
	charge_max = 30
	cooldown_min = 10
	range = 20
	invocation = "CLANG!"
	invocation_type = "shout"
	action_icon_state = "immrod"
	projectile_type = /obj/item/projectile/punchline

/obj/effect/proc_holder/spell/targeted/aimed/boostknuckle/cast(list/targets,mob/user)
	var/mob/living/carbon/C = user
	for(var/obj/item/bodypart/r_arm/B in C.bodyparts)
		B.drop_limb()
		qdel(B)

/obj/item/projectile/punchline
	name = "bolt of fireball"
	icon_state = "fireball"
	damage = 30
	range = 10
	damage_type = BRUTE
	nodamage = FALSE
	penetrating = TRUE

	//explosion values
	var/exp_heavy = 2
	var/exp_light = 2
	var/exp_flash = 3
	var/exp_fire = 2

/obj/item/projectile/punchline/on_hit(target)
	. = ..()
	if(ismob(target))
		var/mob/living/M = target
		M.take_overall_damage(0,10)
	var/turf/T = get_turf(target)
	explosion(T, -1, exp_heavy, exp_light, exp_flash, 0, flame_range = exp_fire)

/obj/item/projectile/punchline/on_hit(atom/target, blocked=0)
	var/mob/living/carbon/human/H = firer
	var/atom/throw_target = get_edge_target_turf(target, H.dir)
	if(istype(target, /obj/structure/window) || istype(target, /obj/machinery/door) || istype(target, /obj/structure/door_assembly))
		damage = 500 
		..()
	if(isliving(target))
		var/mob/living/L = target
		if(!L.anchored && !L.throwing)
			if(iscarbon(L))
				var/mob/living/carbon/C = L
				var/mob/M = firer
				if(istype(M))
					C.throw_at(throw_target, 2, 4, H, 3)
					return BULLET_ACT_HIT

/obj/effect/proc_holder/spell/aimed/jetgadget
	name = "Jet Gadget"
	desc = "Launch your arm, causing it to fly erratically after reaching its destination and attacking the nearest target before coming back."
	charge_max = 60
	clothes_req = FALSE
	invocation = "ONI SOMA"
	invocation_type = "shout"
	range = 8
	cooldown_min = 20 
	projectile_type = /obj/item/projectile/magic/jetgadget
	action_icon = 'icons/mob/actions/humble/actions_humble.dmi'
	base_icon_state = "fireball"
	action_icon_state = "fireball0"
	sound = 'sound/magic/fireball.ogg'
	active_msg = "You prepare to cast your fireball spell!"
	deactive_msg = "You extinguish your fireball... for now."
	active = FALSE

/obj/item/projectile/jetgadget
	name = "bolt of fireball"
	icon_state = "fireball"
	damage = 15
	damage_type = BRUTE
	nodamage = FALSE

/obj/effect/proc_holder/spell/aimed/jetgadget/fire_projectile(mob/living/user, atom/target)
	var/mob/living/carbon/C = user
	for(var/obj/item/bodypart/r_arm/B in C.bodyparts)
		B.drop_limb()
		qdel(B)
		continue
	..()

/obj/item/projectile/magic/jetgadget/on_hit(mob/living/user, atom/target)
	. = ..()
	var/mob/living/carbon/human/H = firer
	var/mob/living/simple_animal/hostile/punchline/p = /mob/living/simple_animal/hostile/punchline
	p = spawn_atom_to_turf(p,src,1)
	p.deadweight = H

/mob/living/simple_animal/hostile/punchline
	name = "flying fist"
	desc = "A mechanical arm propelled by rockets and dead set on punching whoever's closest!"
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "bloodman"
	icon_living = "bloodman"
	icon_dead = "bloodman"
	friendly = "buzzes near"
	vision_range = 10
	speed = 3
	maxHealth = 1
	health = 1
	density = FALSE
	movement_type = FLYING
	harm_intent_damage = 10
	melee_damage_lower = 10
	melee_damage_upper = 10
	faction = list("cuhrazy")
	attacktext = "punches"
	speak_emote = list("beeps")
	attack_sound = 'sound/weapons/pierce.ogg'
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	del_on_death = 1
	rapid_melee = 2
	var/mob/living/carbon/deadweight
	var/obj/item/bodypart/r_arm/robot/breaker/punchline/K

/mob/living/simple_animal/hostile/punchline/Initialize()
	. = ..()
	addtimer(CALLBACK(src, .proc/death), 100)

/mob/living/simple_animal/hostile/punchline/AttackingTarget()
	..()
	if(isliving(target))
		var/mob/living/L = target
		L.Immobilize(10)

/mob/living/simple_animal/hostile/punchline/death(gibbed)
	K = new(src)
	visible_message(span_warning("The fist pulls back and returns to its host!"))
	K.attach_limb(deadweight, TRUE)
	..(gibbed)


//The arms themselves


/obj/item/bodypart/r_arm/robot/breaker
	name = "breaker"
	desc = "baseline for the wire grapple."

/obj/item/bodypart/r_arm/robot/breaker/attach_limb(mob/living/carbon/C)
	. = ..()
	if(!locate(/obj/effect/proc_holder/spell/targeted/wire_snatch) in C.mind.spell_list)
		C.AddSpell(new /obj/effect/proc_holder/spell/targeted/wire_snatch)
		C.AddSpell (new /obj/effect/proc_holder/spell/aoe_turf/repulse/breakaway)

/obj/item/bodypart/r_arm/robot/breaker/drop_limb(special)
	var/mob/living/carbon/C = owner
	C.RemoveSpell (/obj/effect/proc_holder/spell/aoe_turf/repulse/breakaway)
	C.RemoveSpell (/obj/effect/proc_holder/spell/targeted/wire_snatch)

/obj/item/bodypart/r_arm/robot/breaker/overture
	name = "Breaker: Overture"
	desc = "An robotic right arm that can generate large amounts of power and output it to knock foes back."

/obj/item/bodypart/r_arm/robot/breaker/overture/attach_limb(mob/living/carbon/C)
	. = ..()
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/battery)
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/exploder)

/obj/item/bodypart/r_arm/robot/breaker/overture/drop_limb(special)
	var/mob/living/carbon/C = owner
	C.RemoveSpell (/obj/effect/proc_holder/spell/targeted/exploder)
	C.RemoveSpell (/obj/effect/proc_holder/spell/targeted/battery)
	..()

/obj/item/bodypart/r_arm/robot/breaker/punchline
	name = "Breaker: Punch Line"
	desc = "An robotic right arm that can detach itself and fly outwards with jets to deliver heavy impacts."

/obj/item/bodypart/r_arm/robot/breaker/punchline/attach_limb(mob/living/carbon/C, special)
	. = ..()
	C.faction |= "cuhrazy"
	C.AddSpell (new /obj/effect/proc_holder/spell/aimed/boostknuckle)
	C.AddSpell (new /obj/effect/proc_holder/spell/aimed/jetgadget)

/obj/item/bodypart/r_arm/robot/breaker/punchline/drop_limb(special)
	var/mob/living/carbon/C = owner
	C.RemoveSpell (/obj/effect/proc_holder/spell/aoe_turf/repulse/breakaway)
	C.RemoveSpell (/obj/effect/proc_holder/spell/aimed/boostknuckle)
	C.RemoveSpell (/obj/effect/proc_holder/spell/aimed/jetgadget)
