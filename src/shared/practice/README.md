# Practice Modules (shared/practice)

Small, self-contained helpers extracted from the project so you can practice the core ideas without full scripts.

Modules
- OrbitMath.luau
  - stepAngle(angle, dt, baseSpeed, exp, refRadius, radius): advance angle with optional radius-speed curve
  - orbitPosition(angle, radius, center, tilt?): compute XY position with a mild vertical tilt
  - clampBinaryPivotX(areaWidth, rawPivotX, maxBinarySize, edgeMargin, localR): keep right-side pair on-screen

- RankPractice.luau
  - targetsPerMinute(state, now?): sliding-window TPM
  - progress(state, ranks?): returns progress breakdown (current/next, needs, fractions)

- LootBoxPractice.luau
  - weightedPick(weights): choose rarity by weights
  - pickSkin(pools, rarity): choose a skin from rarity pool with fallback

- SkinExtractPractice.luau
  - ownedSet(data): robustly extract owned skin IDs from various data shapes

- HitWindowPractice.luau
  - recordHit(state, now?) / targetsPerMinute(state)
  - onBullseyeRing(state, ringNumber) / resetBullseye(state)

- RefinerTimePractice.luau
  - progress(startTime, duration, now?): returns {progress, remaining}
  - format(remaining): HH:MM(:SS) string based on remaining seconds

Tips
- Require these from client or server scripts for isolated testing.
- Keep state in a local table you pass back into the functions.
- For deterministic tests, pass a fixed `now` instead of using os.time().
