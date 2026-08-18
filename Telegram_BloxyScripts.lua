local RAW_JSON_URL =
    "https://raw.githubusercontent.com/Sell94662/value/main/values.json"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")


-- ==============================================================================
-- CONFIG
-- ==============================================================================

local UPDATE_RATE = 0.08

local VALUE_COLOR =
    Color3.fromRGB(255, 170, 0)

local ITEM_VALUE_COLOR =
    Color3.fromRGB(0, 170, 255)

local PROFIT_COLOR =
    "55FF7F"

local LOSS_COLOR =
    "FF5555"

local VALUE_OFFSET_Y = 8
local SUMMARY_OFFSET_Y = 20


-- ==============================================================================
-- DATABASE
-- ==============================================================================

local ValuesDatabase = {}

local DatabaseLoaded = false
local DatabaseLoadFinished = false


local function Normalize(text)

    if not text then
        return ""
    end

    text = tostring(text)

    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    text = text:gsub("%s+", " ")

    return string.lower(text)

end


-- ==============================================================================
-- UNIVERSAL HTTP
-- ==============================================================================

local function GetRequestFunction()

    -- syn.request
    local ok, fn = pcall(function()
        return syn and syn.request
    end)

    if ok and type(fn) == "function" then
        return fn
    end


    -- http.request
    ok, fn = pcall(function()
        return http and http.request
    end)

    if ok and type(fn) == "function" then
        return fn
    end


    -- http_request
    ok, fn = pcall(function()
        return http_request
    end)

    if ok and type(fn) == "function" then
        return fn
    end


    -- request
    ok, fn = pcall(function()
        return request
    end)

    if ok and type(fn) == "function" then
        return fn
    end


    return nil

end


local function DownloadDatabase()

    ------------------------------------------------------------------
    -- METHOD 1: game:HttpGet
    ------------------------------------------------------------------

    local success, response =
        pcall(function()

            return game:HttpGet(
                RAW_JSON_URL
            )

        end)


    if success
        and type(response) == "string"
        and #response > 0
    then

        return response

    end


    ------------------------------------------------------------------
    -- METHOD 2: executor request API
    ------------------------------------------------------------------

    local requestFunction =
        GetRequestFunction()


    if not requestFunction then
        return nil
    end


    local ok, result =
        pcall(function()

            return requestFunction({

                Url = RAW_JSON_URL,

                Method = "GET"

            })

        end)


    if not ok
        or not result
    then

        return nil

    end


    if type(result) == "table" then

        return result.Body
            or result.body

    end


    if type(result) == "string" then

        return result

    end


    return nil

end


-- ==============================================================================
-- LOAD GITHUB DATABASE
-- ==============================================================================

task.spawn(function()

    local response =
        DownloadDatabase()


    ------------------------------------------------------------------
    -- HTTP недоступен
    --
    -- ВАЖНО:
    -- НЕ блокируем запуск всего скрипта.
    ------------------------------------------------------------------

    if not response then

        warn(
            "[Telegram @BloxyScripts] GitHub download failed"
        )

        DatabaseLoaded = false
        DatabaseLoadFinished = true

        return

    end


    ------------------------------------------------------------------
    -- JSON
    ------------------------------------------------------------------

    local ok, data =
        pcall(function()

            return HttpService:JSONDecode(
                response
            )

        end)


    if not ok
        or type(data) ~= "table"
    then

        warn(
            "[Telegram @BloxyScripts] JSON decode failed"
        )

        DatabaseLoaded = false
        DatabaseLoadFinished = true

        return

    end


    ------------------------------------------------------------------
    -- LOAD VALUES
    ------------------------------------------------------------------

    local count = 0


    for name, value in pairs(data) do

        local key =
            Normalize(name)

        local numberValue =
            tonumber(value)


        if key ~= ""
            and numberValue ~= nil
        then

            ValuesDatabase[key] =
                numberValue

            count += 1

        end

    end


    DatabaseLoaded = true
    DatabaseLoadFinished = true


    print(
        "[Telegram @BloxyScripts] Database loaded:",
        count
    )


    pcall(function()

        game:GetService(
            "StarterGui"
        ):SetCore(
            "SendNotification",
            {
                Title = "Telegram @BloxyScripts",

                Text =
                    "База загружена: "
                    .. count
                    .. " предметов",

                Duration = 4
            }
        )

    end)

end)


