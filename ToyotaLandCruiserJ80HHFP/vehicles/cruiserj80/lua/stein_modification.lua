-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local M = {}

local drivetrain4wdSmoother = newExponentialSmoothing(10)
local wiperValSmoother = newExponentialSmoothing(5)
local wiperStalkSmoother = newExponentialSmoothing(5)
local keySmoother = newExponentialSmoothing(10)
local gear_A_Smoother = newExponentialSmoothing(10)

local queueWiperSwing = false
local wiperSwing = false
local wipersEnabled = 0
local wiperForward = false
local wiperTimer = 0
local wiperMaxTimer = 150

local function onInit()
    queueWiperSwing = false
    wiperSwing = false
    wipersEnabled = 0
    wiperForward = false
    wiperTimer = 0
    wiperMaxTimer = 150

    electrics.values['gear_A'] = 0
    electrics.values['keyTurn'] = 0
    electrics.values['drivetrain_4wd'] = 0
    electrics.values['wiperVal'] = 0
end

local function reset()
  onInit()
end

local function updateGFX(dt)
    if(electrics.values['rpm'] ~= nil and powertrain.getDevice("mainEngine") ~= nil) then
        if(electrics.values['rpm'] > 20 and powertrain.getDevice("mainEngine").starterEngagedCoef > 0) then
            electrics.values['keyTurn'] = 1
        elseif(electrics.values['rpm'] > 20) then
            electrics.values['keyTurn'] = 0.5
        else
            electrics.values['keyTurn'] = 0
        end
    end
    --electrics.values['keyTurn'] = (electrics.values['rpm'] > 20) and 1 or 0 

    -- applyForce(node1, node2, forceMagnitude)
    --obj:applyForce(thruster[2], thruster[1], thruster[3])

    electrics.values['wipers'] = 1-(wipersEnabled / 2)
    if(input.keys.Y and wiperKey == 0) then
        if(wipersEnabled == 0) then
            wipersEnabled = 1
            wiperMaxTimer = 150
            gui.message("Wipers: Slow", 5, "wiperMsg")
        elseif(wipersEnabled == 1) then
            wipersEnabled = 2
            wiperMaxTimer = 50
            gui.message("Wipers: Fast", 5, "wiperMsg")
        else
            wipersEnabled = 0

            gui.message("Wipers: Off", 5, "wiperMsg")
        end
        wiperKey = 1
    end
    if(not input.keys.Y) then wiperKey = 0 end

    if(not wiperForward and wipersEnabled > 0) then
        wiperTimer = wiperTimer + 1
        if(wiperTimer > wiperMaxTimer) then
            queueWiperSwing = true
            wiperForward = true
            wiperTimer = 0
        end
    end
    if(not queueWiperSwing) then
        electrics.values['wiperVal'] = 0
    end
    if(queueWiperSwing) then
        local wipeSpeed = 0.05
        if(electrics.values['wiperVal'] > 0.8) then
            wipeSpeed = math.abs(electrics.values['wiperVal'] - 1.1) / 5
        end
        if(wiperForward) then
            electrics.values['wiperVal'] = electrics.values['wiperVal'] + wipeSpeed
            if(electrics.values['wiperVal'] > 1) then wiperForward = false end
        else
            electrics.values['wiperVal'] = electrics.values['wiperVal'] - wipeSpeed
            if(electrics.values['wiperVal'] < 0) then 
                queueWiperSwing = false
                wiperForward = false
            end
        end
    end
    if(electrics.values['mode4WD'] == 1 and electrics.values['modeRangeBox'] == 0) then
        electrics.values['drivetrain_4wd'] = 0.5
    elseif(electrics.values['mode4WD'] == 1 and electrics.values['modeRangeBox'] == 1) then
        electrics.values['drivetrain_4wd'] = 1
    else
        electrics.values['drivetrain_4wd'] = 0
    end

    electrics.values['gear_A'] = gear_A_Smoother:get(electrics.values['gear_A'])
    electrics.values['drivetrain_4wd'] = drivetrain4wdSmoother:get(electrics.values['drivetrain_4wd'])
    electrics.values['wiperVal'] = wiperValSmoother:get(electrics.values['wiperVal'])
    electrics.values['wipers'] = wiperStalkSmoother:get(electrics.values['wipers'])
    electrics.values['keyTurn'] = keySmoother:get(electrics.values['keyTurn'])
end

-- public interface
M.onInit      = onInit
M.onReset     = onInit
M.updateGFX = updateGFX

return M