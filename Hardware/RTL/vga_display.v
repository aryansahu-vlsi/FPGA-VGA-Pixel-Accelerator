// ============================================================================
// TOP LEVEL: VGA IMAGE DISPLAY
// ============================================================================
module vga_image_display (
    input wire clk,           // 50 MHz input clock
    input wire rst,           // Active high reset
    input wire [1:0] mode,    // 2-bit filter mode selector
    
    // 12-bit VGA Output (4 bits per color)
    output reg [3:0] vga_r,
    output reg [3:0] vga_g,
    output reg [3:0] vga_b,
    output reg hsync,
    output reg vsync
);

    // --- 1. Clock Divider (100 MHz to 25 MHz for standard 640x480 @ 60Hz) ---
    reg [1:0] clk_div = 0;
    wire clk_25mhz = clk_div[1];
    
    always @(posedge clk) begin
        clk_div <= clk_div + 1;
    end

    // --- 2. VGA Synchronization Counters ---
    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;
    
    wire h_max = (h_count == 799); // 640 + 16 + 96 + 48 - 1
    wire v_max = (v_count == 524); // 480 + 10 + 2 + 33 - 1

    always @(posedge clk_25mhz or posedge rst) begin
        if (rst) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_max) begin
                h_count <= 0;
                v_count <= v_max ? 0 : v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    // Sync Pulse Generation
    wire hsync_raw = ~(h_count >= 656 && h_count < 752);
    wire vsync_raw = ~(v_count >= 490 && v_count < 492);
    wire video_on  = (h_count < 640 && v_count < 480);

    // --- 3. Image Positioning (128x160 Centered on 640x480) ---
    // X Offset: (640 - 128) / 2 = 256
    // Y Offset: (480 - 160) / 2 = 160
    wire in_image_region = (h_count >= 256 && h_count < 384) && 
                           (v_count >= 160 && v_count < 320);

    wire [7:0] x_img = h_count - 256;
    wire [7:0] y_img = v_count - 160;
    
    // Address = (y * 128) + x. Multiplying by 128 is identical to shifting left by 7.
    wire [14:0] rom_addr = {y_img[7:0], 7'd0} + x_img; 
    wire [11:0] rom_data;

    // --- 4. Image ROM Instantiation ---
    image_rom my_image (
        .clk(clk_25mhz), // Clock ROM at the pixel rate
        .addr(rom_addr),
        .data(rom_data)
    );

    // --- 5. Color Filtering ---
    wire [3:0] filt_r, filt_g, filt_b;
    
    filter_12bit rgb_filter (
        .clk(clk_25mhz),
        .mode(mode),
        .r_in(rom_data[11:8]),
        .g_in(rom_data[7:4]),
        .b_in(rom_data[3:0]),
        .r_out(filt_r),
        .g_out(filt_g),
        .b_out(filt_b)
    );

    // --- 6. Output Pipeline Alignment ---
    // The ROM and Filter take 2 clock cycles to process data. 
    // We must delay the sync and active signals by 2 cycles so colors align perfectly.
    reg [1:0] video_on_delay, image_region_delay;
    reg [1:0] hsync_delay, vsync_delay;

    always @(posedge clk_25mhz) begin
        video_on_delay     <= {video_on_delay[0], video_on};
        image_region_delay <= {image_region_delay[0], in_image_region};
        hsync_delay        <= {hsync_delay[0], hsync_raw};
        vsync_delay        <= {vsync_delay[0], vsync_raw};

        hsync <= hsync_delay[1];
        vsync <= vsync_delay[1];

        // Draw the filtered image inside the region, draw black elsewhere
        if (video_on_delay[1]) begin
            if (image_region_delay[1]) begin
                vga_r <= filt_r;
                vga_g <= filt_g;
                vga_b <= filt_b;
            end else begin
                vga_r <= 4'h0; vga_g <= 4'h0; vga_b <= 4'h0; // Black background
            end
        end else begin
            vga_r <= 4'h0; vga_g <= 4'h0; vga_b <= 4'h0; // Blanking interval
        end
    end

endmodule

// ============================================================================
// IMAGE ROM (BLOCK RAM - 128x160)
// ============================================================================
module image_rom (
    input wire clk,
    input wire [14:0] addr,
    output reg [11:0] data
);
    reg [11:0] memory_array [0:20479];
    initial begin
        $readmemh("image.mem", memory_array);
    end
    always @(posedge clk) begin
        data <= memory_array[addr];
    end
endmodule

// =========================================================================
// 12-BIT MULTI-MODE FILTER (Normal, Gray, Invert, Threshold)
// =========================================================================
module filter_12bit (
    input wire clk,
    input wire [1:0] mode,
    input wire [3:0] r_in,
    input wire [3:0] g_in,
    input wire [3:0] b_in,
    output reg [3:0] r_out,
    output reg [3:0] g_out,
    output reg [3:0] b_out
);
    wire [11:0] gray_calc = (r_in * 8'd77) + (g_in * 8'd150) + (b_in * 8'd29);
    wire [3:0] gray_val = gray_calc[11:8];

    always @(posedge clk) begin
        case (mode)
            2'b00: begin // Normal
                r_out <= r_in; g_out <= g_in; b_out <= b_in;
            end
            2'b01: begin // Grayscale
                r_out <= gray_val; g_out <= gray_val; b_out <= gray_val;
            end
            2'b10: begin // Invert
                r_out <= ~r_in; g_out <= ~g_in; b_out <= ~b_in;
            end
            2'b11: begin // Threshold
                if (gray_val > 4'd7) begin
                    r_out <= 4'hF; g_out <= 4'hF; b_out <= 4'hF;
                end else begin
                    r_out <= 4'h0; g_out <= 4'h0; b_out <= 4'h0;
                end
            end
        endcase
    end
endmodule