-- ==============================================================================
-- GET VALUE
-- ==============================================================================

local function GetItemValue(name)

    if not name then
        return 0
    end


    local key =
        Normalize(name)


    if ValuesDatabase[key] ~= nil then

        return ValuesDatabase[key]

    end


    return 0

end


-- ==============================================================================
-- REMOVE OLD GUI
-- ==============================================================================

local oldGui =
    PlayerGui:FindFirstChild(
        "MM2ValueOverlay"
    )


if oldGui then

    oldGui:Destroy()

end


-- ==============================================================================
-- OVERLAY
-- ==============================================================================

local overlayGui =
    Instance.new("ScreenGui")


overlayGui.Name =
    "MM2ValueOverlay"

overlayGui.ResetOnSpawn =
    false

overlayGui.IgnoreGuiInset =
    true

overlayGui.DisplayOrder =
    999999

overlayGui.ZIndexBehavior =
    Enum.ZIndexBehavior.Sibling

overlayGui.Parent =
    PlayerGui


-- ==============================================================================
-- VALUE LABEL
-- ==============================================================================

local function CreateValueLabel(name)

    local label =
        Instance.new("TextLabel")


    label.Name =
        name

    label.BackgroundTransparency =
        1

    label.TextColor3 =
        VALUE_COLOR

    label.TextStrokeColor3 =
        Color3.fromRGB(
            0,
            0,
            0
        )

    label.TextStrokeTransparency =
        0

    label.Font =
        Enum.Font.GothamBold

    label.TextSize =
        22

    label.TextXAlignment =
        Enum.TextXAlignment.Left

    label.TextYAlignment =
        Enum.TextYAlignment.Center

    label.Visible =
        false

    label.ZIndex =
        100

    label.Parent =
        overlayGui


    return label

end


local yourValueLbl =
    CreateValueLabel(
        "YourValue"
    )


local theirValueLbl =
    CreateValueLabel(
        "TheirValue"
    )


-- ==============================================================================
-- BOTTOM SUMMARY
-- ==============================================================================

local bottomSummary =
    Instance.new("TextLabel")


bottomSummary.Name =
    "BottomSummary"

bottomSummary.BackgroundTransparency =
    1

bottomSummary.RichText =
    true

bottomSummary.TextSize =
    17

bottomSummary.Font =
    Enum.Font.GothamBold

bottomSummary.TextXAlignment =
    Enum.TextXAlignment.Center

bottomSummary.TextYAlignment =
    Enum.TextYAlignment.Center

bottomSummary.TextStrokeColor3 =
    Color3.fromRGB(
        0,
        0,
        0
    )

bottomSummary.TextStrokeTransparency =
    0

bottomSummary.Visible =
    false

bottomSummary.ZIndex =
    100

bottomSummary.Parent =
    overlayGui


-- ==============================================================================
-- ITEM BADGES
-- ==============================================================================

local badges = {}


local function HideAllBadges()

    for slot, badge in pairs(badges) do

        if badge
            and badge.Parent
        then

            badge.Visible =
                false

        else

            badges[slot] =
                nil

        end

    end

end


local function ApplyItemBadge(
    slot,
    value
)

    if not slot then
        return
    end


    local badge =
        badges[slot]


    if not badge
        or not badge.Parent
    then

        badge =
            Instance.new(
                "TextLabel"
            )


        badge.Name =
            "ValueBadge"

        badge.BackgroundTransparency =
            1

        badge.Size =
            UDim2.new(
                1,
                -6,
                0,
                18
            )

        badge.Position =
            UDim2.new(
                0,
                4,
                0,
                2
            )

        badge.TextColor3 =
            ITEM_VALUE_COLOR

        badge.TextStrokeColor3 =
            Color3.fromRGB(
                0,
                0,
                0
            )

        badge.TextStrokeTransparency =
            0.15

        badge.Font =
            Enum.Font.GothamBlack

        badge.TextSize =
            17

        badge.TextXAlignment =
            Enum.TextXAlignment.Left

        badge.TextYAlignment =
            Enum.TextYAlignment.Top

        badge.ZIndex =
            90

        badge.Parent =
            slot


        badges[slot] =
            badge

    end


    badge.Text =
        tostring(value)

    badge.Visible =
        true

end


-- ==============================================================================
-- TEXT OBJECT
-- ==============================================================================

local function IsTextObject(obj)

    return obj:IsA("TextLabel")
        or obj:IsA("TextButton")

