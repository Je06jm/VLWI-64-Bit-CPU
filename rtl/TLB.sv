module TLB #(
    parameter ENTRIES=8
)(
    input wire i_clk, i_rst,
    input wire i_enabled,
    
    input wire[31:0] i_page_table_base,

    input wire i_is_user,
    input wire[31:0] i_address,
    input wire i_cpu_mem_read, i_cpu_mem_write,
    output reg o_cpu_mem_valid,
    inout wire[31:0] io_cpu_mem_data,

    output reg o_error_not_present,
    output reg o_error_not_user,
    
    output reg[47:0] o_mem_address,
    output reg o_device_space,
    output reg o_mem_read, o_mem_write,
    input wire i_mem_valid,
    inout[31:0] io_mem_data
);
    localparam PAGE_SIZE = 4 * 1024 * 1024;
    localparam TAG_BITS = 32 - $clog2(PAGE_SIZE);
    localparam ETAG_BITS = 48 - $clog2(PAGE_SIZE);

    wire[31:0] i_cpu_mem_data = i_cpu_mem_write ? io_cpu_mem_data : 32'bz;
    reg[31:0] o_cpu_mem_data;
    assign io_cpu_mem_data = i_cpu_mem_read ? o_cpu_mem_data : 'bz;

    wire[31:0] i_mem_data = o_mem_read ? io_mem_data : 'bz;
    reg[31:0] o_mem_data;
    assign io_mem_data = o_mem_write ? o_mem_data : 'bz;

    reg[TAG_BITS-1:0] tags[ENTRIES-1:0];
    reg[ETAG_BITS-1:0] new_tags[ENTRIES-1:0];
    reg[ENTRIES-1:0] valid;
    reg[ENTRIES-1:0] users;
    reg[ENTRIES-1:0] devices;
    reg[$clog2(ENTRIES)-1:0] round_robin;

    reg found;

    wire[TAG_BITS-1:0] address_tag = i_address[31:(32-TAG_BITS)];
    wire[$clog2(PAGE_SIZE)-1:0] address_index = i_address[$clog2(PAGE_SIZE)-1:0];

    integer i;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_error_not_present = 0;
            o_error_not_user = 0;
            o_device_space = 0;
            o_mem_read = 0;
            o_mem_write = 0;
            o_cpu_mem_valid = 0;

            round_robin = 0;

            o_cpu_mem_data = 0;
            o_mem_data = 0;
            found = 0;

            for (i = 0; i < ENTRIES; i = i + 1) begin
                tags[i] = 0;
                new_tags[i] = 0;
                valid[i] = 0;
                users[i] = 0;
                devices[i] = 0;
            end
        end else if (i_enabled) begin
            o_error_not_present <= 0;
            o_error_not_user = 0;
            if (i_cpu_mem_read | i_cpu_mem_write) begin
                found = 0;
                for (i = 0; i < ENTRIES; i = i + 1) begin
                    if ((tags[i] == address_tag) && valid[i]) begin
                        if (~users[i] && i_is_user) begin
                            o_error_not_user = 1;
                        end else begin
                            o_mem_address = {new_tags[i], address_index};
                            o_mem_read = i_cpu_mem_read;
                            o_mem_write = i_cpu_mem_write;
                            o_mem_data = i_cpu_mem_data;
                            o_cpu_mem_data = i_mem_data;
                            o_cpu_mem_valid = i_mem_valid;
                            o_device_space = devices[i];
                            found = 1;
                        end
                    end
                end

                if (~found) begin
                    if (i_mem_valid) begin
                        o_mem_read <= 0;
                        if (i_mem_data[0]) begin
                            o_error_not_present = 1;
                        end else begin
                            tags[round_robin] = address_tag;
                            new_tags[round_robin] = i_mem_data[31:(32-TAG_BITS)];
                            valid[round_robin] = 1;
                            users[round_robin] = i_mem_data[2];
                            devices[round_robin] = i_mem_data[1];
                            round_robin = round_robin + 1;
                        end
                    end else begin
                        o_mem_address = i_page_table_base + {address_tag, {TAG_BITS{1'b0}}};
                        o_mem_read = 1;
                    end
                end
            end
        end else begin
            o_mem_address = {16'b0, i_address};
            o_mem_read = i_cpu_mem_read;
            o_mem_write = i_cpu_mem_write;
            o_mem_data = i_cpu_mem_data;
            o_cpu_mem_data = i_mem_data;
            o_cpu_mem_valid = i_mem_valid;
            o_device_space = 0;
        end
    end

endmodule