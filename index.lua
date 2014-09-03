scriptId = 'com.marctan.myodemo.gmaps'

function down()
    myo.keyboard("down_arrow", "down")
end

function up()
    myo.keyboard("up_arrow", "down")
end

function left()
    myo.keyboard("left_arrow", "down")
end

function right()
    myo.keyboard("right_arrow", "down")
end

function zoomIn()
    myo.keyboard("equal", "press", "shift")
end

function zoomOut()
    myo.keyboard("minus", "press")
end

-- Helpers

-- Makes use of myo.getArm() to swap wave out and wave in when the armband is being worn on
-- the left arm. This allows us to treat wave out as wave right and wave in as wave
-- left for consistent direction. The function has no effect on other poses.
function conditionallySwapWave(pose)
    if myo.getArm() == "left" then
        if pose == "waveIn" then
            pose = "waveOut"
        elseif pose == "waveOut" then
            pose = "waveIn"
        end
    end
    return pose
end

-- Unlock mechanism

function unlock()
    unlocked = true
    extendUnlock()
end

function extendUnlock()
    unlockedSince = myo.getTimeMilliseconds()
end

-- Implement Callbacks

function onPoseEdge(pose, edge)
	currentPose = pose

    -- Unlock
    if pose == "thumbToPinky" then
        if edge == "off" then
            -- Unlock when pose is released in case the user holds it for a while.
            unlock()
        elseif edge == "on" and not unlocked then
            -- Vibrate twice on unlock.
            -- We do this when the pose is made for better feedback.
            myo.vibrate("short")
            myo.vibrate("short")
            extendUnlock()
        end
    end

    -- Forward/backward and shuttle.
    if pose == "waveIn" or pose == "waveOut" then
        local now = myo.getTimeMilliseconds()

        if unlocked and edge == "on" then
            -- Deal with direction and arm.
            pose = conditionallySwapWave(pose)

            -- Determine direction based on the pose.
            if pose == "waveIn" then
                zoomIn()
            end

            if pose == "waveOut" then
            	zoomOut()
            end

            -- Initial burst and vibrate
            myo.vibrate("short")
            extendUnlock()
        end
    end

    if pose == "fist" then
    	previousYaw = 0
    end
end

-- All timeouts in milliseconds.

-- Time since last activity before we lock
UNLOCKED_TIMEOUT = 2200
PREV_TIME = 0
previousYaw = 0

function onPeriodic()

	if PREV_TIME == 0 then
		PREV_TIME = myo.getTimeMilliseconds()
	end

	currentTime = myo.getTimeMilliseconds()

	deltaTime = currentTime - PREV_TIME

	myo.debug("deltaTime: " .. deltaTime)

	PREV_TIME = currentTime

	if unlocked and currentPose == "fist" then
		currentPitch = myo.getPitch()
		currentYaw = myo.getYaw()

		if previousYaw == 0 then
			previousYaw = currentYaw
		end

		deltaYaw = currentYaw - previousYaw

		myo.debug("delta Yaw: " .. deltaYaw)

		previousYaw = currentYaw

		if deltaYaw < -0.1 then
			left()
		elseif deltaYaw > 0.1 then
			right()
		else 
			myo.keyboard("right_arrow", "up")
		 	myo.keyboard("left_arrow", "up")
		 end

		if currentPitch < - 0.1 then
			down()
		elseif currentPitch > 0.1 then
			up()
		else
			myo.keyboard("up_arrow", "up")
		 	myo.keyboard("down_arrow", "up")	
		end
	else 
		 myo.keyboard("up_arrow", "up")
		 myo.keyboard("down_arrow", "up")
		 myo.keyboard("right_arrow", "up")
		 myo.keyboard("left_arrow", "up")
		 
	end


end

function onForegroundWindowChange(app, title)
    -- Here we decide if we want to control the new active app.
    local wantActive = false
    activeApp = ""

    if platform == "MacOS" then
        if app == "com.google.Chrome" then
            -- Keynote on MacOS
            wantActive = true
            activeApp = "Chrome"
        end
    elseif platform == "Windows" then
        -- Powerpoint on Windows
        wantActive = string.match(title, " %- Chrome$")
        activeApp = "Chrome"
    end

    return wantActive
end

function activeAppName()
    -- Return the active app name determined in onForegroundWindowChange
    return activeApp
end

function onActiveChange(isActive)
    if not isActive then
        unlocked = false
    end
end