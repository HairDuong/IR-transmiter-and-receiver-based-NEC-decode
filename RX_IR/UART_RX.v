`define CNT       1249
`define CNT_HALF  624
`define IDLE      2'b00
`define START     2'b01
`define DATA      2'b10
`define STOP      2'b11

module UART_RX (
    input wire clock,
    input wire reset,
    input wire rx,
    output reg [7:0] o_rdat,
	 output reg data_valid
);

// baudrate 9600 counter
reg [13:0] counter;
reg syncff0, syncff1;
reg rx_;
reg [1:0] state, next;
reg [7:0] rdat;
reg [2:0] data_cnt;

wire counter_end, start, start_end, data_end, stop_end, get_dat;

assign get_dat      = (counter == `CNT_HALF); // giữa bit
assign counter_end  = (counter == `CNT);      // kết thúc 1 bit
assign start_end    = (state == `START) && counter_end;
assign data_end     = (state == `DATA)  && counter_end && (data_cnt == 3'd7);
assign stop_end     = (state == `STOP)  && counter_end;

// Đồng bộ tín hiệu rx
always @(posedge clock or negedge reset) begin
    if (!reset) begin
        syncff0 <= 1'b1;
        syncff1 <= 1'b1;
    end else begin
        syncff0 <= rx;
        syncff1 <= syncff0;
    end
end

// Phát hiện cạnh xuống cho start bit
always @(posedge clock or negedge reset) begin
    if (!reset) rx_ <= 1'b1;
    else        rx_ <= syncff1;
end

assign start = ~syncff1 & rx_;  // cạnh xuống (falling edge)

// State machine
always @(posedge clock or negedge reset) begin
    if (!reset) state <= `IDLE;
    else        state <= next;
end

always @(*) begin
    case (state)
        `IDLE:  next = start      ? `START : `IDLE;
        `START: next = start_end  ? `DATA  : `START;
        `DATA:  next = data_end   ? `STOP  : `DATA;
        `STOP:  next = stop_end   ? `IDLE  : `STOP;
        default:next = `IDLE;
    endcase
end

// Bộ đếm baudrate
always @(posedge clock or negedge reset) begin
    if (!reset)
        counter <= 0;
    else if (state != `IDLE) begin
        if (counter_end)
            counter <= 0;
        else
            counter <= counter + 1;
    end
end

// Đếm bit data
always @(posedge clock or negedge reset) begin
    if (!reset)
        data_cnt <= 0;
    else if ((state == `DATA) && counter_end)
        data_cnt <= data_cnt + 1;
end

// Ghi dữ liệu khi đến thời điểm lấy mẫu giữa bit
always @(posedge clock or negedge reset) begin
    if (!reset)
        rdat <= 8'b0;
    else if ((state == `DATA) && get_dat)
        rdat <= {syncff1, rdat[7:1]};  // shift từ LSB
end

// Gán dữ liệu ra LED sau khi kết thúc STOP
always @(posedge clock or negedge reset) begin
    if (!reset)
        o_rdat <= 8'b0;
    else if (stop_end)
        o_rdat <= rdat;
end


// chỉ gán dữ liệu khi stop_end

always @(posedge clock or negedge reset) begin
    if (!reset) begin
        data_valid <= 0;
    end else begin
        data_valid <= stop_end;
    end
end
endmodule