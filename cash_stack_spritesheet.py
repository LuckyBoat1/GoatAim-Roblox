from PIL import Image, ImageDraw, ImageFont
import random, math

random.seed(42)

# ═══════════════════════════════════════════
#  Sprite Sheet
# ═══════════════════════════════════════════
COLS, ROWS = 4, 4
FRAMES = COLS * ROWS       # 16
SHEET_SIZE = 1024
CELL = SHEET_SIZE // COLS   # 256

# ═══════════════════════════════════════════
#  Bill / Animation
# ═══════════════════════════════════════════
BW, BH = 100, 48           # bill width / height

# How many bills are in flight at any given frame
N_FLYING = 3

# ── Physics knobs ──
CURVE_MAX = 10
WAVE_K = 0.9
TUMBLE_MAX = 12             # mild, clean tumble
SWAY_MAX = 6                # very little horizontal drift

# ── Stack ──
STACK_BASE_Y = CELL - 20
STACK_EDGE_H = 4
MAX_STACK = 3              # stack grows to 3 then stays

# ── Colours ──
C_LIGHT  = (130, 220, 135)
C_DARK   = (42, 130, 58)
C_BORDER = (26, 82, 40)
C_SHADOW = (0, 0, 0, 42)
C_EDGE   = (52, 148, 68)
C_BAND   = (34, 100, 48)
C_SPARKLE = (220, 255, 220)
C_TRAIL   = (255, 255, 255)

# ── Sparkle settings ──
N_SPARKLES = 5              # sparkles per bill per frame
SPARKLE_SIZE = (3, 8)       # min/max sparkle arm length

# ── Glow settings ──
GLOW_RADIUS = 38            # radius of soft glow behind each bill
GLOW_COLOR = (130, 255, 150)
GLOW_OPACITY = 55           # max opacity of glow center

# ── Trail settings ──
TRAIL_LINES = 4             # number of wind streaks per bill
TRAIL_LENGTH = 40           # length of each streak in pixels
TRAIL_MAX_W = 3             # max line width

# ── Per-bill random data (one per flying bill) ──
bill_rand = []
for _ in range(N_FLYING):
    bill_rand.append(dict(
        jx  = random.randint(-2, 2),       # very little x scatter
        jr  = random.uniform(-1.0, 1.0),
        wp  = random.uniform(0, math.tau),
        sx  = random.randint(-3, 3),       # minimal sway offset
        # sparkle offsets (pre-baked so they're consistent)
        sparkles = [(random.randint(-44, 44), random.randint(-22, 22),
                     random.uniform(0, math.tau)) for _ in range(N_SPARKLES * 2)],
    ))


# ═══════════════════════════════════════════
#  Curved-bill renderer (supersampled for quality)
# ═══════════════════════════════════════════

N_SEG = 40  # smooth curves

def _edge_pts(ox, oy, hw, hh, curve, phase, sign):
    pts = []
    for i in range(N_SEG + 1):
        t = i / N_SEG
        x = -hw + t * BW
        wave = curve * math.sin(t * math.pi * WAVE_K * 2 + phase)
        sq = 1.0 - 0.18 * abs(
            math.sin(t * math.pi * WAVE_K * 2 + phase)
        ) * min(1.0, curve / 10)
        y = sign * hh * sq + wave
        pts.append((ox + x, oy + y))
    return pts


