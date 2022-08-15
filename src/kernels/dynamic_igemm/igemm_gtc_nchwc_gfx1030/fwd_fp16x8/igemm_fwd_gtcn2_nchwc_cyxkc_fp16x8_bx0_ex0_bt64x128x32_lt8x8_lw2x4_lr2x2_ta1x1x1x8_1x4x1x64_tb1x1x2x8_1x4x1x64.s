/*******************************************************************************
 *
 * MIT License
 *
 * Copyright (c) 2022-2021 Advanced Micro Devices, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 *******************************************************************************/
; generated by igemm_codegen.py (090d5c199adbaae1e85d5c8bad5a26564124d4ba)
;
.include "igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_utils.inc"

;----------------------------------------------------------
; starting of kernel igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_bx0_ex0_bt64x128x32_lt8x8_lw2x4_lr2x2_ta1x1x1x8_1x4x1x64_tb1x1x2x8_1x4x1x64
; tensor_layout              : 'nchwc_cyxkc'
; gemm_m_per_block           : 64
; gemm_n_per_block           : 128
; gemm_k_per_block           : 32
; lanegroup_tile_m           : 8
; lanegroup_wave_m           : 2
; lanegroup_repeat_m         : 2
; lanegroup_tile_n           : 8
; lanegroup_wave_n           : 4
; lanegroup_repeat_n         : 2
; tensor_a_thread_lengths    : [1, 1, 1, 8]
; tensor_a_cluster_lengths   : [1, 4, 1, 64]
; tensor_b_thread_lengths    : [1, 1, 2, 8]
; tensor_b_cluster_lengths   : [1, 4, 1, 64]
; direction                  : 'fwd'
; precision                  : 'fp16'
; nxb                        : 0
; nxe                        : 0
; vector_c                   : 8
; 
; block_size                 : 256
; lds_total                  : 32768
; lds_buffer_num             : 2
; 
.set k_p_in, 0
.set k_p_wei, 8
.set k_p_out, 16
.set k_tile_hw, 24
.set k_ntile_hw, 28
.set k_hi, 32
.set k_wi, 36
.set k_n, 40
.set k_k, 44
.set k_c, 48
.set k_group, 52
.set k_ks, 56
.set k_ho, 60
.set k_wo, 64
.set k_stride_hw, 68
.set k_dilation_hw, 72
.set k_pad_hw, 76
.set k_wei_hw, 80
.set k_move_slice_k, 84
.set k_magic_0, 88
.set k_magic_1, 92
.set k_magic_2, 96
.set k_magic_3, 100
.set k_magic_4, 104
.set k_magic_5, 108
.set k_magic_6, 112
.set k_magic_7, 116
.set k_shift_pack_0, 120
.set k_shift_pack_1, 124
.set k_end, 128

.set s_ka, 0
.set s_bx, 2
.set s_by, 3
.set s_p_in, 4
.set s_p_wei, 8
.set s_p_out, 12
.set s_tile_hw, 16
.set s_ntile_hw, 17
.set s_hi, 18
.set s_wi, 19
.set s_n, 20
.set s_k, 21
.set s_c, 22
.set s_group, 23
.set s_gemmk_split, 24
.set s_magic_0, 32
.set s_magic_1, 33
.set s_magic_2, 34
.set s_magic_3, 35
.set s_magic_4, 36
.set s_magic_5, 37
.set s_magic_6, 38
.set s_magic_7, 39
.set s_shift_pack_0, 40
.set s_shift_pack_1, 41
.set s_i_tile_h, 42
.set s_i_tile_w, 43
.set s_tile_h, 44
.set s_tile_w, 16
.set s_ntile_h, 45
.set s_ntile_w, 17
.set s_sps_hi, 46
.set s_sps_wi, 47
.set s_tile_os_hi, 48
.set s_tile_os_wi, 49
.set s_in_stride_c, 50
.set s_in_stride_hi, 51
.set s_in_stride_n, 52
.set s_in_stride_nb0, 53
.set s_wei_stride_x, 54
.set s_out_stride_k, 55
.set s_out_stride_ho, 56
.set s_out_stride_n, 57
.set s_block_gtc_ig, 58
.set s_block_gtc_ik, 59
.set s_block_gtc_inb, 60
.set s_move_slice_k_stride_gemm_k, 61
.set s_move_slice_k_stride_c, 62
.set s_knum, 3
.set s_dim_br, 63
.set s_dim_mp, 64
.set s_dim_mr, 65
.set s_dim_np, 66
.set s_dim_nr, 67
.set s_move_slice_k_acc_c, 68
.set s_kitr, 1
.set s_0xffff, 69
.set s_in_offset, 70
.set s_tmp, 72
.set s_x_dilation_w, 48
.set s_y_dilation_h, 49
.set s_end, 78

.set v_c, 0
.set v_a, 33
.set v_b, 42
.set v_gld_a, 50
.set v_gld_b, 54
.set v_sst_a_os, 62
.set v_sld_a_os, 63
.set v_sst_b_os, 64
.set v_sld_b_os, 65
.set v_in_os, 66
.set v_in_i_hw_list, 68
.set v_in_flag, 70
.set v_in_flag_n, 72
.set v_wei_os, 73
.set v_out_os, 74
.set v_gtc_ic, 75
.set v_gtc_iec, 76
.set v_gtc_iy, 77
.set v_gtc_ix, 78
.set v_in_inb, 79
.set v_in_in, 80
.set v_wei_ik, 81
.set v_co_sst, 80
.set v_co_sld, 82
.set v_out_flag, 81
.set v_out_inb, 79
.set v_out_ik, 79
.set v_gemm_in, 83
.set v_gemm_im, 84
.set v_co_sub_m_index, 84
.set v_co_sub_n_index, 83
.set v_out_in, 83
.set v_coalescing_store_index, 83
.set v_tmp, 86
.set v_end, 92

