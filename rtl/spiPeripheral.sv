`default_nettype none

module spiPeripheral
  #(parameter int DATA_W = 8)
  ( input  var logic              i_arst   // From local system domain.

  , input  var logic              i_sck    // Seial clock, from controller.
  , input  var logic              i_sdi    // Serial data in, from controller.

  , input  var logic [DATA_W-1:0] i_dataTx // Data word to transmit to controller.

  , output var logic              o_sdo    // Serial data out, to controller.

  , output var logic [DATA_W-1:0] o_dataRx // Data word received from controller,
                                           // to local system domain.
  );
  
  localparam int DSIZE = $clog2(DATA_W);

  // {{{ Count the number of bits transmitted.

  logic [DSIZE-1:0] counter_q;

  always_ff @(negedge i_sck, posedge i_arst)
    if (i_arst)
      counter_q <= '0;
    else
      counter_q <= counter_q+1'b1;

  // }}} Count the number of bits transmitted/received.

  // {{{ Shift-register to transmit and receive data.

  logic [DATA_W-1:0] shift_d, shift_q;

  // If reset or if a byte is transmitted, the shift reg should be loaded with
  // the new data to be transmitted. Otherwise, at every clk cycle data received
  // from the controller is stored and data sent to the controller is shifted out.
  always_ff @(posedge i_sck, posedge i_arst)
    if (i_arst)
      shift_q <= {i_dataTx[DATA_W-2:0], i_sdi};
    else
      shift_q <= shift_d;

  always_comb
    if (counter_q == 0)
      shift_d = {i_dataTx[DATA_W-2:0], i_sdi};
    else
      shift_d = {shift_q[6:0], i_sdi};

  // }}} Shift-register to transmit and receive data.

  logic sdo_q;

  // Store MSB. Aligned to the negedge so SDO is according to spec.
  always_ff @(negedge i_sck)
    sdo_q <= shift_q[7];
  
  // SDO is the MSB shifted out of the shift register.
  always_comb
    if (counter_q == 0)
      o_sdo = i_dataTx[7];
    else
      o_sdo = sdo_q;

endmodule

`resetall
