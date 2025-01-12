local mod_gui = require "mod-gui"
local get_factory_by_entity = remote_api.get_factory_by_entity
local find_surrounding_factory = remote_api.find_surrounding_factory

local function get_camera_toggle_button(player)
    local buttonflow = mod_gui.get_button_flow(player)
    local button = buttonflow.factory_camera_toggle_button or buttonflow.add {type = "sprite-button", name = "factory_camera_toggle_button", sprite = "factorissimo-gui-icon-no-lens"}
    button.visible = player.force.technologies["factory-preview"].researched
    return button
end

factorissimo.on_event({defines.events.on_research_finished, defines.events.on_research_reversed}, function(event)
    local name = event.research.name
    if name ~= "factory-preview" then return end
    for _, player in pairs(game.players) do
        get_camera_toggle_button(player)
    end
end)

local function get_camera_frame(player)
    local frameflow = mod_gui.get_frame_flow(player)
    local camera_frame = frameflow.factory_camera_frame
    if not camera_frame then
        camera_frame = frameflow.add {type = "frame", name = "factory_camera_frame", style = "frame"}
        camera_frame.style.padding = 3
        camera_frame.visible = false
    end
    return camera_frame
end

local function prepare_gui(player)
    get_camera_toggle_button(player)
    get_camera_frame(player)
end

factorissimo.on_event(factorissimo.events.on_init(), function()
    -- Map: Player index -> Whether preview is activated
    storage.player_preview_active = storage.player_preview_active or {}

    for _, player in pairs(game.players) do
        prepare_gui(player)
    end
end)

factorissimo.on_event(defines.events.on_player_created, function(event)
    prepare_gui(game.get_player(event.player_index))
end)

local function set_camera(player, factory, inside)
    if not player.force.technologies["factory-preview"].researched or factory.inactive then return end
    local inside_surface = factory.inside_surface
    local outside_surface = factory.outside_surface
    if not inside_surface.valid or not outside_surface.valid then return end

    local ps = settings.get_player_settings(player)
    local ps_preview_size = ps["Factorissimo2-preview-size"]
    local preview_size = ps_preview_size and ps_preview_size.value or 300
    local ps_preview_zoom = ps["Factorissimo2-preview-zoom"]
    local preview_zoom = ps_preview_zoom and ps_preview_zoom.value or 1
    local position, surface_index, zoom
    if not inside then
        position = {x = factory.outside_x, y = factory.outside_y}
        surface_index = outside_surface.index
        zoom = (preview_size / (32 / preview_zoom)) / (8 + factory.layout.outside_size)
    else
        position = {x = factory.inside_x, y = factory.inside_y}
        surface_index = inside_surface.index
        zoom = (preview_size / (32 / preview_zoom)) / (5 + factory.layout.inside_size)
    end
    local camera_frame = get_camera_frame(player)
    local camera = camera_frame.factory_camera
    if camera then
        camera.position = position
        camera.surface_index = surface_index
        camera.zoom = zoom
        camera.style.minimal_width = preview_size
        camera.style.minimal_height = preview_size
        camera.ignored_by_interaction = true
    else
        local camera = camera_frame.add {type = "camera", name = "factory_camera", position = position, surface_index = surface_index, zoom = zoom}
        camera.style.minimal_width = preview_size
        camera.style.minimal_height = preview_size
        camera.ignored_by_interaction = true
    end
    camera_frame.ignored_by_interaction = true
    camera_frame.visible = true
end

local function unset_camera(player)
    get_camera_frame(player).visible = false
end

local function update_camera(player)
    if not storage.player_preview_active[player.index] then return end
    if not player.force.technologies["factory-preview"].researched then return end
    local cursor_stack = player.cursor_stack
    if cursor_stack and
        cursor_stack.valid_for_read and
        cursor_stack.type == "item-with-tags" and
        cursor_stack.tags and
        storage.saved_factories[cursor_stack.tags.id] then
        local factory = storage.saved_factories[cursor_stack.tags.id]
        if not factory.inactive then
            set_camera(player, factory, true)
            return
        end
    end
    local selected = player.selected
    if selected then
        local factory
        if selected.type == "item-entity" and selected.stack.type == "item-with-tags" and has_layout(selected.stack.name) then
            factory = storage.saved_factories[selected.stack.tags.id]
        else
            factory = get_factory_by_entity(player.selected)
        end
        if factory and not factory.inactive then
            set_camera(player, factory, true)
            return
        elseif selected.name == "factory-power-pole" then
            local factory = find_surrounding_factory(selected.surface, selected.position)
            if factory then
                factorissimo.update_overlay(factory)
                set_camera(player, factory, false)
                return
            end
        end
    end
    unset_camera(player)
end
factorissimo.update_camera = update_camera

factorissimo.on_event(defines.events.on_gui_click, function(event)
    local player = game.get_player(event.player_index)
    if event.element.valid and event.element.name == "factory_camera_toggle_button" then
        if storage.player_preview_active[player.index] then
            get_camera_toggle_button(player).sprite = "factorissimo-gui-icon-no-lens"
            storage.player_preview_active[player.index] = false
            unset_camera(player)
        else
            get_camera_toggle_button(player).sprite = "factorissimo-gui-icon-lens"
            storage.player_preview_active[player.index] = true
            update_camera(player)
        end
    end
end)

local god_controllers = {
    [defines.controllers.god] = true,
    [defines.controllers.editor] = true,
    [defines.controllers.spectator] = true,
}
local function camera_teleport(player, surface, position)
    local old_controller = player.controller_type

    if god_controllers[old_controller] then
        player.teleport(position, surface, true, false)
        return
    end

    player.set_controller {
        type = defines.controllers.remote,
        position = position,
        surface = surface
    }
    player.zoom = 0.6
    player.opened = nil
end

local function open_outside_in_remote_view(player, pole)
    for _, factory in pairs(storage.factories) do
        if factory.built and factory.outside_surface.valid and factorissimo.get_or_create_inside_power_pole(factory) == pole then
            local teleport_position = {x = factory.outside_x, y = factory.outside_y}

            local recursive_parent = remote_api.find_surrounding_factory(factory.outside_surface, teleport_position)
            if recursive_parent then teleport_position = {recursive_parent.inside_x, recursive_parent.inside_y} end

            factorissimo.update_overlay(factory)
            camera_teleport(player, factory.outside_surface, teleport_position)
            return
        end
    end
end

factorissimo.on_event("factory-open-outside-surface-to-remote-view", function(event)
    local player = game.get_player(event.player_index)
    local entity = player.selected
    if not entity or not entity.valid then return end

    if entity.name == "factory-power-pole" then -- teleport the camera to the outside of the factory
        open_outside_in_remote_view(player, entity)
        return
    end

    local factory = remote_api.get_factory_by_entity(entity)
    if not factory then return end

    local teleport_position = {factory.inside_x, factory.inside_y}
    camera_teleport(player, factory.inside_surface, teleport_position)
end)