end


-- ==============================================================================
-- GUI VISIBILITY
-- ==============================================================================

local function IsVisible(obj)

    if not obj then
        return false
    end


    if not obj:IsA("GuiObject") then
        return false
    end


    if not obj.Visible then
        return false
    end


    local pos =
        obj.AbsolutePosition

    local size =
        obj.AbsoluteSize


    if size.X <= 0
        or size.Y <= 0
    then

        return false

    end


    if pos.X + size.X < 0 then
        return false
    end


    if pos.Y + size.Y < 0 then
        return false
    end


    return true

end


-- ==============================================================================
-- SERVICE TEXT
-- ==============================================================================

local function IsServiceText(text)

    if not text then
        return true
    end


    local t =
        Normalize(text)


    if t == "" then
        return true
    end


    local blocked = {

        ["empty"] = true,

        ["your offer"] = true,

        ["their offer"] = true,

        ["decline"] = true,

        ["accept"] = true,

        ["confirm"] = true,

        ["cancel"] = true,

        ["trade"] = true,

        ["trading"] = true,

        ["waiting"] = true,

        ["waiting..."] = true,

        ["wait"] = true,

        ["loading"] = true,

        ["loading..."] = true,

    }


    if blocked[t] then
        return true
    end


    if t:match("^%d+$") then
        return true
    end


    return false

end


-- ==============================================================================
-- FIND TRADE UI
-- ==============================================================================

local function FindTradeUI()

    local your =
        nil

    local their =
        nil

    local decline =
        nil


    for _, gui in ipairs(
        PlayerGui:GetChildren()
    ) do

        if gui:IsA("ScreenGui")
            and gui.Enabled
        then

            for _, obj in ipairs(
                gui:GetDescendants()
            ) do

                if IsTextObject(obj) then

                    local text =
                        Normalize(
                            obj.Text
                        )


                    if text ==
                        "your offer"
                    then

                        if IsVisible(obj) then
                            your = obj
                        end


                    elseif text ==
                        "their offer"
                    then

                        if IsVisible(obj) then
                            their = obj
                        end


                    elseif text ==
                        "decline"
                    then

                        if IsVisible(obj) then
                            decline = obj
                        end

                    end

                end

            end

        end

    end


    return
        your,
        their,
        decline

end


-- ==============================================================================
-- COMMON PARENT
-- ==============================================================================

local function FindCommonParent(
    a,
    b
)

    if not a or not b then
        return nil
    end


    local parents = {}

    local current =
        a


    while current do

        parents[current] =
            true

        current =
            current.Parent

    end


    current =
        b


    while current do

        if parents[current] then
            return current
        end


        current =
            current.Parent

    end


    return nil

end


-- ==============================================================================
-- FIND SLOT
-- ==============================================================================

local function FindSlot(
    textObject,
    root
)

    if not textObject then
        return nil
    end


    local current =
        textObject.Parent

    local candidate =
        nil


    while current
        and current ~= root
    do

        if current:IsA(
            "GuiObject"
        )
        then

            local size =
                current.AbsoluteSize


            if size.X >= 45
                and size.Y >= 45
                and size.X <= 400
                and size.Y <= 400
            then

                candidate =
                    current

            end

        end


        current =
            current.Parent

    end


    return candidate

end


-- ==============================================================================
-- CHECK IF TEXT CAN BE ITEM
-- ==============================================================================

local function IsPossibleItemText(
    obj
)

    if not obj
        or not IsTextObject(obj)
    then

        return false

    end


    if obj.Name ==
        "ValueBadge"
    then

        return false

    end


    if not IsVisible(obj) then
        return false
    end


    local text =
        obj.Text


    if IsServiceText(text) then
        return false
    end


    return true

end


-- ==============================================================================
-- SCAN SIDE
-- ==============================================================================

local function ScanSide(
    header
)

    local total =
        0

    local foundSlots =
        {}


    if not header then
        return 0
    end


    local sideRoot =
        header.Parent


    if not sideRoot then
        return 0
    end


    for _, obj in ipairs(
        sideRoot:GetDescendants()
    ) do

        if IsPossibleItemText(obj) then

            local slot =
                FindSlot(
                    obj,
                    sideRoot
                )


            if slot
                and not foundSlots[slot]
            then

                foundSlots[slot] =
                    true


                local value =
                    GetItemValue(
                        obj.Text
                    )


                total +=
                    value


                ApplyItemBadge(
                    slot,
                    value
                )

            end

        end

    end


    return total

