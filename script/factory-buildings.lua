
-- dependencies
local Event = require 'utils.event'
local Token = require 'utils.token'
local Template = require 'template'

----------- diggy hole -------------
local Task = require 'utils.task'
local CreateParticles = require 'features.create_particles'

local is_diggy_rock = Template.is_diggy_rock
local mine_rock = CreateParticles.mine_rock
local set_timeout_in_ticks = Task.set_timeout_in_ticks

---Triggers a diggy diggy hole for a given big-rock, big-rock or huge-rock.
---@param entity LuaEntity
local function diggy_hole(entity)
    local tiles = {}
    local rocks = {}
    local surface = entity.surface
    local position = entity.position
    local x = position.x
    local y = position.y
    local get_tile = surface.get_tile
    local out_of_map_found = {}
    local count = 0
    game.print("IN DIGGY HOLE!!!!!")
    game.print("  "..get_tile(x, y - 1).name)
    game.print("  "..get_tile(x+1, y ).name)
    game.print("  "..get_tile(x, y + 1).name)
    game.print("  "..get_tile(x - 1, y).name)
    if (get_tile(x, y - 1).name == 'out-of-map') then
        count = count + 1
        out_of_map_found[count] = {x = x, y = y - 1}
    end

    if (get_tile(x + 1, y).name == 'out-of-map') then
        count = count + 1
        out_of_map_found[count] = {x = x + 1, y = y}
    end

    if (get_tile(x, y + 1).name == 'out-of-map') then
        count = count + 1
        out_of_map_found[count] = {x = x, y = y + 1}
    end

    if (get_tile(x - 1, y).name == 'out-of-map') then
        out_of_map_found[count + 1] = {x = x - 1, y = y}
    end

    for i = #out_of_map_found, 1, -1 do
        local void_position = out_of_map_found[i]
        tiles[i] = {name = 'dirt-' .. math.random(1, 7), position = void_position}
        local predicted = math.random()
        if predicted < 0.2 then
            rocks[i] = {name = 'huge-rock', position = void_position}
        elseif predicted < 0.6 then
            rocks[i] = {name = 'big-rock', position = void_position}
        else
            rocks[i] = {name = 'big-rock', position = void_position}
        end
    end

    Template.insert(surface, tiles, rocks)
end

