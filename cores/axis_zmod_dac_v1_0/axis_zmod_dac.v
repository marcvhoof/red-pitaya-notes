
`timescale 1 ns / 1 ps

module axis_zmod_dac #
(
  parameter integer DAC_DATA_WIDTH = 14,
  parameter integer AXIS_TDATA_WIDTH = 32
)
(
  // System signals
  input  wire                        aclk,
  input  wire                        locked,

  // DAC signals
  output wire                        dac_clk,
  output wire [DAC_DATA_WIDTH-1:0]   dac_data,

  // Slave side
  output wire                        s_axis_tready,
  input  wire [AXIS_TDATA_WIDTH-1:0] s_axis_tdata,
  input  wire                        s_axis_tvalid
);

  reg [DAC_DATA_WIDTH-1:0] int_data_a_reg;
  reg [DAC_DATA_WIDTH-1:0] int_data_b_reg;

  wire [DAC_DATA_WIDTH-1:0] int_data_a_wire;
  wire [DAC_DATA_WIDTH-1:0] int_data_b_wire;

  assign int_data_a_wire = s_axis_tdata[DAC_DATA_WIDTH-1:0];
  assign int_data_b_wire = s_axis_tdata[AXIS_TDATA_WIDTH/2+DAC_DATA_WIDTH-1:AXIS_TDATA_WIDTH/2];

  genvar j;

  always @(posedge aclk)
  begin
    if(~locked | ~s_axis_tvalid)
    begin
      int_data_a_reg <= {(DAC_DATA_WIDTH){1'b0}};
      int_data_b_reg <= {(DAC_DATA_WIDTH){1'b0}};
    end
    else
    begin
      int_data_a_reg <= int_data_a_wire;
      int_data_b_reg <= int_data_b_wire;
    end
  end

  ODDR #(
    .DDR_CLK_EDGE("SAME_EDGE"),
    .INIT(1'b0),
    .SRTYPE ("ASYNC" )
  ) ODDR_clk (
    .Q(dac_clk),
    .D1(1'b1),
    .D2(1'b0),
    .C(aclk),
    .CE(1'b1),
    .R(1'b0),
    .S(1'b0)
  );

  generate
    for(j = 0; j < DAC_DATA_WIDTH; j = j + 1)
    begin : DAC_DATA
      ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),
        .INIT(1'b0),
        .SRTYPE ("ASYNC" )
      ) ODDR_inst (
        .Q(dac_data[j]),
        .D1(int_data_a_reg[j]),
        .D2(int_data_b_reg[j]),
        .C(aclk),
        .CE(1'b1),
        .R(1'b0),
        .S(1'b0)
      );
    end
  endgenerate

  assign s_axis_tready = 1'b1;

endmodule
