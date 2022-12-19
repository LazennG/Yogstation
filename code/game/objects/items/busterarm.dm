/obj/effect/proc_holder/spell/targeted/buster
	clothes_req = FALSE
	include_user = TRUE
	range = -1

/obj/effect/proc_holder/spell/targeted/buster/can_cast(mob/living/user)
	var/obj/item/bodypart/l_arm/robot/buster/L = user.get_bodypart(BODY_ZONE_L_ARM)
	var/obj/item/bodypart/r_arm/robot/buster/R = user.get_bodypart(BODY_ZONE_R_ARM)
	if(R?.bodypart_disabled || L?.bodypart_disabled)
		to_chat(user, span_warning("The arm isn't in a functional state right now!"))
		return FALSE
	if(user.IsParalyzed() || user.IsStun() || user.restrained())
		return FALSE
	return TRUE
	
/obj/item/buster/proc/hit(mob/living/user, mob/living/target, damage)
		var/obj/item/bodypart/limb_to_hit = target.get_bodypart(user.zone_selected)
		var/armor = target.run_armor_check(limb_to_hit, MELEE)
		target.apply_damage(damage, BRUTE, limb_to_hit, armor, wound_bonus=CANT_WOUND)

/obj/effect/proc_holder/spell/targeted/buster/proc/grab(mob/living/user, mob/living/target, damage)
		var/obj/item/bodypart/limb_to_hit = target.get_bodypart(user.zone_selected)
		var/armor = target.run_armor_check(limb_to_hit, MELEE)
		target.apply_damage(damage, BRUTE, limb_to_hit, armor, wound_bonus=CANT_WOUND)

/obj/item/buster
	item_flags = DROPDEL
	w_class = 5
	icon = 'icons/obj/wizard.dmi'
	icon_state = "disintegrate"
	item_state = "disintegrate"
	lefthand_file = 'icons/mob/inhands/misc/touchspell_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/touchspell_righthand.dmi'

/obj/item/buster/Initialize()
	. = ..()
	ADD_TRAIT(src, HAND_REPLACEMENT_TRAIT, TRAIT_NODROP)

/obj/effect/proc_holder/spell/targeted/buster/wire_snatch
	name = "Wire Snatch"
	desc = "Extend a wire to your active hand for reeling in foes from a distance. Anchored targets that are hit will pull you towards them instead. It can be used 3 times before \
	reeling back into the arm."
	invocation_type = "none"
	include_user = TRUE
	range = -1
	charge_max = 50
	clothes_req = FALSE
	cooldown_min = 10
	action_icon = 'icons/obj/guns/magic.dmi'
	action_icon_state = "hook"
	var/summon_path = /obj/item/gun/magic/wire

/obj/effect/proc_holder/spell/targeted/buster/wire_snatch/cast(list/targets, mob/user)
	for(var/obj/item/gun/magic/wire/T in user)
		qdel(T)
		to_chat(user, span_notice("The wire returns into your wrist."))
		return
	for(var/mob/living/carbon/C in targets)
		var/GUN = new summon_path
		C.put_in_r_hand(GUN)

/obj/item/gun/magic/wire/Initialize()
	. = ..()
	ADD_TRAIT(src, HAND_REPLACEMENT_TRAIT, NOBLUDGEON)
	if(ismob(loc))
		loc.visible_message(span_warning("A long cable comes out from [loc.name]'s arm!"), span_warning("You extend the breaker's wire from your arm."))

/obj/item/gun/magic/wire
	name = "grappling wire"
	desc = "A combat-ready cable usable for closing the distance, bringing you to walls and heavy targets you hit or bringing lighter ones to you."
	ammo_type = /obj/item/ammo_casing/magic/wire
	icon_state = "hook"
	item_state = "chain"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	fire_sound = 'sound/weapons/batonextend.ogg'
	max_charges = 3
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
		var/mob/living/L = target
		if(!L.anchored)
			if(istype(H))
				L.visible_message(span_danger("[L] is pulled by [H]'s wire!"),span_userdanger("A wire grabs you and pulls you towards [H]!"))
				L.throw_at(get_step_towards(H,L), 8, 4)
				L.Immobilize(1 SECONDS)
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

/obj/effect/proc_holder/spell/targeted/buster/grap
	name = "Grapple"
	desc = "Prepare your left hand for grabbing. Throw your target and inflict more damage if they hit a solid object. If the targeted limb is horribly bruised, you'll tear it off when \
	throwing the victim."
	action_icon = 'icons/mob/actions/actions_arm.dmi'
	action_icon_state = "lariat"
	charge_max = 30
	var/jumpdistance = 4