-- Used in conjunction with set_timeout_in_ticks(robot_mining_delay...  to control bot mining frequency
-- Robot_mining.damage is equal to robot_mining_delay * robot_per_tick_damage
-- So for example if robot_mining delay is doubled, robot_mining.damage gets doubled to compensate.
local metered_bot_mining = Token.register(function(params)
    local entity = params.entity
    local force = params.force
    local health_update = params.health_update
    if entity.valid then
        local health = entity.health
        --If health of entity didn't change during delay apply bot mining damage and re-order order_deconstruction
        --If rock was damaged during the delay the bot gets scared off and stops mining this particular rock.
        if health_update == health - robot_mining.damage then
            entity.health = health_update
            entity.order_deconstruction(force)
        end
    end
end)

local artificial_tiles = {
    ['stone-brick'] = true,
    ['stone-path'] = true,
    ['concrete'] = true,
    ['hazard-concrete-left'] = true,
    ['hazard-concrete-right'] = true,
    ['refined-concrete'] = true,
    ['refined-hazard-concrete-left'] = true,
    ['refined-hazard-concrete-right'] = true,
}

local function on_mined_tile(surface, tiles)
    local new_tiles = {}
    local count = 0
    for _, tile in pairs(tiles) do
        if (artificial_tiles[tile.old_tile.name]) then
            count = count + 1
            new_tiles[count] = {name = 'dirt-' .. math.random(1, 7), position = tile.position}
        end
    end

    Template.insert(surface, new_tiles, {})
end

---- Didnt add this one....
-- local robot_damage_per_mining_prod_level = cfg.robot_damage_per_mining_prod_level
    -- Event.add(defines.events.on_research_finished, function (event)
    --     local new_modifier = event.research.force.mining_drill_productivity_bonus * 50 * robot_damage_per_mining_prod_level

    --     if (robot_mining.research_modifier == new_modifier) then
    --         -- something else was researched
    --         return
    --     end

    --     robot_mining.research_modifier = new_modifier
    --     update_robot_mining_damage()
    -- end)

-----------end diggy hole-----------

----------------added-------------------

local get_factory_by_building = remote_api.get_factory_by_building
local find_surrounding_factory = remote_api.find_surrounding_factory
local insert = table.insert
local has_layout = has_layout

-- INITIALIZATION --

factorissimo.on_event(factorissimo.events.on_init(), function()
    -- List of all factories
    storage.factories = storage.factories or {}
    -- Map: Id from item-with-tags -> Factory
    storage.saved_factories = storage.saved_factories or {}
    -- Map: Entity unit number -> Factory it is a part of
    storage.factories_by_entity = storage.factories_by_entity or {}
    -- Map: Surface index -> list of factories on it
    storage.surface_factories = storage.surface_factories or {}
    -- Scalar
    storage.next_factory_surface = storage.next_factory_surface or 0
end)

-- RECURSION TECHNOLOGY --

local function does_original_planet_match_surface(original_planet, surface)
    if not original_planet then return true end
    if not original_planet.valid then return false end
    local original_planet_name = original_planet.surface.name:gsub("%-factory%-floor$", "")
    local surface_name = surface.name:gsub("%-factory%-floor$", "")
    return original_planet_name == surface_name
end

local function can_place_factory_here(tier, surface, position, original_planet)
    if not does_original_planet_match_surface(original_planet, surface) then
        local original_planet_name = original_planet.name:gsub("%-factory%-floor$", "")
        local original_planet_prototype = (game.planets[original_planet_name] or original_planet).prototype
        local flying_text = {"factory-connection-text.invalid-placement-planet", original_planet_name, original_planet_prototype.localised_name}
        factorissimo.create_flying_text {position = position, text = flying_text}
        return false
    end

    local factory = find_surrounding_factory(surface, position)
    if not factory then return true end
    local outer_tier = factory.layout.tier
    if outer_tier > tier and (factory.force.technologies["factory-recursion-t1"].researched or settings.global["Factorissimo2-free-recursion"].value) then return true end
    if (outer_tier >= tier or settings.global["Factorissimo2-better-recursion-2"].value)
        and (factory.force.technologies["factory-recursion-t2"].researched or settings.global["Factorissimo2-free-recursion"].value) then
        return true
    end
    if outer_tier > tier then
        factorissimo.create_flying_text {position = position, text = {"factory-connection-text.invalid-placement-recursion-1"}}
    elseif (outer_tier >= tier or settings.global["Factorissimo2-better-recursion-2"].value) then
        factorissimo.create_flying_text {position = position, text = {"factory-connection-text.invalid-placement-recursion-2"}}
    else
        factorissimo.create_flying_text {position = position, text = {"factory-connection-text.invalid-placement"}}
    end
    return false
end

local function build_factory_upgrades(factory)
    factorissimo.build_lights_upgrade(factory)
    factorissimo.build_greenhouse_upgrade(factory)
    factorissimo.build_display_upgrade(factory)
    factorissimo.build_roboport_upgrade(factory)
end

--- If a factory factory is built without proper recursion technology, it will be inactive.
--- This function reactivates these factories once the research is complete.
local function activate_factories()
    for _, factory in pairs(storage.factories) do
        factory.inactive = factory.outside_surface.valid and not can_place_factory_here(
            factory.layout.tier,
            factory.outside_surface,
            {x = factory.outside_x, y = factory.outside_y},
            factory.original_planet
        )

        build_factory_upgrades(factory)
    end
end
factorissimo.on_event(factorissimo.events.on_init(), activate_factories)

factorissimo.on_event({defines.events.on_research_finished, defines.events.on_research_reversed}, function(event)
    if not storage.factories then return end -- In case any mod or scenario script calls LuaForce.research_all_technologies() during its on_init
    local name = event.research.name
    if name == "factory-interior-upgrade-lights" then
        for _, factory in pairs(storage.factories) do factorissimo.build_lights_upgrade(factory) end
    elseif name == "factory-interior-upgrade-display" then
        for _, factory in pairs(storage.factories) do factorissimo.build_display_upgrade(factory) end
    elseif name == "factory-interior-upgrade-roboport" then
        for _, factory in pairs(storage.factories) do factorissimo.build_roboport_upgrade(factory) end
    elseif name == "factory-upgrade-greenhouse" then
        for _, factory in pairs(storage.factories) do factorissimo.build_greenhouse_upgrade(factory) end
    elseif name == "factory-recursion-t1" or name == "factory-recursion-t2" then
        activate_factories()
    end
end)

local function update_recursion_techs(force)
    if settings.global["Factorissimo2-hide-recursion"] and settings.global["Factorissimo2-hide-recursion"].value then
        force.technologies["factory-recursion-t1"].enabled = false
        force.technologies["factory-recursion-t2"].enabled = false
    elseif settings.global["Factorissimo2-hide-recursion-2"] and settings.global["Factorissimo2-hide-recursion-2"].value then
        force.technologies["factory-recursion-t1"].enabled = true
        force.technologies["factory-recursion-t2"].enabled = false
    else
        force.technologies["factory-recursion-t1"].enabled = true
        force.technologies["factory-recursion-t2"].enabled = true
    end
end

factorissimo.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting_type == "runtime-global" then activate_factories() end

    for _, force in pairs(game.forces) do
        update_recursion_techs(force)
    end
end)

factorissimo.on_event(defines.events.on_force_created, function(event)
    local force = event.force
    update_recursion_techs(force)
end)

factorissimo.on_event(factorissimo.events.on_init(), function()
    for _, force in pairs(game.forces) do
        update_recursion_techs(force)
    end
end)

-- FACTORY GENERATION --

local function update_destructible(factory)
    if factory.built and factory.building.valid then
        factory.building.destructible = not settings.global["Factorissimo2-indestructible-buildings"].value
    end
end

local function get_surface_name(layout, parent_surface)
    if factorissimo.surface_override then return factorissimo.surface_override end

    if parent_surface.planet then
        return (parent_surface.name .. "-factory-floor"):gsub("%-factory%-floor%-factory%-floor", "-factory-floor")
    end

    storage.next_factory_surface = storage.next_factory_surface + 1
    return storage.next_factory_surface .. "-factory-floor"
end

factorissimo.on_event(defines.events.on_surface_created, function(event)
    local surface = game.get_surface(event.surface_index)
    if not surface.name:find("%-factory%-floor$") then return end

    local mgs = surface.map_gen_settings
    mgs.width = 2
    mgs.height = 2
    surface.map_gen_settings = mgs
end)

