/*
 * Vending machine types - Can be found under /code/modules/vending/
 */

/*
/obj/machinery/vending/[vendors name here]   // --vending machine template   :)
	name = ""
	desc = ""
	icon = ''
	icon_state = ""
	products = list()
	contraband = list()
	premium = list()
IF YOU MODIFY THE PRODUCTS LIST OF A MACHINE, MAKE SURE TO UPDATE ITS RESUPPLY CANISTER CHARGES in vending_items.dm
*/

#define MAX_VENDING_INPUT_AMOUNT 30
/**
  * # vending record datum
  *
  * A datum that represents a product that is vendable
  */
/datum/data/vending_product
	name = "generic"
	///Typepath of the product that is created when this record "sells"
	var/product_path = null
	///How many of this product we currently have
	var/amount = 0
	///How many we can store at maximum
	var/max_amount = 0
	///Does the item have a custom price override
	var/custom_price
	///Does the item have a custom premium price override
	var/custom_premium_price
	///Whether spessmen with an ID with an age below AGE_MINOR (21 by default) can buy this item
	var/age_restricted = FALSE

/**
  * # vending machines
  *
  * Captalism in the year 2525, everything in a vending machine, even love
  */
/obj/machinery/vending
	name = "\improper Vendomat"
	desc = "A generic vending machine."
	icon = 'icons/obj/vending.dmi'
	icon_state = "generic"
	layer = BELOW_OBJ_LAYER
	density = TRUE
	verb_say = "beeps"
	verb_ask = "beeps"
	verb_exclaim = "beeps"
	max_integrity = 300
	integrity_failure = 100
	armor = list("melee" = 20, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 70)
	circuit = /obj/item/circuitboard/machine/vendor
	payment_department = ACCOUNT_SRV
	/// Is the machine active (No sales pitches if off)!
	var/active = 1
	///Are we ready to vend?? Is it time??
	var/vend_ready = 1
	///Next world time to send a purchase message
	var/purchase_message_cooldown
	///Last mob to shop with us
	var/last_shopper
	var/tilted = FALSE
	var/tiltable = TRUE
	var/squish_damage = 75
	var/forcecrit = 0
	var/num_shards = 7
	var/list/pinned_mobs = list()


	/**
	  * List of products this machine sells
	  *
	  *	form should be list(/type/path = amount, /type/path2 = amount2)
	  */
	var/list/products	= list()

	/**
	  * List of products this machine sells when you hack it
	  *
	  *	form should be list(/type/path = amount, /type/path2 = amount2)
	  */
	var/list/contraband	= list()

	/**
	  * List of premium products this machine sells
	  *
	  *	form should be list(/type/path, /type/path2) as there is only ever one in stock
	  */
	var/list/premium 	= list()

	///String of slogans separated by semicolons, optional
	var/product_slogans = ""
	///String of small ad messages in the vending screen - random chance
	var/product_ads = ""

	var/list/product_records = list()
	var/list/hidden_records = list()
	var/list/coin_records = list()
	var/list/slogan_list = list()
	///Small ad messages in the vending screen - random chance of popping up whenever you open it
	var/list/small_ads = list()
	///Message sent post vend (Thank you for shopping!)
	var/vend_reply
	///Last world tick we sent a vent reply
	var/last_reply = 0
	///Last world tick we sent a slogan message out
	var/last_slogan = 0
	///How many ticks until we can send another
	var/slogan_delay = 6000
	///Icon when vending an item to the user
	var/icon_vend
	///Icon to flash when user is denied a vend
	var/icon_deny
	///World ticks the machine is electified for
	var/seconds_electrified = MACHINE_NOT_ELECTRIFIED
	///When this is TRUE, we fire items at customers! We're broken!
	var/shoot_inventory = 0
	///How likely this is to happen (prob 100)
	var/shoot_inventory_chance = 2
	//Stop spouting those godawful pitches!
	var/shut_up = 0
	///can we access the hidden inventory?
	var/extended_inventory = 0
	///Are we checking the users ID
	var/scan_id = 1
	///Coins that we accept?
	var/obj/item/coin/coin
	///Bills we accept?
	var/obj/item/stack/spacecash/bill
	var/chef_price = 10
	///Default price of items if not overridden
	var/default_price = 25
	///Default price of premium items if not overridden
	var/extra_price = 50
	///Whether our age check is currently functional
	var/age_restrictions = TRUE
	/**
	  * Is this item on station or not
	  *
	  * if it doesn't originate from off-station during mapload, everything is free
	  */
	var/onstation = TRUE
	///ID's that can load this vending machine wtih refills
	var/list/canload_access_list

	var/list/vending_machine_input = list()
	///Display header on the input view
	var/input_display_header = "Custom Compartment"

	//The type of refill canisters used by this machine.
	var/obj/item/vending_refill/refill_canister = null

	/// used for narcing on underages
	var/obj/item/radio/alertradio

