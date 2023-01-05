/mob/living/simple_animal/hostile/megafauna/primesoul
	name = "bubblegum"
	desc = "In what passes for a hierarchy among slaughter demons, this one is king."
	health = 2500
	maxHealth = 2500
	attacktext = "rends"
	attack_sound = 'sound/magic/demon_attack1.ogg'
	icon_state = "bubblegum"
	icon_living = "bubblegum"
	icon_dead = ""
	health_doll_icon = "bubblegum"
	friendly = "stares down"
	icon = 'icons/mob/lavaland/96x96megafauna.dmi'
	speak_emote = list("gurgles")
	armour_penetration = 40
	melee_damage_lower = 40
	melee_damage_upper = 40
	speed = 5
	move_to_delay = 5
	retreat_distance = 5
	minimum_distance = 5
	rapid_melee = 8 // every 1/4 second
	melee_queue_distance = 20 // as far as possible really, need this because of blood warp
	ranged = TRUE
	pixel_x = -32
	projectiletype = /obj/item/projectile/primesoul
	del_on_death = TRUE
	crusher_loot = list(/obj/structure/closet/crate/necropolis/bubblegum/crusher)
	loot = list(/obj/structure/closet/crate/necropolis/bubblegum)
	var/charging = FALSE
	var/enrage_till = 0
	var/enrage_time = 70
	var/revving_charge = FALSE
	internal_type = /obj/item/gps/internal/primesoul
	deathmessage = "sinks into a pool of blood, fleeing the battle. You've won, for now... "
	deathsound = 'sound/magic/enter_blood.ogg'
	attack_action_types = list(/datum/action/innate/megafauna_attack/triple_charge,
								/datum/action/innate/megafauna_attack/snake_shot,
							   /datum/action/innate/megafauna_attack/hallucination_charge,
							   /datum/action/innate/megafauna_attack/hallucination_surround)
	small_sprite_type = /datum/action/small_sprite/megafauna/bubblegum

/mob/living/simple_animal/hostile/megafauna/primesoul/Initialize()
	. = ..()
	if(true_spawn)
		for(var/mob/living/simple_animal/hostile/megafauna/primesoul/B in GLOB.mob_living_list)
			if(B != src)
				return INITIALIZE_HINT_QDEL //There can be only one

/datum/action/innate/megafauna_attack/triple_charge
	name = "Triple Charge"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"
	chosen_message = span_colossus("You are now triple charging at the target you click on.")
	chosen_attack_num = 1

/datum/action/innate/megafauna_attack/hallucination_charge
	name = "Hallucination Charge"
	icon_icon = 'icons/effects/bubblegum.dmi'
	button_icon_state = "smack ya one"
	chosen_message = span_colossus("You are now charging with hallucinations at the target you click on.")
	chosen_attack_num = 2

/datum/action/innate/megafauna_attack/hallucination_surround
	name = "Surround Target"
	icon_icon = 'icons/turf/walls/wall.dmi'
	button_icon_state = "wall"
	chosen_message = span_colossus("You are now surrounding the target you click on with hallucinations.")
	chosen_attack_num = 3

/datum/action/innate/megafauna_attack/snake_shot
	name = "Snake Shot"
	icon_icon = 'icons/effects/bubblegum.dmi'
	button_icon_state = "smack ya one"
	chosen_message = span_colossus("You are now shooting a projectile at the target you click on.")
	chosen_attack_num = 4

/mob/living/simple_animal/hostile/megafauna/primesoul/death(gibbed, var/list/force_grant)
	.=..()
	if(true_spawn && !(flags_1 & ADMIN_SPAWNED_1))
		GLOB.bubblegum_dead = TRUE
		var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
		if(D)
			D.adjust_money(maxHealth * MEGAFAUNA_CASH_SCALE)
		for(var/mob/living/L in view(7,src))
			if(L.client)
				SSachievements.unlock_achievement(/datum/achievement/bubblegum, L.client)