.text
.globl igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_bx0_ex0_bt64x128x32_lt8x8_lw2x4_lr2x2_ta1x1x1x8_1x4x1x64_tb1x1x2x8_1x4x1x64
.p2align 8
.type igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_bx0_ex0_bt64x128x32_lt8x8_lw2x4_lr2x2_ta1x1x1x8_1x4x1x64_tb1x1x2x8_1x4x1x64,@function
igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_bx0_ex0_bt64x128x32_lt8x8_lw2x4_lr2x2_ta1x1x1x8_1x4x1x64_tb1x1x2x8_1x4x1x64:
    s_load_dwordx2  s[s_p_in+0:s_p_in+1],   s[s_ka+0:s_ka+1],    0+k_p_in
    s_load_dwordx2  s[s_p_wei+0:s_p_wei+1],   s[s_ka+0:s_ka+1],    0+k_p_wei
    s_load_dwordx2  s[s_p_out+0:s_p_out+1],   s[s_ka+0:s_ka+1],    0+k_p_out
    s_load_dwordx8  s[s_tile_hw+0:s_tile_hw+7],   s[s_ka+0:s_ka+1],    0+k_tile_hw
    s_load_dword  s[s_gemmk_split],   s[s_ka+0:s_ka+1],    0+k_ks
    s_load_dwordx8  s[s_magic_0+0:s_magic_0+7],   s[s_ka+0:s_ka+1],  0+k_magic_0
    s_load_dwordx2  s[s_shift_pack_0+0:s_shift_pack_0+1],   s[s_ka+0:s_ka+1],  0+k_shift_pack_0
    ; wei(1, ce, 1, k-vec-c) thread_lengths: 1x1x1x8, cluster_length: 1x4x1x64, k_pack:8
    v_mov_b32 v[v_tmp], v0
    v_and_b32 v[v_wei_ik], 63, v[v_tmp]
    v_lshrrev_b32 v[v_tmp], 6, v[v_tmp]
    v_and_b32 v[v_gtc_iec], 3, v[v_tmp]

    ; inp(1, ce, nb0, nb1) thread_length: 1x1x2x8, cluster_length: 1x4x1x64, k_pack:8
    v_mov_b32 v[v_tmp], v0
    v_and_b32 v[v_in_inb], 63, v[v_tmp]
    s_mov_b32 s[s_0xffff], 65535
    s_mov_b32 s[s_tmp+1], 255
    s_waitcnt lgkmcnt(0)

    ; calculate index
    s_lshr_b32 s[s_tile_h], s[s_tile_hw], 16
    s_and_b32 s[s_tile_w], s[s_tile_hw], s[s_0xffff]
    s_lshr_b32 s[s_ntile_h], s[s_ntile_hw], 16
    s_and_b32 s[s_ntile_w], s[s_ntile_hw], s[s_0xffff]
    s_lshl_b32 s[s_in_stride_hi], s[s_wi], 3
    s_mul_i32 s[s_in_stride_c], s[s_hi], s[s_in_stride_hi]
    s_mul_i32 s[s_tmp], s[s_in_stride_c], s[s_c]
    s_mul_i32 s[s_in_stride_n], s[s_tmp], s[s_group]
    s_lshl_b32 s[s_wei_stride_x], s[s_k], 3
    s_lshl_b32 s[s_out_stride_ho], s[s_wi], 3
    s_mul_i32 s[s_out_stride_k], s[s_hi], s[s_out_stride_ho]
    s_lshr_b32 s[s_tmp+1], s[s_k], 3
    s_mul_i32 s[s_tmp], s[s_tmp+1], s[s_out_stride_k]
    s_mul_i32 s[s_out_stride_n], s[s_tmp], s[s_group]
    s_mul_i32  s[s_tmp], s[s_n], s[s_in_stride_n]
    s_mul_i32  s[s_tmp+1], s[s_n], s[s_out_stride_n]
    s_lshl_b32 s[s_tmp+4], s[s_tmp], 1
    s_lshl_b32 s[s_tmp+5], s[s_tmp+1], 1
    s_mul_i32 s[s_tmp], s[s_by], s[s_tmp+4]
    s_mul_hi_u32 s[s_tmp+1], s[s_by], s[s_tmp+4]
    s_add_u32 s[s_p_in], s[s_p_in], s[s_tmp]
    s_addc_u32 s[s_p_in+1], s[s_p_in+1], s[s_tmp+1]
    s_mul_i32 s[s_tmp], s[s_by], s[s_tmp+5]
    s_mul_hi_u32 s[s_tmp+1], s[s_by], s[s_tmp+5]
    s_add_u32 s[s_p_out], s[s_p_out], s[s_tmp]
    s_addc_u32 s[s_p_out+1], s[s_p_out+1], s[s_tmp+1]
    s_mov_b32 s[s_knum], s[s_c]
    s_mul_i32 s[s_dim_br], s[s_tile_h], s[s_tile_w]
    s_mul_i32 s[s_dim_nr], s[s_n], s[s_dim_br]
    s_add_u32 s[s_tmp+2], 127, s[s_dim_nr]
    s_lshr_b32 s[s_dim_np], s[s_tmp+2], 7
    s_add_u32 s[s_tmp], 63, s[s_k]
    s_lshr_b32 s[s_dim_mp], s[s_tmp], 6

    ; gemm_m_per_block:64, gemm_n_per_block:128, source_access_order:0
    s_bfe_u32 s[s_tmp+3], s[s_shift_pack_0], 0x00080000 ; offset:0, width:8
    .mdiv_u32_rem_ss s_tmp+4,s_tmp+2,s_bx,s_magic_0,s_tmp+3,s_dim_np,s_tmp
    s_bfe_u32 s[s_tmp+3], s[s_shift_pack_0], 0x00080008 ; offset:8, width:8
    .mdiv_u32_rem_ss s_tmp+5,s_bx,s_tmp+2,s_magic_1,s_tmp+3,s_dim_mp,s_tmp
    ; s_tmp+4:block_gtc_in, s_tmp+5:block_gtc_im
    s_lshl_b32 s[s_block_gtc_inb], s[s_tmp+4], 7
    s_lshl_b32 s[s_block_gtc_ik], s[s_tmp+5], 6
    s_bfe_u32 s[s_tmp+3], s[s_shift_pack_1], 0x00080018 ; offset:24, width:8
    .mdiv_u32_rem_ss s_i_tile_w,s_tmp+2,s_bx,s_magic_7,s_tmp+3,s_ntile_w,s_tmp
    s_bfe_u32 s[s_tmp+3], s[s_shift_pack_1], 0x00080010 ; offset:16, width:8
    .mdiv_u32_rem_ss s_i_tile_h,s_block_gtc_ig,s_tmp+2,s_magic_6,s_tmp+3,s_ntile_h,s_tmp
    ; calculate spatial tiling
    s_mul_i32 s[s_tile_os_hi], s[s_i_tile_h], s[s_tile_h]
    s_sub_u32 s[s_sps_hi], s[s_hi], s[s_tile_os_hi]
    s_cmp_ge_u32 s[s_sps_hi], s[s_tile_h]
    s_cmov_b32 s[s_sps_hi], s[s_tile_h]
    ; calculate spatial tiling
    s_mul_i32 s[s_tile_os_wi], s[s_i_tile_w], s[s_tile_w]
    s_sub_u32 s[s_sps_wi], s[s_wi], s[s_tile_os_wi]
    s_cmp_ge_u32 s[s_sps_wi], s[s_tile_w]
    s_cmov_b32 s[s_sps_wi], s[s_tile_w]
    s_mul_i32 s[s_tmp], s[s_in_stride_hi], s[s_tile_os_hi]
    s_lshl_b32 s[s_tmp+1], s[s_tile_os_wi], 3
    s_add_u32 s[s_tmp], s[s_tmp], s[s_tmp+1]
    s_lshl_b32 s[s_tmp], s[s_tmp], 1
    s_add_u32 s[s_p_in], s[s_p_in], s[s_tmp] ; accumulate tile offset for input
    s_addc_u32 s[s_p_in+1], s[s_p_in+1], 0
    s_add_u32 s[s_p_out], s[s_p_out], s[s_tmp] ; accumulate tile offset for output
    s_addc_u32 s[s_p_out+1], s[s_p_out+1], 0
    v_add_nc_u32 v[v_tmp+5], s[s_block_gtc_inb], v[v_in_inb]
    s_bfe_u32 s[s_tmp+3], s[s_shift_pack_0], 0x00080018 ; offset:24, width:8
    .mdiv_u32_rem_vs v_tmp,v_tmp+4,v_tmp+5,s_magic_3,s_tmp+3,s_tile_w,v_tmp+3
    s_bfe_u32 s[s_tmp+3], s[s_shift_pack_0], 0x00080010 ; offset:16, width:8
    .mdiv_u32_rem_vs v_tmp+1,v_in_in,v_tmp+4,s_magic_2,s_tmp+3,s_tile_h,v_tmp+3
    v_mov_b32 v[v_gtc_ic], v[v_gtc_iec]
    v_cmp_gt_u32  s[s_n], v[v_in_in]
    v_cndmask_b32 v[v_tmp+3], 0, 1
    v_lshlrev_b32 v[v_in_flag_n], 0, v[v_tmp+3]
    s_lshl_b32 s[s_sps_hi], s[s_sps_hi], 16 ; shift to hi-16
    v_lshl_or_b32 v[v_in_i_hw_list], v[v_tmp+1], 16, v[v_tmp]

    ; calculate wei offset
    s_mul_i32 s[s_tmp], s[s_wei_stride_x], s[s_knum]
    s_lshl_b32 s[s_tmp], s[s_tmp], 1
    s_mov_b32 s[s_p_wei+2], s[s_tmp]
    s_mov_b32 s[s_p_wei+3], 0x31014000
    s_mul_i32 s[s_tmp], s[s_block_gtc_ig], s[s_tmp]
    s_mul_hi_u32 s[s_tmp+1], s[s_block_gtc_ig], s[s_tmp]
    s_add_u32 s[s_p_wei], s[s_p_wei], s[s_tmp]
    s_addc_u32 s[s_p_wei+1], s[s_p_wei+1], s[s_tmp+1]
    v_add_nc_u32 v[v_tmp+5], s[s_block_gtc_ik], v[v_wei_ik]
    v_mul_lo_u32 v[v_tmp], s[s_wei_stride_x], v[v_gtc_iec]
    v_lshlrev_b32 v[v_tmp+4], 3, v[v_tmp+5]
    v_add_lshl_u32 v[v_wei_os], v[v_tmp], v[v_tmp+4], 1


    .v_clear_nc v_gld_a, 4
    ; load weight
    buffer_load_dwordx4 v[v_gld_a+0:v_gld_a+0+3], v[v_wei_os], s[s_p_wei:s_p_wei+3], 0 offen offset:0

    ; calculate in offset
    s_mov_b32 s[s_in_offset], 0
    s_mov_b32 s[s_p_in+2], 0xffffffff
    s_mov_b32 s[s_p_in+3], 0x31014000
    s_mul_i32 s[s_tmp+2], s[s_c], s[s_in_stride_c]
    s_lshl_b32 s[s_tmp+2], s[s_tmp+2], 1
    s_mul_i32 s[s_tmp], s[s_block_gtc_ig], s[s_tmp+2]
    s_mul_hi_u32 s[s_tmp+1], s[s_block_gtc_ig], s[s_tmp+2]
    s_add_u32 s[s_p_in], s[s_p_in], s[s_tmp]
    s_addc_u32 s[s_p_in+1], s[s_p_in+1], s[s_tmp+1]

    v_mul_lo_u32 v[v_tmp+5], s[s_in_stride_n], v[v_in_in]
    v_mul_lo_u32 v[v_tmp+4], s[s_in_stride_c], v[v_gtc_ic]
    v_lshrrev_b32 v[v_tmp], 16, v[v_in_i_hw_list]
    v_and_b32 v[v_tmp+1], s[s_0xffff], v[v_in_i_hw_list]
    v_mul_lo_u32 v[v_tmp+3], s[s_wi], v[v_tmp]
    v_add_nc_u32 v[v_tmp+3], v[v_tmp+1], v[v_tmp+3]
    v_add_nc_u32 v[v_tmp+4], v[v_tmp+4], v[v_tmp+5]
    v_lshlrev_b32 v[v_tmp+3], 3, v[v_tmp+3]
    v_add_lshl_u32 v[v_in_os], v[v_tmp+4], v[v_tmp+3], 1
    v_cmp_gt_u32 s[s_c], v[v_gtc_ic]
    v_cndmask_b32 v[v_tmp+4], 0, 1
    v_bfe_u32 v[v_tmp+1], v[v_in_flag_n],  0, 1
    v_and_b32 v[v_tmp+1], v[v_tmp+4], v[v_tmp+1]
    v_cmp_gt_u32  s[s_sps_hi], v[v_in_i_hw_list]
    v_cndmask_b32 v[v_in_flag], 0, v[v_tmp+1]
    v_cmp_gt_u16  s[s_sps_wi], v[v_in_i_hw_list]
    v_cndmask_b32 v[v_in_flag], 0, v[v_in_flag]

    s_mov_b32 s1, 64
    v_add_nc_u32 v[v_tmp+3], s1, v[v_in_inb]
    v_add_nc_u32 v[v_tmp+5], s[s_block_gtc_inb], v[v_tmp+3]
    s_bfe_u32 s[s_tmp+3], s[s_shift_pack_0], 0x00080018 ; offset:24, width:8
    .mdiv_u32_rem_vs v_tmp,v_tmp+4,v_tmp+5,s_magic_3,s_tmp+3,s_tile_w,v_tmp+3
    s_bfe_u32 s[s_tmp+3], s[s_shift_pack_0], 0x00080010 ; offset:16, width:8
    .mdiv_u32_rem_vs v_tmp+1,v_in_in,v_tmp+4,s_magic_2,s_tmp+3,s_tile_h,v_tmp+3
    v_mul_lo_u32 v[v_tmp+5], s[s_in_stride_n], v[v_in_in]
    v_mul_lo_u32 v[v_tmp+4], s[s_in_stride_c], v[v_gtc_ic]
    v_mul_lo_u32 v[v_tmp+3], s[s_wi], v[v_tmp+1]
    v_add_nc_u32 v[v_tmp+3], v[v_tmp], v[v_tmp+3]
    v_add_nc_u32 v[v_tmp+4], v[v_tmp+4], v[v_tmp+5]
    v_lshlrev_b32 v[v_tmp+3], 3, v[v_tmp+3]
    v_add_lshl_u32 v[v_in_os+1], v[v_tmp+4], v[v_tmp+3], 1
    v_cmp_gt_u32 s[s_c], v[v_gtc_ic]
    v_cndmask_b32 v[v_tmp+4], 0, 1
    v_cmp_gt_u32  s[s_n], v[v_in_in]
    v_cndmask_b32 v[v_tmp+3], 0, 1
    v_lshl_or_b32 v[v_in_i_hw_list+1], v[v_tmp+1], 16, v[v_tmp]
    v_lshl_or_b32 v[v_in_flag_n], v[v_tmp+3], 1, v[v_in_flag_n]
    v_and_b32 v[v_tmp+3], v[v_tmp+4], v[v_tmp+3]
    v_cmp_gt_u32  s[s_sps_hi], v[v_in_i_hw_list+1]
    v_cndmask_b32 v[v_in_flag+1], 0, v[v_tmp+3]
    v_cmp_gt_u16  s[s_sps_wi], v[v_in_i_hw_list+1]
    v_cndmask_b32 v[v_in_flag+1], 0, v[v_in_flag+1]
    ; load input, nxe:0
    .v_clear_nc v_gld_b, 8
    v_cmpx_le_u32 1, v[v_in_flag]
    buffer_load_dwordx4 v[v_gld_b:v_gld_b+3], v[v_in_os], s[s_p_in:s_p_in+3], s[s_in_offset] offen offset:0
    s_mov_b64 exec, -1
    v_cmpx_le_u32 1, v[v_in_flag+1]
    buffer_load_dwordx4 v[v_gld_b+4:v_gld_b+4+3], v[v_in_os+1], s[s_p_in:s_p_in+3], s[s_in_offset] offen offset:0
    s_mov_b64 exec, -1

    v_mov_b32 v[v_tmp+5], v0
    ; dotx mapping, get source matrix gemm index, k_pack:8, v_pack:1, k_pack_per_thread:4
    v_and_b32 v[v_gemm_in], 7, v[v_tmp+5]           ; lanegroup_n index 
    v_and_b32 v[v_gemm_im], 7, v[v_tmp+5]           ; lanegroup_m index 
    v_lshrrev_b32 v[v_tmp+5], 3, v[v_tmp+5]
    v_and_b32 v[v_tmp + 0], 3, v[v_tmp+5]          ; lanegroup_n_per_wave index
    v_lshl_or_b32 v[v_gemm_in], v[v_tmp + 0], 3, v[v_gemm_in]
    v_lshrrev_b32 v[v_tmp+5], 2, v[v_tmp+5]
    v_and_b32 v[v_tmp + 1], 1, v[v_tmp+5]          ; lanegroup_m_per_wave index
    v_lshl_or_b32 v[v_gemm_im], v[v_tmp + 1], 3, v[v_gemm_im]
    v_lshrrev_b32 v[v_tmp+5], 1, v[v_tmp+5]
    v_and_b32 v[v_tmp + 2], 1, v[v_tmp+5]  ; waves_per_n index
    v_lshl_or_b32 v[v_gemm_in], v[v_tmp + 2], 5, v[v_gemm_in]
    v_lshrrev_b32 v[v_tmp+5], 1, v[v_tmp+5]
    v_and_b32 v[v_tmp + 3], 1, v[v_tmp+5]  ; waves_per_m index
    v_lshl_or_b32 v[v_gemm_im], v[v_tmp + 3], 4, v[v_gemm_im]

    ; LDS store, wei: 1,ce,1,k: 1x1x1x8, 1x4x1x64, k_pack:8, k_pack_gld_a:8, fp16
    v_lshlrev_b32 v[v_tmp+2], 3, v[v_wei_ik]
    v_mad_u32_u24 v[v_tmp], v[v_gtc_iec], 512, v[v_tmp+2]
    v_lshlrev_b32 v[v_sst_a_os], 1, v[v_tmp]

    v_lshlrev_b32 v[v_sld_a_os], 4, v[v_gemm_im] ; LDS load wei
    ; LDS store, input: 1,ce,nb_vec_c: 1x1x2x8, 1x4x1x64, k_pack:8, k_pack_gld_b:8, fp16
    v_lshlrev_b32 v[v_tmp+2], 3,  v[v_in_inb]
    v_mad_u32_u24 v[v_tmp], v[v_gtc_iec], 1024, v[v_tmp+2]
    v_lshlrev_b32 v[v_sst_b_os], 1, v[v_tmp]
    v_add_nc_u32 v[v_sst_b_os], 4096, v[v_sst_b_os]

    v_lshlrev_b32 v[v_sld_b_os], 4, v[v_gemm_in] ; LDS load input
    v_add_nc_u32 v[v_sld_b_os], 4096, v[v_sld_b_os]
    ; init_co_lds_offset for dotx
    v_lshrrev_b32 v[v_tmp], 3, v[v_gemm_im]    ; shink m by 8
    v_lshlrev_b32 v[v_tmp + 1],  3, v[v_gemm_in]    ; expand n by 8
    v_mad_u32_u24 v[v_co_sst], v[v_tmp], 1024, v[v_tmp + 1]    ; macro_tile_n:128, sld_vec:8
    v_lshlrev_b32 v[v_co_sld], 4, v[0]   ; sld vec:8 * byte:2
    v_lshlrev_b32 v[v_co_sst], 1, v[v_co_sst]
    ; init_co_sub_m_index for dotx
    v_lshrrev_b32 v[v_co_sub_m_index], 7, v[0]
    v_lshlrev_b32 v[v_co_sub_m_index], 3, v[v_co_sub_m_index] ; expand m by sld_vec:8
    v_lshrrev_b32 v[v_co_sub_m_index], 3, v[v_co_sub_m_index] ; fold sub_m by 8
    ; init_co_sub_n_index dotx
    v_and_b32 v[v_co_sub_n_index], 127, v[0]

    ; output offset
    s_lshr_b32 s[s_tmp+3], s[s_k], 3
    s_mul_i32 s[s_tmp+3], s[s_block_gtc_ig],s[s_tmp+3]
    s_lshl_b32 s[s_tmp+4], s[s_out_stride_k], 1
    s_mul_i32 s[s_tmp], s[s_tmp+3], s[s_tmp+4]
    s_mul_hi_u32 s[s_tmp+1], s[s_tmp+3], s[s_tmp+4]
    s_add_u32 s[s_p_out], s[s_p_out], s[s_tmp]
    s_addc_u32 s[s_p_out+1], s[s_p_out+1], s[s_tmp+1]

    s_lshr_b32 s[s_tmp+1], s[s_block_gtc_ik], 3
    s_lshl_b32 s[s_tmp+4], s[s_out_stride_k], 1
    s_mul_i32 s[s_tmp], s[s_tmp+1], s[s_tmp+4]
    s_mul_hi_u32 s[s_tmp+1], s[s_tmp+1], s[s_tmp+4]
    s_add_u32 s[s_p_out], s[s_p_out], s[s_tmp]
    s_addc_u32 s[s_p_out+1], s[s_p_out+1], s[s_tmp+1]

    v_add_nc_u32 v[v_out_inb], s[s_block_gtc_inb], v[v_co_sub_n_index]   ; total n*ho*wo
    ;   compute from n1b
    s_bfe_u32 s[s_tmp+3], s[s_shift_pack_0], 0x00080018 ; offset:24, width:8
    .mdiv_u32_rem_vs v_tmp+4,v_tmp+3,v_out_inb,s_magic_3,s_tmp+3,s_tile_w,v_tmp
    s_bfe_u32 s[s_tmp+3], s[s_shift_pack_0], 0x00080010 ; offset:16, width:8
    .mdiv_u32_rem_vs v_tmp+5,v_out_in,v_tmp+3,s_magic_2,s_tmp+3,s_tile_h,v_tmp
    v_cmp_gt_u32  s[s_n], v[v_out_in]
    v_cndmask_b32 v[v_tmp+3], 0, 1
    v_lshl_or_b32 v[v_tmp], v[v_tmp+5], 16, v[v_tmp+4]
    v_cmp_gt_u32  s[s_sps_hi], v[v_tmp]
    v_cndmask_b32 v[v_out_flag], 0, v[v_tmp+3]
    v_cmp_gt_u16  s[s_sps_wi], v[v_tmp]
    v_cndmask_b32 v[v_out_flag], 0, v[v_out_flag]
    v_mul_lo_u32 v[v_tmp], s[s_wi], v[v_tmp+5]
    v_add_nc_u32 v[v_tmp+4], v[v_tmp], v[v_tmp+4]
    v_mul_lo_u32 v[v_tmp], v[v_out_in], s[s_out_stride_n]
    v_lshlrev_b32 v[v_tmp], 1, v[v_tmp]
    v_lshl_add_u32 v[v_out_os], v[v_tmp+4], 4, v[v_tmp]
    v_mul_lo_u32 v[v_tmp], s[s_out_stride_k], v[v_co_sub_m_index]
    v_lshlrev_b32 v[v_tmp], 1, v[v_tmp]
    v_add_nc_u32 v[v_out_os], v[v_out_os], v[v_tmp]
    ;    mask for coaleascing store
    v_mov_b32 v[v_coalescing_store_index], v[0]
    ; move slice stride
    s_mul_i32 s[s_move_slice_k_stride_c], s[s_in_stride_c], 8
    s_mov_b32 s[s_move_slice_k_acc_c], 4
    s_lshl_b32 s[s_move_slice_k_stride_gemm_k], s[s_k], 6

    s_mov_b32 s[s_p_out+2], 0xffffffff
    s_mov_b32 s[s_p_out+3], 0x31014000
    s_add_i32 s[s_knum], s[s_knum], 3
    s_lshr_b32 s[s_knum], s[s_knum], 2
    s_lshl_b32 s[s_knum], s[s_knum], 2

    ; start FMA loop
    s_waitcnt vmcnt(2)
    ds_write_b128 v[v_sst_a_os], v[v_gld_a+0:v_gld_a+0+3] 
    s_waitcnt vmcnt(0)
    ds_write_b128 v[v_sst_b_os], v[v_gld_b+0:v_gld_b+0+3] 
    ds_write_b128 v[v_sst_b_os], v[v_gld_b+4:v_gld_b+4+3] offset:1024
    .v_clear_nc v_c, 32
    s_sub_i32 s[s_kitr], s[s_knum], 4
    s_cmp_gt_i32 s[s_kitr], 0
    s_cbranch_scc0 L_igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_bx0_ex0_bt64x128x32_lt8x8_lw2x4_lr2x2_ta1x1x1x8_1x4x1x64_tb1x1x2x8_1x4x1x64_end
    
    v_add_nc_u32 v[v_gtc_ic], s[s_move_slice_k_acc_c], v[v_gtc_ic]
    s_add_u32 s[s_in_offset],  s[s_move_slice_k_stride_c], s[s_in_offset]
    v_add_nc_u32 v[v_wei_os], s[s_move_slice_k_stride_gemm_k], v[v_wei_os]
    v_cmp_gt_u32 s[s_c], v[v_gtc_ic]
    v_cndmask_b32 v[v_tmp], 0, 1
    v_and_b32 v[v_in_flag], v[v_in_flag], v[v_tmp]
    v_and_b32 v[v_in_flag+1], v[v_in_flag+1], v[v_tmp]

    v_xor_b32 v[v_sst_b_os], 0x4000, v[v_sst_b_os] ; switch double buffer b store
    v_xor_b32 v[v_sst_a_os], 0x4000, v[v_sst_a_os] ; switch double buffer a store
    s_waitcnt lgkmcnt(0)
    s_barrier
    ; load weight
    buffer_load_dwordx4 v[v_gld_a+0:v_gld_a+0+3], v[v_wei_os], s[s_p_wei:s_p_wei+3], 0 offen offset:0
    ; load input, nxe:0
    .v_clear_nc v_gld_b, 8
    v_cmpx_le_u32 1, v[v_in_flag]
    buffer_load_dwordx4 v[v_gld_b:v_gld_b+3], v[v_in_os], s[s_p_in:s_p_in+3], s[s_in_offset] offen offset:0
    s_mov_b64 exec, -1
    v_cmpx_le_u32 1, v[v_in_flag+1]
    buffer_load_dwordx4 v[v_gld_b+4:v_gld_b+4+3], v[v_in_os+1], s[s_p_in:s_p_in+3], s[s_in_offset] offen offset:0
    s_mov_b64 exec, -1