/obj/item/circuitboard
    ///determines if the circuit board originated from a vendor off station or not.
	var/onstation = TRUE

/**
  * Initialize the vending machine
  *
  * Builds the vending machine inventory, sets up slogans and other such misc work
  *
  * This also sets the onstation var to:
  * * FALSE - if the machine was maploaded on a zlevel that doesn't pass the is_station_level check
  * * TRUE - all other cases
  */
/obj/machinery/vending/Initialize(mapload)
	var/build_inv = FALSE
	if(!refill_canister)
		circuit = null
		build_inv = TRUE
	. = ..()
	wires = new /datum/wires/vending(src)
	if(build_inv) //non-constructable vending machine
		build_inventory(products, product_records)
		build_inventory(contraband, hidden_records)
		build_inventory(premium, coin_records)

	slogan_list = splittext(product_slogans, ";")
	// So not all machines speak at the exact same time.
	// The first time this machine says something will be at slogantime + this random value,
	// so if slogantime is 10 minutes, it will say it at somewhere between 10 and 20 minutes after the machine is crated.
	last_slogan = world.time + rand(0, slogan_delay)
	power_change()

	if(mapload) //check if it was initially created off station during mapload.
		if(!is_station_level(z))
			onstation = FALSE
			if(circuit)
				circuit.onstation = onstation //sync up the circuit so the pricing schema is carried over if it's reconstructed.
	else if(circuit && (circuit.onstation != onstation)) //check if they're not the same to minimize the amount of edited values.
		onstation = circuit.onstation //if it was constructed outside mapload, sync the vendor up with the circuit's var so you can't bypass price requirements by moving / reconstructing it off station.
	if(isnull(alertradio))
		alertradio = new(src)
	alertradio.listening = 0
	alertradio.set_frequency(FREQ_SECURITY)

/obj/machinery/vending/Destroy()
	QDEL_NULL(alertradio)
	QDEL_NULL(wires)
	QDEL_NULL(coin)
	QDEL_NULL(bill)
	return ..()

/obj/machinery/vending/can_speak()
	return !shut_up

/obj/machinery/vending/RefreshParts()         //Better would be to make constructable child
	if(!component_parts)
		return

	product_records = list()
	hidden_records = list()
	coin_records = list()
	build_inventory(products, product_records, start_empty = TRUE)
	build_inventory(contraband, hidden_records, start_empty = TRUE)
	build_inventory(premium, coin_records, start_empty = TRUE)
	for(var/obj/item/vending_refill/VR in component_parts)
		restock(VR)

/obj/machinery/vending/deconstruct(disassembled = TRUE)
	if(!refill_canister) //the non constructable vendors drop metal instead of a machine frame.
		if(!(flags_1 & NODECONSTRUCT_1))
			new /obj/item/stack/sheet/metal(loc, 3)
		qdel(src)
	else
		..()

/obj/machinery/vending/update_icon()
	if(stat & BROKEN)
		icon_state = "[initial(icon_state)]-broken"
	else
		if(powered())
			icon_state = initial(icon_state)
		else
			icon_state = "[initial(icon_state)]-off"


