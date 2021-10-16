#define BASE_POWER_PER_CPU 250
#define POWER_PER_CARD 150
#define TEMP_LIMIT 323.15 //50C, much hotter than a normal server room for leniency :)

GLOBAL_LIST_EMPTY(expansion_card_holders)

/obj/machinery/ai/expansion_card_holder
	name = "Expansion Card Bus"
	desc = "A simple rack of bPCIe slots for installing expansion cards."
	icon = 'icons/obj/machines/telecomms.dmi'
	icon_state = "processor"
	

	var/list/installed_cards

	var/total_cpu = 0

	var/max_cards = 2

	var/was_valid_holder = FALSE


/obj/machinery/ai/expansion_card_holder/Initialize()
	..()
	installed_cards = list()
	GLOB.expansion_card_holders += src
	update_icon()

/obj/machinery/ai/expansion_card_holder/Destroy()
	installed_cards = list()
	GLOB.expansion_card_holders -= src
	//Recalculate all the CPUs and RAM :)
	GLOB.ai_os.update_hardware()
	..()

/obj/machinery/ai/expansion_card_holder/proc/valid_holder()
	if(stat & (BROKEN|NOPOWER|EMPED))
		return FALSE
	
	var/turf/T = get_turf(src)
	var/datum/gas_mixture/env = T.return_air()
	var/total_moles = env.total_moles()
	if(istype(T, /turf/open/space) || total_moles < 10)
		return FALSE
	
	if(env.return_temperature() > TEMP_LIMIT || !env.heat_capacity())
		return FALSE

	was_valid_holder = TRUE
	return TRUE

/obj/machinery/ai/expansion_card_holder/process()
	if(valid_holder())
		var/power_multiple = total_cpu ** (7/8)

		var/total_usage = (power_multiple * BASE_POWER_PER_CPU) + POWER_PER_CARD * installed_cards.len
		use_power(total_usage)

		var/turf/T = get_turf(src)
		var/datum/gas_mixture/env = T.return_air()
		if(env.heat_capacity())
			env.set_temperature(env.return_temperature() + total_usage / env.heat_capacity()) //assume all input power is dissipated

	else if(was_valid_holder)
		was_valid_holder = FALSE
		GLOB.ai_os.update_hardware()
	

/obj/machinery/ai/expansion_card_holder/update_icon()
	cut_overlays()
	
	if(!(stat & (BROKEN|NOPOWER|EMPED)))
		var/mutable_appearance/on_overlay = mutable_appearance(icon, "[initial(icon_state)]_on")
		add_overlay(on_overlay)

/obj/machinery/ai/expansion_card_holder/attackby(obj/item/W, mob/living/user, params)
	if(istype(W, /obj/item/processing_card) || istype(W, /obj/item/memory_card))
		if(installed_cards.len >= max_cards)
			to_chat(user, "<span class='warning'>[src] cannot fit the [W]!</span>")
			return ..()
		to_chat(user, "<span class='notice'>You install [W] into [src].</span>")
		W.forceMove(src)
		installed_cards += W
		GLOB.ai_os.update_hardware()
		if(istype(W, /obj/item/processing_card))
			total_cpu += W.tier
		return FALSE
	if(W.tool_behaviour == TOOL_CROWBAR)
		if(installed_cards.len)
			var/turf/T = get_turf(src)
			for(var/C in installed_cards)
				C.forceMove(T)
			total_cpu = 0
			GLOB.ai_os.update_hardware()
			to_chat(user, "<span class='notice'>You remove all the cards from [src]</span>")
			return FALSE
	return ..()

/obj/machinery/ai/expansion_card_holder/examine()
	. = ..()
	. += "The machine has [installed_cards.len] cards out of a maximum of [max_cards] installed."
	for(var/C in installed_cards)
		. += "There is a [C] installed."
	. += "Use a crowbar to remove cards."


/obj/machinery/ai/expansion_card_holder/prefilled/Initialize()
	..()
	var/obj/item/processing_card/cpu = new /obj/item/processing_card()
	var/obj/item/memory_card/ram = new /obj/item/memory_card()

	cpu.forceMove(src)
	total_cpu++
	ram.forceMove(src)
	installed_cards += cpu
	installed_cards += ram
	GLOB.ai_os.update_hardware()

#undef BASE_POWER_PER_CPU
#undef POWER_PER_CARD
