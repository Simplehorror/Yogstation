#define GRUE_SPAWN 1
#define GRUE_JUVENILE 2
#define GRUE_ADULT 3

/mob/living/simple_animal/hostile/grue
	icon = 'icons/mob/grue.dmi'
	speed = 0
	name = "grue"
	real_name = "grue"

	response_help  = "touches"
	response_disarm = "pushes"
	response_harm   = "punches"
	minbodytemp = 0

	faction = "grue" //Keep grues and grue eggs friendly to each other.

	var/spawn_count = 0 //Eggs hatched.
	var/eaten_count = 0 //Sentients eaten.

	var/life_stage = GRUE_SPAWN

	var/datum/component/light_damage/light_damage = null

/mob/living/simple_animal/hostile/grue/Initialize()
	. = ..()
	light_damage = AddComponent(/datum/component/light_damage, 0.3, 4.5)
	light_damage.damage_types = list(BURN)
	light_damage.ramping_scaler = 1.5
	set_life_stage(life_stage)
	add_client_colour(/datum/client_colour/grue)

/mob/living/simple_animal/hostile/grue/get_status_tab_items()
	. = ..()
	. += "Eggs hatched: [spawn_count]"
	. += "Humans eaten: [eaten_count]"

/mob/living/simple_animal/hostile/grue/proc/update_power() 
	if (life_stage != GRUE_ADULT)
		return FALSE
	light_damage.heal_per_second = 4.5 * (eaten_count * 1.5)
	light_damage.speed_up_in_darkness = -1 * (eaten_count * 0.5)
	melee_damage_lower = 20 + (eaten_count * 7)
	melee_damage_upper = 30 + (eaten_count * 7)

	environment_smash |= ENVIRONMENT_SMASH_STRUCTURES
	if (eaten_count >= 3)
		environment_smash |= ENVIRONMENT_SMASH_WALLS
	if (eaten_count >= 5)
		environment_smash |= ENVIRONMENT_SMASH_RWALLS
	return TRUE

/mob/living/simple_animal/hostile/grue/proc/can_moult()
	if (life_stage == GRUE_SPAWN)
		return TRUE
	if (life_stage == GRUE_JUVENILE)
		return eaten_count >= 1
	return FALSE


/mob/living/simple_animal/hostile/grue/proc/try_devour(mob/living/L)
	to_chat(src, span_notice("You begin to devour \the [L]."))
	if (do_mob(src, L, 3.5 SECONDS))
		to_chat(src, span_notice("You devour \the [L]!"))
		to_chat(L, span_notice("You have been devoured by \the [src]."))
		L.gib()
		if (istype(L, /mob/living/carbon/human))
			eaten_count++
	update_power()
/mob/living/simple_animal/hostile/grue/proc/try_open_airlock(obj/machinery/door/airlock/A)
	if((!A.requiresID() || A.allowed(src)) && A.hasPower())
		return
	if(A.locked)
		to_chat(src, span_warning("The airlock's bolts prevent it from being forced!"))
		return
	if(A.hasPower())
		src.visible_message(span_warning("[src] starts prying [A] open!"), span_warning("You start forcing the airlock open."),
		span_italics("You hear a metal screeching sound."))
		playsound(A, 'sound/machines/airlock_alien_prying.ogg', 150, 1)
		if(!do_after(src, 10 SECONDS, A))
			return
		src.visible_message(span_warning("[src] forces the airlock!"), span_warning("You force the airlock to open."),
		span_italics("You hear a metal screeching sound."))
		A.open(2)
	else
		A.open(2)

/mob/living/simple_animal/hostile/grue/AltClickOn(atom/target)
	if (isliving(target))
		var/mob/living/L = target
		try_devour(L)
		return
	if(istype(target, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/A = target
		try_open_airlock(A)
		return
	. = ..()
	
	


/mob/living/simple_animal/hostile/grue/proc/set_life_stage(var/stage)
	if (stage == GRUE_SPAWN)
		name = "grue larva"
		desc = "A scurrying thing that lives in the dark. It is still a larva."
		maxHealth = 50
		health = 50
		melee_damage_lower = 3
		melee_damage_upper = 5
		icon_living = "gruespawn_living"
		icon_dead  = "gruespawn_dead"
		environment_smash = 0
		ventcrawler = VENTCRAWLER_ALWAYS
	else if (stage == GRUE_JUVENILE)
		name = "grue"
		desc = "A creeping thing that lives in the dark. It is still a juvenile."
		maxHealth = 150
		health = 150
		melee_damage_lower = 15
		melee_damage_upper = 20
		icon_living = "grueling_living"
		icon_dead  = "grueling_dead"
		environment_smash = ENVIRONMENT_SMASH_STRUCTURES
		ventcrawler = VENTCRAWLER_NONE
	else if (stage == GRUE_ADULT)
		name = "grue"
		desc = "A dangerous thing that lives in the dark."
		maxHealth = 250
		health = 250
		melee_damage_lower = 20
		melee_damage_upper = 30
		icon_living = "grue_living"
		icon_dead  = "grue_dead"
		environment_smash = ENVIRONMENT_SMASH_STRUCTURES
		ventcrawler = VENTCRAWLER_NONE
		update_power()
	icon_state = icon_living

/mob/living/simple_animal/hostile/grue/gruespawn
	life_stage = GRUE_SPAWN

/mob/living/simple_animal/hostile/grue/grueling
	life_stage = GRUE_JUVENILE

/mob/living/simple_animal/hostile/grue/grueadult
	life_stage = GRUE_ADULT