/obj/effect/proc_holder/spell/targeted/buster/grap/cast(list/targets, mob/living/user)
	var/obj/item/buster/graphand/G = new()
	var/result = (user.put_in_l_hand(G))
	if(!result)
		to_chat(user, span_warning("You can't do this with your left hand full!"))

/obj/item/buster/graphand
	name = "open hand"
	desc = "Your fingers occasionally curl as if they have their own urge to dig into something."
	color = "#f14b4b"
	var/throwdist = 5
	var/throwdam = 15
	var/slamdam = 10
	var/objdam = 100

/obj/item/buster/graphand/afterattack(atom/target, mob/living/user, proximity)
	var/turf/Z = get_turf(user)
	var/list/thrown = list()
	target.add_fingerprint(user, FALSE)
	if(!proximity)
		return
	if(target == user)
		return
	if(isfloorturf(target))
		return
	if(isitem(target))
		return
	if(isstructure(target) || ismachinery(target))
		qdel(src)
		var/obj/I = target
		var/old_density = I.density
		if(I.anchored == TRUE)
			if(!istype(I, /obj/machinery/vending))
				return
		I.visible_message(span_warning("[user] grabs [I] and lifts it above [user.p_their()] head!"))
		animate(I, time = 0.2 SECONDS, pixel_y = 20)
		I.forceMove(Z)
		I.density = FALSE 
		walk_towards(I, user, 0, 2)
		sleep(2 SECONDS)
		walk(I,0)
		thrown |= I
		I.density = old_density
		animate(I, transform = null, time = 0.5 SECONDS, loop = 0)
	if(isliving(target))
		var/mob/living/L = target
		var/obj/item/bodypart/limb_to_hit = L.get_bodypart(user.zone_selected)
		var/obj/structure/bed/grip/F = new(Z, user)
		qdel(src)
		to_chat(L, span_userdanger("[user] grapples you and lifts you up into the air!"))
		L.forceMove(Z)
		F.buckle_mob(target)
		walk_towards(F, user, 0, 2)
		sleep(1 SECONDS)
		hit(user, L, throwdam)
		if(!limb_to_hit)
			limb_to_hit = L.get_bodypart(BODY_ZONE_CHEST)
		if(limb_to_hit.brute_dam == limb_to_hit.max_damage)
			if(istype(limb_to_hit, /obj/item/bodypart/chest))
				thrown |= L
			else
				to_chat(L, span_userdanger("[user] tears [limb_to_hit] off!"))
				playsound(user,'sound/misc/desceration-01.ogg', 20, 1)
				L.visible_message(span_warning("[user] throws [L], severing [limb_to_hit] from [L.p_them()]!"))
				limb_to_hit.drop_limb()
				user.put_in_l_hand(limb_to_hit)
		if(limb_to_hit == L.get_bodypart(BODY_ZONE_PRECISE_GROIN))
			var/obj/item/organ/T = L.getorgan(/obj/item/organ/tail)
			if(T && limb_to_hit.brute_dam >= 50)
				to_chat(L, span_userdanger("[user] tears your tail off!"))
				playsound(user,'sound/misc/desceration-02.ogg', 20, 1)
				L.visible_message(span_warning("[user] throws [L], severing [L.p_them()] from [L.p_their()] tail!")) //"I'm taking this back."
				T.Remove(L)
				user.put_in_l_hand(T)
		thrown |= L
	if(ismecha(target))
		return
	target.visible_message(span_warning("[user] throws [target]!"))
	var/direction = user.dir
	var/turf/P = get_turf(user)
	for(var/i = 1 to throwdist)
		var/turf/C = get_ranged_target_turf(P, direction, i)
		if(C.density)
			for(var/mob/living/S in thrown)
				hit(user, S, slamdam)
				S.Knockdown(1.5 SECONDS)
				if(isanimal(S) && S.stat == DEAD)
					S.gib()	
			for(var/obj/O in thrown)
				O.take_damage(objdam)
				target.visible_message(span_warning("[target] collides with [C]!"))
			return
		for(var/obj/D in C.contents)
			for(var/obj/O in thrown)
				if(D.density == TRUE)
					O.take_damage(objdam)	
			if(D.density == TRUE && D.anchored == FALSE)
				thrown |= D
				D.take_damage(50)
			if(D.density == TRUE && D.anchored == TRUE)
				for(var/mob/living/S in thrown)
					hit(user, S, slamdam)
					S.Knockdown(1.5 SECONDS)
					if(isanimal(S) && S.stat == DEAD)
						S.gib()	
					if(istype(D, /obj/machinery/disposal/bin))
						var/obj/machinery/disposal/bin/dumpster = D
						S.forceMove(D)
						D.visible_message(span_warning("[S] is thrown down the trash chute!"))
						dumpster.do_flush()
						return
				D.take_damage(objdam)
				if(D.density == TRUE)
					return
		for(var/mob/living/M in C.contents)
			hit(user, M, slamdam)
			M.Paralyze(1.5 SECONDS)
			for(var/mob/living/S in thrown)
				hit(user, S, slamdam)
				S.Paralyze(1 SECONDS)
			thrown |= M
			for(var/obj/O in thrown)
				O.take_damage(objdam)
		if(C)
			for(var/atom/movable/K in thrown)
				K.SpinAnimation(0.2 SECONDS, 1)
				sleep(0.001 SECONDS)
				K.forceMove(C)
				if(istype(C, /turf/open/space))
					var/atom/throw_target = get_edge_target_turf(K, direction)
					K.throw_at(throw_target, 6, 4, user, 3)
				animate(K, transform = null, time = 0.5 SECONDS, loop = 0)
					