local function create_factory_position(layout, building)
    local parent_surface = building.surface
    local surface_name = get_surface_name(layout, parent_surface)
    local surface = game.get_surface(surface_name)

    if surface then
        -- A bit of extra safety to ensure grass does not generate.
        local mgs = surface.map_gen_settings
        mgs.width = 2
        mgs.height = 2
        surface.map_gen_settings = mgs
    else
        if remote.interfaces["RSO"] then -- RSO compatibility
            pcall(remote.call, "RSO", "ignoreSurface", surface_name)
        end

        local planet = game.planets[surface_name]
        if planet then
            surface = planet.surface or planet.create_surface()
        end

        if not surface then
            surface = game.create_surface(surface_name, {width = 2, height = 2})
            surface.localised_name = {"factory-floor", storage.next_factory_surface}
        end

        surface.daytime = 0.5
        surface.freeze_daytime = true
    end

    local n = 0
    for _, factory in pairs(storage.factories) do
        if factory.inside_surface.valid and factory.inside_surface == surface then n = n + 1 end
    end

    local FACTORISSIMO_CHUNK_SPACING = 16
    local cx = FACTORISSIMO_CHUNK_SPACING * (n % 8)
    local cy = FACTORISSIMO_CHUNK_SPACING * math.floor(n / 8)
    -- To make void chnks show up on the map, you need to tell them they've finished generating.
    for xx = -2, 2 do
        for yy = -2, 2 do
            surface.set_chunk_generated_status({cx + xx, cy + yy}, defines.chunk_generated_status.entities)
        end
    end
    surface.destroy_decoratives {area = {{32 * (cx - 2), 32 * (cy - 2)}, {32 * (cx + 2), 32 * (cy + 2)}}}
    factorissimo.spawn_maraxsis_water_shaders(surface, {x = cx, y = cy})

    local factory = {}
    factory.inside_surface = surface
    factory.inside_x = 32 * cx
    factory.inside_y = 32 * cy
    factory.stored_pollution = 0
    factory.outside_x = building.position.x
    factory.outside_y = building.position.y
    factory.outside_door_x = factory.outside_x + layout.outside_door_x
    factory.outside_door_y = factory.outside_y + layout.outside_door_y
    factory.outside_surface = building.surface

    storage.surface_factories[surface.index] = storage.surface_factories[surface.index] or {}
    storage.surface_factories[surface.index][n + 1] = factory

    local fn = table_size(storage.factories) + 1
    storage.factories[fn] = factory
    factory.id = fn

    return factory
end

local function add_tile_rect(tiles, tile_name, xmin, ymin, xmax, ymax) -- tiles is rw
    local i = #tiles
    for x = xmin, xmax - 1 do
        for y = ymin, ymax - 1 do
            i = i + 1
            tiles[i] = {name = tile_name, position = {x, y}}
        end
    end
end

local function add_hidden_tile_rect(factory)
    local surface = factory.inside_surface
    local layout = factory.layout
    local xmin = factory.inside_x - 64
    local ymin = factory.inside_y - 64
    local xmax = factory.inside_x + 64
    local ymax = factory.inside_y + 64

    local position = {0, 0}
    for x = xmin, xmax - 1 do
        for y = ymin, ymax - 1 do
            position[1] = x
            position[2] = y
            surface.set_hidden_tile(position, "water")
        end
    end
end

local function add_tile_mosaic(tiles, tile_name, xmin, ymin, xmax, ymax, pattern) -- tiles is rw
    local i = #tiles
    for x = 0, xmax - xmin - 1 do
        for y = 0, ymax - ymin - 1 do
            if (string.sub(pattern[y + 1], x + 1, x + 1) == "+") then
                i = i + 1
                tiles[i] = {name = tile_name, position = {x + xmin, y + ymin}}
            end
        end
    end
end

local function create_factory_interior(layout, building)
    local force = building.force

    local factory = create_factory_position(layout, building)
    factory.building = building
    factory.layout = layout
    factory.force = force
    factory.quality = building.quality
    factory.inside_door_x = layout.inside_door_x + factory.inside_x
    factory.inside_door_y = layout.inside_door_y + factory.inside_y
    local tiles = {}
    for _, rect in pairs(layout.rectangles) do
        add_tile_rect(tiles, rect.tile, rect.x1 + factory.inside_x, rect.y1 + factory.inside_y, rect.x2 + factory.inside_x, rect.y2 + factory.inside_y)
    end
    for _, mosaic in pairs(layout.mosaics) do
        add_tile_mosaic(tiles, mosaic.tile, mosaic.x1 + factory.inside_x, mosaic.y1 + factory.inside_y, mosaic.x2 + factory.inside_x, mosaic.y2 + factory.inside_y, mosaic.pattern)
    end
    for _, cpos in pairs(layout.connections) do
        table.insert(tiles, {name = layout.connection_tile, position = {factory.inside_x + cpos.inside_x, factory.inside_y + cpos.inside_y}})
    end
    factory.inside_surface.set_tiles(tiles)
    add_hidden_tile_rect(factory)

    factorissimo.get_or_create_inside_power_pole(factory)
    factorissimo.spawn_cerys_entities(factory)

    local radar = factory.inside_surface.create_entity {
        name = "factory-hidden-radar",
        position = {factory.inside_x, factory.inside_y},
        force = force,
    }
    radar.destructible = false
    factory.radar = radar
    factory.inside_overlay_controllers = {}

    factory.connections = {}
    factory.connection_settings = {}
    factory.connection_indicators = {}

    return factory
end

local function create_factory_exterior(factory, building)
    local layout = factory.layout
    local force = factory.force
    factory.outside_x = building.position.x
    factory.outside_y = building.position.y
    factory.outside_door_x = factory.outside_x + layout.outside_door_x
    factory.outside_door_y = factory.outside_y + layout.outside_door_y
    factory.outside_surface = building.surface

    local oer = factory.outside_surface.create_entity {name = layout.outside_energy_receiver_type, position = {factory.outside_x, factory.outside_y}, force = force}
    oer.destructible = false
    oer.operable = false
    oer.rotatable = false
    factory.outside_energy_receiver = oer

    factory.outside_overlay_displays = {}
    factory.outside_port_markers = {}

    storage.factories_by_entity[building.unit_number] = factory
    factory.building = building
    factory.built = true

    factorissimo.recheck_factory(factory, nil, nil)
    factorissimo.update_power_connection(factory)
    factorissimo.update_overlay(factory)
    update_destructible(factory)
    build_factory_upgrades(factory)
    return factory