L_igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_bx0_ex0_bt64x128x32_lt8x8_lw2x4_lr2x2_ta1x1x1x8_1x4x1x64_tb1x1x2x8_1x4x1x64_fma_body:
    ds_read_b128 v[v_b:v_b+3], v[v_sld_b_os] offset:0
    ds_read_b128 v[v_a:v_a+3], v[v_sld_a_os] offset:0
    ds_read_b128 v[v_a+4:v_a+4+3], v[v_sld_a_os] offset:512
    ds_read_b128 v[v_b+4:v_b+4+3], v[v_sld_b_os] offset:1024
    
    
    s_waitcnt lgkmcnt(2)
    .v_lanegroup_dotx_fp16_8x8x8 v_c,v_a,v_b
    s_waitcnt lgkmcnt(1)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+16,v_a+4,v_b
    ds_read_b128 v[v_b:v_b+3], v[v_sld_b_os] offset:0+0*2048+2048
    s_waitcnt lgkmcnt(1)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+8,v_a,v_b+4
    ds_read_b128 v[v_a:v_a+3], v[v_sld_a_os] offset:0+1*1024+0
    .v_lanegroup_dotx_fp16_8x8x8 v_c+24,v_a+4,v_b+4
    ds_read_b128 v[v_a+4:v_a+4+3], v[v_sld_a_os] offset:0+1*1024+512
    ds_read_b128 v[v_b+4:v_b+4+3], v[v_sld_b_os] offset:0+1*2048+1024
    s_waitcnt lgkmcnt(2)
    .v_lanegroup_dotx_fp16_8x8x8 v_c,v_a,v_b
    s_waitcnt lgkmcnt(1)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+16,v_a+4,v_b
    ds_read_b128 v[v_b:v_b+3], v[v_sld_b_os] offset:0+1*2048+2048
    s_waitcnt lgkmcnt(1)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+8,v_a,v_b+4
    ds_read_b128 v[v_a:v_a+3], v[v_sld_a_os] offset:0+2*1024+0
    .v_lanegroup_dotx_fp16_8x8x8 v_c+24,v_a+4,v_b+4
    ds_read_b128 v[v_a+4:v_a+4+3], v[v_sld_a_os] offset:0+2*1024+512
    ds_read_b128 v[v_b+4:v_b+4+3], v[v_sld_b_os] offset:0+2*2048+1024
    s_waitcnt lgkmcnt(2)
    .v_lanegroup_dotx_fp16_8x8x8 v_c,v_a,v_b
    s_waitcnt lgkmcnt(1)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+16,v_a+4,v_b
    ds_read_b128 v[v_b:v_b+3], v[v_sld_b_os] offset:0+2*2048+2048
    s_waitcnt lgkmcnt(1)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+8,v_a,v_b+4
    ds_read_b128 v[v_a:v_a+3], v[v_sld_a_os] offset:0+3*1024+0
    .v_lanegroup_dotx_fp16_8x8x8 v_c+24,v_a+4,v_b+4
    ds_read_b128 v[v_a+4:v_a+4+3], v[v_sld_a_os] offset:0+3*1024+512
    ds_read_b128 v[v_b+4:v_b+4+3], v[v_sld_b_os] offset:0+3*2048+1024
    s_waitcnt lgkmcnt(2)
    .v_lanegroup_dotx_fp16_8x8x8 v_c,v_a,v_b
    s_waitcnt lgkmcnt(1)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+16,v_a+4,v_b
    
    
    v_xor_b32 v[v_sld_b_os], 0x4000, v[v_sld_b_os] ; switch double buffer b load
    v_xor_b32 v[v_sld_a_os], 0x4000, v[v_sld_a_os] ; switch double buffer a load
    s_waitcnt vmcnt(2)
    ds_write_b128 v[v_sst_a_os], v[v_gld_a+0:v_gld_a+0+3] 
    s_waitcnt vmcnt(0)
    ds_write_b128 v[v_sst_b_os], v[v_gld_b+0:v_gld_b+0+3] 
    ds_write_b128 v[v_sst_b_os], v[v_gld_b+4:v_gld_b+4+3] offset:1024
    s_sub_i32 s[s_kitr], s[s_kitr], 4
    s_cmp_gt_i32 s[s_kitr], 0
    s_cbranch_scc0 L_igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_bx0_ex0_bt64x128x32_lt8x8_lw2x4_lr2x2_ta1x1x1x8_1x4x1x64_tb1x1x2x8_1x4x1x64_fma_finishing
    
    v_add_nc_u32 v[v_gtc_ic], s[s_move_slice_k_acc_c], v[v_gtc_ic]
    s_add_u32 s[s_in_offset],  s[s_move_slice_k_stride_c], s[s_in_offset]
    v_add_nc_u32 v[v_wei_os], s[s_move_slice_k_stride_gemm_k], v[v_wei_os]
    v_cmp_gt_u32 s[s_c], v[v_gtc_ic]
    v_cndmask_b32 v[v_tmp], 0, 1
    v_and_b32 v[v_in_flag], v[v_in_flag], v[v_tmp]
    v_and_b32 v[v_in_flag+1], v[v_in_flag+1], v[v_tmp]

    s_waitcnt lgkmcnt(3)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+8,v_a,v_b+4
    v_xor_b32 v[v_sst_b_os], 0x4000, v[v_sst_b_os] ; switch double buffer b store
    v_xor_b32 v[v_sst_a_os], 0x4000, v[v_sst_a_os] ; switch double buffer a store
    s_waitcnt lgkmcnt(0)
    s_barrier
    ; load weight
    buffer_load_dwordx4 v[v_gld_a+0:v_gld_a+0+3], v[v_wei_os], s[s_p_wei:s_p_wei+3], 0 offen offset:0
    ; load input, nxe:0
    .v_clear_nc v_gld_b, 8
    v_cmpx_le_u32 1, v[v_in_flag]
    buffer_load_dwordx4 v[v_gld_b:v_gld_b+3], v[v_in_os], s[s_p_in:s_p_in+3], s[s_in_offset] offen offset:0
    s_mov_b64 exec, -1
    v_cmpx_le_u32 1, v[v_in_flag+1]
    buffer_load_dwordx4 v[v_gld_b+4:v_gld_b+4+3], v[v_in_os+1], s[s_p_in:s_p_in+3], s[s_in_offset] offen offset:0
    s_mov_b64 exec, -1
    .v_lanegroup_dotx_fp16_8x8x8 v_c+24,v_a+4,v_b+4
    s_branch L_igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_bx0_ex0_bt64x128x32_lt8x8_lw2x4_lr2x2_ta1x1x1x8_1x4x1x64_tb1x1x2x8_1x4x1x64_fma_body
