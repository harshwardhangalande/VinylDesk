#!/usr/bin/env python3
import os
import math
import subprocess
from PIL import Image, ImageDraw, ImageFilter, ImageFont

def create_mac_icon():
    WIDTH, HEIGHT = 1024, 1024
    
    # Supersampling factor for ultra-sharp edges
    SCALE = 2
    W, H = WIDTH * SCALE, HEIGHT * SCALE
    
    # Main canvas (transparent RGBA)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    
    # macOS squircle dimensions inside 1024x1024:
    # Standard macOS icon grid: 824x824 tile centered with corner radius ~185 (at 1x)
    tile_w = int(824 * SCALE)
    tile_h = int(824 * SCALE)
    tile_x = (W - tile_w) // 2
    tile_y = (H - tile_h) // 2 - int(10 * SCALE) # slight lift for bottom shadow
    radius = int(185 * SCALE)
    
    # 1. Base Drop Shadow
    shadow_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_img)
    # Multiple shadow layers for realistic macOS depth
    s_offset_y = int(28 * SCALE)
    s_draw.rounded_rectangle(
        [tile_x, tile_y + s_offset_y, tile_x + tile_w, tile_y + tile_h + s_offset_y],
        radius=radius,
        fill=(0, 0, 0, 140)
    )
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(int(36 * SCALE)))
    
    # Contact shadow (closer, sharper)
    contact_shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    c_draw = ImageDraw.Draw(contact_shadow)
    c_draw.rounded_rectangle(
        [tile_x, tile_y + int(12 * SCALE), tile_x + tile_w, tile_y + tile_h + int(12 * SCALE)],
        radius=radius,
        fill=(0, 0, 0, 180)
    )
    contact_shadow = contact_shadow.filter(ImageFilter.GaussianBlur(int(14 * SCALE)))
    
    # Composite shadows
    img = Image.alpha_composite(img, shadow_img)
    img = Image.alpha_composite(img, contact_shadow)
    
    # 2. Squircle Tile Base
    tile_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    t_draw = ImageDraw.Draw(tile_img)
    
    # Draw tile mask
    mask = Image.new("L", (W, H), 0)
    m_draw = ImageDraw.Draw(mask)
    m_draw.rounded_rectangle(
        [tile_x, tile_y, tile_x + tile_w, tile_y + tile_h],
        radius=radius,
        fill=255
    )
    
    # Create tile gradient background (deep studio obsidian / dark slate)
    tile_bg = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tb_draw = ImageDraw.Draw(tile_bg)
    for y in range(tile_y, tile_y + tile_h):
        progress = (y - tile_y) / float(tile_h)
        # Deep rich midnight navy gradient
        r = int(22 * (1.0 - progress) + 10 * progress)
        g = int(26 * (1.0 - progress) + 12 * progress)
        b = int(36 * (1.0 - progress) + 18 * progress)
        tb_draw.line([(tile_x, y), (tile_x + tile_w, y)], fill=(r, g, b, 255))
        
    # Top internal highlight on the squircle
    highlight = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    h_draw = ImageDraw.Draw(highlight)
    for y in range(tile_y, tile_y + int(160 * SCALE)):
        prog = (y - tile_y) / (160.0 * SCALE)
        alpha = int(45 * (1.0 - prog))
        h_draw.line([(tile_x, y), (tile_x + tile_w, y)], fill=(255, 255, 255, alpha))
        
    tile_content = Image.alpha_composite(tile_bg, highlight)
    
    # 3. Vinyl Record
    vinyl_cx = W // 2
    vinyl_cy = tile_y + tile_h // 2
    vinyl_r = int(340 * SCALE)
    
    vinyl_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    v_draw = ImageDraw.Draw(vinyl_layer)
    
    # Vinyl drop shadow onto the squircle
    v_shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    vs_draw = ImageDraw.Draw(v_shadow)
    vs_draw.ellipse(
        [vinyl_cx - vinyl_r, vinyl_cy - vinyl_r + int(15 * SCALE),
         vinyl_cx + vinyl_r, vinyl_cy + vinyl_r + int(15 * SCALE)],
        fill=(0, 0, 0, 200)
    )
    v_shadow = v_shadow.filter(ImageFilter.GaussianBlur(int(20 * SCALE)))
    
    # Base Vinyl Body (solid deep dark carbon black)
    v_draw.ellipse(
        [vinyl_cx - vinyl_r, vinyl_cy - vinyl_r, vinyl_cx + vinyl_r, vinyl_cy + vinyl_r],
        fill=(14, 15, 18, 255),
        outline=(50, 54, 62, 255),
        width=int(2 * SCALE)
    )
    
    # Realistic Anisotropic Butterfly Sheen (conical specular reflection)
    sheen = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    s_pixels = sheen.load()
    # To be fast, render sheen on bounding box with radial/angular formula
    box_r = vinyl_r
    step = 2  # downsample for speed then blur
    sheen_small = Image.new("RGBA", (box_r * 2 // step, box_r * 2 // step), (0, 0, 0, 0))
    sm_pix = sheen_small.load()
    sm_cx = box_r // step
    sm_cy = box_r // step
    sm_r = box_r // step
    
    for sy in range(box_r * 2 // step):
        dy = sy - sm_cy
        for sx in range(box_r * 2 // step):
            dx = sx - sm_cx
            dist = math.hypot(dx, dy)
            if dist < sm_r * 0.35 or dist > sm_r:
                continue
            angle = math.atan2(dy, dx) # -pi to pi
            # Specular peaks at ~45 deg (0.785 rad) and ~225 deg (-2.356 rad)
            # or double butterfly lobes:
            lobe = (math.sin(angle * 2.0 - 0.7)) ** 6
            if lobe > 0.05:
                # falloff near edges and center
                rad_factor = math.sin((dist - sm_r * 0.35) / (sm_r * 0.65) * math.pi)
                alpha = int(lobe * rad_factor * 85)
                sm_pix[sx, sy] = (210, 225, 255, alpha)
                
    sheen_small = sheen_small.resize((box_r * 2, box_r * 2), Image.Resampling.BILINEAR)
    sheen.paste(sheen_small, (vinyl_cx - box_r, vinyl_cy - box_r), sheen_small)
    sheen = sheen.filter(ImageFilter.GaussianBlur(int(4 * SCALE)))
    
    vinyl_layer = Image.alpha_composite(vinyl_layer, sheen)
    v_draw = ImageDraw.Draw(vinyl_layer)
    
    # Concentric Vinyl Sound Grooves
    # Draw fine micro-groove arcs with delicate opacity variations
    num_grooves = 75
    inner_limit = int(vinyl_r * 0.42)
    outer_limit = int(vinyl_r * 0.94)
    for i in range(num_grooves):
        gr_r = int(inner_limit + (outer_limit - inner_limit) * (i / float(num_grooves)))
        # Vary brightness to create realistic track bands (run-out grooves)
        is_gap = (i % 14 == 0 or i % 23 == 0)
        alpha = 60 if is_gap else (35 if i % 2 == 0 else 18)
        color = (200, 210, 230, alpha)
        width = int(1.8 * SCALE) if is_gap else int(1.0 * SCALE)
        v_draw.ellipse(
            [vinyl_cx - gr_r, vinyl_cy - gr_r, vinyl_cx + gr_r, vinyl_cy + gr_r],
            outline=color,
            width=width
        )
        
    # Lead-in outer rim and run-out groove
    v_draw.ellipse(
        [vinyl_cx - outer_limit, vinyl_cy - outer_limit, vinyl_cx + outer_limit, vinyl_cy + outer_limit],
        outline=(255, 255, 255, 50),
        width=int(2 * SCALE)
    )
    v_draw.ellipse(
        [vinyl_cx - inner_limit, vinyl_cy - inner_limit, vinyl_cx + inner_limit, vinyl_cy + inner_limit],
        outline=(255, 255, 255, 70),
        width=int(2 * SCALE)
    )
    
    # 4. Center Vinyl Label (Vibrant Neon Gradient + Typography)
    label_r = int(120 * SCALE)
    label_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    l_draw = ImageDraw.Draw(label_img)
    
    # Center label drop shadow
    label_shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ls_draw = ImageDraw.Draw(label_shadow)
    ls_draw.ellipse(
        [vinyl_cx - label_r, vinyl_cy - label_r + int(4 * SCALE),
         vinyl_cx + label_r, vinyl_cy + label_r + int(4 * SCALE)],
        fill=(0, 0, 0, 180)
    )
    label_shadow = label_shadow.filter(ImageFilter.GaussianBlur(int(6 * SCALE)))
    
    # Draw radial/angled vibrant gradient for the label
    # Electric neon violet / magenta to vivid cyan
    lbl_w = label_r * 2
    lbl_square = Image.new("RGBA", (lbl_w, lbl_w), (0, 0, 0, 0))
    lbl_pix = lbl_square.load()
    for y in range(lbl_w):
        for x in range(lbl_w):
            dx = x - label_r
            dy = y - label_r
            dist = math.hypot(dx, dy)
            if dist <= label_r:
                # Diagonal gradient
                diag = (dx + dy + label_r * 1.414) / (label_r * 2.828)
                diag = max(0.0, min(1.0, diag))
                
                # Gradient: Electric Magenta (#ff0077) -> Electric Purple (#7928ca) -> Deep Cyan/Blue (#0070f3)
                if diag < 0.5:
                    t = diag * 2.0
                    r = int(255 * (1 - t) + 121 * t)
                    g = int(0 * (1 - t) + 40 * t)
                    b = int(119 * (1 - t) + 202 * t)
                else:
                    t = (diag - 0.5) * 2.0
                    r = int(121 * (1 - t) + 0 * t)
                    g = int(40 * (1 - t) + 195 * t)
                    b = int(202 * (1 - t) + 255 * t)
                
                # Subtle ring accent inside label
                if abs(dist - label_r * 0.75) < 1.5 * SCALE:
                    r = min(255, r + 40)
                    g = min(255, g + 40)
                    b = min(255, b + 40)
                    
                lbl_pix[x, y] = (r, g, b, 255)
                
    label_img.paste(lbl_square, (vinyl_cx - label_r, vinyl_cy - label_r), lbl_square)
    
    # Text on label: "VINYL" and audio wave
    l_draw = ImageDraw.Draw(label_img)
    
    # Center decorative ring
    l_draw.ellipse(
        [vinyl_cx - int(label_r * 0.72), vinyl_cy - int(label_r * 0.72),
         vinyl_cx + int(label_r * 0.72), vinyl_cy + int(label_r * 0.72)],
        outline=(255, 255, 255, 80),
        width=int(1.5 * SCALE)
    )
    
    # Decorative stylized waveform / geometric bars on top half of label
    bar_count = 11
    bar_width = int(4 * SCALE)
    bar_spacing = int(3 * SCALE)
    total_bar_w = bar_count * (bar_width + bar_spacing)
    start_bx = vinyl_cx - total_bar_w // 2
    base_by = vinyl_cy - int(45 * SCALE)
    
    for b_idx in range(bar_count):
        # Wave shape: peak in middle
        norm_idx = abs(b_idx - bar_count // 2) / float(bar_count // 2)
        h_val = int((1.0 - norm_idx * 0.75) * 32 * SCALE)
        bx = start_bx + b_idx * (bar_width + bar_spacing)
        l_draw.rounded_rectangle(
            [bx, base_by - h_val // 2, bx + bar_width, base_by + h_val // 2],
            radius=int(2 * SCALE),
            fill=(255, 255, 255, 220)
        )
        
    # Spindle hole
    spindle_r = int(22 * SCALE)
    metal_ring_r = int(30 * SCALE)
    
    # Metallic collar around spindle hole
    l_draw.ellipse(
        [vinyl_cx - metal_ring_r, vinyl_cy - metal_ring_r,
         vinyl_cx + metal_ring_r, vinyl_cy + metal_ring_r],
        fill=(190, 195, 205, 255),
        outline=(240, 245, 255, 255),
        width=int(2 * SCALE)
    )
    # The actual hole (transparent or deep dark showing turntable spindle)
    l_draw.ellipse(
        [vinyl_cx - spindle_r, vinyl_cy - spindle_r,
         vinyl_cx + spindle_r, vinyl_cy + spindle_r],
        fill=(10, 12, 16, 255),
        outline=(80, 85, 95, 255),
        width=int(2 * SCALE)
    )
    # Spindle pin highlight
    l_draw.ellipse(
        [vinyl_cx - int(7 * SCALE), vinyl_cy - int(7 * SCALE),
         vinyl_cx + int(7 * SCALE), vinyl_cy + int(7 * SCALE)],
        fill=(220, 230, 245, 255)
    )
    
    # 5. High-Tech Minimalist Tonearm Stylus (brushed aluminum needle from top right)
    arm_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    a_draw = ImageDraw.Draw(arm_layer)
    
    # Pivot point at top right outside/near edge of squircle
    pivot_x = tile_x + tile_w - int(80 * SCALE)
    pivot_y = tile_y + int(80 * SCALE)
    pivot_r = int(48 * SCALE)
    
    # Target stylus needle point resting in the vinyl groove
    target_x = vinyl_cx + int(190 * SCALE)
    target_y = vinyl_cy + int(90 * SCALE)
    
    # Arm drop shadow
    arm_shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    as_draw = ImageDraw.Draw(arm_shadow)
    as_draw.line(
        [(pivot_x, pivot_y + int(14 * SCALE)), (target_x, target_y + int(14 * SCALE))],
        fill=(0, 0, 0, 150),
        width=int(14 * SCALE)
    )
    arm_shadow = arm_shadow.filter(ImageFilter.GaussianBlur(int(10 * SCALE)))
    
    # Draw arm rod (brushed metallic titanium)
    a_draw.line(
        [(pivot_x, pivot_y), (target_x, target_y)],
        fill=(210, 215, 225, 255),
        width=int(8 * SCALE)
    )
    # Inner specular highlight on arm rod
    a_draw.line(
        [(pivot_x, pivot_y - int(1 * SCALE)), (target_x, target_y - int(1 * SCALE))],
        fill=(255, 255, 255, 180),
        width=int(2 * SCALE)
    )
    
    # Cartridge head at needle tip
    cart_len = int(38 * SCALE)
    cart_w = int(18 * SCALE)
    # Cartridge angle aligns with arm direction
    arm_angle = math.atan2(target_y - pivot_y, target_x - pivot_x)
    
    # Draw cartridge as angled capsule / rounded rect
    cart_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ci_draw = ImageDraw.Draw(cart_img)
    # Cartridge body
    c_p1 = (target_x - int(cart_len * 0.4 * math.cos(arm_angle)),
            target_y - int(cart_len * 0.4 * math.sin(arm_angle)))
    c_p2 = (target_x + int(cart_len * 0.6 * math.cos(arm_angle)),
            target_y + int(cart_len * 0.6 * math.sin(arm_angle)))
    ci_draw.line([c_p1, c_p2], fill=(28, 32, 40, 255), width=cart_w)
    ci_draw.line([c_p1, c_p2], fill=(60, 68, 80, 255), width=int(cart_w * 0.6))
    
    # Glowing neon cyan LED indicator on cartridge
    tip_x = target_x + int(cart_len * 0.5 * math.cos(arm_angle))
    tip_y = target_y + int(cart_len * 0.5 * math.sin(arm_angle))
    
    tip_glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tg_draw = ImageDraw.Draw(tip_glow)
    tg_draw.ellipse(
        [tip_x - int(16 * SCALE), tip_y - int(16 * SCALE),
         tip_x + int(16 * SCALE), tip_y + int(16 * SCALE)],
        fill=(0, 220, 255, 140)
    )
    tip_glow = tip_glow.filter(ImageFilter.GaussianBlur(int(8 * SCALE)))
    
    tg_draw.ellipse(
        [tip_x - int(5 * SCALE), tip_y - int(5 * SCALE),
         tip_x + int(5 * SCALE), tip_y + int(5 * SCALE)],
        fill=(220, 255, 255, 255)
    )
    
    # Pivot base assembly (concentric circles of brushed metal)
    a_draw.ellipse(
        [pivot_x - pivot_r, pivot_y - pivot_r, pivot_x + pivot_r, pivot_y + pivot_r],
        fill=(35, 38, 48, 255),
        outline=(90, 95, 110, 255),
        width=int(3 * SCALE)
    )
    a_draw.ellipse(
        [pivot_x - int(pivot_r * 0.65), pivot_y - int(pivot_r * 0.65),
         pivot_x + int(pivot_r * 0.65), pivot_y + int(pivot_r * 0.65)],
        fill=(180, 185, 195, 255),
        outline=(230, 235, 245, 255),
        width=int(2 * SCALE)
    )
    a_draw.ellipse(
        [pivot_x - int(pivot_r * 0.28), pivot_y - int(pivot_r * 0.28),
         pivot_x + int(pivot_r * 0.28), pivot_y + int(pivot_r * 0.28)],
        fill=(20, 22, 28, 255)
    )
    
    # Composite all layers onto tile content
    tile_composite = Image.alpha_composite(tile_content, v_shadow)
    tile_composite = Image.alpha_composite(tile_composite, vinyl_layer)
    tile_composite = Image.alpha_composite(tile_composite, label_shadow)
    tile_composite = Image.alpha_composite(tile_composite, label_img)
    tile_composite = Image.alpha_composite(tile_composite, arm_shadow)
    tile_composite = Image.alpha_composite(tile_composite, arm_layer)
    tile_composite = Image.alpha_composite(tile_composite, cart_img)
    tile_composite = Image.alpha_composite(tile_composite, tip_glow)
    
    # Elegant inner border & bevel on the squircle edge
    border_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(border_img)
    b_draw.rounded_rectangle(
        [tile_x, tile_y, tile_x + tile_w, tile_y + tile_h],
        radius=radius,
        outline=(255, 255, 255, 55),
        width=int(2 * SCALE)
    )
    tile_composite = Image.alpha_composite(tile_composite, border_img)
    
    # Mask tile_composite to squircle shape
    masked_tile = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    masked_tile.paste(tile_composite, (0, 0), mask)
    
    # Final composite
    img = Image.alpha_composite(img, masked_tile)
    
    # Downsample from 2x (2048x2048) to 1x (1024x1024) with Lanczos antialiasing
    final_icon = img.resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS)
    return final_icon

def generate_iconset():
    print("🎨 Rendering 1024x1024 Master App Icon with PIL...")
    master = create_mac_icon()
    os.makedirs("Resources", exist_ok=True)
    master.save("Resources/AppIcon_1024.png", "PNG")
    print("✓ Saved Resources/AppIcon_1024.png")
    
    iconset_dir = "AppIcon.iconset"
    os.makedirs(iconset_dir, exist_ok=True)
    
    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]
    
    for dim, filename in sizes:
        resized = master.resize((dim, dim), Image.Resampling.LANCZOS)
        out_path = os.path.join(iconset_dir, filename)
        resized.save(out_path, "PNG")
        
    print(f"✓ Generated all {len(sizes)} iconset sizes")
    
    # Compile with iconutil
    icns_path = "Resources/AppIcon.icns"
    subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", icns_path], check=True)
    print(f"✓ Compiled {icns_path} successfully via iconutil")
    
    # Also copy to Sources/VinylDeskCore/Resources/AppIcon.icns
    os.makedirs("Sources/VinylDeskCore/Resources", exist_ok=True)
    subprocess.run(["cp", icns_path, "Sources/VinylDeskCore/Resources/AppIcon.icns"], check=True)
    print("✓ Copied AppIcon.icns to Sources/VinylDeskCore/Resources/AppIcon.icns")
    
    # Clean up iconset directory
    subprocess.run(["rm", "-rf", iconset_dir], check=True)
    print("✓ Cleaned up temporary AppIcon.iconset")

if __name__ == "__main__":
    generate_iconset()
