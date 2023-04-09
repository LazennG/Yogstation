#define COOLDOWN_RECALL 50
/obj/item/dopmirror
	name = "ominous mirror"
	desc = "What do you see looking back at you?"
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "mirrornormal"
	actions_types = list(/datum/action/item_action/recall)
	var/possessed = FALSE
	var/list/reflection = list()
	var/next_recall = 0
	var/mob/living/carbon/original = null

/obj/item/dopmirror/pickup(mob/user)
	..()
	original = user

/obj/item/dopmirror/attack_self(mob/living/user)
	if(possessed)
		return
	if(!(GLOB.ghost_role_flags & GHOSTROLE_STATION_SENTIENCE))
		to_chat(user, span_notice("Anomalous otherworldly energies keep the mirror from reflecting anything!"))
		return

	to_chat(user, "You peer into the mirror...")
	possessed = TRUE
	var/list/mob/dead/observer/candidates = pollGhostCandidates("Do you want to play as the living reflection in service of [user.real_name]?", ROLE_PAI, null, FALSE, 100, POLL_IGNORE_POSSESSED_BLADE)
	if(LAZYLEN(candidates))
		var/mob/dead/observer/C = pick(candidates)
		var/mob/living/simple_animal/hostile/double/S = new(src)
		reflection |= S
		S.ckey = C.ckey
		S.fully_replace_character_name(null, "living reflection")
		S.copy_languages(user, LANGUAGE_MASTER)	
		S.update_atom_languages()
		S.mirror = src
		S.faction = user.faction
		grant_all_languages(FALSE, FALSE, TRUE)
		to_chat(user, "... and you see your reflection trying to leave!")
		playsound(src, 'sound/effects/glassbr2.ogg', 75)
		src.update_icon()
	else
		to_chat(user, "... and your reflection stares back at you. Try again later.")
		possessed = FALSE

/obj/item/dopmirror/Destroy()
	for(var/mob/living/simple_animal/hostile/double/S in reflection)
		to_chat(S, "You were destroyed along with the mirror!")
		qdel(S)
	return ..()


/obj/item/dopmirror/ui_action_click(mob/living/user, action)
	if(istype(action, /datum/action/item_action/recall))
		if(next_recall > world.time)
			to_chat(user, span_warning("You can't do that yet!"))
			return
		if(reflection.len < 1)
			to_chat(user, span_notice("You don't have anything to call back!"))
			return
		playsound(src, 'sound/effects/glassknock.ogg', 75)
		to_chat(user, span_notice("You knock on the mirror and call your reflection back into focus."))
		for(var/mob/living/simple_animal/hostile/double/doppelganger in reflection)
			doppelganger.forceMove(src)
		update_icon(inhabited = TRUE)
		next_recall = world.time + COOLDOWN_RECALL

/obj/item/dopmirror/update_icon(inhabited = FALSE)
	if(inhabited == TRUE)
		icon_state = "mirrornormal"
		return
	icon_state = "mirrorcrack"
	return

/obj/item/dopmirror/dropped(mob/user, silent)
	. = ..()
	if(src in user)
		return
	original = null

//doppelganger code

/mob/living/simple_animal/hostile/double
	name = "living reflection"
	real_name = "living reflection"
	desc = "A bound spirit."
	gender = PLURAL
	icon = 'icons/mob/mob.dmi'
	icon_state = "shade"
	icon_living = "shade"
	mob_biotypes = list(MOB_SPIRIT)
	maxHealth = 20
	health = 20
	speed = -1
	projectiletype = /obj/item/projectile/doppshot
	projectilesound = 'sound/weapons/pierce.ogg'
	ranged = TRUE
	ranged_message = "fires at"
	ranged_cooldown_time = 25
	see_in_dark = 8
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	spacewalk = TRUE
	speak_emote = list("echoes")
	melee_damage_lower = 14
	melee_damage_upper = 14
	obj_damage = 10
	attacktext = "metaphysically strikes"
	minbodytemp = 0
	maxbodytemp = INFINITY
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	movement_type = FLYING
	var/obj/item/dopmirror/mirror = null// the mirror that's returned to on dying
	var/melee_fauna_bonus = 36
	var/hibernating = FALSE
	var/move_range = 20
	var/datum/action/innate/jumpback/jumpback
	var/datum/action/innate/appear/appear
	var/datum/action/innate/swap/swap

/mob/living/simple_animal/hostile/double/Initialize()
	. = ..()
	to_chat(src, span_warning("<b>You are a reflection of your mirror's holder and bound to help whoever you may take the form of.</b>"))
	to_chat(src, span_warning("<b>You are moderately strong and are able to deal stronger blows to typical lavaland fauna.</b>"))
	to_chat(src, span_warning("<b>You are fragile but cannot truly be destroyed until the mirror is. You are able to heal while inside the mirror, and losing will seal you\
	inside of it for 20 seconds.</b>"))
	jumpback = new
	jumpback.Grant(src)
	appear = new
	appear.Grant(src)
	swap = new
	swap.Grant(src)

/mob/living/simple_animal/hostile/double/Bump(atom/A)
	. = ..()
	if(ismineralturf(A))
		var/turf/closed/mineral/M = A
		M.attempt_drill()