/obj/item/buster/graphand/ignition_effect(atom/A, mob/user)
	playsound(user,'sound/misc/fingersnap2.ogg', 20, 1)
	playsound(user,'sound/effects/sparks4.ogg', 20, 1)
	do_sparks(5, TRUE, src)
	. = span_rose("With a single snap, [user] sets [A] alight with sparks from [user.p_their()] metal fingers.")
			
/obj/effect/proc_holder/spell/targeted/buster/mop
	name = "Mop the Floor"
	desc = "Launch forward and drag whoever's in front of you on the ground. The power of this move increases with closeness to the target upon using it."
	action_icon = 'icons/mob/actions/actions_arm.dmi'
	action_icon_state = "mop"
	charge_max = 40	
	var/jumpdistance = 4
	var/dragdam = 8
	var/crashdam = 10

/obj/effect/proc_holder/spell/targeted/buster/mop/cast(atom/target,mob/living/user)
	var/turf/T = get_step(get_turf(user), user.dir)
	var/turf/Z = get_turf(user)
	var/obj/effect/temp_visual/decoy/fading/threesecond/F = new(Z, user)
	var/list/mopped = list()
	user.visible_message(span_warning("[user] sprints forward with [user.p_their()] hand outstretched!"))
	playsound(user,'sound/effects/gravhit.ogg', 20, 1)
	user.Immobilize(0.1 SECONDS) //so they dont skip through the target
	for(var/i = 0 to jumpdistance)
		if(T.density)
			return
		for(var/obj/D in T.contents)
			if(D.density == TRUE)
				return
		if(T)
			sleep(0.01 SECONDS)
			user.forceMove(T)
			walk_towards(F, user, 0, 1.5)
			animate(F, alpha = 0, color = "#d40a0a", time = 0.5 SECONDS)
			for(var/mob/living/L in T.contents)
				if(L != user)
					mopped |= L
					L.add_fingerprint(user, FALSE)
					var/turf/Q = get_step(get_turf(user), user.dir)
					var/mob/living/U = user
					to_chat(L, span_userdanger("[user] grinds you against the ground!"))
					animate(L, transform = matrix(90, MATRIX_ROTATE), time = 0.1 SECONDS, loop = 0)
					if(istype(T, /turf/open/space))
						var/atom/throw_target = get_edge_target_turf(L, user.dir)
						animate(L, transform = null, time = 0.5 SECONDS, loop = 0)
						L.throw_at(throw_target, 2, 4, user, 3)
						return
					if(Q.density)
						grab(user, L, crashdam)
						animate(L, transform = null, time = 0.5 SECONDS, loop = 0)
						U.visible_message(span_warning("[U] rams [L] into [Q]t!"))
						to_chat(L, span_userdanger("[U] rams you into a [Q]!"))
						L.Knockdown(1 SECONDS)
						return
					for(var/obj/D in Q.contents)
						if(D.density == TRUE)
							grab(user, L, crashdam)
							D.take_damage(200)
							L.Knockdown(1 SECONDS)
					U.forceMove(get_turf(L))
					to_chat(L, span_userdanger("[U] catches you with [U.p_their()] hand and drags you down!"))
					U.visible_message(span_warning("[U] hits [L] and drags them through the dirt!"))
					L.forceMove(Q)
					grab(user, L, dragdam)
					playsound(L,'sound/effects/meteorimpact.ogg', 60, 1)
			T = get_step(user, user.dir)
	for(var/mob/living/C in mopped)
		if(C.stat == CONSCIOUS && C.resting == FALSE)
			animate(C, transform = null, time = 0.5 SECONDS, loop = 0)

