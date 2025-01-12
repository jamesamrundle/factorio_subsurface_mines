local F = "__factorissimo-2-notnotmelon__";
local alt_graphics = settings.startup["Factorissimo2-alt-graphics"].value and "-alt" or ""
require("circuit-connector-sprites")

local function cwc0()
    return {shadow = {red = {0, 0}, green = {0, 0}}, wire = {red = {0, 0}, green = {0, 0}}}
end
local function cc0()
    return get_circuit_connector_sprites({0, 0}, nil, 1)
end

data:extend {
    {
        type = "storage-tank",
        name = "factory-1",
        icon = F .. "/graphics/icon/factory-1.png",
        icon_size = 64,
        flags = {"player-creation", "placeable-player"},
        minable = {mining_time = 0.5, result = "factory-1-instantiated", count = 1},
        placeable_by = {item = "factory-1", count = 1},
        max_health = 2000,
        collision_box = {{-3.8, -3.8}, {3.8, 3.8}},
        selection_box = {{-3.8, -3.8}, {3.8, 3.8}},
        pictures = {
            picture = {
                layers = {
                    {
                        filename = F .. "/graphics/factory/factory-1-shadow.png",
                        width = 416 * 2,
                        height = 320 * 2,
                        scale = 0.5,
                        shift = {1.5, 0},
                        draw_as_shadow = true
                    },
                    {
                        filename = F .. "/graphics/factory/factory-1" .. alt_graphics .. ".png",
                        width = 416 * 2,
                        height = 320 * 2,
                        scale = 0.5,
                        shift = {1.5, 0},
                    }
                }
            },
        },
        window_bounding_box = {{0, 0}, {0, 0}},
        fluid_box = {
            volume = 1,
            pipe_covers = pipecoverspictures(),
            pipe_connections = {},
        },
        flow_length_in_ticks = 1,
        circuit_wire_max_distance = 0,
        map_color = {r = 0.8, g = 0.7, b = 0.55},
        is_military_target = true
    },
    {
        type = "item-with-tags",
        name = "factory-1-instantiated",
        localised_name = {"item-name.factory-packed", {"entity-name.factory-1"}},
        icons = {
            {
                icon = F .. "/graphics/icon/factory-1.png",
                icon_size = 64,
            },
            {
                icon = F .. "/graphics/icon/packing-tape.png",
                icon_size = 64,
            }
        },
        subgroup = "factorissimo2",
        order = "a-a",
        place_result = "factory-1",
        stack_size = 1,
        weight = 100000000,
        flags = {"not-stackable"},
        hidden_in_factoriopedia = true,
        factoriopedia_alternative = "factory-1"
    },
    {
        type = "item",
        name = "factory-1",
        icon = F .. "/graphics/icon/factory-1.png",
        icon_size = 64,
        subgroup = "factorissimo2",
        order = "a-a",
        weight = 100000000,
        place_result = "factory-1",
        stack_size = 1,
        flags = {"primary-place-result", "not-stackable"}
    }
}

data:extend {
    {
        type = "storage-tank",
        name = "factory-2",
        icon = F .. "/graphics/icon/factory-2.png",
        icon_size = 64,
        flags = {"player-creation", "placeable-player"},
        minable = {mining_time = 0.5, result = "factory-2-instantiated", count = 1},
        max_health = 3500,
        collision_box = {{-5.8, -5.8}, {5.8, 5.8}},
        selection_box = {{-5.8, -5.8}, {5.8, 5.8}},
        pictures = {
            picture = {
                layers = {
                    {
                        filename = F .. "/graphics/factory/factory-2-shadow.png",
                        width = 544 * 2,
                        height = 448 * 2,
                        scale = 0.5,
                        shift = {1.5, 0},
                        draw_as_shadow = true
                    },
                    {
                        filename = F .. "/graphics/factory/factory-2" .. alt_graphics .. ".png",
                        width = 544 * 2,
                        height = 448 * 2,
                        scale = 0.5,
                        shift = {1.5, 0},
                    }
                }
            },
        },
        window_bounding_box = {{0, 0}, {0, 0}},
        fluid_box = {
            volume = 1,
            pipe_covers = pipecoverspictures(),
            pipe_connections = {},
        },
        flow_length_in_ticks = 1,
        circuit_wire_max_distance = 0,
        map_color = {r = 0.8, g = 0.7, b = 0.55},
        is_military_target = true
    },
    {
        type = "item-with-tags",
        name = "factory-2-instantiated",
        localised_name = {"item-name.factory-packed", {"entity-name.factory-2"}},
        icons = {
            {
                icon = F .. "/graphics/icon/factory-2.png",
                icon_size = 64,
            },
            {
                icon = F .. "/graphics/icon/packing-tape.png",
                icon_size = 64,
            }
        },
        subgroup = "factorissimo2",
        order = "a-b",
        place_result = "factory-2",
        stack_size = 1,
        weight = 100000000,
        flags = {"not-stackable"},
        hidden_in_factoriopedia = true,
        factoriopedia_alternative = "factory-2"
    },
    {
        type = "item",
        name = "factory-2",
        icon = F .. "/graphics/icon/factory-2.png",
        icon_size = 64,
        subgroup = "factorissimo2",
        order = "a-b",
        weight = 100000000,
        place_result = "factory-2",
        stack_size = 1,
        flags = {"primary-place-result", "not-stackable"}
    }
}