/mob/living/simple_animal/hostile/double/death()
	playsound(src, 'sound/effects/glassbr3.ogg', 75)
	src.forceMove(mirror)
	hibernating = TRUE
	appearance = mirror.original.appearance
	for(jumpback in src.actions)
		jumpback.Activate()
	for(var/datum/action/innate/appear/appear in src.actions)
		appear.Activate(died = TRUE)
	return FALSE // want the way to kill it being linked directly to the mirror


/mob/living/simple_animal/hostile/double/Life()
	if(hibernating == TRUE)
		src.heal_bodypart_damage(3)

/mob/living/simple_animal/hostile/double/Move(NewLoc, Dir = 0)
	. = ..()
	if(hibernating == TRUE)
		hibernating = FALSE
	if(get_dist(src,mirror) > move_range)
		to_chat(src, span_notice("You can't move that far from the mirror and are called back!"))
		for(jumpback in src.actions)
			jumpback.Activate()

/mob/living/simple_animal/hostile/double/AttackingTarget()
	..()
	var/mob/living/simple_animal/M = target
	if(ismegafauna(M) || istype(M, /mob/living/simple_animal/hostile/asteroid))
		M.apply_damage(melee_fauna_bonus, BRUTE)


/mob/living/simple_animal/hostile/double/dust(just_ash, drop_items, force)
	death()

/mob/living/simple_animal/hostile/double/gib()
	death()

//reflection's abilities

/datum/action/innate/jumpback
	name = "Return to Mirror"
	icon_icon = 'icons/obj/lavaland/artefacts.dmi'
	button_icon_state = "mirrornormal"

/datum/action/innate/jumpback/Activate()
	var/mob/living/simple_animal/hostile/double/doppelganger = owner
	doppelganger.forceMove(doppelganger.mirror)
	doppelganger.hibernating = TRUE
	doppelganger.mirror.update_icon(inhabited = TRUE)
	doppelganger.appearance = doppelganger.mirror.original.appearance
	doppelganger.alpha = 130
	playsound(doppelganger, 'sound/effects/glassknock.ogg', 75)


#define RESET_TIME 200
/datum/action/innate/appear
	name = "Exit Mirror"
	icon_icon = 'icons/obj/lavaland/artefacts.dmi'
	button_icon_state = "mirrorcrack"
	var/next_appearance = 0

/datum/action/innate/appear/Activate(died = FALSE)
	var/mob/living/simple_animal/hostile/double/doppelganger = owner
	var/turf/M = get_turf(doppelganger.mirror)
	if(next_appearance > world.time)
		to_chat(doppelganger, span_warning("You can't leave the mirror yet!"))
		return
	if(doppelganger.mirror.original == null) //for the sake of avoiding setting up play dates with megafauna
		to_chat(doppelganger, span_warning("You can't leave the mirror without an original to copy!"))
		return
	doppelganger.mirror.update_icon()
	if(died == TRUE)
		next_appearance = world.time + RESET_TIME
		return
	doppelganger.forceMove(M)
	doppelganger.appearance = doppelganger.mirror.original.appearance
	doppelganger.alpha = 130


#define SWAP_TIME 150
/datum/action/innate/swap
	name = "Swap"
	icon_icon = 'icons/obj/lavaland/artefacts.dmi'
	button_icon_state = "mirrorcrack"
	var/next_swap = 0

/datum/action/innate/swap/Activate(died = FALSE)
	var/mob/living/simple_animal/hostile/double/doppelganger = owner
	var/turf/going = get_turf(doppelganger.mirror)
	var/turf/doppspot = get_turf(doppelganger)
	if(next_swap > world.time)
		to_chat(doppelganger, span_warning("You can't leave the mirror yet!"))
		return
	if(doppelganger.buckled)
		return
	if(istype(doppspot, /turf/open/chasm)) 
		to_chat(doppelganger, span_warning("You probably shouldn't risk the mirror falling from such a height."))
		return
	if(istype(doppspot, /turf/open/lava)) 
		to_chat(doppelganger, span_warning("You probably shouldn't risk the mirror falling into lava."))
		return
	next_swap = world.time + SWAP_TIME
	doppelganger.forceMove(going)
	doppelganger.mirror.original.forceMove(doppspot)
	playsound(going, 'sound/effects/bamf.ogg', 50)
	playsound(doppspot, 'sound/effects/bamf.ogg', 50)
	to_chat(doppelganger, span_warning("You exchange places with the mirror's holder!"))


/obj/item/projectile/doppshot
	name = "mirrored shot"
	icon_state = "greyscale_bolt"
	nodamage = TRUE //for the sake of welding tanks
	damage_type = BRUTE
	damage = 0
	var/actual_damage = 5
	var/ranged_fauna_bonus = 15

/obj/item/projectile/doppshot/on_hit(atom/target, blocked = FALSE)
	var/mob/living/M = target
	M.apply_damage(actual_damage, BRUTE)
	if(ismegafauna(M) || istype(M, /mob/living/simple_animal/hostile/asteroid))
		M.apply_damage(ranged_fauna_bonus, BRUTE)
