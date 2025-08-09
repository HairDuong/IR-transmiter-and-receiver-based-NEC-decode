module top_ir_tx (
    input clk,
    input rst,
    output tx_pin,
    input rx_pin
);

// --- UART RX
wire [7:0] o_rdat;
wire data_valid;

// --- UART TX
reg i_valid;
reg [7:0] i_data_in;
wire tx_done;

UART_RX uart_rx_inst (
    .clock(clk),
    .reset(rst),
    .rx(rx_pin),
    .o_rdat(o_rdat),
    .data_valid(data_valid)
);

UART_TX uart_tx_inst (
    .clk(clk),
    .rst(rst),
    .i_valid(i_valid),
    .i_data_in(i_data_in),
    .o_Tx_serial(tx_pin),
    .tx_done(tx_done)
);

// --- FSM truyền A1, F1, rồi data
reg [2:0] state, next_state;
localparam S_IDLE       = 3'd0;
localparam S_SEND_A1    = 3'd1;
localparam S_SEND_F1    = 3'd2;
localparam S_SEND_DATA  = 3'd3;
localparam S_WAIT       = 3'd4;
localparam S_SEND_U1    = 3'd5;
localparam S_SEND_U2    = 3'd6;

reg [7:0] data_buffer;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        state <= S_IDLE;
        i_valid <= 0;
        i_data_in <= 8'd0;
        data_buffer <= 8'd0;
    end else begin
        case (state)
            S_IDLE: begin
                i_valid <= 0;
                if (data_valid) begin
                    data_buffer <= o_rdat;
                    state <= S_SEND_A1;
                end
            end

            S_SEND_A1: begin
                i_data_in <= 8'hFA;
                i_valid <= 1;
                state <= S_WAIT;
					 next_state <= S_SEND_F1;
					 
            end

            S_SEND_F1: begin
                i_data_in <= 8'HF1;
                i_valid <= 1;
                state <= S_WAIT;
					 next_state<= S_SEND_U1;
            end
				
				S_SEND_U1: begin
							  i_data_in <= 8'h00;
							  i_valid <=1;
							  state<= S_WAIT;
							  next_state <= S_SEND_U2;
							  end
				S_SEND_U2:
							begin
							  i_data_in <= 8'h01;
							  i_valid <=1;
							  state<= S_WAIT;
							  next_state <= S_SEND_DATA;
							end

            S_SEND_DATA: begin
                i_data_in <= data_buffer;
                i_valid <= 1;
                state <= S_WAIT;
					 next_state <= S_IDLE;
            end

            S_WAIT: begin
                i_valid <= 0;  // Kéo valid chỉ 1 chu kỳ
                if (tx_done) begin
							state <= next_state;
                end
            end

            default: state <= S_IDLE;
        endcase
    end
end

endmodule