/obj/machinery/vending/obj_break(damage_flag)
	. = ..()
	if(!.)
		return

	var/dump_amount = 0
	var/found_anything = TRUE
	while (found_anything)
		found_anything = FALSE
		for(var/record in shuffle(product_records))
			var/datum/data/vending_product/R = record
			if(R.amount <= 0) //Try to use a record that actually has something to dump.
				continue
			var/dump_path = R.product_path
			if(!dump_path)
				continue
			R.amount--
			// busting open a vendor will destroy some of the contents
			if(found_anything && prob(80))
				continue

			var/obj/O = new dump_path(loc)
			step(O, pick(GLOB.alldirs))
			found_anything = TRUE
			dump_amount++
			if (dump_amount >= 16)
				return

GLOBAL_LIST_EMPTY(vending_products)
/**
  * Build the inventory of the vending machine from it's product and record lists
  *
  * This builds up a full set of /datum/data/vending_products from the product list of the vending machine type
  * Arguments:
  * * productlist - the list of products that need to be converted
  * * recordlist - the list containing /datum/data/vending_product datums
  * * startempty - should we set vending_product record amount from the product list (so it's prefilled at roundstart)
  */
/obj/machinery/vending/proc/build_inventory(list/productlist, list/recordlist, start_empty = FALSE)
	for(var/typepath in productlist)
		var/amount = productlist[typepath]
		if(isnull(amount))
			amount = 0

		var/atom/temp = typepath
		var/datum/data/vending_product/R = new /datum/data/vending_product()
		GLOB.vending_products[typepath] = 1
		R.name = initial(temp.name)
		R.product_path = typepath
		if(!start_empty)
			R.amount = amount
		R.max_amount = amount
		R.custom_price = initial(temp.custom_price)
		R.custom_premium_price = initial(temp.custom_premium_price)
		R.age_restricted = initial(temp.age_restricted)
		recordlist += R
/**
  * Refill a vending machine from a refill canister
  *
  * This takes the products from the refill canister and then fills the products,contraband and premium product categories
  *
  * Arguments:
  * * canister - the vending canister we are refilling from
  */
/obj/machinery/vending/proc/restock(obj/item/vending_refill/canister)
	if (!canister.products)
		canister.products = products.Copy()
	if (!canister.contraband)
		canister.contraband = contraband.Copy()
	if (!canister.premium)
		canister.premium = premium.Copy()
	. = 0
	. += refill_inventory(canister.products, product_records)
	. += refill_inventory(canister.contraband, hidden_records)
	. += refill_inventory(canister.premium, coin_records)
/**
  * Refill our inventory from the passed in product list into the record list
  *
  * Arguments:
  * * productlist - list of types -> amount
  * * recordlist - existing record datums
  */
/obj/machinery/vending/proc/refill_inventory(list/productlist, list/recordlist)
	. = 0
	for(var/R in recordlist)
		var/datum/data/vending_product/record = R
		var/diff = min(record.max_amount - record.amount, productlist[record.product_path])
		if (diff)
			productlist[record.product_path] -= diff
			record.amount += diff
			. += diff
/**
  * Set up a refill canister that matches this machines products
  *
  * This is used when the machine is deconstructed, so the items aren't "lost"
  */
/obj/machinery/vending/proc/update_canister()
	if (!component_parts)
		return

	var/obj/item/vending_refill/R = locate() in component_parts
	if (!R)
		CRASH("Constructible vending machine did not have a refill canister")

	R.products = unbuild_inventory(product_records)
	R.contraband = unbuild_inventory(hidden_records)
	R.premium = unbuild_inventory(coin_records)

/**
  * Given a record list, go through and and return a list of type -> amount
  */
/obj/machinery/vending/proc/unbuild_inventory(list/recordlist)
	. = list()
	for(var/R in recordlist)
		var/datum/data/vending_product/record = R
		.[record.product_path] += record.amount

