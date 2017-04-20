/*
 * Copyright (c) 2017 AMD Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and/or associated documentation files (the
 * "Materials"), to deal in the Materials without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Materials, and to
 * permit persons to whom the Materials are furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Materials.
 *
 * THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * MATERIALS OR THE USE OR OTHER DEALINGS IN THE MATERIALS.
 */


#define _FLOAT					float
#define _FLOAT2					float2
#define _FLOAT4					float4
#define _FLOAT8					float8

#ifndef FLT_MAX
#define FLT_MAX         3.402823466e+38F        /* max value */
#endif

#define UNUSED __attribute__((__unused__))

#define DBG_OUT_OF_RNGE 0

#define MLO_N_OUT_HORIZ_READS ((MLO_OUT_WIDTH + MLO_IN_TILE0 - 1) / MLO_IN_TILE0)
#define MLO_N_SPANS_PER_SCAN (MLO_N_OUT_HORIZ_READS)
#define MLO_N_OUT_HORIZ_PIX_READS (MLO_N_OUT_HORIZ_READS * MLO_IN_TILE0)
#define MLO_OUT_N_PIXS_OFF (MLO_OUT_WIDTH - ((MLO_OUT_WIDTH / MLO_IN_TILE0)*MLO_IN_TILE0))
#define MLO_N_OUT_VERTICAL_READS (MLO_FILTER_SIZE1)
// won't run non-border blocks if  MLO_IN_N_VERT_LOOPS < 2
#if MLO_FILTER_PAD1 > 0 

#if  MLO_IN_N_VERT_LOOPS >= 2
#define MLO_N_GENERIC_LOOPS ((int)(MLO_IN_N_VERT_LOOPS - 2))
#define MLO_IN_VERT_READS (MLO_IN_EXTENT1 + MLO_FILTER_PAD1)
#else
#define MLO_N_GENERIC_LOOPS 0
#define MLO_IN_VERT_READS MLO_IN_EXTENT1
#endif

#else
#define MLO_N_GENERIC_LOOPS (MLO_IN_N_VERT_LOOPS)
#define MLO_IN_VERT_READS MLO_IN_EXTENT1
#endif



// there is an assumption that the scanline fits into LDS
#define MLO_N_IN_HORIZ_PIX_READS (MLO_IN_WIDTH) 
#define MLO_N_IN_HORIZ_READS ((MLO_N_IN_HORIZ_PIX_READS + MLO_READ_UNIT - 1) / MLO_READ_UNIT)
#define MLO_IN_N_PIXS_OFF  (MLO_N_IN_HORIZ_PIX_READS - (MLO_N_IN_HORIZ_PIX_READS/MLO_READ_UNIT)*MLO_READ_UNIT)
#define MLO_IN_LCL_WIDTH (MLO_N_IN_HORIZ_READS * MLO_READ_UNIT + 2* MLO_FILTER_PAD0)
#define MLO_IN_LCL_HEIGHT MLO_IN_VERT_READS
#define MLO_IN_LCL_SZ (MLO_IN_LCL_WIDTH * MLO_IN_LCL_HEIGHT)
#define MLO_TOTAL_IN_LCL_SZ (MLO_N_LCL_BATCHS*MLO_N_LCL_IN_MAPS*MLO_IN_LCL_SZ)

#define MLO_WEI_LCL_SZ (MLO_GRP_SZ * MLO_FILTER_SIZE0)
#if MLO_TOTAL_IN_LCL_SZ > MLO_WEI_LCL_SZ
#define MLO_LCL_SZ (MLO_TOTAL_IN_LCL_SZ)
#else
#define MLO_LCL_SZ (MLO_WEI_LCL_SZ)
#endif


__attribute__((always_inline))
int iDiv(int v, int d)
{
	int r = (int)((float)v / d + 0.00001f);
	return(r);
}

__attribute__((always_inline))
int iMod(int v, int u, int d)
{
	int r = v - mul24((int)u, (int)d);
	return(r);
}