/obj/effect/proc_holder/spell/targeted/buster/suplex
	name = "Suplex"
	desc = "Grab the target in front of you and slam them back onto the ground. \
	 If there's a solid object behind you when the move is successfully performed then it will \ take substantial damage."
	action_icon = 'icons/mob/actions/actions_arm.dmi'	
	action_icon_state = "suplex"
	charge_max = 5
	var/supdam = 20
	var/crashdam = 10

/obj/effect/proc_holder/spell/targeted/buster/suplex/cast(atom/target,mob/living/user)
	var/turf/T = get_step(get_turf(user), user.dir)
	var/turf/Z = get_turf(user)
	user.visible_message(span_warning("[user] outstretches [user.p_their()] arm and goes for a grab!"))
	for(var/mob/living/L in T.contents)
		var/turf/Q = get_step(get_turf(user), turn(user.dir,180))
		if(Q.density)
			var/turf/closed/wall/W = Q
			grab(user, L, crashdam)
			to_chat(user, span_warning("[user] turns around and slams [L] against [Q]!"))
			to_chat(L, span_userdanger("[user] crushes you against [Q]!"))
			playsound(L, 'sound/effects/meteorimpact.ogg', 60, 1)
			playsound(user, 'sound/effects/gravhit.ogg', 20, 1)
			if(!istype(W, /turf/closed/wall/r_wall))
				W.dismantle_wall(1)
				L.forceMove(Q)
			else		
				L.forceMove(Z)
			return
		for(var/obj/D in Q.contents)
			if(D.density == TRUE)
				if(istype(D, /obj/machinery/disposal/bin))
					var/obj/machinery/disposal/bin/dumpster = D
					L.forceMove(D)
					dumpster.do_flush()
					to_chat(L, span_userdanger("[user] throws you down disposals!"))
					target.visible_message(span_warning("[L] is thrown down the trash chute!"))
					return
				user.visible_message(span_warning("[user] turns around and slams [L] against [D]!"))
				grab(user, L, crashdam)
				D.take_damage(400)
		for(var/mob/living/M in Q.contents)
			grab(user, L, crashdam)	
			to_chat(L, span_userdanger("[user] throws you into [M]"))
			to_chat(M, span_userdanger("[user] throws [L] into you!"))
			user.visible_message(span_warning("[L] slams into [M]!"))
		L.forceMove(Q)
		if(istype(Q, /turf/open/space))
			user.setDir(turn(user.dir,180))
			var/atom/throw_target = get_edge_target_turf(L, user.dir)
			L.throw_at(throw_target, 2, 4, user, 3)
			user.visible_message(span_warning("[user] throws [L] behind [user.p_them()]!"))
			return
		playsound(L,'sound/effects/meteorimpact.ogg', 60, 1)
		playsound(user, 'sound/effects/gravhit.ogg', 20, 1)
		to_chat(L, span_userdanger("[user] catches you with [user.p_their()] hand and crushes you on the ground!"))
		user.visible_message(span_warning("[user] turns around and slams [L] against the ground!"))
		user.setDir(turn(user.dir, 180))
		animate(L, transform = matrix(179, MATRIX_ROTATE), time = 0.1 SECONDS, loop = 0)
		if(isanimal(L))
			L.adjustBruteLoss(20)
			if(L.stat == DEAD)
				L.visible_message(span_warning("[L] explodes into gore on impact!"))
				L.gib()
		grab(user, L, supdam)
		sleep(0.5 SECONDS)
		if(L.stat == CONSCIOUS && L.resting == FALSE)
			animate(L, transform = null, time = 0.1 SECONDS, loop = 0)
		
/obj/effect/proc_holder/spell/targeted/buster/megabuster
	name = "mega buster"
	desc = "Put the buster arm through its paces to gain extreme power for five seconds. Connecting the blow will devastate the target and send them flying if they're not anchored. \
	Flying targets will have a snowball effect on hitting other unanchored people or objects collided with. Punching a mangled limb will instead send it flying and momentarily stun \
	its owner. Once the five seconds are up or a strong wall or person is hit, the entire arm will be unusable for 15 seconds. Punching a person, reinforced wall, or exosuit will\
	disable the arm"
	action_icon = 'icons/mob/actions/actions_arm.dmi'
	action_icon_state = "ponch"
	charge_max = 150

/obj/effect/proc_holder/spell/targeted/buster/megabuster/cast(list/targets, mob/living/user)
	var/obj/item/buster/megabuster/B = new()
	user.visible_message(span_userdanger("[user]'s arm begins crackling loudly!"))
	playsound(user,'sound/effects/beepskyspinsabre.ogg', 60, 1)
	do_after(user, 2 SECONDS, user, TRUE, stayStill = FALSE)
	var/result = (user.put_in_l_hand(B))
	if(!result)
		to_chat(user, span_warning("You can't do this with your left hand full!"))
	if(result)
		user.visible_message(span_danger("[user]'s arm begins!"))
		B.fizzle(user)