/obj/machinery/vending/crowbar_act(mob/living/user, obj/item/I)
	if(!component_parts)
		return FALSE
	default_deconstruction_crowbar(I)
	return TRUE

/obj/machinery/vending/wrench_act(mob/living/user, obj/item/I)
	if(panel_open)
		default_unfasten_wrench(user, I, time = 60)
		unbuckle_all_mobs(TRUE)
	return TRUE

/obj/machinery/vending/screwdriver_act(mob/living/user, obj/item/I)
	if(..())
		return TRUE
	if(anchored)
		default_deconstruction_screwdriver(user, icon_state, icon_state, I)
		cut_overlays()
		if(panel_open)
			add_overlay("[initial(icon_state)]-panel")
		updateUsrDialog()
	else
		to_chat(user, span_warning("You must first secure [src]."))
	return TRUE

/obj/machinery/vending/attackby(obj/item/I, mob/user, params)
	if(panel_open && is_wire_tool(I))
		wires.interact(user)
		return
	if(refill_canister && istype(I, refill_canister))
		if (!panel_open)
			to_chat(user, span_notice("You should probably unscrew the service panel first."))
		else if (stat & (BROKEN|NOPOWER))
			to_chat(user, span_notice("[src] does not respond."))
		else
			//if the panel is open we attempt to refill the machine
			var/obj/item/vending_refill/canister = I
			if(canister.get_part_rating() == 0)
				to_chat(user, span_notice("[canister] is empty!"))
			else
				// instantiate canister if needed
				var/transferred = restock(canister)
				if(transferred)
					to_chat(user, span_notice("You loaded [transferred] items in [src]."))
				else
					to_chat(user, span_notice("There's nothing to restock!"))
			return
	if(user.a_intent != INTENT_HARM && compartmentLoadAccessCheck(user))
		if(canLoadItem(I))
			loadingAttempt(I,user)
			updateUsrDialog() //can't put this on the proc above because we spam it below

		if(istype(I, /obj/item/storage/bag)) //trays USUALLY
			var/obj/item/storage/T = I
			var/loaded = 0
			var/denied_items = 0
			for(var/obj/item/the_item in T.contents)
				if(contents.len >= MAX_VENDING_INPUT_AMOUNT) // no more than 30 item can fit inside, legacy from snack vending although not sure why it exists
					to_chat(user, span_warning("[src]'s chef compartment is full."))
					break
				if(canLoadItem(the_item) && loadingAttempt(the_item,user))
					SEND_SIGNAL(T, COMSIG_TRY_STORAGE_TAKE, the_item, src, TRUE)
					loaded++
				else
					denied_items++
			if(denied_items)
				to_chat(user, span_notice("[src] refuses some items."))
			if(loaded)
				to_chat(user, span_notice("You insert [loaded] dishes into [src]'s chef compartment."))
				updateUsrDialog()
	else
		..()
		if(tiltable && !tilted && I.force)
			switch(rand(1, 100))
				if(1 to 5)
					freebie(user, 3)
				if(6 to 15)
					freebie(user, 2)
				if(16 to 25)
					freebie(user, 1)
				if(76 to 90)
					tilt(user)
				if(91 to 100)
					tilt(user, crit=TRUE)

/obj/machinery/vending/proc/freebie(mob/fatty, freebies)
	visible_message("<span class='notice'>[src] yields [freebies > 1 ? "several free goodies" : "a free goody"]!</span>")

	for(var/i in 1 to freebies)
		for(var/datum/data/vending_product/R in shuffle(product_records))

			if(R.amount <= 0) //Try to use a record that actually has something to dump.
				continue
			var/dump_path = R.product_path
			if(!dump_path)
				continue

			R.amount--
			new dump_path(get_turf(src))
			break