__attribute__((always_inline))
void ReduceKernel(__local _FLOAT * lcl_blob, __private _FLOAT *weights_accum, int lcl_id, int scan_lcl, int sum_stride, int unit_len, UNUSED bool debug)
{
// read first half
	if (scan_lcl < (sum_stride >> 1))
	{
		for (int i = 0; i < unit_len; ++i)
		{
			weights_accum[i] = lcl_blob[(lcl_id + scan_lcl) * unit_len + i];

		}

	}
// add second half
// appload accumulated value so far
	for (int j = (sum_stride >> 1); j > 0; j >>= 1)
	{
		barrier(CLK_LOCAL_MEM_FENCE);
		if (scan_lcl < j)
		{
			for (int i = 0; i < unit_len; ++i)
			{
				weights_accum[i] += lcl_blob[(lcl_id + j) * unit_len + i];

				lcl_blob[lcl_id * unit_len + i] = weights_accum[i];
			}

		}
	}
}


/*
	group cooperative read
	read by MLO_READ_UNIT
	handle out of range both horizontally and vertically (by fixed number of veryical reads)

	no guard against number of inputs
*/
__attribute__((always_inline))
void readInput(int lcl_id, int gbl_in_scan_off, int n_v_reads, const __global _FLOAT * __restrict bot, __local _FLOAT * __restrict lcl_bot)
{
	for (int p4 = lcl_id; p4 < MLO_N_LCL_IN_MAPS * MLO_N_IN_HORIZ_READS * n_v_reads;
		p4 += MLO_GRP_SZ)
	{
		__private _FLOAT in_rd_data[MLO_READ_UNIT];
// TODO : more than 1 input
		int c = 0;
		int t_p4 = p4;
#if MLO_N_LCL_IN_MAPS > 1
		c = iDiv(p4, (MLO_N_IN_HORIZ_READS * n_v_reads));
		t_p4 = iMod(p4, c, (MLO_N_IN_HORIZ_READS * n_v_reads));
#endif

		int c_scan = iDiv(t_p4, (MLO_N_IN_HORIZ_READS));

		int c_pix4 = iMod(t_p4, c_scan, (MLO_N_IN_HORIZ_READS));

//		if (c < MLO_N_INPUTS)

		{
			int bot_off = gbl_in_scan_off + c*MLO_IN_CHANNEL_STRIDE + c_scan* MLO_IN_STRIDE + c_pix4*MLO_READ_UNIT;
#if MLO_IN_N_PIXS_OFF > 0

			if (c_pix4 == MLO_N_IN_HORIZ_READS - 1)
			{
				for (int i = 0; i < MLO_IN_N_PIXS_OFF; ++i)
				{

					in_rd_data[i] = bot[bot_off + i];
#if DBG_OUT_OF_RNGE
					if (bot_off + i >= MLO_IN_BATCH_STRIDE * MLO_BATCH_SZ)
					{
						printf("k:err:in-of-range\n");
					}
#endif
				}

				for (int i = MLO_IN_N_PIXS_OFF; i < MLO_READ_UNIT; ++i)
				{
					in_rd_data[i] = 0;
				}

			}
			else
#endif
			{
				
				for (int i = 0; i < MLO_READ_UNIT; ++i)
				{
					in_rd_data[i] = bot[bot_off + i];
#if DBG_OUT_OF_RNGE
					if (bot_off + i >= MLO_IN_BATCH_STRIDE * MLO_BATCH_SZ)
					{
						printf("k:err:in-of-range\n");
					}
#endif
				}
			}

// MLO_N_LCL_IN_MAPS inputs
			for (int i = 0; i < MLO_READ_UNIT; ++i)
			{
				int lcl_in_off = c*MLO_IN_LCL_SZ + c_scan* MLO_IN_LCL_WIDTH + MLO_FILTER_PAD0 + c_pix4*MLO_READ_UNIT + i;
				lcl_bot[lcl_in_off] = in_rd_data[i];
			}
		}

	} // for (int p4 = lcl_id; p4 < MLO_N_LCL_IN_MAPS * MLO_N_IN_HORIZ_READS * MLO_IN_VERT_READS;

	barrier(CLK_LOCAL_MEM_FENCE);


}