def draw_curved_bill(img, cx, cy,
                     curve_amp=0, curve_phase=0,
                     angle=0, opacity=255):
    buf_sz = int(max(BW, BH) * 2.8)
    buf = Image.new("RGBA", (buf_sz, buf_sz), (0, 0, 0, 0))
    d = ImageDraw.Draw(buf)
    ox, oy = buf_sz // 2, buf_sz // 2
    hw, hh = BW / 2, BH / 2

    top = _edge_pts(ox, oy, hw, hh, curve_amp, curve_phase, -1)
    bot = _edge_pts(ox, oy, hw, hh, curve_amp, curve_phase, +1)

    # Slope-shaded body strips
    for i in range(N_SEG):
        t_mid = (i + 0.5) / N_SEG
        slope = (curve_amp * math.cos(t_mid * math.pi * WAVE_K * 2 + curve_phase)
                 * WAVE_K * 2 * math.pi / BW)
        brt = 0.45 + 0.48 * math.tanh(slope * 6)
        r = int(C_DARK[0] + (C_LIGHT[0] - C_DARK[0]) * brt)
        g = int(C_DARK[1] + (C_LIGHT[1] - C_DARK[1]) * brt)
        b = int(C_DARK[2] + (C_LIGHT[2] - C_DARK[2]) * brt)
        d.polygon([top[i], top[i+1], bot[i+1], bot[i]],
                  fill=(r, g, b, opacity))

    # Outline
    bdr = (*C_BORDER, opacity)
    d.line(top, fill=bdr, width=2)
    d.line(list(reversed(bot)), fill=bdr, width=2)
    d.line([top[0], bot[0]], fill=bdr, width=2)
    d.line([top[-1], bot[-1]], fill=bdr, width=2)

    # Inner margin
    mg = max(2, int(N_SEG * 0.10))
    inset = 6
    itop, ibot = [], []
    for i in range(mg, N_SEG + 1 - mg):
        t = i / N_SEG
        x = -hw + t * BW
        wave = curve_amp * math.sin(t * math.pi * WAVE_K * 2 + curve_phase)
        sq = 1.0 - 0.18 * abs(
            math.sin(t * math.pi * WAVE_K * 2 + curve_phase)
        ) * min(1.0, curve_amp / 10)
        itop.append((ox + x, oy - hh * sq + wave + inset))
        ibot.append((ox + x, oy + hh * sq + wave - inset))
    if len(itop) > 1:
        ic = (*C_BORDER, min(opacity, 130))
        d.line(itop, fill=ic, width=1)
        d.line(list(reversed(ibot)), fill=ic, width=1)
        d.line([itop[0], ibot[0]], fill=ic, width=1)
        d.line([itop[-1], ibot[-1]], fill=ic, width=1)

    # Dollar sign + circle
    ctr_wave = curve_amp * math.sin(0.5 * math.pi * WAVE_K * 2 + curve_phase)
    try:
        font = ImageFont.truetype("arial.ttf", 14)
    except (OSError, IOError):
        font = ImageFont.load_default()
    dcol = (*C_BORDER, min(opacity, 220))
    tb = d.textbbox((0, 0), "$", font=font)
    tw, th = tb[2]-tb[0], tb[3]-tb[1]
    dy = int(ctr_wave)
    d.text((ox - tw//2, oy - th//2 + dy - 1), "$", fill=dcol, font=font)
    cr = 8
    d.ellipse([ox-cr, oy+dy-cr, ox+cr, oy+dy+cr], outline=dcol, width=1)

    # Rotate
    if angle != 0:
        buf = buf.rotate(angle, resample=Image.BICUBIC, expand=True)

    px = cx - buf.width // 2
    py = cy - buf.height // 2
    img.paste(buf, (px, py), buf)


# ═══════════════════════════════════════════
#  Stack
# ═══════════════════════════════════════════

def draw_stack(img, cx, n):
    if n <= 0:
        return
    d = ImageDraw.Draw(img)
    hw = BW // 2 - 3
    n = min(n, MAX_STACK)
    total_edge = n * STACK_EDGE_H

    for i in range(n):
        ey = STACK_BASE_Y - i * STACK_EDGE_H
        shade = C_EDGE if i % 2 == 0 else (
            C_EDGE[0]-10, C_EDGE[1]-10, C_EDGE[2]-10)
        d.rectangle([cx-hw, ey-STACK_EDGE_H, cx+hw, ey],
                    fill=shade, outline=C_BORDER, width=1)
        d.line([(cx-hw+3, ey-STACK_EDGE_H+1),
                (cx+hw-3, ey-STACK_EDGE_H+1)],
               fill=(*C_LIGHT, 80), width=1)

    if n >= 2:
        pass  # no band

    top_y = STACK_BASE_Y - total_edge - BH // 2 + 2
    draw_curved_bill(img, cx, top_y, curve_amp=0, angle=0)


# ═══════════════════════════════════════════
#  Physics for a single bill
# ═══════════════════════════════════════════

def bill_physics(t, bi):
    """t ∈ [0,1]. Returns (y_frac, sway, rot, curve_amp, curve_phase).
    y_frac: 0=top of frame, 1=landed."""
    bd = bill_rand[bi % len(bill_rand)]

    # Vertical: blend linear + quadratic for visible movement
    y_frac = 0.35 * t + 0.65 * t * t

    # Sway
    fade = (1 - t) ** 0.8
    sway = SWAY_MAX * math.sin(t * math.pi * 2.2 + bd['wp']) * fade
    sway += bd['sx'] * (1 - t)

    # Rotation
    rot = TUMBLE_MAX * math.sin(t * math.pi * 1.8 + bd['wp']) * fade
    rot += bd['jr'] * t

    # Curve
    c_amp = CURVE_MAX * (1 - t) ** 0.5
    c_phase = t * math.pi * 5 + bd['wp']

    return y_frac, sway, rot, c_amp, c_phase


# ═══════════════════════════════════════════
#  Glow – soft radial glow behind each bill
# ═══════════════════════════════════════════

def draw_bill_glow(img, cx, cy, frame_idx, bill_idx):
    """Draw a soft radial glow behind the bill to make it pop."""
    r = GLOW_RADIUS
    buf = Image.new("RGBA", (r * 2, r * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(buf)
    # Draw concentric circles with decreasing opacity
    steps = 12
    for i in range(steps):
        frac = i / steps
        radius = int(r * (1 - frac * 0.7))
        opa = int(GLOW_OPACITY * (1 - frac) ** 1.5)
        if opa < 3:
            break
        col = (*GLOW_COLOR, opa)
        d.ellipse([r - radius, r - radius, r + radius, r + radius], fill=col)
    px = cx - r
    py = cy - r
    img.paste(buf, (px, py), buf)


# ═══════════════════════════════════════════
#  Motion trail – vertical streak showing bill path
# ═══════════════════════════════════════════

def draw_motion_trail(draw, cx, cy, y_frac, start_y):
    """Draw a fading vertical trail above the bill showing where it came from."""
    if y_frac < 0.08:
        return
    trail_len = int(min(35, (cy - start_y) * 0.5))
    if trail_len < 4:
        return
    for i in range(trail_len):
        frac = i / trail_len
        opa = int(90 * (1 - frac) ** 1.5)
        if opa < 5:
            break
        ty = cy - i - 2
        hw = max(1, int(3 * (1 - frac * 0.7)))
        draw.line([(cx - hw, ty), (cx + hw, ty)],
                  fill=(200, 255, 210, opa), width=1)


# ═══════════════════════════════════════════
#  Soft landing – gentle puff when bill lands
# ═══════════════════════════════════════════

def draw_soft_landing(img, cx, land_y, t_land, frame_idx):
    """Draw a soft puff/squash at landing. t_land: 0=impact, 1=settled."""
    if t_land < 0 or t_land > 1:
        return
    d = ImageDraw.Draw(img)
    fade = (1 - t_land) ** 2.5
    hw = BW // 2

    # Small horizontal puff lines
    for side in (-1, 1):
        for i in range(3):
            spread = int((15 + i * 8) * fade)
            sx = cx + side * (hw // 2 + i * 5)
            sy = land_y + BH // 2 + 2 - i * 2
            ex = sx + side * spread
            opa = int(120 * fade * (1 - i * 0.25))
            if opa < 8:
                continue
            d.line([(sx, sy), (ex, sy)],
                   fill=(255, 255, 255, opa), width=max(1, 2 - i))

    # Tiny particles popping up
    for p in range(3):
        ang = -math.pi / 2 + (p - 1) * 0.6
        dist = 6 + t_land * 10 + p * 2
        px = cx + math.cos(ang) * dist
        py = land_y + BH // 2 + math.sin(ang) * dist
        pr = max(1, int(2 * fade))
        opa = int(100 * fade)
        if opa < 8:
            continue
        d.ellipse([px - pr, py - pr, px + pr, py + pr],
                  fill=(220, 255, 220, opa))


# ═══════════════════════════════════════════
#  Sparkles – 4-pointed star glints
# ═══════════════════════════════════════════

def draw_sparkle(draw, cx, cy, arm_len, angle_off=0, opacity=180):
    """Draw a tiny 4-pointed star sparkle."""
    col = (*C_SPARKLE, opacity)
    col_core = (255, 255, 255, min(255, opacity + 40))
    for a in range(4):
        ang = angle_off + a * math.pi / 4
        ex = cx + math.cos(ang) * arm_len
        ey = cy + math.sin(ang) * arm_len
        draw.line([(cx, cy), (ex, ey)], fill=col, width=1)
    # bright center dot
    draw.rectangle([cx-1, cy-1, cx+1, cy+1], fill=col_core)


def draw_sparkles_on_bill(draw, bx, by, bill_idx, frame_idx):
    """Draw sparkles around a bill position. They shimmer per frame."""
    bd = bill_rand[bill_idx % len(bill_rand)]
    for s in range(N_SPARKLES):
        # Pick a sparkle slot, cycle through them per frame
        slot = (s + frame_idx) % len(bd['sparkles'])
        sx, sy, base_ang = bd['sparkles'][slot]
        # Shimmer: arm length oscillates with frame
        phase = base_ang + frame_idx * 0.8
        arm = SPARKLE_SIZE[0] + (SPARKLE_SIZE[1] - SPARKLE_SIZE[0]) * \
              (0.5 + 0.5 * math.sin(phase))
        # Opacity pulses
        opa = int(120 + 80 * math.sin(phase + 1.2))
        draw_sparkle(draw, int(bx + sx), int(by + sy),
                     arm, angle_off=base_ang + frame_idx * 0.3, opacity=opa)


# ═══════════════════════════════════════════
#  Wind trails – detached streaks beside bills
# ═══════════════════════════════════════════

def draw_wind_trails(draw, cur_x, cur_y, y_frac, frame_idx, bill_idx, rot):
    """Draw wind streaks floating beside the bill (not attached to edges)."""
    if y_frac < 0.05:
        return
    bd = bill_rand[bill_idx % len(bill_rand)]
    intensity = min(1.0, y_frac * 3)
    hw = BW // 2

    # Two sides: left and right of the bill
    for side in (-1, 1):
        # Small gap so streaks don't touch the bill edge
        gap = 6 + 3 * math.sin(frame_idx * 0.4 + bd['wp'])
        base_x = cur_x + side * (hw + gap)

        # 2 streaks per side
        for s in range(2):
            y_off = -5 + s * 10
            sx = base_x + side * s * 4
            sy = cur_y + y_off

            streak_len = int(TRAIL_LENGTH * intensity)
            if streak_len < 3:
                continue

            # Streaks flow upward with gentle outward lean
            base_angle = -math.pi / 2 + side * 0.3
            wobble = 0.15 * math.sin(frame_idx * 0.7 + bd['wp'] + s * 2.5)

            pts = []
            for p in range(streak_len):
                frac_p = p / max(1, streak_len - 1)
                curve = side * 0.25 * math.sin(frac_p * math.pi)
                ang = base_angle + wobble + curve
                px = sx + math.cos(ang) * p * 1.05
                py = sy + math.sin(ang) * p * 1.05
                pts.append((px, py))

            if len(pts) < 2:
                continue

            # Draw with tapering opacity – starts full bright
            for i in range(len(pts) - 1):
                frac = i / len(pts)
                fade_out = (1 - frac) ** 0.6
                opa = int(255 * intensity * fade_out)
                opa = min(255, opa)
                if opa < 10:
                    break
                w = max(1, int(TRAIL_MAX_W * (1 - frac * 0.6)))
                col = (*C_TRAIL, opa)
                draw.line([pts[i], pts[i + 1]], fill=col, width=w)


# ═══════════════════════════════════════════
#  Stack shine – animated gleam across the stack
# ═══════════════════════════════════════════

def draw_stack_shine(draw, cx, n_stack, frame_idx):
    """Draw corner sparkles on the stack."""
    if n_stack <= 0:
        return
    hw = BW // 2 - 3
    n = min(n_stack, MAX_STACK)
    total_edge = n * STACK_EDGE_H
    stack_top = STACK_BASE_Y - total_edge - BH + 2
    stack_bot = STACK_BASE_Y
    stack_left = cx - hw
    stack_right = cx + hw

    # Corner sparkles on stack
    corners = [
        (stack_left + 4, stack_top + 4),
        (stack_right - 4, stack_top + 4),
        (stack_left + 4, stack_bot - 4),
        (stack_right - 4, stack_bot - 4),
    ]
    for i, (sx, sy) in enumerate(corners):
        phase = frame_idx * 0.6 + i * 1.5
        arm = 2 + 2 * (0.5 + 0.5 * math.sin(phase))
        opa = int(100 + 80 * math.sin(phase + 0.8))
        draw_sparkle(draw, int(sx), int(sy), arm,
                     angle_off=phase * 0.4, opacity=opa)


# ═══════════════════════════════════════════
#  Build the sheet
# ═══════════════════════════════════════════
sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))

# Each of the N_FLYING bills has a time offset so they're staggered
# Bill i starts its fall at phase offset i/N_FLYING of the full cycle
# The animation loops over 16 frames

for f in range(FRAMES):
    frame = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    fcx = CELL // 2

    # Stack grows: frame 0-3 = 0, 4-7 = 1, 8-11 = 2, 12-15 = 3
    n_stack = min(f // 4, MAX_STACK)
    if n_stack > 0:
        draw_stack(frame, fcx, n_stack)
        # Shine effect on the stack
        fd_shine = ImageDraw.Draw(frame)
        draw_stack_shine(fd_shine, fcx, n_stack, f)

    # Soft landing effect on frames after stack grows
    if f > 0 and f % 4 == 0:
        land_fx_y = STACK_BASE_Y - min(n_stack, MAX_STACK) * STACK_EDGE_H - BH // 2
        draw_soft_landing(frame, fcx, land_fx_y, 0.0, f)
    elif f > 0 and f % 4 == 1:
        land_fx_y = STACK_BASE_Y - min(n_stack, MAX_STACK) * STACK_EDGE_H - BH // 2
        draw_soft_landing(frame, fcx, land_fx_y, 0.5, f)
    elif f > 0 and f % 4 == 2:
        land_fx_y = STACK_BASE_Y - min(n_stack, MAX_STACK) * STACK_EDGE_H - BH // 2
        draw_soft_landing(frame, fcx, land_fx_y, 0.85, f)

    # Stack top y (where bills land)
    stack_h = min(n_stack, MAX_STACK) * STACK_EDGE_H + (BH if n_stack > 0 else 0)
    land_y = STACK_BASE_Y - stack_h - BH // 2 + 4

    # Top of fall area
    start_y = BH // 2 + 8
    margin_x = BW // 2 + 8

    # Draw N_FLYING bills in a neat vertical column, evenly spaced
    for b in range(N_FLYING):
        # Each bill is offset by 1/N_FLYING of the cycle
        phase_offset = b / N_FLYING
        raw_t = (f / FRAMES + phase_offset) % 1.0

        # Gradually introduce bills over the first few frames
        entry_frame = b * 2
        if f < entry_frame:
            continue

        y_frac, sway, rot, c_amp, c_phase = bill_physics(raw_t, b)

        # Position: centered column, evenly spaced vertically
        cur_y = int(start_y + (land_y - start_y) * y_frac)
        cur_x = int(fcx + sway + bill_rand[b]['jx'])

        # Clamp inside cell
        cur_x = max(margin_x, min(CELL - margin_x, cur_x))
        cur_y = max(start_y, min(land_y, cur_y))

        # Opacity: slightly transparent
        opa = int(200 + 55 * y_frac)

        # Glow behind the bill
        draw_bill_glow(frame, cur_x, cur_y, f, b)

        # Motion trail above the bill
        fd_mt = ImageDraw.Draw(frame)
        draw_motion_trail(fd_mt, cur_x, cur_y, y_frac, start_y)

        # Wind trails (drawn behind the bill)
        fd = ImageDraw.Draw(frame)
        draw_wind_trails(fd, cur_x, cur_y, y_frac, f, b, rot)

        # The bill itself
        draw_curved_bill(frame, cur_x, cur_y,
                         curve_amp=c_amp, curve_phase=c_phase,
                         angle=rot, opacity=opa)

        # Sparkles on top of the bill
        fd2 = ImageDraw.Draw(frame)
        draw_sparkles_on_bill(fd2, cur_x, cur_y, b, f)

    row, col = f // COLS, f % COLS
    sheet.paste(frame, (col * CELL, row * CELL))

sheet.save("cash_stack_spritesheet.png")
print("Done – saved cash_stack_spritesheet.png")