/obj/item/buster/megabuster
	name = "supercharged emitter"
	desc = "The result of all the prosthetic's power building up in its palm. It's fading fast."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "disintegrate"
	item_state = "disintegrate"
	lefthand_file = 'icons/mob/inhands/misc/touchspell_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/touchspell_righthand.dmi'
	color = "#0ef2fa"
	var/flightdist = 8
	var/punchdam = 30
	var/colldam = 20
	var/mechdam = 200
	var/objdam = 400

/obj/item/buster/megabuster/ignition_effect(atom/A, mob/user)
	playsound(user,'sound/misc/fingersnap1.ogg', 20, 1)
	playsound(user,'sound/effects/sparks4.ogg', 20, 1)
	do_sparks(5, TRUE, src)
	. = span_rose("With a single snap, [user] sets [A] alight with sparks from [user.p_their()] metal fingers.")

/obj/item/buster/megabuster/afterattack(atom/target, mob/living/user, proximity)
	var/direction = user.dir
	var/obj/item/bodypart/l_arm/R = user.get_bodypart(BODY_ZONE_L_ARM)
	var/list/knockedback = list()
	var/mob/living/L = target
	if(!proximity)
		return
	if(target == user)
		return
	if(isitem(target))
		var/obj/I = target
		if(!isturf(I.loc))
			if(!istype(I, /obj/item/clothing/mask/cigarette))
				to_chat(user, span_warning("You probably shouldn't attack something on your person."))
			return
		if(!istype(I, /obj/item/clothing/mask/cigarette))
			I.take_damage(objdam)
			user.visible_message(span_warning("[user] pulverizes [I]!"))
		return
	if(isopenturf(target))
		return
	playsound(L, 'sound/effects/gravhit.ogg', 60, 1)
	if(iswallturf(target))
		var/turf/closed/wall/W = target
		if(istype(W, /turf/closed/wall/r_wall))
			W.dismantle_wall(1)
			qdel(src)
			to_chat(user, span_warning("The huge impact takes the arm out of commission!"))
			(R?.set_disabled(TRUE))
			addtimer(CALLBACK(R, /obj/item/bodypart/l_arm/.proc/set_disabled), 15 SECONDS, TRUE)
		else
			W.dismantle_wall(1)
		user.visible_message(span_warning("[user] demolishes [W]!"))
		return
	if(ismecha(target))
		var/obj/mecha/A = target
		A.take_damage(mechdam)
		user.visible_message(span_warning("[user] crushes [target]!"))
		(R?.set_disabled(TRUE))
		addtimer(CALLBACK(R, /obj/item/bodypart/l_arm/.proc/set_disabled), 15 SECONDS, TRUE)
	if(isstructure(target) || ismachinery(target))
		user.visible_message(span_warning("[user] strikes [target]!"))
		var/obj/I = target
		if(I.anchored == TRUE)
			I.take_damage(objdam)
			return
		I.take_damage(50)
		knockedback |= I
		if(QDELETED(I))
			return
	if(isliving(L))
		var/obj/item/bodypart/limb_to_hit = L.get_bodypart(user.zone_selected)
		var/armor = L.run_armor_check(limb_to_hit, MELEE)
		qdel(src, force = TRUE)
		(R?.set_disabled(TRUE))
		to_chat(user, span_warning("The huge impact takes the arm out of commission!"))
		shake_camera(L, 4, 3)
		L.apply_damage(punchdam, BRUTE, limb_to_hit, armor, wound_bonus=CANT_WOUND)
		addtimer(CALLBACK(R, /obj/item/bodypart/l_arm/.proc/set_disabled), 15 SECONDS, TRUE)
		if(!limb_to_hit)
			limb_to_hit = L.get_bodypart(BODY_ZONE_CHEST)
		if(iscarbon(L))
			if(limb_to_hit.brute_dam == limb_to_hit.max_damage)
				if(istype(limb_to_hit, /obj/item/bodypart/chest))
					knockedback |= L
				else
					var/atom/throw_target = get_edge_target_turf(L, direction)
					to_chat(L, span_userdanger("[user] blows [limb_to_hit] off with inhuman force!"))
					user.visible_message(span_warning("[user] punches [L]'s [limb_to_hit] clean off!"))
					limb_to_hit.drop_limb()
					limb_to_hit.throw_at(throw_target, 8, 4, user, 3)
					L.Paralyze(3 SECONDS)
					return
		L.SpinAnimation(0.5 SECONDS, 2)
		to_chat(L, span_userdanger("[user] hits you with a blast of energy and sends you flying!"))
		user.visible_message(span_warning("[user] blasts [L] with a surge of energy and sends [L.p_them()] flying!"))
		knockedback |= L
	for(var/mob/M in view(7, user))
		shake_camera(2, 3)
	var/turf/P = get_turf(user)
	for(var/i = 2 to flightdist)
		var/turf/T = get_ranged_target_turf(P, direction, i)
		if(T.density)
			var/turf/closed/wall/W = T
			for(var/mob/living/S in knockedback)
				hit(user, S, colldam)
				if(isanimal(S) && S.stat == DEAD)
					S.gib()
			if(!istype(W, /turf/closed/wall/r_wall))
				W.dismantle_wall(1)
			else
				return
		for(var/obj/D in T.contents)
			if(D.density == TRUE && D.anchored == FALSE)
				knockedback |= D
				D.take_damage(50)
			if(D.density == TRUE && D.anchored == TRUE)
				D.take_damage(objdam)
				if(D.density == TRUE)
					return
				for(var/mob/living/S in knockedback)
					hit(user, S, colldam)
					if(isanimal(S) && S.stat == DEAD)
						S.gib()		
		for(var/mob/living/M in T.contents)
			hit(user, M, colldam)
			for(var/mob/living/S in knockedback)
				hit(user, S, colldam)
			knockedback |= M
		if(T)
			for(var/atom/movable/K in knockedback)
				K.SpinAnimation(0.2 SECONDS, 1)
				sleep(0.001 SECONDS)
				K.forceMove(T)
				if(istype(T, /turf/open/space))
					var/atom/throw_target = get_edge_target_turf(K, direction)
					animate(K, transform = null, time = 0.5 SECONDS, loop = 0)
					K.throw_at(throw_target, 6, 4, user, 3)
					return