/*
	core processing loop
	bot - input, from local (1 span)
	top - output diff, from global (array of spans, filters vertical size)

	loop over filter vertical size

*/
__attribute__((always_inline))
void Processing(UNUSED int sc, int sc_lcl_off, int top_lim, int bot_lim, __private _FLOAT * __restrict pvt_accum, __local _FLOAT * __restrict lcl_bot, __private _FLOAT * __restrict top_dat)
{
	for (int l = top_lim; l >= bot_lim; --l)
	{
		for (int m = 0; m < MLO_IN_TILE0; ++m)
		{
			for (int n = 0; n < MLO_FILTER_SIZE0; ++n)
			{
				for(int c = 0; c < MLO_N_LCL_IN_MAPS; ++c)
				{
					int bot_off = sc_lcl_off + c*MLO_IN_LCL_SZ + n + m;
					_FLOAT bot_val = lcl_bot[bot_off];
					for(int k = 0; k < MLO_N_LCL_OUT_MAPS; ++k)
					{
						int pvt_top_off = k*MLO_IN_TILE0 * MLO_FILTER_SIZE1 + (top_lim - l) * MLO_IN_TILE0 + m;
						int pvt_accum_off = (k*MLO_N_LCL_IN_MAPS + c) *MLO_FILTER_SIZE1*MLO_FILTER_SIZE0 + l*MLO_FILTER_SIZE0 + n;

						_FLOAT top_val = top_dat[pvt_top_off];

						pvt_accum[pvt_accum_off]
						// each wk-it process an input
							+= bot_val*top_val;
#if 0
						if (/*bot_val * top_val != 0 && */l == 0 && n == 1 && get_local_id(0) == 0 && get_local_id(1) == 0 && get_local_id(2) == 0 && k == 0)
						{
							printf("K: %d %d %d %f %f %f %f\n",
								sc,
								bot_off,
								pvt_top_off,
								pvt_accum[pvt_accum_off],
								bot_val * top_val,
								bot_val,
								top_val
							);
						}
#endif

					}
				}
			}

		}

	}

}

__attribute__((always_inline))
void moveOutputUp(__private _FLOAT * __restrict top_dat)
{
	// move up output to reduce overfetch
	for (int k = 0; k < MLO_N_LCL_OUT_MAPS; ++k)
	{
		for (int j = 0; j < MLO_FILTER_SIZE1 - 1; ++j)
		{
			for (int i = 0; i < MLO_IN_TILE0; ++i)
			{
				int pvt_off_n = k*MLO_IN_TILE0 * MLO_FILTER_SIZE1 + j *MLO_IN_TILE0 + i;
				int pvt_off_o = k*MLO_IN_TILE0 * MLO_FILTER_SIZE1 + (j + 1) *MLO_IN_TILE0 + i;
				top_dat[pvt_off_n] = top_dat[pvt_off_o];
			}
		}
	}
}

__attribute__((always_inline))

__attribute__((always_inline))
void spanReadingOutput(int spn, int k, int j, int top_df_off, _FLOAT mask,
	__private _FLOAT * __restrict top_dat, const __global _FLOAT * __restrict top_df)
{
	int pvt_off = k*MLO_IN_TILE0 * MLO_FILTER_SIZE1 + j *MLO_IN_TILE0;
#if MLO_OUT_N_PIXS_OFF > 0
	if (spn == MLO_N_SPANS_PER_SCAN - 1)
	{
		int i = 0;
		for (; i < MLO_OUT_N_PIXS_OFF; ++i)
		{
			top_dat[pvt_off + i] = top_df[top_df_off + i] * mask;

#if DBG_OUT_OF_RNGE
			if (top_df_off + i >= MLO_OUT_BATCH_STRIDE * MLO_BATCH_SZ)
			{
				printf("k:err:out-of-range\n");
			}
#endif
		}
		for (; i < MLO_IN_TILE0; ++i)
		{
			top_dat[pvt_off + i] = 0;
		}
	}
	else
#else 
	(void)spn;
#endif
	{
		for (int i = 0; i < MLO_IN_TILE0; ++i)
		{
			top_dat[pvt_off + i] = top_df[top_df_off + i] * mask;
#if DBG_OUT_OF_RNGE
			if (top_df_off + i >= MLO_OUT_BATCH_STRIDE * MLO_BATCH_SZ)
			{
				printf("k:err:out-of-range\n");
			}
#endif
			
		}
	}
}