/mob/living/simple_animal/hostile/megafauna/primesoul/OpenFire()
	if(charging)
		return

	anger_modifier = clamp(((maxHealth - health)/60),0,20)
	enrage_time = initial(enrage_time) * clamp(anger_modifier / 20, 0.5, 1)
	ranged_cooldown = world.time + 50

	if(client)
		switch(chosen_attack)
			if(1)
				triple_charge()
			if(2)
				hallucination_charge()
			if(3)
				surround_with_hallucinations()
			if(4)
				snake_shot()
		return

	if(!BUBBLEGUM_SMASH)
		triple_charge()
	else
		if(prob(50 + anger_modifier))
			hallucination_charge()
		else
			surround_with_hallucinations()

/mob/living/simple_animal/hostile/megafauna/primesoul/proc/triple_charge()
	charge(delay = 6)
	charge(delay = 4)
	charge(delay = 2)
	SetRecoveryTime(15)

/mob/living/simple_animal/hostile/megafauna/primesoul/proc/hallucination_charge()
	if(!BUBBLEGUM_SMASH || prob(33))
		hallucination_charge_around(times = 6, delay = 8)
		SetRecoveryTime(10)
	else
		hallucination_charge_around(times = 4, delay = 9)
		hallucination_charge_around(times = 4, delay = 8)
		hallucination_charge_around(times = 4, delay = 7)
		triple_charge()
		SetRecoveryTime(20)

/mob/living/simple_animal/hostile/megafauna/primesoul/proc/surround_with_hallucinations()
	for(var/i = 1 to 5)
		INVOKE_ASYNC(src, .proc/hallucination_charge_around, 2, 8, 2, 0, 4)
		if(ismob(target))
			charge(delay = 6)
	SetRecoveryTime(20)

/mob/living/simple_animal/hostile/megafauna/primesoul/proc/snake_shot(var/atom/shootat = target)
	Shoot(target)
	
/mob/living/simple_animal/hostile/megafauna/primesoul/proc/charge(var/atom/chargeat = target, var/delay = 3, var/chargepast = 2)
	if(!chargeat)
		return
	var/chargeturf = get_turf(chargeat)
	if(!chargeturf)
		return
	var/dir = get_dir(src, chargeturf)
	var/turf/T = get_ranged_target_turf(chargeturf, dir, chargepast)
	if(!T)
		return
	new /obj/effect/temp_visual/dragon_swoop/bubblegum(T)
	charging = TRUE
	revving_charge = TRUE
	DestroySurroundings()
	walk(src, 0)
	setDir(dir)
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc,src)
	animate(D, alpha = 0, color = "#FF0000", transform = matrix()*2, time = 0.3 SECONDS)
	SLEEP_CHECK_DEATH(delay)
	revving_charge = FALSE
	var/movespeed = 0.7
	walk_towards(src, T, movespeed)
	SLEEP_CHECK_DEATH(get_dist(src, T) * movespeed)
	walk(src, 0) // cancel the movement
	charging = FALSE

/mob/living/simple_animal/hostile/megafauna/primesoul/proc/be_aggressive()
	if(BUBBLEGUM_IS_ENRAGED)
		return TRUE
	if(isliving(target))
		var/mob/living/livingtarget = target
		return (livingtarget.stat != CONSCIOUS || !(livingtarget.mobility_flags & MOBILITY_STAND))
	return FALSE

/mob/living/simple_animal/hostile/megafauna/primesoul/proc/get_retreat_distance()
	return (be_aggressive() ? null : initial(retreat_distance))

/mob/living/simple_animal/hostile/megafauna/primesoul/proc/get_minimum_distance()
	return (be_aggressive() ? 1 : initial(minimum_distance))

/mob/living/simple_animal/hostile/megafauna/primesoul/proc/update_approach()
	retreat_distance = get_retreat_distance()
	minimum_distance = get_minimum_distance()