data:extend {
    {
        type = "storage-tank",
        name = "factory-3",
        icon = F .. "/graphics/icon/factory-3.png",
        icon_size = 64,
        flags = {"player-creation", "placeable-player"},
        minable = {mining_time = 0.5, result = "factory-3-instantiated", count = 1},
        max_health = 5000,
        collision_box = {{-7.8, -7.8}, {7.8, 7.8}},
        selection_box = {{-7.8, -7.8}, {7.8, 7.8}},
        pictures = {
            picture = {
                layers = {
                    {
                        filename = F .. "/graphics/factory/factory-3-shadow.png",
                        width = 704 * 2,
                        height = 608 * 2,
                        scale = 0.5,
                        shift = {2, -0.09375},
                        draw_as_shadow = true
                    },
                    {
                        filename = F .. "/graphics/factory/factory-3" .. alt_graphics .. ".png",
                        width = 704 * 2,
                        height = 608 * 2,
                        scale = 0.5,
                        shift = {2, -0.09375},
                    }
                }
            },
        },
        window_bounding_box = {{0, 0}, {0, 0}},
        fluid_box = {
            volume = 1,
            pipe_covers = pipecoverspictures(),
            pipe_connections = {},
        },
        flow_length_in_ticks = 1,
        circuit_wire_max_distance = 0,
        map_color = {r = 0.8, g = 0.7, b = 0.55},
        is_military_target = true
    },
    {
        type = "item-with-tags",
        name = "factory-3-instantiated",
        localised_name = {"item-name.factory-packed", {"entity-name.factory-3"}},
        icons = {
            {
                icon = F .. "/graphics/icon/factory-3.png",
                icon_size = 64,
            },
            {
                icon = F .. "/graphics/icon/packing-tape.png",
                icon_size = 64,
            }
        },
        subgroup = "factorissimo2",
        order = "a-c",
        weight = 100000000,
        place_result = "factory-3",
        stack_size = 1,
        flags = {"not-stackable"},
        hidden_in_factoriopedia = true,
        factoriopedia_alternative = "factory-3"
    },
    {
        type = "item",
        name = "factory-3",
        icon = F .. "/graphics/icon/factory-3.png",
        icon_size = 64,
        subgroup = "factorissimo2",
        order = "a-c",
        weight = 100000000,
        place_result = "factory-3",
        stack_size = 1,
        flags = {"primary-place-result", "not-stackable"}
    }
}


data:extend {
    {
        type = "storage-tank",
        name = "mine_entrance",
        icon = F .. "/graphics/icon/factory-1.png",
        icon_size = 64,
        flags = {"player-creation", "placeable-player"},
        minable = {mining_time = 0.5, result = "mine_entrance-instantiated", count = 1},
        placeable_by = {item = "mine_entrance", count = 1},
        max_health = 2000,
        collision_box = {{-3.8, -3.8}, {3.8, 3.8}},
        selection_box = {{-3.8, -3.8}, {3.8, 3.8}},
        pictures = {
            picture = {
                layers = {
                    {
                        filename = F .. "/graphics/factory/factory-1-shadow.png",
                        width = 416 * 2,
                        height = 320 * 2,
                        scale = 0.5,
                        shift = {1.5, 0},
                        draw_as_shadow = true
                    },
                    {
                        filename = F .. "/graphics/factory/factory-1" .. alt_graphics .. ".png",
                        width = 416 * 2,
                        height = 320 * 2,
                        scale = 0.5,
                        shift = {1.5, 0},
                    }
                }
            },
        },
        window_bounding_box = {{0, 0}, {0, 0}},
        fluid_box = {
            volume = 1,
            pipe_covers = pipecoverspictures(),
            pipe_connections = {},
        },
        flow_length_in_ticks = 1,
        circuit_wire_max_distance = 0,
        map_color = {r = 0.8, g = 0.7, b = 0.55},
        is_military_target = true
    },
    {
        type = "item-with-tags",
        name = "mine_entrance-instantiated",
        localised_name = {"item-name.factory-packed", {"entity-name.mine_entrance"}},
        icons = {
            {
                icon = F .. "/graphics/icon/factory-1.png",
                icon_size = 64,
            },
            {
                icon = F .. "/graphics/icon/packing-tape.png",
                icon_size = 64,
            }
        },
        subgroup = "factorissimo2",
        order = "a-a",
        place_result = "mine_entrance",
        stack_size = 1,
        weight = 100000000,
        flags = {"not-stackable"},
        hidden_in_factoriopedia = true,
        factoriopedia_alternative = "mine_entrance"
    },
    {
        type = "item",
        name = "mine_entrance",
        icon = F .. "/graphics/icon/factory-1.png",
        icon_size = 64,
        subgroup = "factorissimo2",
        order = "a-a",
        weight = 100000000,
        place_result = "mine_entrance",
        stack_size = 1,
        flags = {"primary-place-result", "not-stackable"}
    }
}