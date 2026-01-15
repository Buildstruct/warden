hook.Add("InitPostEntity", "WardenACF", function()
	if not ACF then return end

	Warden.PERMISSION_ACF, acf = Warden.RegisterPermissionSimple("acf", "ACF", 2, nil, "warden/acf.png", "icon16/car.png")
	acf:SetDefault(true, true)
	acf:SetEnabled(false, true)
end)