/mob/living/simple_animal/hostile/megafauna/primesoul/proc/blood_enrage()
	if(!BUBBLEGUM_CAN_ENRAGE)
		return FALSE
	enrage_till = world.time + enrage_time
	update_approach()
	change_move_delay(3.75)
	var/newcolor = rgb(149, 10, 10)
	add_atom_colour(newcolor, TEMPORARY_COLOUR_PRIORITY)
	var/datum/callback/cb = CALLBACK(src, .proc/blood_enrage_end)
	addtimer(cb, enrage_time)

/mob/living/simple_animal/hostile/megafauna/primesoul/proc/blood_enrage_end(var/newcolor = rgb(149, 10, 10))
	update_approach()
	change_move_delay()
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, newcolor)

/mob/living/simple_animal/hostile/megafauna/primesoul/proc/change_move_delay(var/newmove = initial(move_to_delay))
	move_to_delay = newmove
	set_varspeed(move_to_delay)
	handle_automated_action() // need to recheck movement otherwise move_to_delay won't update until the next checking aka will be wrong speed for a bit

/mob/living/simple_animal/hostile/megafauna/primesoul/proc/hallucination_charge_around(var/times = 4, var/delay = 6, var/chargepast = 0, var/useoriginal = 1, var/radius)
	var/startingangle = rand(1, 360)
	if(!target)
		return
	var/turf/chargeat = get_turf(target)
	var/srcplaced = FALSE
	if(!radius)
		radius = times
	for(var/i = 1 to times)
		var/ang = (startingangle + 360/times * i)
		if(!chargeat)
			return
		var/turf/place = locate(chargeat.x + cos(ang) * radius, chargeat.y + sin(ang) * radius, chargeat.z)
		if(!place)
			continue
		if(!nest || nest && nest.parent && get_dist(nest.parent, place) <= nest_range)
			if(!srcplaced && useoriginal)
				forceMove(place)
				srcplaced = TRUE
				continue
		var/mob/living/simple_animal/hostile/megafauna/primesoul/hallucination/B = new /mob/living/simple_animal/hostile/megafauna/primesoul/hallucination(src.loc)
		B.forceMove(place)
		INVOKE_ASYNC(B, .proc/charge, chargeat, delay, chargepast)
	if(useoriginal)
		charge(chargeat, delay, chargepast)

/obj/item/gps/internal/primesoul
	icon_state = null
	gpstag = "Bloody Signal"
	desc = "You're not quite sure how a signal can be bloody."
	invisibility = 100

/mob/living/simple_animal/hostile/megafauna/primesoul/do_attack_animation(atom/A, visual_effect_icon)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/megafauna/primesoul/AttackingTarget()
	if(!charging)
		. = ..()
		if(.)
			recovery_time = world.time + 20 // can only attack melee once every 2 seconds but rapid_melee gives higher priority

/mob/living/simple_animal/hostile/megafauna/primesoul/bullet_act(obj/item/projectile/P)
	if(BUBBLEGUM_IS_ENRAGED)
		visible_message(span_danger("[src] deflects the projectile; [p_they()] can't be hit with ranged weapons while enraged!"), span_userdanger("You deflect the projectile!"))
		playsound(src, pick('sound/weapons/bulletflyby.ogg', 'sound/weapons/bulletflyby2.ogg', 'sound/weapons/bulletflyby3.ogg'), 300, 1)
		return BULLET_ACT_BLOCK
	return ..()

/mob/living/simple_animal/hostile/megafauna/primesoul/ex_act(severity, target)
	if(severity >= EXPLODE_LIGHT)
		return
	severity = EXPLODE_LIGHT // puny mortals
	return ..()

/mob/living/simple_animal/hostile/megafauna/primesoul/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(istype(mover, /mob/living/simple_animal/hostile/megafauna/primesoul/hallucination))
		return TRUE