end

local function create_mine_exterior(factory, building)
    local layout = factory.layout
    local force = factory.force
    factory.outside_x = building.position.x
    factory.outside_y = building.position.y
    factory.outside_door_x = factory.outside_x + layout.outside_door_x
    factory.outside_door_y = factory.outside_y + layout.outside_door_y
    factory.outside_surface = building.surface

    local oer = factory.outside_surface.create_entity {name = layout.outside_energy_receiver_type, position = {factory.outside_x, factory.outside_y}, force = force}
    oer.destructible = false
    oer.operable = false
    oer.rotatable = false
    factory.outside_energy_receiver = oer

    factory.outside_overlay_displays = {}
    factory.outside_port_markers = {}

    storage.factories_by_entity[building.unit_number] = factory
    factory.building = building
    factory.built = true

    factorissimo.recheck_factory(factory, nil, nil)
    -- factorissimo.update_power_connection(factory)
    factorissimo.update_overlay(factory)
    update_destructible(factory)
    -- build_factory_upgrades(factory)
    return factory
end

local function cleanup_factory_exterior(factory, building)
    factorissimo.cleanup_outside_energy_receiver(factory)
    factorissimo.cleanup_factory_roboport_exterior_chest(factory)

    factorissimo.disconnect_factory_connections(factory)
    for _, render_id in pairs(factory.outside_overlay_displays) do
        local object = rendering.get_object_by_id(render_id)
        if object then object.destroy() end
    end
    factory.outside_overlay_displays = {}
    for _, render_id in pairs(factory.outside_port_markers) do
        local object = rendering.get_object_by_id(render_id)
        if object then object.destroy() end
    end
    factory.outside_port_markers = {}
    factory.building = nil
    factory.built = false
end

-- FACTORY MINING AND DECONSTRUCTION --

local sprite_path_translation = {
    virtual = "virtual-signal",
}
local function generate_factory_item_description(factory)
    local overlay = factory.inside_overlay_controller
    local params = {}
    if overlay and overlay.valid then
        for _, section in pairs(overlay.get_or_create_control_behavior().sections) do
            for _, filter in pairs(section.filters) do
                if filter.value and filter.value.name then
                    local sprite_type = sprite_path_translation[filter.value.type] or filter.value.type
                    table.insert(params, "[" .. sprite_type .. "=" .. filter.value.name .. "]")
                end
            end
        end
    end
    local params = table.concat(params, "\n")
    if params ~= "" then return "[font=heading-2]" .. params .. "[/font]" end
end

local function reverse_event(id)
    for name, event_id in pairs(defines.events) do
      if id == event_id then
        return name
      end
    end
  end

-- How players pick up factories
-- Working factory buildings don't return items, so we have to manually give the player an item
factorissimo.on_event({
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.on_space_platform_mined_entity
}, function(event)
    local entity = event.entity
    local name = entity.name
    local event_name = reverse_event(event.name)
    -- game.print("mined event")
    -- game.print(reverse_event(event.name))
    if  is_diggy_rock(name) then
        -- game.print("is diggy rock")
        if event_name == "on_robot_mined_entity" then
            game.print("robo mined")
            local health = entity.health
            local health_update = health - robot_mining.damage
            event.buffer.clear()

            local graphics_variation = entity.graphics_variation
            local create_entity = entity.surface.create_entity
            local create_particle = entity.surface.create_particle
            local position = entity.position
            local force = event.robot.force
            local delay = robot_mining.delay

            if health_update < 1 then
                entity.die(force)
                return
            end
            entity.destroy()

            local rock = create_entity({name = name, position = position})
            mine_rock(create_particle, math.ceil(delay / 2), position)
            rock.graphics_variation = graphics_variation
            rock.health = health
            --Mark replaced rock for de-construction and apply health_update after delay.  Health verified and
            --update applied after delay to help prevent more rapid damage if someone were to spam deconstruction blueprints
            set_timeout_in_ticks(delay, metered_bot_mining, {entity = rock, force = force, health_update = health_update})
        end

        if event_name == "on_player_mined_entity" then
            game.print("player mined")
            event.buffer.clear()

            diggy_hole(entity)
            mine_rock(entity.surface.create_particle, 6, entity.position)
        end    
    end
    ----
    if not has_layout(entity.name) then return end

    local factory = get_factory_by_building(entity)
    if not factory then return end
    cleanup_factory_exterior(factory, entity)
    storage.saved_factories[factory.id] = factory
    local buffer = event.buffer
    buffer.clear()
    buffer.insert {
        name = factory.layout.name .. "-instantiated",
        count = 1,
        tags = {id = factory.id},
        custom_description = generate_factory_item_description(factory),
        quality = entity.quality,
        health = entity.health / entity.max_health
    }
    local item_stack = buffer[1]
    assert(item_stack.valid_for_read and item_stack.is_item_with_tags)
    local item = item_stack.item
    assert(item and item.valid)
    factory.item = item
end)


factorissimo.on_event({
    defines.events.on_robot_mined_tile
}, function(event)
    on_mined_tile(event.robot.surface, event.tiles)
end)