/obj/machinery/vending/proc/tilt(mob/fatty, crit=FALSE)
	visible_message("<span class='danger'>[src] tips over!</span>")
	tilted = TRUE
	layer = ABOVE_MOB_LAYER

	var/crit_case
	if(crit)
		crit_case = rand(1,5)

	if(forcecrit)
		crit_case = forcecrit

	if(in_range(fatty, src))
		for(var/mob/living/L in get_turf(fatty))
			var/mob/living/carbon/C = L

			if(istype(C))
				var/crit_rebate = 0 // lessen the normal damage we deal for some of the crits

				if(crit_case != 5) // the head asplode case has its own description
					C.visible_message("<span class='danger'>[C] is crushed by [src]!</span>", \
						"<span class='userdanger'>You are crushed by [src]!</span>")

				switch(crit_case) // only carbons can have the fun crits
					if(1) // shatter their legs and bleed 'em
						crit_rebate = 60
						C.bleed(150)
						var/obj/item/bodypart/l_leg/l = C.get_bodypart(BODY_ZONE_L_LEG)
						if(l)
							l.receive_damage(brute=200, updating_health=TRUE)
						var/obj/item/bodypart/r_leg/r = C.get_bodypart(BODY_ZONE_R_LEG)
						if(r)
							r.receive_damage(brute=200, updating_health=TRUE)
						if(l || r)
							C.visible_message("<span class='danger'>[C]'s legs shatter with a sickening crunch!</span>", \
								"<span class='userdanger'>Your legs shatter with a sickening crunch!</span>")
					if(2) // pin them beneath the machine until someone untilts it
						forceMove(get_turf(C))
						buckle_mob(C, force=TRUE)
						C.visible_message("<span class='danger'>[C] is pinned underneath [src]!</span>", \
							"<span class='userdanger'>You are pinned down by [src]!</span>")
					if(3) // glass candy
						crit_rebate = 50
						for(var/i = 0, i < num_shards, i++)
							var/obj/item/shard/shard = new /obj/item/shard(get_turf(C))
							shard.embedding = shard.embedding.setRating(embed_chance = 100, embedded_ignore_throwspeed_threshold = TRUE, embedded_impact_pain_multiplier=1,embedded_pain_chance=5)
							C.hitby(shard, skipcatch = TRUE, hitpush = FALSE)
							shard.embedding = shard.embedding.setRating(embed_chance = EMBED_CHANCE, embedded_ignore_throwspeed_threshold = FALSE)
					if(4) // paralyze this binch
						// the new paraplegic gets like 4 lines of losing their legs so skip them
						visible_message("<span class='danger'>[C]'s spinal cord is obliterated with a sickening crunch!</span>")
						C.gain_trauma(/datum/brain_trauma/severe/paralysis/paraplegic)
					if(5) // skull squish!
						var/obj/item/bodypart/head/O = C.get_bodypart(BODY_ZONE_HEAD)
						if(O)
							C.visible_message("<span class='danger'>[O] explodes in a shower of gore beneath [src]!</span>", \
								"<span class='userdanger'>Oh f-</span>")
							O.dismember()
							O.drop_organs()
							qdel(O)
							new /obj/effect/gibspawner/human/bodypartless(get_turf(C))

				C.apply_damage(max(0, squish_damage - crit_rebate))
				C.AddComponent(/datum/component/squish, 18 SECONDS)
			else
				L.visible_message("<span class='danger'>[L] is crushed by [src]!</span>", \
				"<span class='userdanger'>You are crushed by [src]!</span>")
				L.apply_damage(squish_damage)
				if(crit_case)
					L.apply_damage(squish_damage)

			L.Paralyze(60)
			L.emote("scream")
			playsound(L, 'sound/effects/blobattack.ogg', 40, TRUE)
			playsound(L, 'sound/effects/splat.ogg', 50, TRUE)

	var/matrix/M = matrix()
	M.Turn(pick(90, 270))
	transform = M

	if(get_turf(fatty) != get_turf(src))
		throw_at(get_turf(fatty), 1, 1, spin=FALSE)