/obj/item/buster/megabuster/Initialize(mob/living/user)
	. = ..()
	animate(src, alpha = 50, time = 5 SECONDS)
	
/obj/item/buster/megabuster/proc/fizzle(mob/living/user, right = FALSE)
	var/obj/item/bodypart/l_arm/L = user.get_bodypart(BODY_ZONE_L_ARM)
	var/obj/item/bodypart/r_arm/R = user.get_bodypart(BODY_ZONE_R_ARM)
	sleep(5 SECONDS)
	qdel(src)
	if(right)
		(R?.set_disabled(TRUE))
		addtimer(CALLBACK(R, /obj/item/bodypart/r_arm/.proc/set_disabled), 15 SECONDS, TRUE)
	else
		(L?.set_disabled(TRUE))
		addtimer(CALLBACK(L, /obj/item/bodypart/l_arm/.proc/set_disabled), 15 SECONDS, TRUE)

/obj/structure/bed/grip
	name = ""
	icon_state = ""
	can_buckle = TRUE
	density = FALSE

/obj/structure/bed/grip/Initialize()
	. = ..()
	QDEL_IN(src, 1.2 SECONDS)

/obj/structure/bed/grip/user_unbuckle_mob(mob/living/buckled_mob, mob/living/user)
	if(has_buckled_mobs())
		for(var/buckl in buckled_mobs)
			var/mob/living/M = buckl
			if(!do_after(M, 2 SECONDS, src))
				if(M && M.buckled)
					to_chat(M, span_warning("You fail to free yourself!"))
				return
			if(!M.buckled)
				return
			unbuckle_mob(M)
			add_fingerprint(user)

/obj/effect/proc_holder/spell/targeted/buster/grap/right
	desc = "Prepare your right hand for grabbing. Throw your target and inflict more damage if they hit a solid object. If the targeted limb is horribly bruised, you'll tear it off when \
	throwing the victim."

/obj/effect/proc_holder/spell/targeted/buster/grap/right/cast(list/targets, mob/living/user)
	var/obj/item/buster/graphand/G = new()
	var/result = (user.put_in_r_hand(G))
	if(!result)
		to_chat(user, span_warning("You can't do this with your right hand full!"))

/obj/effect/proc_holder/spell/targeted/buster/megabuster/right

/obj/effect/proc_holder/spell/targeted/buster/megabuster/right/cast(list/targets, mob/living/user)
	var/obj/item/buster/megabuster/right/B = new()
	user.visible_message(span_userdanger("[user]'s arm begins crackling loudly!"))
	playsound(user,'sound/effects/beepskyspinsabre.ogg', 60, 1)
	do_after(user, 2 SECONDS, user, TRUE, stayStill = FALSE)
	var/result = (user.put_in_r_hand(B))
	if(!result)
		to_chat(user, span_warning("You can't do this with your right hand full!"))
	if(result)
		user.visible_message(span_danger("[user]'s arm begins!"))
		B.fizzle(user, right = TRUE)

