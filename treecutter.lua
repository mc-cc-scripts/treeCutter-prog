---@class scm
local scm = require("./scm")

---@class Config
local Config = scm:load("config")

---@type turtleController
local turtleController = scm:load("turtleController")

---@class Vector
---@field x number
---@field y number
---@field z number


local defaults = {
    ["treeGap"] = {
        ["description"] = "Gap between trees",
        ["default"] = 4,
        ["type"] = "number"
    },
    ["treesPerRow"] = {
        ["description"] = "Amount of trees per row",
        ["default"] = 8,
        ["type"] = "number"
    },
    ["rows"] = {
        ["description"] = "Amount of rows",
        ["default"] = 2,
        ["type"] = "number",
    },
    ["moveDir"] = {
        ["description"] = "Direction the turtle will move (e.g. from first tree to next it moves in this direction)",
        ["default"] = "right",
        ["type"] = "string",
    },
    ["saplingName"] = {
        ["description"] = "Sapling name",
        ["default"] = "minecraft:oak_sapling",
        ["type"] = "string",
    }
}

Config:init(defaults)

local args = {...}
if args[1] == "config" then
    Config:command(args)
    return
end

turtleController.canBreakBlocks = true

local checkBlock, cutAdjacent

function checkBlock()
    local block = turtle.inspect()
    if string.find(block.name, "wood") then
        turtleController:tryMove("f")
        cutAdjacent()
    end
end

---@comment cuts a 3x3 area
--- checks 5x5 area
function cutAdjacent()
    
    local function step (check)
        checkBlock()
        turtleController:tryMove("f")
        if(check) then
            checkBlock()
            turtleController:tryMove("tR")
            checkBlock()
            turtleController:tryMove("tL")
        end
    end

    local function line ()
        step(true)
        step(true)
        turtleController:tryMove("tL")
    end

    step(false)
    checkBlock()
    turtleController:tryMove("tL")
    step(true)
    checkBlock()
    turtleController:tryMove("tL")
    line()
    line()
    line()
    turtleController:compactMove("f,tL,f,tA")
    --- Legend: o => unchecked, c => checked, x => mined, s => startPos
    --- o c c c o
    --- c x x x c
    --- c x s x c
    --- c x x x c
    --- o c c c o
    

end

---@comment Checks if tree exists, sheers it, 
--- cuts it, places sapling, moves back to start pos
local function cutTree()
    local inspectedBlock = turtle.inspect()
    -- assuming the block is wood then continue
    if (not inspectedBlock or (inspectedBlock.name == Config:get("saplingName"))) then
        return nil
    end

    local height = 0
    turtleController:tryAction("dig")
    turtleController:tryMove("f")
    while turtle.detectUp() do
        turtleController:tryAction("digU")
        turtleController:tryMove("u")
        height = height + 1
    end

    while height > 1 do
        cutAdjacent()
        turtleController:tryMove("d")
        height = height - 1
    end
    turtleController:compactMove("d,b")
    
end


local moveDir = (Config:get("moveDir") == "right") and {"tR", "tL"} or {"tL", "tR"}
while true do
    
    for j = 1, Config:get("rows"), 1 do
        local oddEven =j % 2 == 1 and {1,2} or {2,1}
        for i = 1, Config:get("treesPerRow"), 1 do
            cutTree()
            ---@type string
            local moveString = moveDir[oddEven[1]] .. ",f" .. tostring(Config:get("treeGap")) .. "," .. moveDir[oddEven[2]]
            
            turtleController:compactMove(moveString)
        end
        local mString = moveDir[oddEven[2]] .. ",f," .. moveDir[oddEven[1]] 
        .. ",f" .. tostring(Config:get("treeGap"))",".. moveDir[oddEven[1]] 
        .. ",f," .. moveDir[oddEven[2]]
        turtleController:compactMove(mString)
    end
    sleep(10)
end