/obj/machinery/vending/proc/untilt(mob/user)
	user.visible_message("<span class='notice'>[user] rights [src].", \
		"<span class='notice'>You right [src].")

	unbuckle_all_mobs(TRUE)

	tilted = FALSE
	layer = initial(layer)

	var/matrix/M = matrix()
	M.Turn(0)
	transform = M

/obj/machinery/vending/unbuckle_mob(mob/living/buckled_mob, force=FALSE)
	if(!force)
		return
	. = ..()

/obj/machinery/vending/proc/loadingAttempt(obj/item/I,mob/user)
	. = TRUE
	if(!user.transferItemToLoc(I, src))
		return FALSE
	for(var/datum/data/vending_product/R as anything in product_records)
		if(R.product_path == I.type)
			R.amount++
			to_chat(user, span_notice("You insert [I] into [src]'s input compartment."))
			qdel(I)
			break

	return FALSE


/obj/machinery/vending/exchange_parts(mob/user, obj/item/storage/part_replacer/W)
	if(!istype(W))
		return FALSE
	if((flags_1 & NODECONSTRUCT_1) && !W.works_from_distance)
		return FALSE
	if(!component_parts || !refill_canister)
		return FALSE

	var/moved = 0
	if(panel_open || W.works_from_distance)
		if(W.works_from_distance)
			display_parts(user)
		for(var/I in W)
			if(istype(I, refill_canister))
				moved += restock(I)
	else
		display_parts(user)
	if(moved)
		to_chat(user, "[moved] items restocked.")
		W.play_rped_sound()
	return TRUE

/obj/machinery/vending/on_deconstruction()
	update_canister()
	. = ..()

/obj/machinery/vending/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	to_chat(user, span_notice("You short out the product lock on [src]."))

/obj/machinery/vending/_try_interact(mob/user)
	if(seconds_electrified && !(stat & NOPOWER))
		if(shock(user, 100))
			return

	if(tilted && !user.buckled && !isAI(user))
		to_chat(user, "<span class='notice'>You begin righting [src].")
		if(do_after(user, 50, target=src))
			untilt(user)
		return
	return ..()

/obj/machinery/vending/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/vending),
	)

/obj/machinery/vending/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Vending")
		ui.open()

/obj/machinery/vending/ui_static_data(mob/user)
	. = list()
	.["onstation"] = onstation
	.["department"] = payment_department
	.["product_records"] = list()
	for (var/datum/data/vending_product/R in product_records)
		var/list/data = list(
			path = replacetext(replacetext("[R.product_path]", "/obj/item/", ""), "/", "-"),
			name = R.name,
			price = R.custom_price || default_price,
			max_amount = R.max_amount,
			ref = REF(R)
		)
		.["product_records"] += list(data)
	.["coin_records"] = list()
	for (var/datum/data/vending_product/R in coin_records)
		var/list/data = list(
			path = replacetext(replacetext("[R.product_path]", "/obj/item/", ""), "/", "-"),
			name = R.name,
			price = R.custom_premium_price || extra_price,
			max_amount = R.max_amount,
			ref = REF(R),
			extended = TRUE
		)
		.["coin_records"] += list(data)
	.["hidden_records"] = list()
	for (var/datum/data/vending_product/R in hidden_records)
		var/list/data = list(
			path = replacetext(replacetext("[R.product_path]", "/obj/item/", ""), "/", "-"),
			name = R.name,
			price = R.custom_price || extra_price,
			max_amount = R.max_amount,
			ref = REF(R),
			extended = TRUE
		)
		.["hidden_records"] += list(data)

/obj/machinery/vending/ui_data(mob/user)
	. = list()
	var/mob/living/carbon/human/H
	var/obj/item/card/id/C

	var/mob/living/L
	if(isliving(user))
		L = user
	.["ignores_capitalism"] = L?.ignores_capitalism

	if(ishuman(user))
		H = user
		C = H.get_idcard(TRUE)

		if(C?.registered_account)
			.["user"] = list()
			.["user"]["name"] = C.registered_account.account_holder
			.["user"]["cash"] = C.registered_account.account_balance
			if(C.registered_account.account_job)
				.["user"]["job"] = C.registered_account.account_job.title
				.["user"]["department"] = C.registered_account.account_job.paycheck_department
			else
				.["user"]["job"] = "No Job"
				.["user"]["department"] = "No Department"
	.["stock"] = list()
	for (var/datum/data/vending_product/R in product_records + coin_records + hidden_records)
		.["stock"][R.name] = R.amount
	.["extended_inventory"] = extended_inventory

