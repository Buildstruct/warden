function Warden.AddDListElems(PANEL)
	-- override
	function PANEL:FixColumnsLayout()
		local numCols = table.Count(self.Columns)
		if numCols < 1 then return end

		local totalWidth = 0
		for k, col in pairs(self.Columns) do
			if k == 1 then continue end

			totalWidth = totalWidth + math.ceil(col:GetWide())
		end

		local nameCol = self.Columns[1]
		if nameCol then
			nameCol:SetWidth(self.pnlCanvas:GetWide() - totalWidth)
		end

		local x = 0
		for k, col in pairs(self.Columns) do
			col.x = x
			x = x + math.ceil(col:GetWide())

			col:SetTall(self:GetHeaderHeight())
			col:SetVisible(not self:GetHideHeaders())
		end
	end

	function PANEL:NewPermCol(id, perm)
		local col = self:AddColumn("")
		self.PermList[id] = col
		col.ID = id
		col.KEY = perm.KEY

		col:SetTooltip(perm:GetName())
		col:SetTooltipDelay(0)
		col:SetFixedWidth(self:GetHeaderHeight())

		function col.Header.PaintOver(_, w, h)
			surface.SetMaterial(perm:GetIcon())
			surface.SetDrawColor(255, 255, 255)
			surface.DrawTexturedRect(w / 2 - 8, h / 2 - 8, 16, 16)
		end
	end

	function PANEL:SetPermColumns(force)
		local changed = false

		for k, v in pairs(self.PermList) do
			if not IsValid(v) then
				self.PermList[k] = nil
				changed = true
			elseif not Warden.GetPermission(v.ID, force) then
				v:Remove()
				self.PermList[k] = nil
				changed = true
			end
		end

		for k, v in pairs(self._Perms) do
			if self.PermList[k] then continue end

			self:NewPermCol(k, v)
			changed = true
		end

		if changed then
			local c = table.Count(self._Perms)
			local h = self:GetHeaderHeight()
			local width = h + math.max((h / 4) * (6 - c), 0)

			for k, v in pairs(self.Columns) do
				if not IsValid(v) then
					self.Columns[k] = nil
					continue
				end
			end

			for k, v in pairs(self.PermList) do
				v:SetFixedWidth(width)
			end
		end

		return changed
	end

	function PANEL:NewSettingCol(name, desc, id)
		local col = self:AddColumn(name, id)

		col:SetTooltip(desc)
		col:SetTooltipDelay(0)
		col:SetFixedWidth(30)

		return col
	end
end