factorissimo.on_event({
    defines.events.on_player_mined_tile
}, function(event)
    on_mined_tile(game.surfaces[event.surface_index], event.tiles)
end)

local function prevent_factory_mining(entity)
    local factory = get_factory_by_building(entity)
    if not factory then return end
    storage.factories_by_entity[entity.unit_number] = nil
    local entity = entity.surface.create_entity {
        name = entity.name,
        position = entity.position,
        force = entity.force,
        raise_built = false,
        create_build_effect_smoke = false,
        player = entity.last_user
    }
    storage.factories_by_entity[entity.unit_number] = factory
    factory.building = entity
    factorissimo.update_overlay(factory)
    if #factory.outside_port_markers ~= 0 then
        factory.outside_port_markers = {}
        toggle_port_markers(factory)
    end
    factorissimo.create_flying_text {position = entity.position, text = {"factory-cant-be-mined"}}
end

local fake_robots = {["repair-block-robot"] = true} -- Modded construction robots with heavy control scripting
factorissimo.on_event(defines.events.on_robot_pre_mined, function(event)
    local entity = event.entity
    if has_layout(entity.name) and fake_robots[event.robot.name] then
        prevent_factory_mining(entity)
        entity.destroy()
    elseif entity.type == "item-entity" and entity.stack.valid_for_read and has_layout(entity.stack.name) then
        event.robot.destructible = false
    end
end)

-- How biters pick up factories
-- Too bad they don't have hands
factorissimo.on_event(defines.events.on_entity_died, function(event)
    local entity = event.entity
    
    local name = entity.name
    game.print("entity died event")
    if  is_diggy_rock(name) then
        game.print("entity died is diggy rock")
        if event.loot then
            event.loot.clear()
        end
        diggy_hole(entity)
    end

    if not has_layout(entity.name) then return end
    local factory = get_factory_by_building(entity)
    
    if factory then 
        storage.saved_factories[factory.id] = factory
        cleanup_factory_exterior(factory, entity)

        local items = entity.surface.spill_item_stack {
            position = entity.position,
            stack = {
                name = factory.layout.name .. "-instantiated",
                tags = {id = factory.id},
                quality = entity.quality.name,
                count = 1,
                custom_description = generate_factory_item_description(factory)
            },
            enable_looted = true,
            force = entity.force_index,
            allow_belts = false,
            max_radius = 0,
            use_start_position_on_failure = true
        }
        assert(table_size(items) == 1)
        local item = items[1].stack.item
        assert(item and item.valid)
        factory.item = item
    end
end)

factorissimo.on_event(defines.events.on_post_entity_died, function(event)
    if not has_layout(event.prototype.name) or not event.ghost then return end
    local factory = storage.factories_by_entity[event.unit_number]
    if not factory then return end
    event.ghost.tags = {id = factory.id}
end)

-- Just rebuild the factory in this case
factorissimo.on_event(defines.events.script_raised_destroy, function(event)
    local entity = event.entity
    local name = entity.name
    if is_diggy_rock(name) then
        diggy_hole(entity)
    end
    
    if has_layout(entity.name) then
        prevent_factory_mining(entity)
    end
end)

local function on_delete_surface(surface)
    storage.surface_factories[surface.index] = nil

    local childen_surfaces_to_delete = {}
    for _, factory in pairs(storage.factories) do
        local inside_surface = factory.inside_surface
        local outside_surface = factory.outside_surface
        if inside_surface.valid and outside_surface.valid and factory.outside_surface == surface then
            game.print("q")
            childen_surfaces_to_delete[inside_surface.index] = inside_surface
        end
    end

    for _, factory_list in pairs{storage.factories, storage.saved_factories, storage.factories_by_entity} do
        for k, factory in pairs(factory_list) do
            local inside_surface = factory.inside_surface
            if not inside_surface.valid or childen_surfaces_to_delete[inside_surface.index] then
                factory_list[k] = nil
            end
        end
    end

    for _, child_surface in pairs(childen_surfaces_to_delete) do
        on_delete_surface(child_surface)
        game.delete_surface(child_surface)
    end
end

-- Delete all children surfaces in this case.
factorissimo.on_event(defines.events.on_pre_surface_cleared, function(event)
    on_delete_surface(game.get_surface(event.surface_index))
end)

-- FACTORY PLACEMENT AND INITALIZATION --

local function create_fresh_factory(entity)
    local layout = remote_api.create_layout(entity.name, entity.quality)
    local factory = create_factory_interior(layout, entity)
    create_factory_exterior(factory, entity)
    factory.original_planet = entity.surface.planet
    factory.inactive = not can_place_factory_here(layout.tier, entity.surface, entity.position)
    return factory
end


local function create_mine_surface(entity)
    
    -- local factory = create_factory_interior(layout, entity) -- only need to init a new surface

