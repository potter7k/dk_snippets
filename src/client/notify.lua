RegisterNetEvent('dk/notify')
AddEventHandler('dk/notify', function(mode,message,time,title)
	if not mode or not message then return end
	SendNUIMessage({ notify = {
		index = mode,
		time = time,
		title = title,
		message = message,
	} })
end)