/obj/machinery/vending/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("vend")
			. = TRUE
			if(!vend_ready)
				return
			if(panel_open)
				to_chat(usr, span_warning("The vending machine cannot dispense products while its service panel is open!"))
				return
			vend_ready = FALSE //One thing at a time!!
			var/datum/data/vending_product/R = locate(params["ref"])
			var/list/record_to_check = product_records + coin_records
			if(extended_inventory)
				record_to_check = product_records + coin_records + hidden_records
			if(!R || !istype(R) || !R.product_path)
				vend_ready = TRUE
				return
			var/price_to_use = default_price
			if(R.custom_price)
				price_to_use = R.custom_price
			if(R in hidden_records)
				if(!extended_inventory)
					vend_ready = TRUE
					return
			else if (!(R in record_to_check))
				vend_ready = TRUE
				message_admins("Vending machine exploit attempted by [ADMIN_LOOKUPFLW(usr)]!")
				return
			if (R.amount <= 0)
				say("Sold out of [R.name].")
				flick(icon_deny,src)
				vend_ready = TRUE
				return
			var/mob/living/L
			if(isliving(usr))
				L = usr

			if(onstation && ishuman(usr) && (L && !L.ignores_capitalism))
				var/mob/living/carbon/human/H = usr
				var/obj/item/card/id/C = H.get_idcard(TRUE)

				if(!C)
					say("No card found.")
					flick(icon_deny,src)
					vend_ready = TRUE
					return
				else if (!C.registered_account)
					say("No account found.")
					flick(icon_deny,src)
					vend_ready = TRUE
					return
				else if(age_restrictions && R.age_restricted && (!C.registered_age || C.registered_age < AGE_MINOR))
					say("You are not of legal age to purchase [R.name].")
					if(!(usr in GLOB.narcd_underages))
						alertradio.set_frequency(FREQ_SECURITY)
						alertradio.talk_into(src, "SECURITY ALERT: Underaged crewmember [H] recorded attempting to purchase [R.name] in [get_area(src)]. Please watch for substance abuse.", FREQ_SECURITY)
						GLOB.narcd_underages += H
					flick(icon_deny,src)
					vend_ready = TRUE
					return
				var/datum/bank_account/account = C.registered_account
				if(account.account_job && account.account_job.paycheck_department == payment_department)
					price_to_use = 0
				if(coin_records.Find(R) || hidden_records.Find(R))
					price_to_use = R.custom_premium_price ? R.custom_premium_price : extra_price
				if(price_to_use && !account.adjust_money(-price_to_use))
					say("You do not possess the funds to purchase [R.name].")
					flick(icon_deny,src)
					vend_ready = TRUE
					return
				var/datum/bank_account/D = SSeconomy.get_dep_account(payment_department)
				if(D)
					D.adjust_money(price_to_use)
			if(last_shopper != usr || purchase_message_cooldown < world.time)
				say("Thank you for shopping with [src]!")
				purchase_message_cooldown = world.time + 5 SECONDS
				last_shopper = usr
			use_power(5)
			if(icon_vend) //Show the vending animation if needed
				flick(icon_vend,src)
			playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
			new R.product_path(get_turf(src))
			R.amount--
			SSblackbox.record_feedback("nested tally", "vending_machine_usage", 1, list("[type]", "[R.product_path]"))
			vend_ready = TRUE

