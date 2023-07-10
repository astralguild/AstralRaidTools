local L = select(2, ...).L('koKR')

-- Common Terms/Phrases
L['CAST'] = 'Cast'
L['AURA'] = 'Aura'
L['RAID'] = RAID
L['GUILD'] = GUILD
L['PARTY'] = PARTY
L['FONT'] = 'Font'
L['FONT_SIZE'] = 'Font Size'
L['SHOW_IN_PARTY'] = 'Show in Party'
L['PRINT_RESULTS'] = 'Print Results'
L['LOG_TO_DISK'] = 'Log to Disk'
L['ROSTER'] = 'Roster'
L['SEND_TO_LOCAL'] = 'Send to Local'
L['SEND_TO_OFFICER'] = 'Send to Officer'
L['SEND_TO_GROUP'] = 'Send to Group'
L['ICON_SIZE'] = 'Icon Size'

-- Modules
L['GENERAL_OPTIONS'] = 'General Options'
L['REMINDERS'] = 'Reminders'
L['BOSS_MODULES'] = 'Boss Modules'
L['EARLY_PULL'] = 'Early Pull'
L['NOTIFIERS'] = 'Notifiers'

-- Options
L['TOGGLE_OPTIONS'] = 'Left click to toggle options window'
L['SHOW_MINIMAP_BUTTON'] = 'Show Minimap Button'

-- Reminders
L['RELEASE_SPIRIT'] = 'Release Spirit' -- important to have same as in-game UI
L['EAT_FOOD'] = 'EAT FOOD'
L['CAULDRON_DOWN'] = 'CAULDRON DOWN'
L['REPAIR'] = 'REPAIR'
L['GRAB_HEALTHSTONES'] = 'GRAB HEALTHSTONES'
L['GRAB_HEALING_POTIONS'] = 'GRAB HEALING POTIONS'
L['GRAB_COMBAT_POTIONS'] = 'GRAB COMBAT POTIONS'
L['RUNE_UP'] = 'RUNE UP'
L['DONT_RELEASE'] = 'DONT RELEASE'
L['REMINDERS_OPTIONS'] = 'Reminders Options'
L['TEST_REMINDERS'] = 'Test Reminders'
L['SPECIFIC_REMINDERS'] = 'Specific Reminders'

-- Early Pull
L['BOSS_PULLED'] = 'Boss pulled'
L['BOSS_PULLED_EARLY'] = 'Boss pulled %.2f seconds early'
L['BOSS_PULLED_ON_TIME'] = 'Boss pulled on time'
L['BOSS_PULLED_LATE'] = 'Boss pulled %.2f seconds late'
L['EARLY_PULL_DETECTION'] = 'Early Pull Detection'
L['EARLY_PULL_PRINT_RESULTS'] = 'Print Results to Local '
L['EARLY_PULL_DESC'] = 'Even if this module is enabled, only one group member will announce based on role and rank.'
L['EARLY_PULL_ANNOUNCE'] = 'Announce on Pull'
L['UNTIMED_PULL'] = 'Untimed Pull'
L['LATE_PULL'] = 'Late Pull'
L['ON_TIME_PULL']  = 'On-Time Pull'

-- Notifiers
L['ENABLE_NOTIFIER'] = 'Enable Notifier'
L['ENCOUNTER_NOTIFIERS'] = 'Encounter Notifiers'
L['SPECIFIC_NOTIFIERS'] = 'Specific Notifiers'
L['AURA_NOTIFIER_MSG'] = '%s affected by %s at %s'
L['CAST_NOTIFIER_MSG'] = '%s used %s (target: %s) at %s'

-- BossModules
L['BDG_NELTH_HEART_TITLE'] = 'BDG Heart Macro Detection'
L['BDG_NELTH_HEART_DESC'] = 'Notify on heart macro press from %s.'
L['BDG_NELTH_HEART_ICON_DESC'] = 'Show an icon on %s that only hides when you press the macro.'
L['BDG_NELTH_HEART_SET_MESSAGE'] = 'Heart (set %d) completed in %.2fs.'
L['BDG_NELTH_HEART_PRESSED_MESSAGE'] = 'Heart (set %d) macro (%d) hit by %s at %s after %.2fs'
L['BDG_NELTH_HEART_PRESSED_MESSAGE_UNKNOWN_TIME'] = 'Heart (set %d) macro (%d) hit by %s at %s after unknown time (no known last heart event)'
L['BDG_NELTH_HEART_PRESSED_MESSAGE_PERSONAL'] = 'Pressed macro in %.2fs'
L['BDG_NELTH_HEART_PRESSED_MESSAGE_PERSONAL_UNKNOWN_TIME'] = 'Pressed macro'
L['BDG_NELTH_HEART_ENABLE_ICON'] = 'Enable Large Icon'

-- Roster
L['ROSTER_VIEW'] = 'Roster View'
L['NO_RESPONSE'] = 'No Response'
L['YOUR_VERSION'] = 'Your Version'
L['THEIR_VERSION'] = 'Their Version'
L['ROSTER_MUST_BE_IN_GROUP'] = 'You must be in a group to inspect a group roster.'

-- Information
L['ADDON_SUMMARY'] = 'Astral |cfff5e4a8Raid Tools|r is a packaged set of tools for raid leaders and raiders.'
L['ADDON_DESC'] = 'Raid leaders can use this addon to perform raid roster management and raiders can have access to specific tier-specific boss modules, get visual reminders pre-pull and during pull, and many other useful tools.'