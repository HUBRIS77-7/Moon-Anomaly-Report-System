# AnomalyDatabase.gd
extends Node

enum Category { ALL, MEDICAL, SECURITY, GEOLOGICAL, SCIENTIFIC, BIOLOGICAL, INDUSTRIAL, UNKNOWN, GENERAL, ANOMALOUS }

const NOT_FOUND = "NOT_FOUND"
const NOT_ACCESSIBLE = "NOT_ACCESSIBLE"

# Each entry shape:
# {
#   "id":                int,
#   "name":              String,
#   "category":          Category,
#   "severity":          int,
#   "danger":            int,
#   "scale":             int,
#   "type":              Category,
#   "description":       String,
#   "icon_path":         String,
#   "unlocked_on_day":   int,     # Locks entry until this day of the current week
#   "accessible":        bool,
#   "exclusive_to_week": String,  # If set, entry ONLY appears during that week ID.
#                                 # Leave as "" for base-universe entries that
#                                 # appear in every week.
# }

var entries: Array[Dictionary] = [
	{
		"id": 1,
		"name": "Incorrect Clearence Code",
		"category": Category.SECURITY,
		"severity": 2,
		"danger": 2,
		"scale": 1,
		"type": Category.SECURITY,
		"description": "All avenues of access into restricted or otherwise locked areas of the complexes that make up the Primary Lunar Construction (PLC) are controlled by Access Cards. Every individual upon the lunar surface possesses a clearence code. This individual is attempting to access a area that their code does not permit. \n\n Upon use of a incorrect clearence code, a access terminal will beep loudly and display the words 'incorrect clearence'.  \n \n  If you suspect that the individual attempting to access a locked area is doing so unlawfully, please report this as a Attempted Break-In.",
		"icon_path": "res://wp12013121.jpg",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 2,
		"name": "Minor Injury",
		"category": Category.MEDICAL,
		"severity": 1,
		"danger": 1,
		"scale": 1,
		"type": Category.MEDICAL,
		"description": "A Minor Injury. While all individuals on the lunar surface have months of basic and expert training when it comes to possible lunar hazards. Mistakes still occur. This one is minor. \n \n If you feel that the caller is not being honest about the full nature of the injury, either in origin or effects, please report this as a Unknown Injury (#78).",
		"icon_path": "",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 3,
		"name": "Minor Mining Machinery Malfunction",
		"category": Category.INDUSTRIAL,
		"severity": 2,
		"danger": 2,
		"scale": 2,
		"type": Category.INDUSTRIAL,
		"description": "All machinery on the Lunar Surface are prone to malfunctions due to the nature of Lunar Dust. This primarily occurs in mining equipment due to the amount of Lunar Dust that it kicks up.  \n \n If a machine involved in mining begins to malfunction, all staff are required to evacuate the surrounding area and attempt to remove the breaker that powers the sector. If this is not possible, please file the incident under Rouge Malfunctioning Mining Machinery (#102).",
		"icon_path": "",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 4,
		"name": "Luna Shake",
		"category": Category.GEOLOGICAL,
		"severity": 1,
		"danger": 2,
		"scale": 2,
		"type": Category.GEOLOGICAL,
		"description": "Not to be confused with a Moonquake (#13). A Luna Shake is a more a consolidated geological event, typically caused a minor collosion between Lunar Tectonic Plates. Indicated by small cracks in the lunar surface, preceeded by a loud rumbling. Often indicative of soon-to-be further geological activity. \n \n Additionally, Luna Shakes can dislodge underground material assets, such as fuel transport lines, power cables, and fibre optic cables. Their occurance has also been associated with nearby deposits of Volatile Regolith.",
		"icon_path": "",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 5,
		"name": "Measuring Equipment Malfunction",
		"category": Category.SCIENTIFIC,
		"severity": 1,
		"danger": 1,
		"scale": 1,
		"type": Category.SCIENTIFIC,
		"description": "After initial colonization efforts, hundreds of tons of scientific equipment was sent to the Moon for the purposes of scientific advancement. Many of them are several decades old, and prone to malfunction. These errors commonly include incorrect units of measure, malfunctioning battery units, and being unable to connect to the Lunar Cloud Network. \n \n If a malfunction of measuring equipment occurs on a space-craft, please instead file the incident as a Space-Faring Scientific Equipment Failure.",
		"icon_path": "",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 6,
		"name": "Food Spoilage",
		"category": Category.BIOLOGICAL,
		"severity": 3,
		"danger": 2,
		"scale": 1,
		"type": Category.BIOLOGICAL,
		"description": "Food Spoilage is a result of either improper food storage, or food management. Food Spoilage is most often noticed due to foul smelling odors, or sick crew. While in most major stations such as PLC, food spoilage isn't a large danger, smaller stations that are disconnected from the primary supply line have to potential to starve before help can arrive. \n \n Upon designation, PLC supply vehicles will deploy to the site of the incident. \n \n This designation is not be assigned to stations undergoing experimental food-printing trials. ",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 7,
		"name": "Station Untidiness",
		"category": Category.GENERAL,
		"severity": 2,
		"danger": 0,
		"scale": 2,
		"type": Category.GENERAL,
		"description": "Station Untidiness is a general term referring to stations that are generally messy, dirty, or unmaintained. All designations of Station Untidiness are forwarded to the local Station Inspector, or, if applicable, Station Janitor positions. \n \n If you believe that the Station Untidiness is a smaller part of a generally unmaintained station, please file it under Unmaintained Station (#91). \n \n If you believe that it is a sign of a 'Coat' anomaly, please file under Coat (#102).",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 8,
		"name": "Gas Leak",
		"category": Category.INDUSTRIAL,
		"severity": 3,
		"danger": 4,
		"scale": 2,
		"type": Category.INDUSTRIAL,
		"description": "A gas leak is a incredibly dangerous industrial accident that can occur in particularly industrial or residential stations. Individuals present near gas leaks report neausa, dizziness, and chest pain. \n \n If similar signs are reported on Scientific stations, please designate the leak as a Aerosilzed Substance Leak (#27), unless caller otherwise states.  ",
		"icon_path": "",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 9,
		"name": "Fights (Class-1)",
		"category": Category.SECURITY,
		"severity": 1,
		"danger": 3,
		"scale": 2,
		"type": Category.SECURITY,
		"description": "Fighting often occurs between two crew members due to insignificant reasons. Callers often note that a fight is happening. A Class-1 Fight is any fight that occurs in non-restricted areas, such as public venues (residential districts, city streets, etc), or general living stations. \n \n If a fight occurs outside these areas, please designate it as a Class-2 Fight (#17). \n \n If a fight is occuring outside of a station, and on the Lunar Surface, please designate it as EVA Suit Misuse (#21)",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 10,
		"name": "Regolith Exposure",
		"category": Category.MEDICAL,
		"severity": 3,
		"danger": 3,
		"scale": 1,
		"type": Category.MEDICAL,
		"description": "Lunar regolith is a incredibly sharp and very fine dust that is present on the lunar surface. Regolith is incredibly harmful to individuals over long-periods of time, with short-term symptoms being sneezing, coughing, and short-breath, and long-term symptoms being lack of stamina, chest pains, and migranes. ",
		"icon_path": "",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 11,
		"name": "Data Corruption",
		"category": Category.SCIENTIFIC,
		"severity": 3,
		"danger": 3,
		"scale": 2,
		"type": Category.SCIENTIFIC,
		"description": "Data Corruption refers to the loss of data within storage drives across the Moon, and is often causes by improper storage, or subtle exposure of lunar regolith. Due to the nature of the job of Incident Reporter, incidents of Data Corruption are to be solved by the Reporter on duty. Please interface with the Client Interaction System to resolve. \n \n If you believe that the corruption affects a major system, please file under Major System Corruption (#12)",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 12,
		"name": "Major System Corruption",
		"category": Category.SCIENTIFIC,
		"severity": 4,
		"danger": 5,
		"scale": 3,
		"type": Category.SCIENTIFIC,
		"description": "Major System Corruption refers to either the loss of data important to the function of a major system aboard a station, or the loss of control over the same. In both cases, the incident is to be resolved by the responding Incident Reporter using the Client Interface. Due to the nature of these types of incidents, time is of the essence. \n \n If you believe that the cause of the system corruption is due to a malfunctioning AI unit, please file under Rouge AI Unit (#39), and activate the AI Interference Eliminator Module within the CI. There are no such things as Moon Ghosts. ",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 13,
		"name": "Moonquakes",
		"category": Category.GEOLOGICAL,
		"severity": 2,
		"danger": 3,
		"scale": 2,
		"type": Category.GEOLOGICAL,
		"description": "Moonquakes are the lunar cousin of Earthquakes, and are caused the sudden movement of lunar tectonic plates. However, due to the nature of the moon's geology, the movement of lunar tectonic plates should not be possible. Instead, most Moonquakes are caused by major nearby accidents, such as cave-ins and explosions. Most Moonquakes cause similar signs as Earthquakes. \n \n Moonquakes have also been known to temporarily cause effects similar to that of a Electromagnetic Pulse, and can cause temporary loss of eletricity and signal.",
		"icon_path": "",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 14,
		"name": "Satellite Crash",
		"category": Category.INDUSTRIAL,
		"severity": 2,
		"danger": 3,
		"scale": 1,
		"type": Category.INDUSTRIAL,
		"description": "A Satellite Crash refers to an incident where a Satellite in orbit of the moon crashes onto the surface. A crash should only be designated as an incident when the satellite in question is not being decommissioned. Please check the Satellite Database before filing. \n \n The only exception to this rule is any satellite originating from countries on Earth. \n \n If the caller indicates that the Satallite is still falling, please file under Falling Satallite (#31). \n \n If the satallite is both unscheduled and endangering a populated area. Please alert Lunar Command",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 15,
		"name": "Moon Vine Infestation",
		"category": Category.BIOLOGICAL,
		"severity": 3,
		"danger": 2,
		"scale": 4,
		"type": Category.BIOLOGICAL,
		"description": "Moon Vines are a biological organism present on the Moon. Since human colonization, the growth of Moon Vine has skyrocketed, and poses a constant threat to stations on the edge of colonized territory. Signs of moon vine infestation include the presence of moon vine, foundational instability, and purple water. The arrival of Moon Vine is typically aligns with the arrival of Moonigrade, which can be detected in the water supply if checked. \n \n If the Moon Vines are the least of the caller's worries, please designate as a Major Biological Intrusion (#40) ",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 16,
		"name": "Complaint",
		"category": Category.GENERAL,
		"severity": 1,
		"danger": 1,
		"scale": 1,
		"type": Category.GENERAL,
		"description": "Complaints can be lodged by any individual who is a member of the Lunar Station Union. Compliants are to be transferred to the Department of Customer Service via the Call Transference App present on your primary terminal. \n \n If you believe that the caller's complaint warrants further investigation, please attempt to file under any other incident designation present in the database. \n \n If the caller is in the Caller Database as a 'Frequent Flyer', please file under Complaint unless otherwise indicated.",
		"icon_path": "",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 17,
		"name": "Lunar Magnificence",
		"category": Category.MEDICAL,
		"severity": 2,
		"danger": 2,
		"scale": 1,
		"type": Category.MEDICAL,
		"description": "Lunar Magnificence is a mental condition that can occur in individuals who have recently arrived on the Moon. Symptoms include a increased appreciation for the Moon as both a physical object, and a concept, desire to spend time outdoors on the surface, and a sudden hatred against the idea of going back to Earth or any other planet. \n \n If left untreated, it can evolve into Lunar Psychosis (#44).",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 18,
		"name": "Implosion Anxiety",
		"category": Category.GENERAL,
		"severity": 2,
		"danger": 2,
		"scale": 1,
		"type": Category.MEDICAL,
		"description": "Implosion Anxiety is a common type of mental condition that can affect those living in standard pressurized units. Due to the constant strain that pressurized units endure on the lunar surface, they are prone to making creaking, ticking, and even knocking noises. This can cause the resident within the unit to undergo Implosion Anxiety, a mental condition in which they believe that the unit is going to implode at some point in the future \\n Those going through the inital stages of Implosion Anxiety usually hyper-fixate on the noises created by the pressurized unit, often times believing it to be some sort of outside source. The later stages include symptoms such as paranoia, nightmares about dying on the lunar surface, high heart rate, and conclude with the individual in question attempting to exit from the unit. ",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 19,
		"name": "Intruding Signal",
		"category": Category.SCIENTIFIC,
		"severity": 2,
		"danger": 1,
		"scale": 2,
		"type": Category.SCIENTIFIC,
		"description": "Intruding Signal is a common form of interference with radio equipment on and around the Moon due to the high amount of traffic, both physical and digital. This type of interference typically manifests in radio equipment as overlapping voices, subtle static, or sudden bursts of noise in received transmissions. \n \n If you believe that the signal originates from a Echo, please file under Echo (#32) ",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 20,
		"name": "Drone Crash",
		"category": Category.INDUSTRIAL,
		"severity": 2,
		"danger": 3,
		"scale": 1,
		"type": Category.INDUSTRIAL,
		"description": "Drone Crashes are a common type of accident in industrialized areas of the moon due to the large population of them. They are typically caused by the sudden loss of power within a drone unit, which can cause it to coast for miles before crashing with intense speed into infrastructure. \n \n The crash typically ejects the major components, such as propellers and computational units, while keeping the internal non-important componetns within itself. \n \n If a drone crash involves more than 20 drones, please file as a Major Industrial Accident (#57) \n \n If you believe the crash was caused intentionally by a third party, please file as Industrial Sabotage (#62)" ,
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 21,
		"name": "EVA Suit Misuse",
		"category": Category.SECURITY,
		"severity": 1,
		"danger": 2,
		"scale": 2,
		"type": Category.SECURITY,
		"description": "EVA Suit Misuse is often a result, or in better words, symptom of larger violations of the Lunar Surface Laws established by the PLC. As per regulation, EVA suits are not to be used in the commission of any crime, traspass onto restricted land, traspass onto decommissioned stations, and use beyond the orbit of the Moon or below the Moon's crust. \n \n Additionally, the use of an EVA suit outside of permitted hours 8:00 DH to 5:00 LH unless permitted via command. \n \n EVA Suit Misuse is punishable by 30 orbits within PLC jail.",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 22,
		"name": "Rover Computational Error",
		"category": Category.SCIENTIFIC,
		"severity": 2,
		"danger": 2,
		"scale": 1,
		"type": Category.SCIENTIFIC,
		"description": "Of the many errors that can occur with lunar rovers, computational errors regarding their computing systems are the most common on units manufactured before 2050 and before the Standards of Lunar Technology Act. Due to the nature of this type of incident, Incident Reporters will have to interface with the rover computational board in order to rectify the issue. Please use your primary terminal in order to do so. \n \n If the rover has crashed, please designate as Rover Crash (#53) instead.",
		"icon_path": "",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 23,
		"name": "Cave-In",
		"category": Category.GEOLOGICAL,
		"severity": 1,
		"danger": 1,
		"scale": 1,
		"type": Category.GENERAL,
		"description": "Cave-Ins are a very common event when exploring lunar caves and or lava tunnels. While the signs of a cave-in are obvious to describe, the primary issue with designating a cave-in is receiving a signal from the caller at all due to poor reception. Individuals involved in a cave in often have spotty reception, and may drop out of the call before fully complete. \n \n Additionally, due to the nature of lunar caves, some calls may need you to utilize lunar cave maps in order to identify where the caller is. These are located on your primary terminal.  ",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 24,
		"name": "Major Injury",
		"category": Category.MEDICAL,
		"severity": 3,
		"danger": 3,
		"scale": 1,
		"type": Category.MEDICAL,
		"description": "Unlike minor injuries, Major Injuries are significantly more dangerous, and must be handled more urgently. Additionally, Major Injuries have been 'sub-designated', which has led to there being entries for specific major injuries. These will not be listed here. This entry exists for injuries that are more general, such as broken bones and such, and not specific entries like Gunshot Wound (#54) and Long-Term Radiation Exposure (#55)",
		"icon_path": "",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 25,
		"name": "Apollo Muscaria",
		"category": Category.BIOLOGICAL,
		"severity": 2,
		"danger": 3,
		"scale": 3,
		"type": Category.BIOLOGICAL,
		"description": "Apollo Muscaria is a exotic, purple and white speckled, lunar mushroom that was discovered growing on the Apollo 11 lander, hence its name. However, Apollo Muscaria is one of the many biological threats upon the Moon as well, as it emits massive quantities of poisonous spores into the space around it. When introduced into a pressurized and atmospheric environment, Apollo Muscaria can poison entire stations if not handled quickly. \n \n If the caller has been poisoned by Apollo Muscaria, please refer to Apollo Muscaria Poisoning (#26) for designation.",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 26,
		"name": "Long-Term Gravity Deprevation Syndrome",
		"category": Category.MEDICAL,
		"severity": 2,
		"danger": 1,
		"scale": 1,
		"type": Category.MEDICAL,
		"description": "Long-Term Gravity Deprevation Syndrome is a side-effect of long-term habitation in a Zero-G environment that those who have never been in one for a extended period of time common experience. Medically speaking, LTGDS causes the body to undergo a series of rapid adaptations to make the human body more suitable to zero-g environments. Because of this, those afflicted often report feeling either lethargic, in constant pain, stressed, and dizzy or incredibly energetic, agile, aware, and strong. LTGDS varies between both extremes depending on the individual affectedd.",
		"icon_path": "",
		"unlocked_on_day": 3,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 27,
		"name": "Robbery",
		"category": Category.SECURITY,
		"severity": 2,
		"danger": 3,
		"scale": 1,
		"type": Category.SECURITY,
		"description": "A Robbery is a type of crime that is often committed on the Moon, more so than Earth due to the inherent higher value of everything present on the surface. Robbery is very easy to diagnose, as most callers recognize the fact that they have been robbed. \n Never let a caller convince you to help them find what they have lost. That is not your job. Should a caller ask you to help them, ignore the request and submit the report. \n You may request any corresponding files after your shift from the Archive Hall at Central Station.",
		"icon_path": "",
		"unlocked_on_day": 3,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 28,
		"name": "Unmarked Lava Tunnel",
		"category": Category.GEOLOGICAL,
		"severity": 2,
		"danger": 2,
		"scale": 2,
		"type": Category.GEOLOGICAL,
		"description": "Unmarked Lava Tunnels are a type of Natural Hazard that can present itself on the Lunar Surface. After the passing of the ULG's 'One Small Step' Act, all discovered Lava Tunnels have been marked with corresponding signage. However, some tunnels which had not been discovered at the time may be unmarked. Please advise the caller to back away from the tunnel, and report the tunnel to the authorities.",
		"icon_path": "",
		"unlocked_on_day": 4,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 29,
		"name": "Farm Overgrowth",
		"category": Category.BIOLOGICAL,
		"severity": 2,
		"danger": 2,
		"scale": 2,
		"type": Category.BIOLOGICAL,
		"description": "Farm Overgrowth is a common mistake made by first-time farmers when attempting to grow edible or non-edible plants. Most of the time, Farm Overgrowth exhibits itself quite obviously, with plant material growing outside the boundries of where it should. What is more vital is the reason as to why this is happening. \n \n The Lunar Farming Association suggests that first time farmers only use imported soil and grow lamps for their first harvests, as Lunar sunlight and Regolith have been shown to boost plant growth exponentially. If the plant grow isn't because of these two factors, please designate as something else.",
		"icon_path": "",
		"unlocked_on_day": 4,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 30,
		"name": "Minor System Malfunctions",
		"category": Category.GENERAL,
		"severity": 1,
		"danger": 1,
		"scale": 1,
		"type": Category.GENERAL,
		"description": "Minor System Malfunctions is a general classification of anomaly meant to designate any malfunction with non-essential systems aboard either a station or ship. These systems include, but are not limited to; Toiletry, Gravity Stabilizers, Agricultural Units that house any non-edible plant, Animal Storage Units that house any exotic animals, Clocks, Automated Cleaning System, and anything that the caller designates as Minor. If the system is in fact not minor, please designate it as a Major System Malfunction.",
		"icon_path": "res://wp12013121.jpg",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 32,
		"name": "Illegal EVA Suit Production",
		"category": Category.SECURITY,
		"severity": 1,
		"danger": 2,
		"scale": 1,
		"type": Category.SECURITY,
		"description": "In line with ULG Act #215, only Nectaris Lunar EVA suits are permitted on the Lunar surface. Any other EVA suit is strictly forbidden due to unregulated production. Due to this law, the production of EVA suits outside of Nectaris buildings is also illegal. While the use of said suits is also illegal, that is classed under another designation. This designation is only to be used when designated the production of EVA suits. If there is no evidence of EVA production, but it is heavily suspected by the caller, please still designate it as such.",
		"icon_path": "res://wp12013121.jpg",
		"unlocked_on_day": 3,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 33,
		"name": "Chemical Spill",
		"category": Category.SCIENTIFIC,
		"severity": 1,
		"danger": 1,
		"scale": 1,
		"type": Category.SCIENTIFIC,
		"description": "Chemical Spills are one of the most common accidents that can occur aboard a Lunar Scientific Outpost, but must be treated with the utmost care when suspected. Most commonly, those who suspect a Chemical Spill report empty chemical vials, strange smells, and most obviously, spilled chemicals. If a caller reports similar symptoms, but no spilled chemicals, please refer to Anomaly #75. If a caller reports a chemical spill with no symptoms besides the spilt chemicals, please mark as such.",
		"icon_path": "res://wp12013121.jpg",
		"unlocked_on_day": 4,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 34,
		"name": "Regolith Freeze-Up",
		"category": Category.GENERAL,
		"severity": 2,
		"danger": 3,
		"scale": 1,
		"type": Category.GENERAL,
		"description": "Regolith Freeze-Up is a type of thermal occurance that often manifests itself after a shower of ice-packed meteors. When exposed to large amounts of pressure, such as heavy loads or cars, the frozen regolith can burst into thousands of shards, then quickly resolidify, often trapping people and vehicles in it's wake. \\n It is advised to not tamper with the regolith post burst, as  \\n Due to the record high occurances of this anomaly as of late, no employers are allowed to demerit employees for lateness caused by Freeze-Ups. ",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 35,
		"name": "Lunar Psychosis",
		"category": Category.MEDICAL,
		"severity": 3,
		"danger": 3,
		"scale": 2,
		"type": Category.MEDICAL,
		"description": "Lunar Psychosis is a common psychological side-effect of long-term habitation on the moon. Since humanity has only recently attained the ability for mass settlement of the moon, those who do stay on the moon aren't prepared for the psychological stressors that lunar life comes with. \\n Those who especially cannot cope can suffer Lunar Psychosis, which, as the name implies, is a psychotic break in relation to the moon. Unlike Lunar Magnificance, Lunar Psychosis is often noted by the sufferer's disire to leave the Moon and return to where they came, Earth or not.",
		"icon_path": "",
		"unlocked_on_day": 3,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 36,
		"name": "Omitted Signs",
		"category": Category.ANOMALOUS,
		"severity": 3,
		"danger": 4,
		"scale": 3,
		"type": Category.ANOMALOUS,
		"description": "Omitted Signs refers to any and all signs not present in the Lunar Signage Database. Those reporting Omitted Signs typically describe said signs as containing illogical information, omnious information, or personal information. \\n Individuals are advised to not travel on any path that a Omitted Sign is on. If a individual has already begun to travel on a path with an Omitted Sign, submit instead as #56.",
		"icon_path": "",
		"unlocked_on_day": 5,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 37,
		"name": "Solar Panel Misalignment",
		"category": Category.GENERAL,
		"severity": 3,
		"danger": 1,
		"scale": 2,
		"type": Category.GENERAL,
		"description": "Solar Panel Misalignment is a common mechanical aliment of many automatically alligned solar panels. Due to the constant exposure to radiation, electronic systems have a tendency to malfunction slightly, which can cause the solar panels to misalign. While this isn't a major issue in the beginning, over time, this can cause major flucuations in power. \\n The most common symptom of Solar Panel Misalignment, besides the obvious visual misalignment of the solar panels, are power fluclations at both dusk and dawn, decreased available power dedicated towards minor systems, and even short-term blackouts due to improper battery charging. \\n To fix misalignment, please swap out the old motor control board within the solar panel to a replacement one.",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 38,
		"name": "Ice Geyser",
		"category": Category.GEOLOGICAL,
		"severity": 2,
		"danger": 2,
		"scale": 1,
		"type": Category.GEOLOGICAL,
		"description": "Ice Geysers are an uncommon Geological anomaly that can occur across the lunar surface, though more commonly in Mare Frigoris, Oceanus Procellarum, and Mare Imbrium. Ice Geysers are caused due to the sudden formation of liquid water pockets, often due to above-average exposure to sunlight, that suddenly burst out into space due to the pressure difference. \\n This is different from Regolith Freeze-Ups, as these geysers often explode much more violently, and spread large amounts of sharp ice shards around the area of detonation.",
		"icon_path": "",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
		{
		"id": 39,
		"name": "Cargo Accident",
		"category": Category.INDUSTRIAL,
		"severity": 2,
		"danger": 1,
		"scale": 3,
		"type": Category.INDUSTRIAL,
		"description": "Cargo Accidents are a type of industrial accident that can occasionally occur on the Lunar Surface. However, due to the large scale automation of transportation, there is little chance for any harm to befall a individual. Cargo Accidents are quite obvious to diagnose, but in order to qualify as a Cargo Accident, no human party must be at fault. \\n If a human party caused the accident, accidently, please file as a #40. \\n If a human party caused the accident intentionally, please file as a #51. \\n If a non-human party caused the accident, please file as a #61.",
		"icon_path": "",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 40,
		"name": "Accidental EMP Blast",
		"category": Category.SCIENTIFIC,
		"severity": 2,
		"danger": 3,
		"scale": 5,
		"type": Category.SCIENTIFIC,
		"description": "Accidental EMP Blasts are a major type of accident, and should be treated as such. In most cases, you will receive the report of a Accidental EMP Blast after the fact, this does not make the situation any less urgent. The calls you receive after a Accidental EMP Blast are much more important than the blast itself. The caller will usually indicate that one has happened. \\n If the caller manages to make contact before or during the blast, but does not indicate, the sudden disconnect should indicate it as well. You can also check the Lunar Power Grid Network to cross-reference if a power outage has occured.",
		"icon_path": "",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 41,
		"name": "Nanobug Swarm",
		"category": Category.GENERAL,
		"severity": 1,
		"danger": 1,
		"scale": 2,
		"type": Category.INDUSTRIAL,
		"description": "Nanobug Swarm is a common situation that those in or near industrial environments often find themselves. In order to minimize risk to human life, most corporations use automated cleaning and repair forces in order to maintain large scale industrial installments such as mining rigs, refinerers, and power plants. \\n The only sign of a Nanobug swarm is occasionaly clicking or ticking sounds originating from walls.",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 42,
		"name": "Noise Complaint",
		"category": Category.GENERAL,
		"severity": 1,
		"danger": 1,
		"scale": 1,
		"type": Category.GENERAL,
		"description": "Noise Complaints are a sub-set of complaints that often occur in residential areas. The signs of a noise complaint are quite obvious. If a traditional #16 complaint specifically notes noise as the reason for the complaint, please file as this. \\n If you believe that the Noise Complaint isn't as it seems, please designate as a #61. \\n If the location of a Noise Complaint is also in the same location as a 969 call, please file as a #72",
		"icon_path": "",
		"unlocked_on_day": 2,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 43,
		"name": "Door Malfunctions",
		"category": Category.GENERAL,
		"severity": 1,
		"danger": 2,
		"scale": 1,
		"type": Category.GENERAL,
		"description": "A Door Malfunction refers to any event affecting a door present within a lunar station. Often presents as an inability to open a door, rapid opening and closing of a door, or a loud whirring sound when attempting to open it. Can be solved locally by using a Manual Override Key, which is present in every room aboard every station according to regulation. If you do not have a override key, you can insert a small metal rod into the key slot instead, but this renders the door permnantly open. \n \n If the malfunction is instead present within an Airlock, please designate it as an Airlock Malfunction (#32). ",
		"icon_path": "",
		"unlocked_on_day": 1,
		"accessible": true,
		"exclusive_to_week": "",
	},
	{
		"id": 44,
		"name": "Root Instablity",
		"category": Category.GEOLOGICAL,
		"severity": 3,
		"danger": 2,
		"scale": 2,
		"type": Category.BIOLOGICAL,
		"description": "Root Instability is a geological anomaly that can occur when a vacuum-resistent species of plant is exposedd to Lunar Regolith. Due to the large amount of nitrogen and other nutrients that were added to the regolith near bases, plants tend to thrive in regolith when exposed, creating massive root structures that can span miles \\n This however causes problems for the stability of the regolith, as the roots often grow faster than the regolith has time to properly restabalize, often leading to minor shakes, and tremors, all the to Luna Shakes and Sinkholes.",
		"icon_path": "",
		"unlocked_on_day": 3,
		"accessible": true,
		"exclusive_to_week": "",
	},







]


# ── Filtering helpers ─────────────────────────────────────────────────────────

## Returns true if the entry should be visible right now, given the
## current week and day. All public API goes through this.
func _is_entry_visible(entry: Dictionary) -> bool:
	if not entry.get("accessible", true):
		return false

	var unlock_day: int = entry.get("unlocked_on_day", 1)
	if GameState.current_day < unlock_day:
		return false

	var exclusive_week: String = entry.get("exclusive_to_week", "")
	if exclusive_week != "" and exclusive_week != GameState.current_week_id:
		return false

	return true


# ── Public API ────────────────────────────────────────────────────────────────

func get_entry(id: int) -> Dictionary:
	for entry in entries:
		if entry["id"] == id:
			if not _is_entry_visible(entry):
				return {"status": NOT_ACCESSIBLE}
			return entry
	return {"status": NOT_FOUND}

func _is_entry_navigable(entry: Dictionary) -> bool:
	if not entry.get("accessible", true):
		return false
	var exclusive_week: String = entry.get("exclusive_to_week", "")
	if exclusive_week != "" and exclusive_week != GameState.current_week_id:
		return false
	return true

func get_next_id(current_id: int, direction: int, category: Category) -> int:
	var valid_ids: Array[int] = []
	for entry in entries:
		if not _is_entry_navigable(entry):  # <-- changed from _is_entry_visible
			continue
		if category == Category.ALL or entry["category"] == category:
			valid_ids.append(entry["id"])
	valid_ids.sort()

	if valid_ids.is_empty():
		return current_id

	if direction > 0:
		for id in valid_ids:
			if id > current_id:
				return id
		return valid_ids.back()
	else:
		var reversed := valid_ids.duplicate()
		reversed.reverse()
		for id in reversed:
			if id < current_id:
				return id
		return valid_ids.front()

func get_category_name(category: Category) -> String:
	match category:
		Category.ALL:        return "ALL"
		Category.MEDICAL:    return "MEDICAL"
		Category.SECURITY:   return "SECURITY"
		Category.GEOLOGICAL: return "GEOLOGICAL"
		Category.SCIENTIFIC: return "SCIENTIFIC"
		Category.BIOLOGICAL: return "BIOLOGICAL"
		Category.INDUSTRIAL: return "INDUSTRIAL"
		Category.UNKNOWN:    return "UNKNOWN"
		Category.ANOMALOUS:  return "ANOMALOUS"
		Category.GENERAL:    return "GENERAL"
	return "ALL"
