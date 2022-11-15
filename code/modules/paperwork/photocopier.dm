/*	Photocopiers!
 *	Contains:
 *		Photocopier
 *		Toner Cartridge
 */

/*
 * Photocopier
 */

/obj/machinery/photocopier
	name = "photocopier"
	desc = "Used to copy important documents and anatomy studies."
	icon = 'icons/obj/library.dmi'
	icon_state = "photocopier"
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 30
	active_power_usage = 200
	power_channel = EQUIP
	max_integrity = 300
	integrity_failure = 100
	var/insert_anim = "photocopier1"
	var/obj/item/paper/copy = null	//what's in the copier!
	var/obj/item/photo/photocopy = null
	var/obj/item/documents/doccopy = null
	var/copies = 1	//how many copies to print!
	var/toner = 40 //how much toner is left! woooooo~
	var/maxcopies = 10	//how many copies can be copied at once- idea shamelessly stolen from bs12's copier!
	var/greytoggle = "Greyscale"
	var/busy = FALSE

/obj/machinery/photocopier/ui_interact(mob/user)
	. = ..()
	var/dat = "<HTML><HEAD><meta charset='UTF-8'></HEAD><BODY>Photocopier<BR><BR>"
	if(copy || photocopy || doccopy)
		dat += "<a href='byond://?src=[REF(src)];remove=1'>Remove Paper</a><BR>"
		if(toner)
			dat += "<a href='byond://?src=[REF(src)];copy=1'>Copy</a><BR>"
			dat += "Printing: [copies] copies."
			dat += "<a href='byond://?src=[REF(src)];min=1'>-</a> "
			dat += "<a href='byond://?src=[REF(src)];add=1'>+</a><BR><BR>"
			if(photocopy)
				dat += "Printing in <a href='byond://?src=[REF(src)];colortoggle=1'>[greytoggle]</a><BR><BR>"
	else if(toner)
		dat += "Please insert paper to copy.<BR><BR>"
	if(isAI(user))
		dat += "<a href='byond://?src=[REF(src)];aipic=1'>Print photo from database</a><BR><BR>"
	dat += "Current toner level: [toner]"
	if(!toner)
		dat +="<BR>Please insert a new toner cartridge!"
	dat += "</BODY></HTML>"
	user << browse(dat, "window=copier")
	onclose(user, "copier")

/obj/machinery/photocopier/proc/clearcolor(text) // Breaks all font color spans in the HTML text.
	return replacetext(replacetext(text, "<font face=\"[CRAYON_FONT]\" color=", "<font face=\"[CRAYON_FONT]\" nocolor="), "<font face=\"[PEN_FONT]\" color=", "<font face=\"[PEN_FONT]\" nocolor=") //This basically just breaks the existing color tag, which we need to do because the innermost tag takes priority.

