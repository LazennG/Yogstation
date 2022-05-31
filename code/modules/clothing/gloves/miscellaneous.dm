
/obj/item/clothing/gloves/fingerless
	name = "fingerless gloves"
	desc = "Plain black gloves without fingertips for the hard working."
	icon_state = "fingerless"
	item_state = "fingerless"
	item_color = null	//So they don't wash.
	transfer_prints = TRUE
	strip_delay = 40
	equip_delay_other = 20
	cold_protection = HANDS
	min_cold_protection_temperature = GLOVES_MIN_TEMP_PROTECT
	custom_price = 10

/obj/item/clothing/gloves/botanic_leather
	name = "botanist's leather gloves"
	desc = "These leather gloves protect against thorns, barbs, prickles, spikes and other harmful objects of floral origin.  They're also quite warm."
	icon_state = "leather"
	item_state = "ggloves"
	permeability_coefficient = 0.9
	cold_protection = HANDS
	min_cold_protection_temperature = GLOVES_MIN_TEMP_PROTECT
	heat_protection = HANDS
	max_heat_protection_temperature = GLOVES_MAX_TEMP_PROTECT
	resistance_flags = NONE
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 70, ACID = 30)

/obj/item/clothing/gloves/combat
	name = "combat gloves"
	desc = "These tactical gloves are fireproof and shock resistant."
	icon_state = "black"
	item_state = "blackgloves"
	siemens_coefficient = 0
	permeability_coefficient = 0.05
	strip_delay = 80
	cold_protection = HANDS
	min_cold_protection_temperature = GLOVES_MIN_TEMP_PROTECT
	heat_protection = HANDS
	max_heat_protection_temperature = GLOVES_MAX_TEMP_PROTECT
	resistance_flags = NONE
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 80, ACID = 50)

/obj/item/clothing/gloves/bracer
	name = "bone bracers"
	desc = "For when you're expecting to get slapped on the wrist. Offers modest protection to your arms."
	icon_state = "bracers"
	item_state = "bracers"
	item_color = null	//So they don't wash.
	transfer_prints = TRUE
	strip_delay = 40
	equip_delay_other = 20
	body_parts_covered = ARMS
	cold_protection = ARMS
	min_cold_protection_temperature = GLOVES_MIN_TEMP_PROTECT
	max_heat_protection_temperature = GLOVES_MAX_TEMP_PROTECT
	resistance_flags = NONE
	armor = list(MELEE = 15, BULLET = 25, LASER = 15, ENERGY = 15, BOMB = 20, BIO = 10, RAD = 0, FIRE = 0, ACID = 0)

/obj/item/clothing/gloves/rapid
	name = "Gloves of the North Star"
	desc = "Just looking at these fills you with an urge to beat the shit out of people."
	icon_state = "rapid"
	item_state = "rapid"
	transfer_prints = TRUE
	var/warcry = "AT"

/obj/item/clothing/gloves/rapid/Touch(mob/living/target,proximity = TRUE)
	var/mob/living/M = loc

	if(M.a_intent == INTENT_HARM)
		M.changeNext_move(CLICK_CD_RAPID)
		if(warcry)
			M.say("[warcry]", ignore_spam = TRUE, forced = "north star warcry")
	.= FALSE

/obj/item/clothing/gloves/rapid/attack_self(mob/user)
	var/input = stripped_input(user,"What do you want your battlecry to be? Max length of 6 characters.", ,"", 7)
	input = replacetext(input, "*", "")
	if(input)
		warcry = input

/obj/item/clothing/gloves/rapid/hug
	name = "Gloves of Hugging"
	desc = "Just looking at these fills you with an urge to hug the shit out of people."

/obj/item/clothing/gloves/rapid/hug/Touch(mob/living/target,proximity = TRUE)
	var/mob/living/M = loc

	if(M.a_intent == INTENT_HELP)
		M.changeNext_move(CLICK_CD_RAPID)
	else
		to_chat(M, span_warning("You don't want to hurt anyone, just give them hugs!"))
		M.a_intent = INTENT_HELP
	.= FALSE

/obj/item/clothing/gloves/bracer/cuffs
	name = "rabid cuffs"
	desc = "Chainless manacles fashioned after the hungriest of slaughter demons. Grants the wearer a similar hunger that can be sated in a similar way."
	icon_state = "cuff"
	item_state = "cuff"
	var/obj/effect/proc_holder/swipe/swipe_ability

