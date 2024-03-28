local this = {}

---@class set_tooltip
---@field control any
---@field tooltip string
---Sets control tooltip
---@param params set_tooltip
function this.SetTooltip(params)
    if params.tooltip ~= nil then
        params.control:SetHandler("OnMouseEnter",
            function(ctrl) ZO_Tooltips_ShowTextTooltip(ctrl, TOP, params.tooltip) end)
        params.control:SetHandler("OnMouseExit", function() ZO_Tooltips_HideTextTooltip() end)
    else
        params.control:SetHandler("OnMouseEnter", nil)
        params.control:SetHandler("OnMouseExit", nil)
    end
end

---@class label_params
---@field align table
---@field anchor string
---@field color table
---@field dims table
---@field font string
---@field hidden boolean
---@field name string
---@field parent string
---@field text string
---@field tooltip string
---Creates a CT_LABEL control
---@param params label_params
function this.Label(params)
    --Validate params and set defaults
    if (params.name == nil or params.name == "") then return end
    params.parent = (params.parent == nil) and GuiRoot or params.parent
    if (#params.anchor ~= 4 and #params.anchor ~= 5) then return end
    params.font = (params.font == nil) and "ZoFontGame" or params.font
    params.color = (params.color ~= nil and #params.color == 4) and params.color or { 1, 1, 1, 1 }
    params.align = (params.align ~= nil and #params.align == 2) and params.align or { 0, 0 }
    params.hidden = (params.hidden == nil) and false or params.hidden

    --Create label
    local label = _G[params.name] or WINDOW_MANAGER:CreateControl(params.name, params.parent, CT_LABEL)

    --Initialize lable
    if params.dims then label:SetDimensions(params.dims[1], params.dims[2]) end
    label:ClearAnchors()
    label:SetAnchor(params.anchor[1], params.anchor[2], params.anchor[3], params.anchor[4], params.anchor[5])
    label:SetFont(params.font)
    ---@diagnostic disable-next-line: deprecated
    label:SetColor(unpack(params.color))
    label:SetHorizontalAlignment(params.align[1])
    label:SetVerticalAlignment(params.align[2])
    label:SetText(params.text)
    label:SetHidden(params.hidden)
    this.SetTooltip({ control = label, tooltip = params.tooltip })

    label:SetDrawTier(2)

    return label
end

LibPanicida.Controls = this
