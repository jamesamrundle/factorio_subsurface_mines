factorissimo.on_event(factorissimo.events.on_init(), function()
    if not remote.interfaces["PickerDollies"] then return end

    remote.call("PickerDollies", "add_blacklist_name", "factory-1", true)
    remote.call("PickerDollies", "add_blacklist_name", "factory-2", true)
    remote.call("PickerDollies", "add_blacklist_name", "factory-3", true)
    remote.call("PickerDollies", "add_blacklist_name", "mine_entrance", true)
end)