/obj/machinery/photocopier/Topic(href, href_list)
	if(..())
		return
	if(href_list["copy"])
		if(copy)
			for(var/i = 0, i < copies, i++)
				if(toner > 0 && !busy && copy)
					copy(copy)
					busy = TRUE
					sleep(1.5 SECONDS)
					busy = FALSE
				else
					break
			updateUsrDialog()
		else if(photocopy)
			for(var/i = 0, i < copies, i++)
				if(toner >= 5 && !busy && photocopy)  //Was set to = 0, but if there was say 3 toner left and this ran, you would get -2 which would be weird for ink
					new /obj/item/photo (loc, photocopy.picture.Copy(greytoggle == "Greyscale"? TRUE : FALSE))
					busy = TRUE
					sleep(1.5 SECONDS)
					busy = FALSE
				else
					break
		else if(doccopy)
			for(var/i = 0, i < copies, i++)
				if(toner > 5 && !busy && doccopy)
					new /obj/item/documents/photocopy(loc, doccopy)
					toner-= 6 // the sprite shows 6 papers, yes I checked
					busy = TRUE
					sleep(1.5 SECONDS)
					busy = FALSE
				else
					break
			updateUsrDialog()
		updateUsrDialog()
	else if(href_list["remove"])
		if(copy)
			remove_photocopy(copy, usr)
			copy = null
		else if(photocopy)
			remove_photocopy(photocopy, usr)
			photocopy = null
		else if(doccopy)
			remove_photocopy(doccopy, usr)
			doccopy = null
		updateUsrDialog()
	else if(href_list["min"])
		if(copies > 1)
			copies--
			updateUsrDialog()
	else if(href_list["add"])
		if(copies < maxcopies)
			copies++
			updateUsrDialog()
	else if(href_list["aipic"])
		if(!isAI(usr))
			return
		if(toner >= 5 && !busy)
			var/mob/living/silicon/ai/tempAI = usr
			if(tempAI.aicamera.stored.len == 0)
				to_chat(usr, span_boldannounce("No images saved"))
				return
			var/datum/picture/selection = tempAI.aicamera?.selectpicture(usr)
			var/obj/item/photo/photo = new(loc, selection)
			photo.pixel_x = rand(-10, 10)
			photo.pixel_y = rand(-10, 10)
			toner -= 5	 //AI prints color pictures only, thus they can do it more efficiently
			busy = TRUE
			sleep(1.5 SECONDS)
			busy = FALSE
		updateUsrDialog()
	else if(href_list["colortoggle"])
		if(greytoggle == "Greyscale")
			greytoggle = "Color"
		else
			greytoggle = "Greyscale"
		updateUsrDialog()

/obj/machinery/photocopier/proc/do_insertion(obj/item/O, mob/user)
	O.forceMove(src)
	to_chat(user, "<span class ='notice'>You insert [O] into [src].</span>")
	flick(insert_anim, src)
	updateUsrDialog()

/obj/machinery/photocopier/proc/remove_photocopy(obj/item/O, mob/user)
	if(!issilicon(user)) //surprised this check didn't exist before, putting stuff in AI's hand is bad
		O.forceMove(user.loc)
		user.put_in_hands(O)
	else
		O.forceMove(drop_location())
	to_chat(user, span_notice("You take [O] out of [src]."))

/obj/machinery/photocopier/attackby(obj/item/O, mob/user, params)
	if(default_unfasten_wrench(user, O))
		return
	else if(istype(O, /obj/item/paper) || istype(O, /obj/item/paper_bundle))
		if(copier_empty())
			if(istype(O, /obj/item/paper/contract/infernal))
				to_chat(user, span_warning("[src] smokes, smelling of brimstone!"))
				resistance_flags |= FLAMMABLE
				fire_act()
			else
				if(!user.temporarilyRemoveItemFromInventory(O))
					return
				copy = O
				do_insertion(O, user)
		else
			to_chat(user, span_warning("There is already something in [src]!"))

	else if(istype(O, /obj/item/photo))
		if(copier_empty())
			if(!user.temporarilyRemoveItemFromInventory(O))
				return
			photocopy = O
			do_insertion(O, user)
		else
			to_chat(user, span_warning("There is already something in [src]!"))

	else if(istype(O, /obj/item/documents))
		if(copier_empty())
			if(!user.temporarilyRemoveItemFromInventory(O))
				return
			doccopy = O
			do_insertion(O, user)
		else
			to_chat(user, span_warning("There is already something in [src]!"))

	else if(istype(O, /obj/item/toner))
		if(toner <= 0)
			if(!user.temporarilyRemoveItemFromInventory(O))
				return
			qdel(O)
			toner = initial(toner)
			to_chat(user, span_notice("You insert [O] into [src]."))
			updateUsrDialog()
		else
			to_chat(user, span_warning("This cartridge is not yet ready for replacement! Use up the rest of the toner."))

	else if(istype(O, /obj/item/areaeditor/blueprints))
		to_chat(user, span_warning("The Blueprint is too large to put into the copier. You need to find something else to record the document"))
	else
		return ..()

