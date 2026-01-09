local WM = WINDOW_MANAGER
local GuiRoot = GuiRoot

local Controls = {}

local function SetTooltip(control, tooltipLines)
    if not tooltipLines or #tooltipLines == 0 then
        control:SetHandler("OnMouseEnter", nil)
        control:SetHandler("OnMouseExit", nil)
        return
    end

    control:SetHandler("OnMouseEnter", function(ctrl)
        InitializeTooltip(InformationTooltip, ctrl, TOPRIGHT, -10, 0, TOPLEFT)
        for _, lineText in ipairs(tooltipLines) do
            InformationTooltip:AddLine(lineText, "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
        end
    end)

    control:SetHandler("OnMouseExit", function()
        ClearTooltip(InformationTooltip)
    end)
end

local function ValidateAnchor(anchor)
    if not anchor then return false end
    local len = #anchor
    return len == 4 or len == 5
end

function Controls.Label(name, parent, dims, anchor, font, color, align, text, hidden, tooltipLines)
    if not name or name == "" then return end
    if not ValidateAnchor(anchor) then return end

    parent = parent or GuiRoot
    font = font or "ZoFontGame"
    color = (color and #color == 4) and color or { 1, 1, 1, 1 }
    align = (align and #align == 2) and align or { 0, 0 }
    hidden = hidden or false

    local label = WM:GetControlByName(name) or WM:CreateControl(name, parent, CT_LABEL)

    if dims then
        label:SetDimensions(dims[1], dims[2])
    end

    label:ClearAnchors()
    -- Handle both 4 and 5 parameter anchors safely
    if #anchor == 5 then
        label:SetAnchor(anchor[1], anchor[2], anchor[3], anchor[4], anchor[5])
    else
        label:SetAnchor(anchor[1], anchor[2], anchor[3], anchor[4])
    end

    label:SetFont(font)
    label:SetColor(unpack(color))
    label:SetHorizontalAlignment(align[1])
    label:SetVerticalAlignment(align[2])
    label:SetText(text)
    label:SetHidden(hidden)
    label:SetDrawTier(DT_HIGH)

    SetTooltip(label, tooltipLines)

    return label
end

function Controls.Button(name, parent, dims, anchor, text, func, enabled, tooltip, hidden)
    if not name or name == "" then return end
    if not ValidateAnchor(anchor) then return end

    hidden = hidden or false

    local button = WM:GetControlByName(name) or
        WM:CreateControlFromVirtual(name, parent, "Panicida_Button")

    if dims then
        button:SetDimensions(dims[1], dims[2])
    end

    button:SetText(text)
    button:ClearAnchors()

    if #anchor == 5 then
        button:SetAnchor(anchor[1], anchor[2], anchor[3], anchor[4], anchor[5])
    else
        button:SetAnchor(anchor[1], anchor[2], anchor[3], anchor[4])
    end

    button:SetClickSound("Click")
    button:SetHandler("OnClicked", func)
    button:SetState(enabled and BSTATE_NORMAL or BSTATE_DISABLED)
    button:SetDrawTier(DT_HIGH)
    button:SetHidden(hidden)

    SetTooltip(button, tooltip)

    return button
end

function Controls.Checkbox(name, parent, dims, anchor, text, func, enabled, checked, hidden)
    if not name or name == "" then return end
    if not ValidateAnchor(anchor) then return end

    local checkbox = Controls.Button(name, parent, dims, anchor, text, func, enabled, nil, hidden)
    if not checkbox then return end
    local label = Controls.Label(
        name .. "_Label",
        checkbox,
        { dims[2], dims[2] },
        { LEFT, checkbox, LEFT, 0, 0 },
        nil, nil, { 0, 1 }
    )

    local function SetChecked(check)
        local iconPath = check and
            "/esoui/art/cadwell/checkboxicon_checked.dds" or
            "/esoui/art/cadwell/checkboxicon_unchecked.dds"
        local iconText = string.format("|t%d:%d:%s|t", dims[2], dims[2], iconPath)

        if label then
            label:SetText(iconText)
        end
    end

    checkbox:SetNormalTexture("")
    checkbox:SetDisabledTexture("")
    checkbox.SetChecked = SetChecked

    SetChecked(checked)

    return checkbox
end

LibPanicida.Controls = Controls