/mob/living/simple_animal/hostile/megafauna/primesoul/Goto(target, delay, minimum_distance)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/megafauna/primesoul/MoveToTarget(list/possible_targets)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/megafauna/primesoul/Move()
	update_approach()
	if(revving_charge)
		return FALSE
	if(charging)
		new /obj/effect/temp_visual/decoy/fading(loc,src)
		DestroySurroundings()
	..()

/mob/living/simple_animal/hostile/megafauna/primesoul/Moved(atom/OldLoc, Dir, Forced = FALSE)
	if(charging)
		DestroySurroundings()
	playsound(src, 'sound/effects/meteorimpact.ogg', 200, 1, 2, 1)
	return ..()

/mob/living/simple_animal/hostile/megafauna/primesoul/Bump(atom/A)
	if(charging)
		if(isturf(A) || isobj(A) && A.density)
			if(isobj(A))
				SSexplosions.med_mov_atom += A
			else
				SSexplosions.medturf += A
		DestroySurroundings()
		if(isliving(A))
			var/mob/living/L = A
			L.visible_message(span_danger("[src] slams into [L]!"), span_userdanger("[src] tramples you into the ground!"))
			src.forceMove(get_turf(L))
			L.apply_damage(istype(src, /mob/living/simple_animal/hostile/megafauna/primesoul/hallucination) ? 15 : 30, BRUTE, wound_bonus = CANT_WOUND)
			playsound(get_turf(L), 'sound/effects/meteorimpact.ogg', 100, 1)
			shake_camera(L, 4, 3)
			shake_camera(src, 2, 3)
	..()

/obj/effect/temp_visual/dragon_swoop/primesoul
	duration = 10

/mob/living/simple_animal/hostile/megafauna/primesoul/hallucination
	name = "afterimage"
	desc = "He's fast!"
	health = 1
	maxHealth = 1
	alpha = 127.5
	crusher_loot = null
	loot = null
	deathmessage = "fades away!"
	true_spawn = FALSE

/obj/item/projectile/primesoul
	name ="snake bolt"
	icon_state= "seedling"
	damage = 25
	armour_penetration = 100
	speed = 10
	damage_type = BRUTE
	pass_flags = PASSTABLE
	var/parrydist = 2

/obj/item/projectile/reflected
	name ="reflected snake bolt"
	icon_state= "plasma"
	damage = 25
	armour_penetration = 100
	speed = 0.5
	damage_type = BRUTE
	pass_flags = PASSTABLE
	var/parrydist = 2

/obj/item/projectile/primesoul/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	var/target = src.firer
	if(get_dist(src, user) > parrydist)
		return
	else
		user.gib()
		qdel(src)
		var/turf/startloc = get_turf(user)
		var/obj/item/projectile/P = new /obj/item/projectile/reflected(startloc)
		P.fire(target)

/mob/living/simple_animal/hostile/megafauna/primesoul/hallucination/Initialize()
	..()
	toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/megafauna/primesoul/hallucination/charge(var/atom/chargeat = target, var/delay = 3, var/chargepast = 2)
	..()
	qdel(src)

/mob/living/simple_animal/hostile/megafauna/primesoul/hallucination/Destroy()
	new /obj/effect/decal/cleanable/blood(get_turf(src))
	. = ..()

/mob/living/simple_animal/hostile/megafauna/primesoul/hallucination/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(istype(mover, /mob/living/simple_animal/hostile/megafauna/primesoul)) // hallucinations should not be stopping bubblegum or eachother
		return TRUE

/mob/living/simple_animal/hostile/megafauna/primesoul/hallucination/Life()
	return

/mob/living/simple_animal/hostile/megafauna/primesoul/hallucination/adjustBruteLoss(amount, updating_health = TRUE, forced = FALSE)
	return

/mob/living/simple_animal/hostile/megafauna/primesoul/hallucination/OpenFire()
	return

/mob/living/simple_animal/hostile/megafauna/primesoul/hallucination/AttackingTarget()
	return
