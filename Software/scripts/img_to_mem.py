from PIL import Image

# Load image
img = Image.open("image.png")

# Resize to 128x160 resolution for the FPGA
img = img.resize((128, 160))
img = img.convert("RGB")

width, height = img.size

with open("image.mem", "w") as f:
    for y in range(height):
        for x in range(width):
            r, g, b = img.getpixel((x, y))

            # Convert 8-bit → 4-bit
            r4 = r >> 4
            g4 = g >> 4
            b4 = b >> 4

            # 12-bit RGB (RRRRGGGGBBBB)
            pixel = (r4 << 8) | (g4 << 4) | b4

            f.write(f"{pixel:03X}\n")

print("128x160 MEM file generated successfully!")