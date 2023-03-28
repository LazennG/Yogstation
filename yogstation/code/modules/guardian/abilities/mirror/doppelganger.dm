///put the mirror type in here so arrow holoparas dont run the risk of getting it

/datum/guardian_ability/major/doppelganger
	name = "Doppelganger"
	desc = "The guardian can burrow through rock and its attacks especially affect fauna."
	has_mode = TRUE
	recall_mode = TRUE
	mode_on_msg = span_bolddanger("You switch to scout mode.")
	mode_off_msg = span_bolddanger("You switch to combat mode.")
	var/melee_animal_damage = 30
	guardian.ranged = 10
	var/fauna_bonus_damage = 40
	var/animal_damage_type = BRUTE

/datum/guardian_ability/major/doppelganger/proc/copy_look(mob/living/copycat, mob/living/copied)
	copycat.appearance = copied.appearance
	return


/datum/guardian_ability/major/doppelganger/Attack(atom/target)
	if (isanimal(target))
		var/mob/living/L = target
		L.apply_damage(melee_animal_damage,animal_damage_type)
		to_chat(L, span_userdanger("The apparition tears into you!"))