end


-- ==============================================================================
-- HIDE EVERYTHING
-- ==============================================================================

local function HideOverlay()

    yourValueLbl.Visible =
        false

    theirValueLbl.Visible =
        false

    bottomSummary.Visible =
        false


    HideAllBadges()

end


-- ==============================================================================
-- DRAW VALUE
-- ==============================================================================

local function DrawValueLabel(
    label,
    header,
    total
)

    if not header
        or not IsVisible(header)
    then

        label.Visible =
            false

        return

    end


    local pos =
        header.AbsolutePosition

    local size =
        header.AbsoluteSize


    label.Size =
        UDim2.fromOffset(
            math.max(
                size.X,
                260
            ),
            30
        )


    label.Position =
        UDim2.fromOffset(

            pos.X,

            pos.Y
                + size.Y
                + VALUE_OFFSET_Y

        )


    label.Text =
        tostring(total)
        .. " VALUE"


    label.Visible =
        true

end


-- ==============================================================================
-- DRAW SUMMARY
-- ==============================================================================

local function DrawSummary(
    decline,
    yourTotal,
    theirTotal
)

    if not decline
        or not IsVisible(decline)
    then

        bottomSummary.Visible =
            false

        return

    end


    local diff =
        theirTotal
        - yourTotal


    local pct =
        0


    if yourTotal > 0 then

        pct =
            math.floor(
                (diff / yourTotal)
                * 100
            )

    end


    local diffText


    if diff >= 0 then
        diffText =
            "+" .. diff
    else
        diffText =
            tostring(diff)
    end


    local pctText


    if pct >= 0 then
        pctText =
            "+" .. pct .. "%"
    else
        pctText =
            tostring(pct) .. "%"
    end


    local color =
        diff >= 0
        and PROFIT_COLOR
        or LOSS_COLOR


    bottomSummary.Text =
        string.format(

            '<font color="#FFFFFF">YOU </font>' ..

            '<font color="#FFAA00">%d</font>' ..

            '<font color="#FFFFFF">    THEM </font>' ..

            '<font color="#FFAA00">%d</font>' ..

            '<font color="#FFFFFF">    </font>' ..

            '<font color="#%s">%s %s</font>',

            yourTotal,

            theirTotal,

            color,

            diffText,

            pctText

        )


    local pos =
        decline.AbsolutePosition

    local size =
        decline.AbsoluteSize


    local centerX =
        pos.X
        + size.X / 2


    local summaryWidth =
        math.max(
            size.X + 100,
            340
        )


    bottomSummary.Size =
        UDim2.fromOffset(
            summaryWidth,
            28
        )


    bottomSummary.Position =
        UDim2.fromOffset(

            centerX
                - summaryWidth / 2
                - 40,

            pos.Y
                + size.Y
                + SUMMARY_OFFSET_Y

        )


    bottomSummary.Visible =
        true

end


-- ==============================================================================
-- MAIN LOOP
-- ==============================================================================

task.spawn(function()

    ------------------------------------------------------------------
    -- НЕ ЖДЁМ DatabaseLoaded
    --
    -- Это главное исправление.
    --
    -- Если HTTP не работает, GUI всё равно запускается.
    ------------------------------------------------------------------

    task.wait(0.1)


    while true do

        task.wait(
            UPDATE_RATE
        )


        local success =
            pcall(function()

                HideOverlay()


                local yourHeader,
                    theirHeader,
                    declineBtn =

                    FindTradeUI()


                if not yourHeader
                    or not theirHeader
                then

                    HideOverlay()

                    return

                end


                local tradeRoot =
                    FindCommonParent(
                        yourHeader,
                        theirHeader
                    )


                if not tradeRoot then

                    HideOverlay()

                    return

                end


                local yourTotal =
                    ScanSide(
                        yourHeader
                    )


                local theirTotal =
                    ScanSide(
                        theirHeader
                    )


                DrawValueLabel(
                    yourValueLbl,
                    yourHeader,
                    yourTotal
                )


                DrawValueLabel(
                    theirValueLbl,
                    theirHeader,
                    theirTotal
                )


                if declineBtn then

                    DrawSummary(
                        declineBtn,
                        yourTotal,
                        theirTotal
                    )

                end

            end)


        if not success then

            HideOverlay()

        end

    end

end)