/obj/item/clothing/gloves/bracer/cuffs/Initialize()
	. = ..()
	swipe_ability = new(swipe_ability)

/obj/item/clothing/gloves/bracer/cuffs/equipped(mob/living/user, slot)
	. = ..()
	if(ishuman(user) && slot == ITEM_SLOT_GLOVES)
		user.AddAbility(swipe_ability)

/obj/item/clothing/gloves/bracer/cuffs/dropped(mob/living/user)
	. = ..()
	user.RemoveAbility(swipe_ability)

obj/effect/proc_holder/swipe
	name = "swipe"
	desc = "Swipe at a target area, dealing damage and consuming dead creatures to heal yourself. People are ineligible for total consumption. Creatures take 30 damage and heal the most while people and cyborgs take 10 damage and heal for the least. People that have been thoroughly burned and bruised heal you for a bit more than those that aren't."
	action_background_icon_state = "bg_demon"
	action_icon = 'icons/mob/actions/actions_items.dmi'
	action_icon_state = "cuff"
	ranged_mousepointer = 'icons/effects/mouse_pointers/supplypod_target.dmi'
	var/cooldown = 15 SECONDS
	COOLDOWN_DECLARE(scan_cooldown)

/obj/effect/proc_holder/swipe/on_lose(mob/living/user)
	remove_ranged_ability()
	
/obj/effect/proc_holder/swipe/Click(location, control, params)
	. = ..()
	if(!isliving(usr))
		return TRUE
	var/mob/living/user = usr
	fire(user)

/obj/effect/proc_holder/swipe/fire(mob/living/carbon/user)
	if(active)
		remove_ranged_ability(span_notice("You relax your arms."))
	else
		add_ranged_ability(user, span_notice("You ready your cuffs. <B>Left-click a creature or floor to swipe at it!</B>"), TRUE)

/obj/effect/proc_holder/swipe/InterceptClickOn(mob/living/caller, params, atom/target)
	. = ..()
	var/turf/open/T = get_turf(target)
	var/mob/living/L = target
	if(.)
		return
	if(ranged_ability_user.stat)
		remove_ranged_ability()
		return
	if(!COOLDOWN_FINISHED(src, scan_cooldown))
		to_chat(ranged_ability_user, span_warning("Your cuffs aren't ready to do that yet. Give them some time to recharge!"))
		return
	if(!istype(T))
		return
	new /obj/effect/temp_visual/bubblegum_hands/rightpaw(T)
	new /obj/effect/temp_visual/bubblegum_hands/rightthumb(T)
	to_chat(L, span_userdanger("A claw swipes at you!"))
	to_chat(ranged_ability_user, "You summon claws at [L]'s location!")
	for(L in range(0,T))
		if(isanimal(L))
			L.adjustBruteLoss(30)
			if(L.stat == DEAD)
				L.gib()
				caller.adjustBruteLoss(-20)
				caller.adjustFireLoss(-20)
				caller.adjustToxLoss(-20)
				caller.blood_volume = BLOOD_VOLUME_NORMAL(caller)*1.10
		L.adjustBruteLoss(10)
		if(L.getBruteLoss()+L.getFireLoss() >= 299)
			to_chat(caller, span_notice("You're able to consume a bit more as the body has been softened up!"))
			caller.adjustBruteLoss(-15)
			caller.adjustFireLoss(-15)
			caller.adjustToxLoss(-15)
			caller.blood_volume = BLOOD_VOLUME_NORMAL(caller)*1.05
		if(L.stat == DEAD)
			caller.adjustBruteLoss(-5)
			caller.adjustFireLoss(-5)
			caller.adjustToxLoss(-5)
			caller.blood_volume = BLOOD_VOLUME_NORMAL(caller)*1.01
	COOLDOWN_START(src, scan_cooldown, cooldown)
	addtimer(CALLBACK(src, .proc/cooldown_over, ranged_ability_user), cooldown)
	remove_ranged_ability()
	return TRUE

/obj/effect/proc_holder/swipe/proc/cooldown_over()
	to_chat(usr, (span_notice("You're ready to swipe again!")))