/obj/machinery/photocopier/obj_break(damage_flag)
	. = ..()
	if(. && toner > 0)
		new /obj/effect/decal/cleanable/oil(get_turf(src))
		toner = 0

/obj/machinery/photocopier/proc/copier_blocked()
	if(QDELETED(src))
		return
	if(loc.density)
		return 1
	for(var/atom/movable/AM in loc)
		if(AM == src)
			continue
		if(AM.density)
			return 1
	return 0

/obj/machinery/photocopier/proc/copier_empty()
	if(copy || photocopy || doccopy)
		return 0
	else
		return 1

/*
 * Toner cartridge
 */
/obj/item/toner
	name = "toner cartridge"
	icon = 'icons/obj/device.dmi'
	icon_state = "tonercartridge"
	grind_results = list(/datum/reagent/iodine = 40, /datum/reagent/iron = 10)
	var/charges = 25
	var/max_charges = 25

/obj/item/toner/large
	name = "large toner cartridge"
	grind_results = list(/datum/reagent/iodine = 90, /datum/reagent/iron = 10)
	charges = 75
	max_charges = 75
	
/obj/machinery/photocopier/proc/copy(var/obj/item/paper/copy)
	var/copy_as_paper = TRUE
	if(istype(copy, /obj/item/paper/contract/employment))
		var/obj/item/paper/contract/employment/E = copy
		var/obj/item/paper/contract/employment/C = new /obj/item/paper/contract/employment (loc, E.target.current)
		if(C)
			copy_as_paper = FALSE
	if(copy_as_paper)
		var/obj/item/paper/c = new /obj/item/paper (loc)
		if(length(copy.info) || length(copy.written))	//Only print and add content if the copied doc has words on it
			if(toner > 10)	//lots of toner, make it dark
				c.coloroverride = "101010"
			else			//no toner? shitty copies for you!
				c.coloroverride = "808080"
			var/copyinfo = copy.info
			copyinfo = clearcolor(copyinfo)
			c.info += copyinfo + "</font>"
			//Now for copying the new $written var
			for(var/L in copy.written)
				if(istype(L,/datum/langtext))
					var/datum/langtext/oldL = L
					var/datum/langtext/newL = new(clearcolor(oldL.text),oldL.lang)
					c.written += newL
				else
					c.written += L
			c.name = copy.name
			c.fields = copy.fields
			c.update_icon()
			c.stamps = copy.stamps
			if(copy.stamped)
				c.stamped = copy.stamped.Copy()
			c.copy_overlays(copy, TRUE)
			toner--
		return c


/obj/machinery/photocopier/proc/photocopy(var/obj/item/photo/photocopy)
	. = new /obj/item/photo (loc, photocopy.picture.Copy(greytoggle == "Greyscale"? TRUE : FALSE))
	toner -= 5	//photos use a lot of ink!
	if(toner < 0)
		toner = 0
		visible_message("<span class='notice'>A red light on \the [src] flashes, indicating that it is out of toner.</span>")

//If need_toner is 0, the copies will still be lightened when low on toner, however it will not be prevented from printing. TODO: Implement print queues for fax machines and get rid of need_toner
/obj/machinery/photocopier/proc/bundlecopy(var/obj/item/paper_bundle/bundle, var/need_toner=1)
	var/obj/item/paper_bundle/p = new /obj/item/paper_bundle (src)
	for(var/obj/item/W in bundle)
		if(toner <= 0 && need_toner)
			toner = 0
			visible_message("<span class='notice'>A red light on \the [src] flashes, indicating that it is out of toner.</span>")
			break

		if(istype(W, /obj/item/paper))
			W = copy(W)
		else if(istype(W, /obj/item/photo))
			W = photocopy(W)
		W.loc = p
		p.amount++
	//p.amount--
	p.loc = src.loc
	p.update_icon()
	p.icon_state = "paper_words"
	p.name = bundle.name
	p.pixel_y = rand(-8, 8)
	p.pixel_x = rand(-9, 9)
	return p