/*********************************************************************************************************
// wrw algorithm for large filters
// idea:
// split output scan-line on number of spans by the  MLO_IN_TILE0 (2 for example)
// 1 scan-line has ((MLO_OUT_WIDTH + MLO_IN_TILE0 - 1/MLO_IN_TILE0) spans
// group will process MLO_GRP_SZ/((MLO_OUT_WIDTH + MLO_IN_TILE0 - 1/MLO_IN_TILE0) output maps

// alg
// load a block of input map (or full map) into LDS
// loop
// read MLO_FILTER_SIZE1 number of spans from output map into VGPRs (for example 5 *2 = 10)
// read 1 input line for  maps into LDS
// accumulate

// accumulate all spans at the end
// start new loop for the next batch (if defined)
// write out 

// kerenl handles 5x5, 3x3 with padding
// small images in 1 short- MLO_N_GENERIC_LOOPS == 0
// big images  in 2 blocks - MLO_IN_N_VERT_LOOPS == 2 or multiple blocks - MLO_IN_N_VERT_LOOPS > 2
// there are prolog and apilog that deal with top/bottom padding.
// left/right padding handles as a LDS border pixels zeroed at the beginning.

**********************************************************************************************************/

__attribute__((reqd_work_group_size(MLO_GRP_SZ0, MLO_GRP_SZ1, MLO_GRP_SZ2)))
__kernel void MIOpenCvBwdWrW(
	const __global _FLOAT * __restrict top_df,
	const __global _FLOAT * __restrict bot,
	__global _FLOAT * __restrict weights_df,
#if MLO_CONV_BIAS
	__global _FLOAT * __restrict bias_df,
#endif
	UNUSED _FLOAT padding_val
)
{


	// input/output tiles + reduce buffer

	__local _FLOAT lcl[(MLO_LCL_SZ) + 1];
	__local _FLOAT * lcl_bot = lcl;

	int lcl_id = get_local_id(0);

	int c_idx_base = get_group_id(0); // input map index base

	int o_idx_base = get_group_id(1);// output map index base

	int ib_base = get_group_id(2);

	int ib = ib_base*(MLO_N_BATCH_LOOPS*MLO_N_LCL_BATCHS);

	int c_idx = c_idx_base * MLO_N_LCL_IN_MAPS; // input map index

	int o_idx = o_idx_base * (MLO_N_LCL_OUT_MAPS * MLO_OUT_STACKS); // output map index

	int gbl_in_off = c_idx * MLO_IN_CHANNEL_STRIDE + ib * MLO_IN_BATCH_STRIDE;
	int gbl_out_off = o_idx * MLO_OUT_CHANNEL_STRIDE + ib * MLO_OUT_BATCH_STRIDE;
	// 1 span per wk_item, total scanline with MLO_N_SPANS_PER_SCAN spans 
	// TODO: more than 1 input
	int o = iDiv(lcl_id, MLO_N_SPANS_PER_SCAN);
	//	bool scan_lead = (o*MLO_N_SPANS_PER_SCAN == lcl_id);
	int spn = iMod(lcl_id, o, MLO_N_SPANS_PER_SCAN);


	int lcl_bot_off = spn * MLO_IN_TILE0;
	int out_wk_item_off = o * MLO_OUT_CHANNEL_STRIDE + lcl_bot_off;
	gbl_out_off += out_wk_item_off;
// no output out of range
	gbl_out_off = (o_idx + o < MLO_N_OUTPUTS && o < MLO_OUT_STACKS) ? gbl_out_off : 0;

#define MLO_TOP_DAT_SZ (MLO_N_LCL_OUT_MAPS * MLO_IN_TILE0 * MLO_FILTER_SIZE1)

	__private _FLOAT top_dat[MLO_TOP_DAT_SZ];

	for (int i = 0; i < MLO_TOP_DAT_SZ; ++i)
	{
		top_dat[i] = 0;
	}

#define MLO_ACCUM_SZ (MLO_N_LCL_OUT_MAPS * MLO_N_LCL_IN_MAPS * MLO_FILTER_SIZE1*MLO_FILTER_SIZE0)

	__private _FLOAT pvt_accum[MLO_ACCUM_SZ];

	for (int i = 0; i < MLO_ACCUM_SZ; ++i)
	{
		pvt_accum[i] = 0;
	}


	// zero out LDS
	for (int i = lcl_id; i < (MLO_LCL_SZ); i += MLO_GRP_SZ)
	{
		lcl[i] = 0;
	}



	// over all batches
	for (int b = 0;
		b < MLO_N_BATCH_LOOPS;
		++b,
		gbl_in_off += MLO_N_LCL_BATCHS*MLO_IN_BATCH_STRIDE,
		gbl_out_off += MLO_N_LCL_BATCHS*MLO_OUT_BATCH_STRIDE
		)
	{
		barrier(CLK_LOCAL_MEM_FENCE);
		// top border input block
		int gbl_in_scan_off = gbl_in_off;
		int gbl_out_scan_off = gbl_out_off;


		// read input map
		readInput(lcl_id, gbl_in_scan_off, MLO_IN_VERT_READS, bot, lcl_bot);
		// move input pointer
		gbl_in_scan_off += MLO_IN_STRIDE * MLO_IN_EXTENT1;

		for (int i = 0; i < MLO_TOP_DAT_SZ; ++i)
		{
			top_dat[i] = 0;
		}

		// prefetch output

		int gbl_out_scan_off1 = gbl_out_scan_off;
		for (int k = 0; k < MLO_N_LCL_OUT_MAPS; ++k, gbl_out_scan_off1 += MLO_OUT_STACKS * MLO_OUT_CHANNEL_STRIDE)
		{
			for (int j = 0; j < MLO_FILTER_SIZE1 - 1; ++j)
			{
				// loop around all output maps
				int top_df_off = gbl_out_scan_off1 + j*MLO_OUT_STRIDE;
				_FLOAT mask = 1;
#if MLO_IN_HEIGHT !=  MLO_OUT_HEIGHT || MLO_FILTER_SIZE1 - 1 > MLO_OUT_HEIGHT
				top_df_off = (j < MLO_OUT_HEIGHT) ? top_df_off : 0;
				mask = (j < MLO_OUT_HEIGHT) ? 1 : 0;
#endif

					spanReadingOutput(spn, k, j, top_df_off, mask,
						top_dat, top_df);

			}
		}


		gbl_out_scan_off += (MLO_FILTER_SIZE1 - 1) * MLO_OUT_STRIDE;

		int sc = 0;
		int sc_lcl_off = lcl_bot_off;
		

		// prolog
		// handling padding

		// top padding 
		for (; sc < MLO_FILTER_SIZE1 - MLO_FILTER_PAD1 - 1; ++sc, sc_lcl_off += MLO_IN_LCL_WIDTH)
		{
			Processing(sc, sc_lcl_off, sc + MLO_FILTER_PAD1, 0, pvt_accum, lcl_bot, top_dat);
		}

		for (; sc < MLO_IN_EXTENT1
#if MLO_IN_N_VERT_LOOPS == 1
			- MLO_FILTER_PAD1
#endif
			; ++sc, gbl_out_scan_off += MLO_OUT_STRIDE, sc_lcl_off += MLO_IN_LCL_WIDTH)
		{


			for (int k = 0; k < MLO_N_LCL_OUT_MAPS; ++k)
			{
				int top_df_off = gbl_out_scan_off + k*MLO_OUT_STACKS * MLO_OUT_CHANNEL_STRIDE;
				_FLOAT mask = 1;

#if MLO_IN_HEIGHT !=  MLO_OUT_HEIGHT || MLO_FILTER_SIZE1 - 1 > MLO_OUT_HEIGHT
				top_df_off = ((sc + MLO_FILTER_PAD1) < MLO_OUT_HEIGHT) ? top_df_off : 0;
				mask = ((sc + MLO_FILTER_PAD1) < MLO_OUT_HEIGHT) ? 1 : 0;
#endif
					spanReadingOutput(spn, k, (MLO_FILTER_SIZE1 - 1), top_df_off, mask,
						top_dat, top_df);

			}

			// processing
			Processing(sc, sc_lcl_off, MLO_FILTER_SIZE1 - 1, 0, pvt_accum, lcl_bot, top_dat);

			// move up output to reduce overfetch
			moveOutputUp(top_dat);

		}



// non-border input blocks
		for (int i_loop = 0;i_loop < MLO_N_GENERIC_LOOPS; ++i_loop, gbl_in_scan_off += MLO_IN_STRIDE * MLO_IN_EXTENT1)
		{
			barrier(CLK_LOCAL_MEM_FENCE);

			readInput(lcl_id, gbl_in_scan_off, MLO_IN_VERT_READS, bot, lcl_bot);

// point to the start of the local buffer

			sc_lcl_off = lcl_bot_off;


			for (; sc < (i_loop + 2) * MLO_IN_EXTENT1
				; ++sc, gbl_out_scan_off += MLO_OUT_STRIDE, sc_lcl_off += MLO_IN_LCL_WIDTH)
			{


				for (int k = 0; k < MLO_N_LCL_OUT_MAPS; ++k)
				{
					int top_df_off = gbl_out_scan_off + k*MLO_OUT_STACKS * MLO_OUT_CHANNEL_STRIDE;
					_FLOAT mask = 1;

#if MLO_IN_HEIGHT !=  MLO_OUT_HEIGHT
					top_df_off = ((sc + MLO_FILTER_PAD1) < MLO_OUT_HEIGHT) ? top_df_off : 0;
					mask = ((sc + MLO_FILTER_PAD1) < MLO_OUT_HEIGHT) ? 1 : 0;
#endif
						spanReadingOutput(spn, k, (MLO_FILTER_SIZE1 - 1), top_df_off, mask,
							top_dat, top_df);


				}

				// processing
				Processing(sc, sc_lcl_off, MLO_FILTER_SIZE1 - 1, 0, pvt_accum, lcl_bot, top_dat);

				// move up output to reduce overfetch
				moveOutputUp(top_dat);


			}
		}



// bottom border block

		for (int i_loop = 0; i_loop < (MLO_IN_N_VERT_LOOPS - MLO_N_GENERIC_LOOPS - 1); ++i_loop, gbl_in_scan_off += MLO_IN_STRIDE * MLO_IN_EXTENT1)
		{
			barrier(CLK_LOCAL_MEM_FENCE);
// read 1 scan line less
// padding processing takes care of the bottom border.

#define MLO_LAST_VERT_READS (MLO_IN_HEIGHT - MLO_IN_EXTENT1 * (MLO_IN_N_VERT_LOOPS - 1))

            readInput(lcl_id, gbl_in_scan_off, MLO_LAST_VERT_READS, bot, lcl_bot);

			// point to the start of the local buffer

			sc_lcl_off = lcl_bot_off;

			for (; sc < MLO_OUT_HEIGHT - MLO_FILTER_PAD1
				; ++sc, gbl_out_scan_off += MLO_OUT_STRIDE, sc_lcl_off += MLO_IN_LCL_WIDTH)
			{

				for (int k = 0; k < MLO_N_LCL_OUT_MAPS; ++k)
				{
					int top_df_off = gbl_out_scan_off + k*MLO_OUT_STACKS * MLO_OUT_CHANNEL_STRIDE;
					_FLOAT mask = 1;

#if MLO_IN_HEIGHT !=  MLO_OUT_HEIGHT
					top_df_off = ((sc + MLO_FILTER_PAD1) < MLO_OUT_HEIGHT) ? top_df_off : 0;
					mask = ((sc + MLO_FILTER_PAD1) < MLO_OUT_HEIGHT) ? 1 : 0;
#endif
						spanReadingOutput(spn, k, (MLO_FILTER_SIZE1 - 1), top_df_off, mask,
							top_dat, top_df);

				}

				// processing
				Processing(sc, sc_lcl_off, MLO_FILTER_SIZE1 - 1, 0, pvt_accum, lcl_bot, top_dat);

				// move up output to reduce overfetch
				moveOutputUp(top_dat);

			}
		}

		// epilog 
		// handling padding

		for (; sc < MLO_IN_HEIGHT; ++sc, sc_lcl_off += MLO_IN_LCL_WIDTH)
		{


			// processing
			Processing(sc, sc_lcl_off, MLO_FILTER_SIZE1 - 1, (MLO_FILTER_PAD1 + 1 - (MLO_IN_HEIGHT - sc)), pvt_accum, lcl_bot, top_dat);
			// move up output to reduce overfetch
			moveOutputUp(top_dat);


		} // for (; sc < MLO_OUT_HEIGHT - MLO_FILTER_PAD1 + 2; ++sc, gbl_out_scan_off += MLO_OUT_CHANNEL_STRIDE, gbl_in_scan_off += MLO_IN_CHANNEL_STRIDE)


	} // 	for (int b = 0;





	// final summation over all output maps and each filter row
	// this coudl be done with log but it negligeble anyway
	for (int k = 0; k < MLO_N_LCL_OUT_MAPS; ++k)
	{
		for(int c = 0; c < MLO_N_LCL_IN_MAPS; ++c)
		{

			for (int l = 0; l < MLO_FILTER_SIZE1; ++l)
			{

				barrier(CLK_LOCAL_MEM_FENCE);
				for (int n = 0; n < MLO_FILTER_SIZE0; ++n)
				{
					int pvt_off = (k*MLO_N_LCL_IN_MAPS + c) *MLO_FILTER_SIZE1*MLO_FILTER_SIZE0 + l*MLO_FILTER_SIZE0 + n;
					lcl[lcl_id * MLO_FILTER_SIZE0 + n] =
						pvt_accum[pvt_off];

				}

				barrier(CLK_LOCAL_MEM_FENCE);

				if (spn == 0)
				{
					for (int s = 0; s < MLO_N_SPANS_PER_SCAN - 1; ++s)
					{
						
						for (int n = 0; n < MLO_FILTER_SIZE0; ++n)
						{
							int pvt_off = (k*MLO_N_LCL_IN_MAPS + c) *MLO_FILTER_SIZE1*MLO_FILTER_SIZE0 + l*MLO_FILTER_SIZE0 + n;
							pvt_accum[pvt_off]
								+= lcl[(lcl_id + s + 1) * MLO_FILTER_SIZE0 + n];
						}

					}
				}

			}
		}
	}



// output 
// inputs are outputs
// TODO : for more than 1 input

	int wei_df_off = (((ib/MLO_N_BATCH_LOOPS) * MLO_N_OUTPUTS + o_idx + o) * (int)MLO_WEI_BATCH_STRIDE)
		// this input channel
		+ mul24(c_idx, (int)MLO_WEI_CHANNEL_STRIDE);
	for (int k = 0; k < MLO_N_LCL_OUT_MAPS; ++k)
	{
		for (int c = 0; c < MLO_N_LCL_IN_MAPS; ++c)
		{
			for (int i = 0; i < (MLO_FILTER_SIZE1 * MLO_FILTER_SIZE0); ++i)
			{
				if (spn == 0 && o_idx + o + k*MLO_OUT_STACKS < MLO_N_OUTPUTS && o < MLO_OUT_STACKS)
				{
					weights_df[wei_df_off + k*MLO_OUT_STACKS*MLO_WEI_BATCH_STRIDE + c*MLO_WEI_CHANNEL_STRIDE + i] = pvt_accum[(k*MLO_N_LCL_IN_MAPS + c) *MLO_FILTER_SIZE1*MLO_FILTER_SIZE0 + i];
				}
			}

		}
	}


}