L_igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_bx0_ex0_bt64x128x32_lt8x8_lw2x4_lr2x2_ta1x1x1x8_1x4x1x64_tb1x1x2x8_1x4x1x64_fma_finishing:
    s_waitcnt lgkmcnt(3)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+8,v_a,v_b+4
    .v_lanegroup_dotx_fp16_8x8x8 v_c+24,v_a+4,v_b+4
L_igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_bx0_ex0_bt64x128x32_lt8x8_lw2x4_lr2x2_ta1x1x1x8_1x4x1x64_tb1x1x2x8_1x4x1x64_end:
    s_waitcnt lgkmcnt(0)
    s_barrier
    ds_read_b128 v[v_b:v_b+3], v[v_sld_b_os] offset:0
    ds_read_b128 v[v_a:v_a+3], v[v_sld_a_os] offset:0
    ds_read_b128 v[v_a+4:v_a+4+3], v[v_sld_a_os] offset:512
    ds_read_b128 v[v_b+4:v_b+4+3], v[v_sld_b_os] offset:1024
    
    
    s_waitcnt lgkmcnt(2)
    .v_lanegroup_dotx_fp16_8x8x8 v_c,v_a,v_b
    s_waitcnt lgkmcnt(1)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+16,v_a+4,v_b
    ds_read_b128 v[v_b:v_b+3], v[v_sld_b_os] offset:0+0*2048+2048
    s_waitcnt lgkmcnt(1)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+8,v_a,v_b+4
    ds_read_b128 v[v_a:v_a+3], v[v_sld_a_os] offset:0+1*1024+0
    .v_lanegroup_dotx_fp16_8x8x8 v_c+24,v_a+4,v_b+4
    ds_read_b128 v[v_a+4:v_a+4+3], v[v_sld_a_os] offset:0+1*1024+512
    ds_read_b128 v[v_b+4:v_b+4+3], v[v_sld_b_os] offset:0+1*2048+1024
    s_waitcnt lgkmcnt(2)
    .v_lanegroup_dotx_fp16_8x8x8 v_c,v_a,v_b
    s_waitcnt lgkmcnt(1)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+16,v_a+4,v_b
    ds_read_b128 v[v_b:v_b+3], v[v_sld_b_os] offset:0+1*2048+2048
    s_waitcnt lgkmcnt(1)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+8,v_a,v_b+4
    ds_read_b128 v[v_a:v_a+3], v[v_sld_a_os] offset:0+2*1024+0
    .v_lanegroup_dotx_fp16_8x8x8 v_c+24,v_a+4,v_b+4
    ds_read_b128 v[v_a+4:v_a+4+3], v[v_sld_a_os] offset:0+2*1024+512
    ds_read_b128 v[v_b+4:v_b+4+3], v[v_sld_b_os] offset:0+2*2048+1024
    s_waitcnt lgkmcnt(2)
    .v_lanegroup_dotx_fp16_8x8x8 v_c,v_a,v_b
    s_waitcnt lgkmcnt(1)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+16,v_a+4,v_b
    ds_read_b128 v[v_b:v_b+3], v[v_sld_b_os] offset:0+2*2048+2048
    s_waitcnt lgkmcnt(1)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+8,v_a,v_b+4
    ds_read_b128 v[v_a:v_a+3], v[v_sld_a_os] offset:0+3*1024+0
    .v_lanegroup_dotx_fp16_8x8x8 v_c+24,v_a+4,v_b+4
    ds_read_b128 v[v_a+4:v_a+4+3], v[v_sld_a_os] offset:0+3*1024+512
    ds_read_b128 v[v_b+4:v_b+4+3], v[v_sld_b_os] offset:0+3*2048+1024
    s_waitcnt lgkmcnt(2)
    .v_lanegroup_dotx_fp16_8x8x8 v_c,v_a,v_b
    s_waitcnt lgkmcnt(1)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+16,v_a+4,v_b
    s_waitcnt lgkmcnt(0)
    .v_lanegroup_dotx_fp16_8x8x8 v_c+8,v_a,v_b+4
    .v_lanegroup_dotx_fp16_8x8x8 v_c+24,v_a+4,v_b+4
    
    
    
    
    
    ; coalescing store, mapping:c_m:8x1-1x2-1x2-2x1, c_n:1x8-1x4-1x2-2x1, a_m:1x8, a_n:1x8, a_k:2x1
    ; coalescing_groups:1, num_dword_per_group:32, block_size:256
    ; gemm_co_prev_desc:[2, 2, 2, 1, 8, 128], gemm_co_split_lengths:[2, 2, 2, 1, 8, 2, 2, 4, 8, 1], gemm_co_post_desc:[1, 32, 2, 128, 1]
    s_lshl_b32 s[s_out_stride_k], s[s_out_stride_k], 1
    s_barrier
    s_barrier
    v_cvt_f16_f32 v[v_c], v[v_c]
    v_cvt_f16_f32_sdwa v[v_c], v[v_c+1]  dst_sel:WORD_1
    v_cvt_f16_f32 v[v_c+1], v[v_c+2]
    v_cvt_f16_f32_sdwa v[v_c+1], v[v_c+3]  dst_sel:WORD_1
    v_cvt_f16_f32 v[v_c+2], v[v_c+4]
    v_cvt_f16_f32_sdwa v[v_c+2], v[v_c+5]  dst_sel:WORD_1
    v_cvt_f16_f32 v[v_c+3], v[v_c+6]
    v_cvt_f16_f32_sdwa v[v_c+3], v[v_c+7]  dst_sel:WORD_1
    ds_write_b128 v[v_co_sst], v[v_c:v_c+3] 
    v_cvt_f16_f32 v[v_c+8], v[v_c+8]
    v_cvt_f16_f32_sdwa v[v_c+8], v[v_c+9]  dst_sel:WORD_1
    v_cvt_f16_f32 v[v_c+9], v[v_c+10]
    v_cvt_f16_f32_sdwa v[v_c+9], v[v_c+11]  dst_sel:WORD_1
    v_cvt_f16_f32 v[v_c+10], v[v_c+12]
    v_cvt_f16_f32_sdwa v[v_c+10], v[v_c+13]  dst_sel:WORD_1
    v_cvt_f16_f32 v[v_c+11], v[v_c+14]
    v_cvt_f16_f32_sdwa v[v_c+11], v[v_c+15]  dst_sel:WORD_1
    ds_write_b128 v[v_co_sst], v[v_c+8:v_c+8+3] offset:1024
    v_cvt_f16_f32 v[v_c+16], v[v_c+16]
    v_cvt_f16_f32_sdwa v[v_c+16], v[v_c+17]  dst_sel:WORD_1
    v_cvt_f16_f32 v[v_c+17], v[v_c+18]
    v_cvt_f16_f32_sdwa v[v_c+17], v[v_c+19]  dst_sel:WORD_1
    v_cvt_f16_f32 v[v_c+18], v[v_c+20]
    v_cvt_f16_f32_sdwa v[v_c+18], v[v_c+21]  dst_sel:WORD_1
    v_cvt_f16_f32 v[v_c+19], v[v_c+22]
    v_cvt_f16_f32_sdwa v[v_c+19], v[v_c+23]  dst_sel:WORD_1
    ds_write_b128 v[v_co_sst], v[v_c+16:v_c+16+3] offset:8192
    v_cvt_f16_f32 v[v_c+24], v[v_c+24]
    v_cvt_f16_f32_sdwa v[v_c+24], v[v_c+25]  dst_sel:WORD_1
    v_cvt_f16_f32 v[v_c+25], v[v_c+26]
    v_cvt_f16_f32_sdwa v[v_c+25], v[v_c+27]  dst_sel:WORD_1
    v_cvt_f16_f32 v[v_c+26], v[v_c+28]
    v_cvt_f16_f32_sdwa v[v_c+26], v[v_c+29]  dst_sel:WORD_1
    v_cvt_f16_f32 v[v_c+27], v[v_c+30]
    v_cvt_f16_f32_sdwa v[v_c+27], v[v_c+31]  dst_sel:WORD_1
    ds_write_b128 v[v_co_sst], v[v_c+24:v_c+24+3] offset:9216
    s_mov_b32 s[s_tmp], 0   ; i_m:0(i_m0:0,i_m1:0, fold_m:8)
    v_lshlrev_b32 v[v_co_sub_m_index], 3, v[v_co_sub_m_index]
    v_add_nc_u32 v[v_out_ik], s[s_block_gtc_ik], v[v_co_sub_m_index]
    v_mov_b32 v[v_tmp], v[v_out_ik]
    s_waitcnt lgkmcnt(0)
    s_barrier
    ;   load from lds, i_ssgroup:0, num_sld_issues_per_ssgroup:4
    v_cmpx_gt_u32 256, v[v_coalescing_store_index]
    ds_read_b128 v[v_c:v_c+3], v[v_co_sld] offset:0
    ds_read_b128 v[v_c+4:v_c+4+3], v[v_co_sld] offset:4096
    ds_read_b128 v[v_c+8:v_c+8+3], v[v_co_sld] offset:8192
    ds_read_b128 v[v_c+12:v_c+12+3], v[v_co_sld] offset:12288
    v_cmp_eq_i32 1, v[v_out_flag]
    s_and_saveexec_b64 s[s_tmp+4:s_tmp+5], vcc
    ;   store to global, m index start:0
    s_waitcnt lgkmcnt(3)
    v_cmp_gt_u32 s[s_k], v[v_tmp]
    s_and_saveexec_b64 s[s_tmp+4:s_tmp+5], vcc
    buffer_store_dwordx4 v[v_c:v_c+3], v[v_out_os], s[s_p_out:s_p_out+3], s[s_tmp] offen offset:0
    s_or_b64 exec, exec, s[s_tmp+4:s_tmp+5]
    s_mul_i32 s[s_tmp], 2, s[s_out_stride_k]   ; i_m:16(i_m0:0,i_m1:0, fold_m:8)
    v_add_nc_u32 v[v_tmp], 16, v[v_out_ik]
    s_waitcnt lgkmcnt(2)
    v_cmp_gt_u32 s[s_k], v[v_tmp]
    s_and_saveexec_b64 s[s_tmp+4:s_tmp+5], vcc
    buffer_store_dwordx4 v[v_c+4:v_c+4+3], v[v_out_os], s[s_p_out:s_p_out+3], s[s_tmp] offen offset:0
    s_or_b64 exec, exec, s[s_tmp+4:s_tmp+5]
    s_mul_i32 s[s_tmp], 4, s[s_out_stride_k]   ; i_m:32(i_m0:0,i_m1:0, fold_m:8)
    v_add_nc_u32 v[v_tmp], 32, v[v_out_ik]
    s_waitcnt lgkmcnt(1)
    v_cmp_gt_u32 s[s_k], v[v_tmp]
    s_and_saveexec_b64 s[s_tmp+4:s_tmp+5], vcc
    buffer_store_dwordx4 v[v_c+8:v_c+8+3], v[v_out_os], s[s_p_out:s_p_out+3], s[s_tmp] offen offset:0
    s_or_b64 exec, exec, s[s_tmp+4:s_tmp+5]
    s_mul_i32 s[s_tmp], 6, s[s_out_stride_k]   ; i_m:48(i_m0:0,i_m1:0, fold_m:8)
    v_add_nc_u32 v[v_tmp], 48, v[v_out_ik]
    s_waitcnt lgkmcnt(0)
    v_cmp_gt_u32 s[s_k], v[v_tmp]
    s_and_saveexec_b64 s[s_tmp+4:s_tmp+5], vcc
    buffer_store_dwordx4 v[v_c+12:v_c+12+3], v[v_out_os], s[s_p_out:s_p_out+3], s[s_tmp] offen offset:0
    s_or_b64 exec, exec, s[s_tmp+4:s_tmp+5]
    s_mov_b64 exec, -1
