-- keeps track of the buffs for the bot mining mining_efficiency
robot_mining = {
    damage = 0,
    active_modifier = 0,
    research_modifier = 0,
    delay = 0
}



require 'data_stages'
_LIFECYCLE = _STAGE.control -- Control stage
require 'refresh_map'
require "diggy_hole"
require "lib.lib"

require "script.remote-api"
require "script.layout"
require "script.factory-buildings"
require "script.connections.connections"
require "script.roboport.roboport"
require "script.blueprint"
require "script.camera"
require "script.travel"
require "script.overlay"
require "script.pollution"
require "script.electricity"
require "script.greenhouse"
require "script.lights"
require "script.port-markers"
require "script.borehole-pump"
require "script.migration"

require "compat.factorio-maps"
require "compat.cerys"
require "compat.maraxsis"
require "compat.resource-spawner-overhaul"
require "compat.picker-dollies"



factorissimo.finalize_events()
