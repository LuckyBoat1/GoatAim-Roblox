--!strict
-- OrbitMath: Pure helpers for deterministic orbits and the right-side binary pair clamp

export type OrbitCenter = Vector2

local OrbitMath = {}

-- Advance an angle given base speed and an optional radius-speed curve
-- speed(angle) = baseSpeed * (refRadius / radius)^exp  (exp=0 => uniform)
function OrbitMath.stepAngle(
	angle: number,
	dt: number,
	baseSpeed: number,
	exp: number,
	refRadius: number,
	radius: number
): number
	local mul = 1
	if exp ~= 0 and radius > 0 and refRadius > 0 then
		mul = (refRadius / radius) ^ exp
	end
	return angle + dt * baseSpeed * mul
end

-- Compute a planet position on an ellipse with a mild vertical tilt
-- Returns screen-space coordinates (pixels) if center and radius are in pixels
function OrbitMath.orbitPosition(
	angle: number,
	radius: number,
	center: OrbitCenter,
	tilt: number?
): Vector2
	local t = tilt or 0
	local x = center.X + math.cos(angle) * radius
	local y = center.Y + math.sin(angle) * radius + math.sin(angle) * (t * radius)
	return Vector2.new(x, y)
end

-- Clamp the binary pivot X so the pair is fully on-screen
-- areaWidth: screen width in pixels
-- rawPivotX: the desired pivot (from sun center + cluster radius)
-- maxBinarySize: the largest planet size in the pair (pixels)
-- edgeMargin: extra padding from screen edges (pixels)
-- localR: the local orbit radius of the pair (pixels)
function OrbitMath.clampBinaryPivotX(
	areaWidth: number,
	rawPivotX: number,
	maxBinarySize: number,
	edgeMargin: number,
	localR: number
): number
	local halfMax = (maxBinarySize * 0.5) + edgeMargin + localR
	return math.clamp(rawPivotX, halfMax, areaWidth - halfMax)
end

return OrbitMath
