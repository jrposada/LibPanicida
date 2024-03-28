local GAFE = GroupActivityFinderExtensions
local WM = WINDOW_MANAGER

GAFE.UI = {
    Controls = {}
}



function GAFE.UI.ZOButton(name, parent, dims, anchor, text, func, enabled, tooltip, hidden)
    hidden = (hidden == nil) and false or hidden

    --Create button
    local button = _G[name] or WM:CreateControlFromVirtual(name, parent, "ZO_DefaultButton")

    if dims then button:SetDimensions(dims[1], dims[2]) end
    button:SetText(text)
    button:ClearAnchors()
    button:SetAnchor(anchor[1], anchor[2], anchor[3], anchor[4], anchor[5])
    button:SetClickSound("Click")
    button:SetHandler("OnClicked", function() func() end)
    button:SetState(enabled and BSTATE_NORMAL or BSTATE_DISABLED)
    button:SetDrawTier(2)
    button:SetHidden(hidden)

    GAFE.UI.SetTooltip(button, tooltip)

    return button
end

function GAFE.UI.Button(name, parent, dims, anchor, text, func, enabled, tooltip, hidden)
    hidden = (hidden == nil) and false or hidden

    --Create button
    local button = _G[name] or WM:CreateControlFromVirtual(name, parent, "GAFE_Button")

    if dims then button:SetDimensions(dims[1], dims[2]) end
    button:SetText(text)
    button:ClearAnchors()
    button:SetAnchor(anchor[1], anchor[2], anchor[3], anchor[4], anchor[5])
    button:SetClickSound("Click")
    button:SetHandler("OnClicked", function() func() end)
    button:SetState(enabled and BSTATE_NORMAL or BSTATE_DISABLED)
    button:SetDrawTier(2)
    button:SetHidden(hidden)

    GAFE.UI.SetTooltip(button, tooltip)

    return button
end

function GAFE.UI.Texture(name, parent, dims, anchor, texture)
    local control = _G[name] or WM:CreateControl(name, parent, CT_TEXTURE)

    if dims then control:SetDimensions(dims[1], dims[2]) end
    control:ClearAnchors()
    control:SetAnchor(anchor[1], anchor[2], anchor[3], anchor[4], anchor[5])
    control:SetTexture(texture)

    return control
end

function GAFE.UI.Checkbox(name, parent, dims, anchor, text, func, enabled, checked, hidden)
    local function SetChecked(check)
        local labelText = check and "/esoui/art/cadwell/checkboxicon_checked.dds" or
        "/esoui/art/cadwell/checkboxicon_unchecked.dds"
        labelText = "|t" .. dims[2] .. ":" .. dims[2] .. ":" .. labelText .. "|t"

        _G[name .. "_L"]:SetText(labelText)
    end

    -- Create checkbox
    local checkboxContainer = GAFE.UI.ZOButton(name, parent, dims, anchor, text, func, enabled, nil, hidden)
    checkboxContainer:SetNormalTexture("")
    checkboxContainer:SetDisabledTexture("")
    checkboxContainer.GAFE_SetChecked = SetChecked

    -- Create label
    GAFE.UI.Label(name .. "_L", checkboxContainer, { dims[2], dims[2] }, { LEFT, checkboxContainer, LEFT, 0, 0 }, nil,
        nil, { 0, 1 })

    checkboxContainer.GAFE_SetChecked(checked)

    return checkboxContainer
end