------------------------------
---
    
    local layout = remote_api.create_layout("mine_entrance", entity.quality)
    local building = entity
    local parent_surface = building.surface
    local surface_name =  parent_surface.name.."_mine_level"
    local surface = game.get_surface(surface_name)

    if surface then
        
    else
        
        surface = game.create_surface(surface_name)
        surface.localised_name = {surface_name,1}
       
        surface.daytime = 0.5
        surface.freeze_daytime = true

    end

    local n = 0
    for _, factory in pairs(storage.factories) do
        if factory.inside_surface.valid and factory.inside_surface == surface then n = n + 1 end
    end

    --- 
    --- I think i can get rid of this because mine will all be one contiguous circuit
    --- 
    -- local FACTORISSIMO_CHUNK_SPACING = 16
    -- local cx = FACTORISSIMO_CHUNK_SPACING * (n % 8)
    -- local cy = FACTORISSIMO_CHUNK_SPACING * math.floor(n / 8)
    -- -- To make void chnks show up on the map, you need to tell them they've finished generating.
    -- for xx = -2, 2 do
    --     for yy = -2, 2 do
    --         surface.set_chunk_generated_status({cx + xx, cy + yy}, defines.chunk_generated_status.entities)
    --     end
    -- end

    -- surface.destroy_decoratives {area = {{32 * (cx - 2), 32 * (cy - 2)}, {32 * (cx + 2), 32 * (cy + 2)}}}
    -- factorissimo.spawn_maraxsis_water_shaders(surface, {x = cx, y = cy})

    

    local mine = {}
    mine.inside_surface = surface
    mine.inside_x = 32
    mine.inside_y = 32
    mine.stored_pollution = 0
    mine.outside_x = building.position.x
    mine.outside_y = building.position.y
    mine.outside_door_x = mine.outside_x + layout.outside_door_x -- valid because im using factory-1 as model for mine entrance
    mine.outside_door_y = mine.outside_y + layout.outside_door_y
    mine.outside_surface = building.surface

    storage.surface_factories[surface.index] = storage.surface_factories[surface.index] or {}
    storage.surface_factories[surface.index][n + 1] = mine

    local fn = table_size(storage.factories) + 1
    storage.factories[fn] = mine
    mine.id = fn

    -- surface.set_chunk_generated_status({math.floor(building.position.x /32), math.floor(building.position.y /32) }, 
    --                                     defines.chunk_generated_status.entities)
    
           ----- create_factory_interior code                             
    mine.building = building
    mine.layout = layout
    mine.force = building.force
    mine.quality = building.quality
    mine.inside_door_x = layout.inside_door_x + mine.inside_x
    mine.inside_door_y = layout.inside_door_y + mine.inside_y
    
    local tiles = {}
    for _, rect in pairs(layout.rectangles) do
        add_tile_rect(tiles, rect.tile, rect.x1 + mine.inside_x, rect.y1 + mine.inside_y, rect.x2 + mine.inside_x, rect.y2 + mine.inside_y)
    end
    for _, mosaic in pairs(layout.mosaics) do
        add_tile_mosaic(tiles, mosaic.tile, mosaic.x1 + mine.inside_x, mosaic.y1 + mine.inside_y, mosaic.x2 + mine.inside_x, mosaic.y2 + mine.inside_y, mosaic.pattern)
    end
    for _, cpos in pairs(layout.connections) do
        table.insert(tiles, {name = layout.connection_tile, position = {mine.inside_x + cpos.inside_x, mine.inside_y + cpos.inside_y}})
    end
    mine.inside_surface.set_tiles(tiles)
    add_hidden_tile_rect(mine)

    factorissimo.get_or_create_inside_power_pole(mine)
    factorissimo.spawn_cerys_entities(mine)

    local radar = mine.inside_surface.create_entity {
        name = "factory-hidden-radar",
        position = {mine.inside_x, mine.inside_y},
        force = force,
    }
    radar.destructible = false
    mine.radar = radar
    mine.inside_overlay_controllers = {}

    mine.connections = {}
    mine.connection_settings = {}
    mine.connection_indicators = {}
    
    -- return mine
    ------------------------------

    create_factory_exterior(mine, entity)
    mine.original_planet = entity.surface.planet
    mine.inactive = not can_place_factory_here(layout.tier, entity.surface, entity.position)
    return mine
end

local function create_mine_surface2(entity)
    
    -- local factory = create_factory_interior(layout, entity) -- only need to init a new surface