// final reduction kernel
// add filters over batches
__attribute__((reqd_work_group_size(MLO_UT_GRP_SZ0, 1, 1)))
__kernel void MIOpenCvBwdWrW_rdc(
	const __global _FLOAT * weight_df_tmp,
	__global _FLOAT * weights_df
)
{
	int gbl_id = get_global_id(0);
	int wei_idx0 = gbl_id * MLO_UT_READ_UNIT;

	int wei_blk_idx = iDiv(wei_idx0, MLO_WEI_CHANNEL_STRIDE);
	int wei_idx = iMod(wei_idx0, wei_blk_idx, MLO_WEI_CHANNEL_STRIDE);

	_FLOAT pvt_accum_wei[MLO_UT_READ_UNIT];
	for (int i = 0; i < MLO_UT_READ_UNIT; ++i)
	{
		pvt_accum_wei[i] = 0;
	}

	int batch_loop = (MLO_BATCH_SZ + (MLO_N_BATCH_LOOPS*MLO_N_LCL_BATCHS) - 1) / (MLO_N_BATCH_LOOPS*MLO_N_LCL_BATCHS);
	for (int i = 0; i < batch_loop; ++i)
	{
		for (int j = 0; j < MLO_UT_READ_UNIT; ++j)
		{
			pvt_accum_wei[j]
				+= weight_df_tmp[(wei_blk_idx * MLO_WEI_CHANNEL_STRIDE + i* MLO_N_OUTPUTS*MLO_WEI_BATCH_STRIDE) + wei_idx + j];
		}
	}

	for (int j = 0; j < MLO_UT_READ_UNIT; ++j)
	{
		weights_df[wei_idx0 + j] = pvt_accum_wei[j];
	}

}
