`define CNT 1249  // Sửa lại cho đúng 100MHz/9600
module UART_TX(
    input clk,
    input rst,
    input i_valid,
    input [7:0] i_data_in,
    output reg o_Tx_serial, 
    output reg tx_done
);

localparam IDLE = 2'b00;
localparam START = 2'b01;
localparam DATA = 2'b10;
localparam STOP = 2'b11;

reg [1:0] state, next_state;
reg [15:0] counter;  // Mở rộng cho CNT lớn
reg [7:0] r_data_in;
reg [2:0] index;
wire cnt_end;

assign cnt_end = (counter == `CNT);
// Bộ đếm baudrate
always @(posedge clk or negedge rst) begin
    if (!rst)
        counter <= 0;
    else if (state != IDLE) begin
        if (cnt_end)
            counter <= 0;
        else
            counter <= counter + 1;
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
       
        state <= IDLE;
        o_Tx_serial <= 1'b1;
        index <= 0;
        tx_done <= 0;
        r_data_in <= 0;
    end
    else begin
        
        
        case(state)
            IDLE: begin
                o_Tx_serial <= 1'b1;
                tx_done <= 0;
                if (i_valid) begin
                    r_data_in <= i_data_in;
                    state <= START;
                end
            end
            
            START: begin
                o_Tx_serial <= 1'b0;
                if (cnt_end) state <= DATA;
            end
            
            DATA: begin
                o_Tx_serial <= r_data_in[index];
                if (cnt_end) begin
                    index <= (index < 7) ? index + 1 : 0;
                    state <= (index == 7) ? STOP : DATA;
                end
            end
            
            STOP: begin
                o_Tx_serial <= 1'b1;
                if (cnt_end) begin
                    tx_done <= 1;
                    state <= IDLE;
                end
            end
        endcase
    end
end
endmodule