/obj/item/buster/megabuster/right

/obj/item/buster/megabuster/right/afterattack(atom/target, mob/living/user, proximity)
	var/direction = user.dir
	var/obj/item/bodypart/r_arm/R = user.get_bodypart(BODY_ZONE_R_ARM)
	var/list/knockedback = list()
	var/mob/living/L = target
	if(!proximity)
		return
	if(target == user)
		return
	if(isitem(target))
		var/obj/I = target
		if(!isturf(I.loc))
			if(!istype(I, /obj/item/clothing/mask/cigarette))
				to_chat(user, span_warning("You probably shouldn't attack something on your person."))
			return
		if(!istype(I, /obj/item/clothing/mask/cigarette))
			I.take_damage(objdam)
			user.visible_message(span_warning("[user] pulverizes [I]!"))
		return
	if(isopenturf(target))
		return
	playsound(L, 'sound/effects/gravhit.ogg', 60, 1)
	if(iswallturf(target))
		var/turf/closed/wall/W = target
		if(!istype(W, /turf/closed/wall/r_wall))
			W.dismantle_wall(1)
		else
			W.dismantle_wall(1)
			qdel(src)
			to_chat(user, span_warning("The huge impact takes the arm out of commission!"))
			(R?.set_disabled(TRUE))
			addtimer(CALLBACK(R, /obj/item/bodypart/l_arm/.proc/set_disabled), 15 SECONDS, TRUE)
		user.visible_message(span_warning("[user] demolishes [W]!"))
		return
	if(ismecha(target))
		var/obj/mecha/A = target
		A.take_damage(mechdam)
		user.visible_message(span_warning("[user] crushes [target]!"))
		(R?.set_disabled(TRUE))
		addtimer(CALLBACK(R, /obj/item/bodypart/l_arm/.proc/set_disabled), 15 SECONDS, TRUE)
	if(isstructure(target) || ismachinery(target))
		user.visible_message(span_warning("[user] strikes [target]!"))
		var/obj/I = target
		if(I.anchored == TRUE)
			I.take_damage(objdam)
			return
		I.take_damage(50)
		knockedback |= I
		if(QDELETED(I))
			return
	if(isliving(L))
		var/obj/item/bodypart/limb_to_hit = L.get_bodypart(user.zone_selected)
		var/armor = L.run_armor_check(limb_to_hit, MELEE)
		qdel(src, force = TRUE)
		(R?.set_disabled(TRUE))
		to_chat(user, span_warning("The huge impact takes the arm out of commission!"))
		shake_camera(L, 4, 3)
		L.apply_damage(punchdam, BRUTE, limb_to_hit, armor, wound_bonus=CANT_WOUND)
		addtimer(CALLBACK(R, /obj/item/bodypart/l_arm/.proc/set_disabled), 15 SECONDS, TRUE)
		if(!limb_to_hit)
			limb_to_hit = L.get_bodypart(BODY_ZONE_CHEST)
		if(iscarbon(L))
			if(limb_to_hit.brute_dam == limb_to_hit.max_damage)
				if(istype(limb_to_hit, /obj/item/bodypart/chest))
					knockedback |= L
				else
					var/atom/throw_target = get_edge_target_turf(L, direction)
					to_chat(L, span_userdanger("[user] blows [limb_to_hit] off with inhuman force!"))
					user.visible_message(span_warning("[user] punches [L]'s [limb_to_hit] clean off!"))
					limb_to_hit.drop_limb()
					limb_to_hit.throw_at(throw_target, 8, 4, user, 3)
					L.Paralyze(3 SECONDS)
					return
		L.SpinAnimation(0.5 SECONDS, 2)
		to_chat(L, span_userdanger("[user] hits you with a blast of energy and sends you flying!"))
		user.visible_message(span_warning("[user] blasts [L] with a surge of energy and sends [L.p_them()] flying!"))
		knockedback |= L
	for(var/mob/M in view(7, user))
		shake_camera(2, 3)
	var/turf/P = get_turf(user)
	for(var/i = 2 to flightdist)
		var/turf/T = get_ranged_target_turf(P, direction, i)
		if(T.density)
			var/turf/closed/wall/W = T
			for(var/mob/living/S in knockedback)
				hit(user, S, colldam)
				if(isanimal(S) && S.stat == DEAD)
					S.gib()
			if(!istype(W, /turf/closed/wall/r_wall))
				W.dismantle_wall(1)
			else
				return
		for(var/obj/D in T.contents)
			if(D.density == TRUE && D.anchored == FALSE)
				knockedback |= D
				D.take_damage(50)
			if(D.density == TRUE && D.anchored == TRUE)
				D.take_damage(objdam)
				if(D.density == TRUE)
					return
				for(var/mob/living/S in knockedback)
					hit(user, S, colldam)
					if(isanimal(S) && S.stat == DEAD)
						S.gib()		
		for(var/mob/living/M in T.contents)
			hit(user, M, colldam)
			for(var/mob/living/S in knockedback)
				hit(user, S, colldam)
			knockedback |= M
		if(T)
			for(var/atom/movable/K in knockedback)
				K.SpinAnimation(0.2 SECONDS, 1)
				sleep(0.001 SECONDS)
				K.forceMove(T)
				if(istype(T, /turf/open/space))
					var/atom/throw_target = get_edge_target_turf(K, direction)
					animate(K, transform = null, time = 0.5 SECONDS, loop = 0)
					K.throw_at(throw_target, 6, 4, user, 3)
					return