/obj/machinery/vending/process()
	if(stat & (BROKEN|NOPOWER))
		return PROCESS_KILL
	if(!active)
		return

	if(seconds_electrified > MACHINE_NOT_ELECTRIFIED)
		seconds_electrified--

	//Pitch to the people!  Really sell it!
	if(last_slogan + slogan_delay <= world.time && slogan_list.len > 0 && !shut_up && prob(5))
		var/slogan = pick(slogan_list)
		speak(slogan)
		last_slogan = world.time

	if(shoot_inventory && prob(shoot_inventory_chance))
		throw_item()
/**
  * Speak the given message verbally
  *
  * Checks if the machine is powered and the message exists
  *
  * Arguments:
  * * message - the message to speak
  */
/obj/machinery/vending/proc/speak(message)
	if(stat & (BROKEN|NOPOWER))
		return
	if(!message)
		return

	say(message)

/obj/machinery/vending/power_change()
	if(stat & BROKEN)
		return

	if(powered())
		stat &= ~NOPOWER
		START_PROCESSING(SSmachines, src)
	else
		stat |= NOPOWER

	update_icon()

//Somebody cut an important wire and now we're following a new definition of "pitch."
/**
  * Throw an item from our internal inventory out in front of us
  *
  * This is called when we are hacked, it selects a random product from the records that has an amount > 0
  * This item is then created and tossed out in front of us with a visible message
  */
/obj/machinery/vending/proc/throw_item()
	var/obj/throw_item = null
	var/mob/living/target = locate() in view(7,src)
	if(!target)
		return 0

	for(var/datum/data/vending_product/R in shuffle(product_records))
		if(R.amount <= 0) //Try to use a record that actually has something to dump.
			continue
		var/dump_path = R.product_path
		if(!dump_path)
			continue

		R.amount--
		throw_item = new dump_path(loc)
		break
	if(!throw_item)
		return 0

	pre_throw(throw_item)

	throw_item.throw_at(target, 16, 3)
	visible_message(span_danger("[src] launches [throw_item] at [target]!"))
	return 1
/**
  * A callback called before an item is tossed out
  *
  * Override this if you need to do any special case handling
  *
  * Arguments:
  * * I - obj/item being thrown
  */
/obj/machinery/vending/proc/pre_throw(obj/item/I)
	return
/**
  * Shock the passed in user
  *
  * This checks we have power and that the passed in prob is passed, then generates some sparks
  * and calls electrocute_mob on the user
  *
  * Arguments:
  * * user - the user to shock
  * * prb - probability the shock happens
  */
/obj/machinery/vending/proc/shock(mob/user, prb)
	if(stat & (BROKEN|NOPOWER))		// unpowered, no shock
		return FALSE
	if(!prob(prb))
		return FALSE
	do_sparks(5, TRUE, src)
	var/check_range = TRUE
	if(electrocute_mob(user, get_area(src), src, 0.7, check_range))
		return TRUE
	else
		return FALSE
/**
  * Are we able to load the item passed in
  *
  * Arguments:
  * * I - the item being loaded
  * * user - the user doing the loading
  */
/obj/machinery/vending/proc/canLoadItem(obj/item/I,mob/user)
	return FALSE
/**
  * Is the passed in user allowed to load this vending machines compartments
  *
  * Arguments:
  * * user - mob that is doing the loading of the vending machine
  */
/obj/machinery/vending/proc/compartmentLoadAccessCheck(mob/user)
	if(!canload_access_list)
		return TRUE
	else
		var/do_you_have_access = FALSE
		var/req_access_txt_holder = req_access_txt
		for(var/i in canload_access_list)
			req_access_txt = i
			if(!allowed(user) && !(obj_flags & EMAGGED) && scan_id)
				continue
			else
				do_you_have_access = TRUE
				break //you passed don't bother looping anymore
		req_access_txt = req_access_txt_holder // revert to normal (before the proc ran)
		if(do_you_have_access)
			return TRUE
		else
			to_chat(user, span_warning("[src]'s input compartment blinks red: Access denied."))
			return FALSE

/obj/machinery/vending/onTransitZ()
	return
