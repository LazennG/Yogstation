/obj/item/clothing/gloves
	var/transfer_blood = 0

/obj/item/reagent_containers/glass/rag
	name = "damp rag"
	desc = "For cleaning up messes, you suppose."
	w_class = WEIGHT_CLASS_TINY
	icon = 'icons/obj/toy.dmi'
	icon_state = "rag"
	item_flags = NOBLUDGEON
	reagent_flags = OPENCONTAINER_NOSPILL
	amount_per_transfer_from_this = 5
	possible_transfer_amounts = list()
	volume = 5
	var/cleanspeed = 3 SECONDS

/obj/item/reagent_containers/glass/rag/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] is smothering [user.p_them()]self with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	return (OXYLOSS)

/obj/item/reagent_containers/glass/rag/afterattack(atom/target, mob/living/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(iscarbon(target) && target.reagents && reagents.total_volume)
		var/mob/living/carbon/C = target
		var/reagentlist = pretty_string_from_reagent_list(reagents)
		var/log_object = "containing [reagentlist]"
		if(user.combat_mode && !C.is_mouth_covered())
			reagents.reaction(C, INGEST)
			reagents.trans_to(C, reagents.total_volume, transfered_by = user)
			C.visible_message(span_danger("[user] has smothered \the [C] with \the [src]!"), span_userdanger("[user] has smothered you with \the [src]!"), span_italics("You hear some struggling and muffled cries of surprise."))
			log_combat(user, C, "smothered", src, log_object)
		else
			reagents.reaction(C, TOUCH)
			reagents.clear_reagents()
			C.visible_message(span_notice("[user] has touched \the [C] with \the [src]."))
			log_combat(user, C, "touched", src, log_object)

	else if(istype(target) && (src in user))
		user.visible_message("[user] starts to wipe down [target] with [src]!", span_notice("You start to wipe down [target] with [src]..."))
		if(do_after(user, cleanspeed, target))
			user.visible_message("[user] finishes wiping off [target]!", span_notice("You finish wiping off [target]."))
			target.wash(CLEAN_SCRUB)
			reagents.reaction(target, TOUCH)
			reagents.clear_reagents()