L_igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_bx0_ex0_bt64x128x32_lt8x8_lw2x4_lr2x2_ta1x1x1x8_1x4x1x64_tb1x1x2x8_1x4x1x64_out:
    s_endpgm
.rodata
.p2align 6
.amdhsa_kernel igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_bx0_ex0_bt64x128x32_lt8x8_lw2x4_lr2x2_ta1x1x1x8_1x4x1x64_tb1x1x2x8_1x4x1x64
    .amdhsa_group_segment_fixed_size 32768
    .amdhsa_user_sgpr_kernarg_segment_ptr 1
    .amdhsa_system_sgpr_workgroup_id_x 1
    .amdhsa_system_sgpr_workgroup_id_y 1
    .amdhsa_system_sgpr_workgroup_id_z 1
    .amdhsa_system_vgpr_workitem_id 0
    .amdhsa_next_free_vgpr 92
    .amdhsa_next_free_sgpr 78
    .amdhsa_ieee_mode 0
    .amdhsa_dx10_clamp 0
    .amdhsa_wavefront_size32 1
    .amdhsa_workgroup_processor_mode 1
.end_amdhsa_kernel

.amdgpu_metadata
---
amdhsa.version: [ 1, 0 ]
amdhsa.kernels:
  - .name: igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_bx0_ex0_bt64x128x32_lt8x8_lw2x4_lr2x2_ta1x1x1x8_1x4x1x64_tb1x1x2x8_1x4x1x64
    .symbol: igemm_fwd_gtcn2_nchwc_cyxkc_fp16x8_bx0_ex0_bt64x128x32_lt8x8_lw2x4_lr2x2_ta1x1x1x8_1x4x1x64_tb1x1x2x8_1x4x1x64.kd
    .sgpr_count: 84
    .vgpr_count: 92
    .kernarg_segment_align: 8
    .kernarg_segment_size: 128
    .group_segment_fixed_size: 32768
    .private_segment_fixed_size: 0
    .wavefront_size: 32
    .reqd_workgroup_size : [256, 1, 1]
    .max_flat_workgroup_size: 256
    .args:
    - { .name: p_in      , .size: 8, .offset:   0, .value_kind: global_buffer, .value_type: f32, .address_space: global, .is_const: true}
    - { .name: p_wei     , .size: 8, .offset:   8, .value_kind: global_buffer, .value_type: f32, .address_space: global, .is_const: true}
    - { .name: p_out     , .size: 8, .offset:  16, .value_kind: global_buffer, .value_type: f32, .address_space: global, .is_const: false}
    - { .name: tile_hw   , .size: 4, .offset:  24, .value_kind: by_value, .value_type: i32}
    - { .name: ntile_hw  , .size: 4, .offset:  28, .value_kind: by_value, .value_type: i32}
    - { .name: hi        , .size: 4, .offset:  32, .value_kind: by_value, .value_type: i32}
    - { .name: wi        , .size: 4, .offset:  36, .value_kind: by_value, .value_type: i32}
    - { .name: n         , .size: 4, .offset:  40, .value_kind: by_value, .value_type: i32}
    - { .name: k         , .size: 4, .offset:  44, .value_kind: by_value, .value_type: i32}
    - { .name: c         , .size: 4, .offset:  48, .value_kind: by_value, .value_type: i32}
    - { .name: group     , .size: 4, .offset:  52, .value_kind: by_value, .value_type: i32}
    - { .name: gemm_k_split, .size: 4, .offset:  56, .value_kind: by_value, .value_type: i32}
    - { .name: ho        , .size: 4, .offset:  60, .value_kind: by_value, .value_type: i32}
    - { .name: wo        , .size: 4, .offset:  64, .value_kind: by_value, .value_type: i32}
    - { .name: stride_hw , .size: 4, .offset:  68, .value_kind: by_value, .value_type: i32}
    - { .name: dilation_hw, .size: 4, .offset:  72, .value_kind: by_value, .value_type: i32}
    - { .name: pad_hw    , .size: 4, .offset:  76, .value_kind: by_value, .value_type: i32}
    - { .name: wei_hw    , .size: 4, .offset:  80, .value_kind: by_value, .value_type: i32}
    - { .name: move_slice_k, .size: 4, .offset:  84, .value_kind: by_value, .value_type: i32}
    - { .name: magic_0   , .size: 4, .offset:  88, .value_kind: by_value, .value_type: i32}
    - { .name: magic_1   , .size: 4, .offset:  92, .value_kind: by_value, .value_type: i32}
    - { .name: magic_2   , .size: 4, .offset:  96, .value_kind: by_value, .value_type: i32}
    - { .name: magic_3   , .size: 4, .offset: 100, .value_kind: by_value, .value_type: i32}
    - { .name: magic_4   , .size: 4, .offset: 104, .value_kind: by_value, .value_type: i32}
    - { .name: magic_5   , .size: 4, .offset: 108, .value_kind: by_value, .value_type: i32}
    - { .name: magic_6   , .size: 4, .offset: 112, .value_kind: by_value, .value_type: i32}
    - { .name: magic_7   , .size: 4, .offset: 116, .value_kind: by_value, .value_type: i32}
    - { .name: shift_pack_0, .size: 4, .offset: 120, .value_kind: by_value, .value_type: i32}
    - { .name: shift_pack_1, .size: 4, .offset: 124, .value_kind: by_value, .value_type: i32}
...
.end_amdgpu_metadata
