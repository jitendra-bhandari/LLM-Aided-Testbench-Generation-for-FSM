module calc (
                  input [7:0]  inpA ,
                  input [7:0]  inpB ,
                  input [01:0] inpOpType ,
                  output[15:0] outC  ,

                  input        iValid ,
                  output       iStall ,

                  input        oStall ,
                  output       oValid ,

                  input        clk ,
                  input        rstn 
                  ) ;
//----------------------------------------------------------------------

   parameter   ST_IDL   = 1'b0 ;
   parameter   ST_STALL = 1'b1 ;
  
   reg         inp_dstall_r, oup_dval_r, lat_inp_r ;
   reg         inp_dstall_s, oup_dval_s, lat_inp_s ;

   reg         st_cur, st_nxt ;


   reg  [31:0] store_a, store_b, oup_s ;
   reg  [01:0] store_ctrl ;
   

//----------------------------------------------------------------------
//FSM
//----------------------------------------------------------------------
always @* begin
  inp_dstall_s = 1'b0 ;
  oup_dval_s   = 1'b0 ;
  lat_inp_s    = 1'b0 ;
  st_nxt       = st_cur ;
  case(st_cur) 
    ST_IDL : begin
       if(iValid) begin
         oup_dval_s = 1'b1 ;
         lat_inp_s    = 1'b1 ;
         if(oStall) begin
           inp_dstall_s = 1'b1 ;
           st_nxt       = ST_STALL ;
         end
       end
     end
    ST_STALL : begin
         inp_dstall_s = 1'b1 ;
         if(oStall) begin
           oup_dval_s = 1'b1 ;
         end
         else begin
           st_nxt       = ST_IDL ;
           oup_dval_s   = 1'b0 ;
         end
     end
  endcase
end
//----------------------------------------------------------------------
always @(posedge clk or negedge rstn) begin
  if(!rstn) begin
    lat_inp_r    <= 1'b0 ;
    inp_dstall_r <= 1'b0 ;
    st_cur       <= ST_IDL ;
    oup_dval_r   <= 1'b0 ;
  end
  else begin
    inp_dstall_r <= inp_dstall_s ;
    lat_inp_r    <= lat_inp_s ;
    st_cur       <= st_nxt ;
    oup_dval_r   <= oup_dval_s ;
  end
end
//----------------------------------------------------------------------
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
    end
    else begin
    end
end
always @(posedge clk) begin
  if(lat_inp_s) begin
    store_a    <= inpA ;
    store_b    <= inpB ;
    store_ctrl <= inpOpType ;
  end
end
//----------------------------------------------------------------------
always @* begin
  if(store_ctrl == 2'b00) oup_s = store_a + store_b ;
  else if(store_ctrl == 2'b01) oup_s = store_a - store_b ;
  else if(store_ctrl == 2'b10) oup_s = store_a * store_b ;
  else if(store_b == 0) oup_s = 0 ;
  else oup_s = store_a / store_b ;
end
//----------------------------------------------------------------------
assign iStall   = inp_dstall_r ;
assign oValid   = oup_dval_r ;
assign outC     = oup_s ;
//----------------------------------------------------------------------

endmodule 
