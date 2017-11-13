`timescale 1ns / 1ps
/*****************************************************************************
 //
 // Description:   lpc_decode.v
 //
 //*****************************************************************************
   //
   // Copyright 2016 ADVANCED MICRO DEVICES, INC.  All Rights Reserved.
   //
   // AMD is granting you permission to use this software (the Materials)
   // pursuant to the terms and conditions of your Software License Agreement
   // with AMD.  This header does *NOT* give you permission to use the Materials
   // or any rights under AMD's intellectual property.  Your use of any portion
   // of these Materials shall constitute your acceptance of those terms and
   // conditions.  If you do not agree to the terms and conditions of the Software
   // License Agreement, please do not use any portion of these Materials.
   //
   // CONFIDENTIALITY:  The Materials and all other information, identified as
   // confidential and provided to you by AMD shall be kept confidential in
   // accordance with the terms and conditions of the Software License Agreement.
   //
   // LIMITATION OF LIABILITY: THE MATERIALS AND ANY OTHER RELATED INFORMATION
   // PROVIDED TO YOU BY AMD ARE PROVIDED "AS IS" WITHOUT ANY EXPRESS OR IMPLIED
   // WARRANTY OF ANY KIND, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
   // MERCHANTABILITY, NONINFRINGEMENT, TITLE, FITNESS FOR ANY PARTICULAR PURPOSE,
   // OR WARRANTIES ARISING FROM CONDUCT, COURSE OF DEALING, OR USAGE OF TRADE.
   // IN NO EVENT SHALL AMD OR ITS LICENSORS BE LIABLE FOR ANY DAMAGES WHATSOEVER
   // (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS, BUSINESS
   // INTERRUPTION, OR LOSS OF INFORMATION) ARISING OUT OF AMD'S NEGLIGENCE,
   // GROSS NEGLIGENCE, THE USE OF OR INABILITY TO USE THE MATERIALS OR ANY OTHER
   // RELATED INFORMATION PROVIDED TO YOU BY AMD, EVEN IF AMD HAS BEEN ADVISED OF
   // THE POSSIBILITY OF SUCH DAMAGES.  BECAUSE SOME JURISDICTIONS PROHIBIT THE
   // EXCLUSION OR LIMITATION OF LIABILITY FOR CONSEQUENTIAL OR INCIDENTAL DAMAGES,
   // THE ABOVE LIMITATION MAY NOT APPLY TO YOU.
   //
   // AMD does not assume any responsibility for any errors which may appear in
   // the Materials or any other related information provided to you by AMD, or
   // result from use of the Materials or any related information.
   //
   // You agree that you will not reverse engineer or decompile the Materials.
   //
   // NO SUPPORT OBLIGATION: AMD is not obligated to furnish, support, or make any
   // further information, software, technical information, know-how, or show-how
   // available to you.  Additionally, AMD retains the right to modify the
   // Materials at any time, without notice, and is not obligated to provide such
   // modified Materials to you.
   //
   // U.S. GOVERNMENT RESTRICTED RIGHTS: The Materials are provided with
   // "RESTRICTED RIGHTS." Use, duplication, or disclosure by the Government is
   // subject to the restrictions as set forth in FAR 52.227-14 and
   // DFAR252.227-7013, et seq., or its successor.  Use of the Materials by the
   // Government constitutes acknowledgement of AMD's proprietary rights in them.
   //
   // EXPORT ASSURANCE:  You agree and certify that neither the Materials, nor any
   // direct product thereof will be exported directly or indirectly, into any
   // country prohibited by the United States Export Administration Act and the
   // regulations thereunder, without the required authorization from the U.S.
   // government nor will be used for any purpose prohibited by the same.
   //*****************************************************************************/

module lpc_decode(
		  //lpc decode inputs
		  input 	    lclk,
		  input 	    lrst,
		  input 	    lframe,

		  //lpc decode outputs
		  output reg [31:0] port_reg,

		  //lpc decode inouts
		  inout [3:0] 	    lad
		  );


   //reg [31:0] port_reg;
   reg [2:0] 			    cmd_reg;
   reg 				    lad_oe_reg;
   reg [31:0] 			    address_reg;
   reg [4:0] 			    state_lpc;
   reg [3:0] 			    start_reg;
   reg [7:0] 			    lad_out_mux;
   reg [3:0] 			    lad_in;
   reg [3:0] 			    lad_out;

   wire 			    memr = 1'b0;
   wire 			    iow = ~cmd_reg[2] & ~cmd_reg[1] & cmd_reg[0];
   wire 			    lad_oe = lad_oe_reg & lframe;
   wire 			    iow_hit = (address_reg[31:20] == 12'h008);
   assign lad = lad_oe ? lad_out : 4'hz;
   wire 			    memr_hit = 1'b0;

   always @(lframe,lrst,lad)
     begin
	lad_in = lad;
     end

   parameter [4:0] idle = 5'h00;
   parameter [4:0] command = 5'h01;
   parameter [4:0] addr7 = 5'h02;
   parameter [4:0] addr6 = 5'h03;
   parameter [4:0] addr5 = 5'h04;
   parameter [4:0] addr4 = 5'h05;
   parameter [4:0] addr3 = 5'h06;
   parameter [4:0] addr2 = 5'h07;
   parameter [4:0] addr1 = 5'h08;
   parameter [4:0] addr0 = 5'h09;
   parameter [4:0] memr_pre_tar0 = 5'h0A;
   parameter [4:0] memr_sync0 = 5'h0B;
   parameter [4:0] memr_data0 = 5'h0C;
   parameter [4:0] memr_data1 = 5'h0D;
   parameter [4:0] iow_pre_tar0 = 5'h0E;
   parameter [4:0] iow_pre_tar1 = 5'h15;
   parameter [4:0] iow_sync0 = 5'h0F;
   parameter [4:0] iow_data0 = 5'h10;
   parameter [4:0] iow_data1 = 5'h11;
   parameter [4:0] post_tar0 = 5'h12;
   parameter [4:0] post_tar1 = 5'h13;
   parameter [4:0] abort = 5'h14;

   always @(posedge lclk or negedge lrst)
     begin
	if (~lrst)
	  begin
   	     state_lpc <=  idle;
	     address_reg <=  32'h00000000;
	     start_reg <=  4'h0;
	     cmd_reg <=  3'b000;
	     lad_out <=  4'h0;
	     lad_oe_reg <=  1'b0;
	     port_reg <=  32'h00000000;
   	  end
  	else
	  begin
	     case (state_lpc)
	       idle:
		 begin
		    lad_oe_reg <= 1'b0;

		    if (~lframe)
		      begin
		      	 start_reg <=  lad_in;
	   	      	 state_lpc <=  command;
		      end
		    else
		      begin
		   	 state_lpc <= idle;
		      end
	      	 end

	       command:
		 begin
	            if (~lframe)
		      begin
	   	      	 start_reg <=  lad_in;
		   	 state_lpc <=  command;
	      	      end
	            else if (start_reg == 4'b0000)
		      begin
	   	      	 cmd_reg <=  lad_in[3:1];
	      	    	 state_lpc <=  addr7;
		      end
		         else
			   begin
         	   	      state_lpc <=  idle;
          		   end
	      	 end

	       addr7:
		 begin
		    address_reg[31:28] <=  lad_in;
	   	    if (~lframe)
		      begin
	         	 state_lpc <=  abort;
	              end
		    else
		      begin
	      	    	 state_lpc <= addr6;
	      	      end
        	 end

	       addr6:
		 begin
      	  	    address_reg[27:24] <=  lad_in;
         	    if (~lframe)
		      begin
	          	 state_lpc <=  abort;
         	      end
          	    else
		      begin
            		 state_lpc <=  addr5;
 	              end
   	    	 end

	       addr5:
		 begin
      	  	    address_reg[23:20] <= lad_in;
	      	    if (~lframe)
		      begin
	          	 state_lpc <=  abort;
	              end
   	       	    else
		      begin
         	   	 state_lpc <= addr4;
	              end
   	     	 end

	       addr4:
		 begin
		    address_reg[19:16] <= lad_in;
	      	    if (~lframe)
		      begin
			 state_lpc <=  abort;
		      end
	            else if (iow)
		      begin
	   	       	 state_lpc <=  iow_data0;
	              end
   	       		 else
			   begin
	      	    	      state_lpc <=  addr3;
          		   end
        	 end

	       addr3:
		 begin
		    address_reg[15:12] <=  lad_in;
	      	    if (~lframe)
		      begin
			 state_lpc <= abort;
	              end
		    else
		      begin
	      	    	 state_lpc <= addr2;
	              end
      	  	 end

	       addr2:
		 begin
		    address_reg[11:8] <= lad_in;
		    if (~lframe)
		      begin
		         state_lpc <= abort;
  		      end
	  	    else
		      begin
		         state_lpc <= addr1;
		      end
  	      	 end

	       addr1:
		 begin
		    address_reg[7:4] <= lad_in;
		    if (~lframe)
		      begin
		         state_lpc <= abort;
	  	      end
	  	    else
		      begin
		         state_lpc <= addr0;
		      end
  	      	 end

	       addr0:
		 begin
		    address_reg[3:0] <=  lad_in;
		    if (~lframe)
		      begin
  		         state_lpc <= abort;
	  	      end
	            else if (memr)
		      begin
		         state_lpc <= memr_pre_tar0;
	  	      end
	          	 else
			   begin
		              state_lpc <= idle;
		           end
  	      	 end

	       memr_pre_tar0:
		 begin
	  	    if (~lframe)
		      begin
		         state_lpc <= abort;
  		      end
 	            else if (memr_hit)
		      begin
  		         state_lpc <= memr_sync0;
   	       	      end
      	    		 else
			   begin
	       		      state_lpc <= idle;
		           end
		 end

	       memr_sync0:
		 begin
      	    	    lad_oe_reg <= 1'b1;
         	    lad_out <= 4'h0;
          	    if (~lframe)
		      begin
		         state_lpc <=  abort;
  		      end
  		    else
		      begin
   	         	 state_lpc <=  memr_data0;
      	    	      end
      	  	 end

	       memr_data0:
		 begin
  		    lad_out <= lad_out_mux[3:0];

		    if (~lframe)
		      begin
		         state_lpc <= abort;
   	       	      end
      	    	    else
		      begin
	            	 state_lpc <=  memr_data1;
   	       	      end
      	  	 end

 	       memr_data1:
		 begin
	            lad_out <= lad_out_mux[7:4];

  		    if (~lframe)
		      begin
	   	       	 state_lpc <= abort;
      	    	      end
         	    else
		      begin
         	   	 state_lpc <=  post_tar0;
          	      end
        	 end

	       iow_data0:
		 begin
	   	    if (~lframe)
		      begin
	         	 state_lpc <= abort;
 	              end
   	       	    else if (address_reg[31:20] == 12'h008)
		      begin
	      	    	 case (address_reg[19:16])
	              	   4'h0: port_reg[3:0] <= lad_in;
   	       	    	   4'h1: port_reg[11:8] <= lad_in;
      	      	  	   4'h2: port_reg[19:16] <= lad_in;
         	     	   4'h3: port_reg[27:24] <= lad_in;
   	         	 endcase
	            	 state_lpc <= iow_data1;
    	      	      end
 	         	 else
			   begin
		              state_lpc <= idle;
		           end
		 end

	       iow_data1:
		 begin
		    if (~lframe)
		      begin
		         state_lpc <=  abort;
  		      end
	            else
		      begin
	      	    	 case (address_reg[19:16])
      	      	  	   4'h0: port_reg[7:4]   <= lad_in;
           		   4'h1: port_reg[15:12] <= lad_in;
            		   4'h2: port_reg[23:20] <= lad_in;
			   4'h3: port_reg[31:28] <= lad_in;
	 	         endcase
 		         state_lpc <= iow_pre_tar0;
      	    	      end
	     	 end

	       iow_pre_tar0:
		 begin
      	   	    if (~lframe)
		      begin
		         state_lpc <= abort;
      	    	      end
	            else
		      begin
      	      		 state_lpc <= iow_pre_tar1;
      	    	      end
      	  	 end

	       iow_pre_tar1:
		 begin
      	   	    if (~lframe)
		      begin
		         state_lpc <= abort;
      	    	      end
	            else
		      begin
      	      		 state_lpc <= iow_sync0;
      	    	      end
      	  	 end

	       iow_sync0:
		 begin
	  	    lad_oe_reg <=  1'b1;
 	            lad_out <= 4'h0;
	            if (~lframe)
		      begin
		         state_lpc <=  abort;
	              end
	  	    else
		      begin
          		 state_lpc <=  post_tar0;
     		      end
        	 end

	       post_tar0:
		 begin
       	   	    lad_out <=  4'hF;
       	   	    if (~lframe)
		      begin
	   	      	 state_lpc <=  abort;
      	    	      end
      	    	    else
		      begin
      	      		 state_lpc <=  post_tar1;
    	      	      end
    	    	 end

	       post_tar1:
		 begin
    		    lad_oe_reg <=  1'b0;
   	       	    if (~lframe)
		      begin
	   	    	 state_lpc <= abort;
          	      end
		    else
		      begin
 	   	         state_lpc <=  idle;
   	       	      end
        	 end

	       abort:
		 begin
		    lad_oe_reg <=  1'b0;
      	    	    if (~lframe)
		      begin
			 state_lpc <=  abort;
          	      end
          	    else
		      begin
		         state_lpc <=  idle;
         	      end
      	  	 end

	       default:
	         state_lpc <=  idle;
	     endcase
	  end
     end
endmodule