/obj/effect/proc_holder/spell/targeted/buster/wire_snatch/right/cast(list/targets, mob/user)
	for(var/obj/item/gun/magic/wire/T in user)
		qdel(T)
		to_chat(user, span_notice("The wire returns into your wrist."))
		return
	for(var/mob/living/carbon/C in targets)
		var/GUN = new summon_path
		C.put_in_l_hand(GUN)

//buster Arm

/obj/item/bodypart/l_arm/robot/buster
	name = "buster left arm"
	desc = "A robotic arm designed explicitly for combat and providing the user with extreme power."
	icon = 'icons/mob/augmentation/augments_seismic.dmi'
	icon_state = "seismic_r_arm"
	max_damage = 60

/obj/item/bodypart/l_arm/robot/buster/attach_limb(mob/living/carbon/C, special)
	. = ..()
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/buster/wire_snatch)
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/buster/grap)
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/buster/mop)
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/buster/suplex)
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/buster/megabuster)

/obj/item/bodypart/l_arm/robot/buster/drop_limb(special)
	var/mob/living/carbon/C = owner
	C.RemoveSpell (/obj/effect/proc_holder/spell/targeted/buster/wire_snatch)
	C.RemoveSpell (/obj/effect/proc_holder/spell/targeted/buster/grap)
	C.RemoveSpell (/obj/effect/proc_holder/spell/targeted/buster/mop)
	C.RemoveSpell (/obj/effect/proc_holder/spell/targeted/buster/suplex)
	C.RemoveSpell (/obj/effect/proc_holder/spell/targeted/buster/megabuster)
	..()

/obj/item/bodypart/l_arm/robot/buster/attack(mob/living/L, proximity)
	if(!proximity)
		return
	if(!ishuman(L))
		return
	replace_limb(L)//why isnt the arm sprite showing up

/obj/item/bodypart/l_arm/robot/buster/screwdriver_act(mob/living/user, obj/item/I)
	to_chat(user, span_notice("You modify [src] to be installed on the right arm."))
	new /obj/item/bodypart/r_arm/robot/buster(user)
	qdel(src)

/obj/item/bodypart/r_arm/robot/buster
	name = "buster right arm"
	desc = "A robotic arm designed explicitly for combat and providing the user with extreme power."
	icon = 'icons/mob/augmentation/augments_seismic.dmi'
	icon_state = "seismic_r_arm"
	max_damage = 60

/obj/item/bodypart/r_arm/robot/buster/attack(mob/living/L, proximity)
	if(!proximity)
		return
	if(!ishuman(L))
		return
	replace_limb(L)//why isnt the arm sprite showing up

/obj/item/bodypart/r_arm/robot/buster/screwdriver_act(mob/living/user, obj/item/I)
	to_chat(user, span_notice("You modify [src] to be installed on the left arm."))
	new /obj/item/bodypart/l_arm/robot/buster(user)
	qdel(src)

/obj/item/bodypart/r_arm/robot/buster/attach_limb(mob/living/carbon/C, special)
	. = ..()
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/buster/wire_snatch/right)
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/buster/grap/right)
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/buster/mop)
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/buster/suplex)
	C.AddSpell (new /obj/effect/proc_holder/spell/targeted/buster/megabuster/right)

/obj/item/bodypart/r_arm/robot/buster/drop_limb(special)
	var/mob/living/carbon/C = owner
	C.RemoveSpell (/obj/effect/proc_holder/spell/targeted/buster/wire_snatch/right)
	C.RemoveSpell (/obj/effect/proc_holder/spell/targeted/buster/grap/right)
	C.RemoveSpell (/obj/effect/proc_holder/spell/targeted/buster/mop)
	C.RemoveSpell (/obj/effect/proc_holder/spell/targeted/buster/suplex)
	C.RemoveSpell (/obj/effect/proc_holder/spell/targeted/buster/megabuster/right)
	..()