------------------------------
---
    
    local layout = remote_api.create_layout("mine_entrance", entity.quality)
    local building = entity
    local parent_surface = building.surface
    local surface_name =  parent_surface.name.."_mine_level"
    local surface = game.get_surface(surface_name)

    if surface then
        
    else
        
        surface = game.create_surface(surface_name)
        surface.localised_name = {surface_name,1}
       
        surface.daytime = 0.5
        surface.freeze_daytime = true

    end

    local n = 0
    for _, factory in pairs(storage.factories) do
        if factory.inside_surface.valid and factory.inside_surface == surface then n = n + 1 end
    end

    --- 
    --- I think i can get rid of this because mine will all be one contiguous circuit
    --- 
    -- local FACTORISSIMO_CHUNK_SPACING = 16
    -- local cx = FACTORISSIMO_CHUNK_SPACING * (n % 8)
    -- local cy = FACTORISSIMO_CHUNK_SPACING * math.floor(n / 8)
    -- -- To make void chnks show up on the map, you need to tell them they've finished generating.
    -- for xx = -2, 2 do
    --     for yy = -2, 2 do
    --         surface.set_chunk_generated_status({cx + xx, cy + yy}, defines.chunk_generated_status.entities)
    --     end
    -- end

    -- surface.destroy_decoratives {area = {{32 * (cx - 2), 32 * (cy - 2)}, {32 * (cx + 2), 32 * (cy + 2)}}}
    -- factorissimo.spawn_maraxsis_water_shaders(surface, {x = cx, y = cy})

    

    local mine = {}
    mine.inside_surface = surface
    
    mine.stored_pollution = 0
    mine.outside_x = building.position.x
    mine.outside_y = building.position.y 
    mine.outside_door_x = mine.outside_x + layout.outside_door_x -- valid because im using factory-1 as model for mine entrance
    mine.outside_door_y = mine.outside_y + layout.outside_door_y
    mine.outside_surface = building.surface
    mine.inside_x = 8 + mine.outside_door_x
    mine.inside_y = 8 + mine.outside_door_y


    storage.surface_factories[surface.index] = storage.surface_factories[surface.index] or {}
    storage.surface_factories[surface.index][n + 1] = mine

    local fn = table_size(storage.factories) + 1
    storage.factories[fn] = mine
    mine.id = fn

    

           ----- create_factory_interior code                             
    mine.building = building
    mine.layout = layout
    mine.force = building.force
    mine.quality = building.quality
    mine.inside_door_x = layout.inside_door_x + mine.inside_x
    mine.inside_door_y = layout.inside_door_y + mine.inside_y
    
    ------------------ added -------------------
    local sx = mine.outside_door_x
    local sy = mine.outside_door_y

    -- surface.set_chunk_generated_status({math.floor(mine.outside_door_x /32), math.floor(mine.outside_door_y /32) }, 
    --                                     defines.chunk_generated_status.entities)
    
    for xx = -2, 2 do
        for yy = -2, 2 do
            surface.set_chunk_generated_status({math.floor(sx/32) + xx, math.floor(sy/32) + yy}, defines.chunk_generated_status.entities)
        end
    end

    game.print(" creating mine with start of "..sx..","..sy)

    local starting_zone_size  = 8

    local start_point_area = {{-0.9, -0.9}, {0.9, 0.9}}
    local start_point_cleanup = {{-0.9, -0.9}, {1.9, 1.9}}
    
    -- local surface = event.surface ## DEFINED EARLER

    -- hack to figure out whether the important chunks are generated via diggy.feature.refresh_map.
    -- if (4 ~= surface.count_tiles_filtered({start_point_area, name = 'lab-dark-1'})) then
    --     log("returning from 4 ~=")
    --     return
    -- end

    -- ensure a clean starting point
    for _, entity in pairs(surface.find_entities_filtered({area = start_point_cleanup, type = 'resource'})) do
        entity.destroy()
    end

    local tiles = {}
    local rocks = {}

    local dirt_range = math.floor(starting_zone_size * 0.5)
    local rock_range = starting_zone_size - 2
    local stress_hack = math.floor(starting_zone_size * 0.1)

    -- game.print(" building start")    

    for x = -starting_zone_size, starting_zone_size do
        for y = -starting_zone_size, starting_zone_size do

    -- for x = sx-starting_zone_size, sx+starting_zone_size do
    --     for y = sy-starting_zone_size, sy+starting_zone_size do
            local distance = math.floor(math.sqrt(x * x + y * y))
            -- game.print("   ("..x..","..y..") : "..distance)
            if (distance < starting_zone_size) then
                if (distance > dirt_range) then
                    -- game.print("insert tile 1")
                    insert(tiles, {name = 'dirt-' .. math.random(1, 7), position = {x = x+sx, y = y+sy}})
                else
                    -- game.print("insert tile 2")
                    insert(tiles, {name = 'stone-path', position = {x = x+sx, y = y+sy}})
                end

                if (distance > rock_range) then
                    -- game.print("insert rock 1")
                    insert(rocks, {name = 'big-rock', position = {x = x+sx, y = y+sy}})
                end

                -- -- hack to avoid starting area from collapsing
                -- if (distance > stress_hack) then
                --     DiggyCaveCollapse.stress_map_add(surface, {x = x, y = y}, -0.5)
                -- end
            end
        end
    end

    -- game.print(">"..#tiles)
    -- game.print("..")
    -- game.print(">"..#rocks)

    Template.insert(surface, tiles, rocks)

    -- local position = config.market_spawn_position;
    -- local player_force = game.forces.player;

    -- local market = surface.create_entity({name = 'market', position = position})
    -- market.destructible = false

    -- Retailer.set_market_group_label('player', 'Diggy Market')
    -- Retailer.add_market('player', market)

    -- player_force.add_chart_tag(surface, {
    --     text = 'Market',
    --     position = position,
    -- })

    -- raise_event(Template.events.on_placed_entity, {entity = market})

    -- Event.remove_removable(defines.events.on_chunk_generated, callback_token)
    -------------------end added ---------------
    
    log("passed diggy code")

    factorissimo.get_or_create_inside_power_pole(mine)
    -- factorissimo.spawn_cerys_entities(mine)

    local radar = mine.inside_surface.create_entity {
        name = "factory-hidden-radar",
        position = {mine.inside_x, mine.inside_y},
        force = force,
    }
    radar.destructible = false
    mine.radar = radar
    mine.inside_overlay_controllers = {}

    mine.connections = {}
    mine.connection_settings = {}
    mine.connection_indicators = {}
    
    -- return mine
    ------------------------------

    create_factory_exterior(mine, entity)
    mine.original_planet = entity.surface.planet
    mine.inactive = not can_place_factory_here(layout.tier, entity.surface, entity.position)
    return mine
end

-- It's possible that the item used to build this factory is not the same as the one that was saved.
-- In this case, clear tags and description of the saved item such that there is only 1 copy of the factory item.
-- https://github.com/notnotmelon/factorissimo-2-notnotmelon/issues/155
local function handle_factory_control_xed(factory)
    local item = factory.item
    if not item or not item.valid then return end
    factory.item.tags = {}
    factory.item.custom_description = factory.item.prototype.localised_description

    -- We should also attempt to swapped the packed factory item with an unpacked.
    -- If this fails, whatever. It's just to avoid confusion. A packed factory with no tags is equal to an unpacked factory.
    local item_stack = item.item_stack
    if not item_stack or not item_stack.valid_for_read then return end

    item_stack.set_stack {
        name = item.name:gsub("%-instantiated$", ""),
        count = item_stack.count,
        quality = item_stack.quality,
        health = item_stack.health,
    }
end

local function handle_factory_placed(entity, tags)
    if not tags or not tags.id then
        create_fresh_factory(entity)
        return
    end

    local factory = storage.saved_factories[tags.id]
    storage.saved_factories[tags.id] = nil
    if factory and factory.inside_surface and factory.inside_surface.valid then
        -- This is a saved factory, we need to unpack it
        factory.quality = entity.quality
        create_factory_exterior(factory, entity)
        factory.inactive = not can_place_factory_here(factory.layout.tier, entity.surface, entity.position, factory.original_planet)
        handle_factory_control_xed(factory)
        return
    end

    if not factory and storage.factories[tags.id] then
        -- This factory was copied from somewhere else. Clone all contained entities
        local factory = create_fresh_factory(entity)
        factorissimo.copy_entity_ghosts(storage.factories[tags.id], factory)
        factorissimo.update_overlay(factory)
        return
    end

    factorissimo.create_flying_text {position = entity.position, text = {"factory-connection-text.invalid-factory-data"}}
    entity.destroy()
end

local function handle_mine_entrance_placed(entity, tags)
    
    local mine = nil
    
    if not tags or not tags.id then
       mine = create_mine_surface2(entity) -- init the mine surface. entrances are just different entry points to the same surface
    end

    -- local factory = storage.saved_factories[tags.id]
    -- storage.saved_factories[tags.id] = nil
    if mine and mine.inside_surface and mine.inside_surface.valid then
        -- This is a saved mine, we need to unpack it
        mine.quality = entity.quality
        create_factory_exterior(mine, entity)
        mine.inactive = not can_place_factory_here(mine.layout.tier, entity.surface, entity.position, mine.original_planet)
        handle_factory_control_xed(mine)
        return
    end

    if not mine and storage.factories[tags.id] then
        -- This mine was copied from somewhere else. Clone all contained entities
        local mine = create_mine_surface(entity)
        factorissimo.copy_entity_ghosts(storage.factories[tags.id], mine)
        factorissimo.update_overlay(mine)
        return
    end

    factorissimo.create_flying_text {position = entity.position, text = {"factory-connection-text.invalid-factory-data"}}
    entity.destroy()
end

factorissimo.on_event(factorissimo.events.on_built(), function(event)
    local entity = event.entity
    if not entity.valid then return end
    local entity_name = entity.name

    print("built a "..entity_name)
    print("built a x")
    local out = "built a "..entity_name
    log("baka.."..out)


    if entity_name == "mine_entrance" then
        local inventory = event.consumed_items
        local tags = event.tags or (inventory and not inventory.is_empty() and inventory[1].valid_for_read and inventory[1].is_item_with_tags and inventory[1].tags) or nil
        handle_mine_entrance_placed(entity,tags)
        return
    end

    if has_layout(entity_name) then
        local inventory = event.consumed_items
        local tags = event.tags or (inventory and not inventory.is_empty() and inventory[1].valid_for_read and inventory[1].is_item_with_tags and inventory[1].tags) or nil
        handle_factory_placed(entity, tags)
        return
    end

    if entity.type ~= "entity-ghost" then return end
    local ghost_name = entity.ghost_name

    if has_layout(ghost_name) and entity.tags then
        local copied_from_factory = storage.factories[entity.tags.id]
        if copied_from_factory then
            factorissimo.update_overlay(copied_from_factory, entity)
        end
    end
end)

-- How to clone your factory
-- This implementation will not actually clone factory buildings, but move them to where they were cloned.
local clone_forbidden_prefixes = {
    "factory-1-",
    "factory-2-",
    "factory-3-",
    "mine_entrance-",
    "factory-power-input-",
    "factory-connection-indicator-",
    "factory-power-pole",
    "factory-overlay-controller",
    "factory-port-marker",
    "factory-fluid-dummy-connector-"
}

local function is_entity_clone_forbidden(name)
    for _, prefix in pairs(clone_forbidden_prefixes) do
        if name:sub(1, #prefix) == prefix then
            return true
        end
    end
    return false
end

factorissimo.on_event(defines.events.on_entity_cloned, function(event)
    local src_entity = event.source
    local dst_entity = event.destination
    if is_entity_clone_forbidden(dst_entity.name) then
        dst_entity.destroy()
    elseif has_layout(src_entity.name) then
        local factory = get_factory_by_building(src_entity)
        cleanup_factory_exterior(factory, src_entity)
        if src_entity.valid then src_entity.destroy() end
        create_factory_exterior(factory, dst_entity)
    end
end)

-- MISC --

commands.add_command("give-lost-factory-buildings", {"command-help-message.give-lost-factory-buildings"}, function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.connected and player.admin) then return end
    local inventory = player.get_main_inventory()
    if not inventory then return end
    for id, factory in pairs(storage.saved_factories) do
        for i = 1, #inventory do
            local stack = inventory[i]
            if stack.valid_for_read and stack.name == factory.layout.name and stack.type == "item-with-tags" and stack.tags.id == id then goto found end
        end
        player.insert {name = factory.layout.name .. "-instantiated", count = 1, tags = {id = id}}
        ::found::
    end
end)

factorissimo.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    local setting = event.setting
    if setting == "Factorissimo2-indestructible-buildings" then
        for _, factory in pairs(storage.factories) do
            update_destructible(factory)
        end
    end
end)

factorissimo.on_event(defines.events.on_forces_merging, function(event)
    for _, factory in pairs(storage.factories) do
        if not factory.force.valid then
            factory.force = game.forces["player"]
        end
        if factory.force.name == event.source.name then
            factory.force = event.destination
        end
    end
end)
