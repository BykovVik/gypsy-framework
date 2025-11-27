-- Gypsy Loading - Client
-- Waits for character menu to be ready, then shuts down loading screen

RegisterNetEvent("gypsy-multicharacter:readyToShowMenu")
AddEventHandler("gypsy-multicharacter:readyToShowMenu", function()
    -- Shutdown loading screen when character menu is ready
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end)

CreateThread(function()
    while true do
        Wait(0)
        InvalidateIdleCam()
        InvalidateVehicleIdleCam()
    end
end)