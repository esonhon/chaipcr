## calibration.jl
##
## calibration procedure:
## 1. multichannel deconvolution
## 2. adjust well-to-well variation in absolute fluorescence values

import DataStructures.OrderedDict
import Memento: debug, error


## function: perform deconvolution and adjust well-to-well variation in absolute fluorescence
function calibrate(
    fr_ary3                 ::AbstractArray,        ## array of raw fluorescence by cycle, well, channel
    dcv                     ::Bool,                 ## signal to perform multi-channel deconvolution
    channel_nums            ::AbstractVector,       ## vector of channel numbers
    ## remove MySql dependency
    # db_conn ::MySQL.MySQLHandle, ## `db_conn_default` is defined in "__init__.jl"
    # calib_info ::Union{Integer,OrderedDict},
    # well_nums_found_in_fr ::AbstractVector,
    # well_nums_in_req ::AbstractVector=[],
    calib_data              ::Associative,          ## calibration dataset
    well_nums_found_in_fr   ::AbstractVector,       ## vector of well numbers
    dye_in                  ::Symbol = :FAM,
    dyes_2bfild             ::AbstractVector =[];
    aw_out_format           ::Symbol = :both        ## :array, :dict, :both
)
    debug(logger, "at calibrate()")

    ## remove MySql dependency
    # calib_info = ensure_ci(db_conn, calib_info)
    # wva_data, wva_well_nums = prep_adj_w2wvaf(db_conn, calib_info, well_nums_in_req, dye_in, dyes_2bfild)

    ## assume without checking that we are using all the wells, all the time
    const well_nums_in_req = calib_data |> num_wells |> from(0) |> collect
    #
    ## prepare data to adjust well-to-well variation in absolute fluorescence values
    const (wva_data, wva_well_nums) =
        prep_normalize(calib_data, well_nums_in_req, dye_in, dyes_2bfild)
    #
    ## overwrite the dummy well_nums
    wva_well_nums = well_nums_found_in_fr
    #
    const num_channels = length(channel_nums)
    # if length(well_nums_found_in_fr) == 0
    #     well_nums_found_in_fr = wva_well_nums
    # end

    ## remove MySql dependency
    #
    # wva_well_idc_wfluo = find(wva_well_nums) do wva_well_num
    #     wva_well_num in well_nums_found_in_fr
    # end ## do wva_well_num

    ## issue:
    ## we can't match well numbers between calibration data and experimental data
    ## because we don't have that information for the calibration data
    const wva_well_idc_wfluo = wva_well_nums |> length |> from(1) |> collect
    debug(logger, repr(wva_well_idc_wfluo))

    ## subtract background
    ## mw = minus water
    const mw_ary3 =
        cat(3,
            ## devectorized code avoids transposition
            [
                [   fr_ary3[u,w,c] - wva_data[:water][c][wva_well_idc_wfluo][w]
                    for u in 1:size(fr_ary3, 1),
                        w in wva_well_idc_wfluo     ]
                for c in 1:num_channels                 ]...)

    const (k4dcv, dcvd_ary3) =
        if dcv
            ## addition with flexible ratio instead of deconvolution (commented out)
            # k_inv_vec = fill(reshape(DataArray([1, 0, 1, 0]), 2, 2), 16)

            ## removing MySql dependency
            # k4dcv, dcvd_ary3 = deconvolute(
            #     1. * mw_ary3, channel_nums, wva_well_idc_wfluo, db_conn, calib_info, well_nums_in_req;
            #     out_format="array")
            deconvolute(
                1. * mw_ary3,
                channel_nums,
                wva_well_idc_wfluo,
                calib_data,
                well_nums_in_req;
                out_format = :array)
        else ## !dcv
            K4Deconv(), mw_ary3
        end
    #
    const dcvd_aw_dict =
        OrderedDict(
            map(range(1, num_channels)) do channel_i
                channel_nums[channel_i] =>
                    normalize(
                        dcvd_ary3[:, :, channel_i],
                        wva_data,
                        wva_well_idc_wfluo,
                        channel_i;
                        minus_water = false)
            end) ## do channel_i

    ## format output
    ## the following line of code needs the keys of dcvd_aw_dict to be in sort order
    dcvd_aw_ary3() = cat(3, values(dcvd_aw_dict)...)
    const dcvd_aw =
        if      (aw_out_format == :array) tuple(dcvd_aw_ary3())
        elseif  (aw_out_format == :dict)  tuple(dcvd_aw_dict)
        elseif  (aw_out_format == :both)  tuple(dcvd_aw_ary3(), dcvd_aw_dict)
        else                              throw(ArgumentException(
                                              "`aw_out_format` must be :array, :dict or :both"))
        end ## if
    return (mw_ary3, k4dcv, dcvd_ary3, wva_data, wva_well_nums, dcvd_aw...)
end ## calibrate()


## unused function
# function calib_calib(
#     ## remove MySql dependency
#     #
#     # db_conn_1 ::MySQL.MySQLHandle,
#     # db_conn_2 ::MySQL.MySQLHandle,
#     # calib_info_1 ::OrderedDict,
#     # calib_info_2 ::OrderedDict,
#     # well_nums_1 ::AbstractVector=[],
#     # well_nums_2 ::AbstractVector=[];
#     dye_in      ::Symbol =:FAM,
#     dyes_2bfild ::AbstractVector =[]
# )
#     ## This function is expected to handle situations where `calib_info_1` and `calib_info_2`
#     ## have different combinations of wells, but the number of wells should be the same.
#     if length(well_nums_1) != length(well_nums_2)
#         throw(DimensionMismatch("length(well_nums_1) != length(well_nums_2)"))
#     end

#     ## remove MySql dependency
#     #
#     # calib_dict_1 = get_full_calib_data(db_conn_1, calib_info_1, well_nums_1)
#     # water_well_nums_1 = calib_dict_1["water"][2]
#     #
#     # calib_key_vec_1 = get_ordered_keys(calib_info_1)
#     # cd_key_vec_1 = calib_key_vec_1[2:end] ## cd = channel of dye. "water" is index 1 per original order.
#     # channel_nums_1 = map(cd_key_vec_1) do cd_key
#     #     parse(Int, split(cd_key, "_")[2])
#     # end
#
#     const ary2dcv_1 =
#         cat(1,
#             map(values(calib_dict_1)) do value_1
#                 reshape(transpose(fluo_data), 1, size(value_1[1])[2:-1:1]...)
#             end...) ## do value_1
#     const (mw_ary3_1, k4dcv_2, dcvd_ary3_1, wva_data_2, wva_well_nums_2, dcv_aw_ary3_1) =
#         dcv_aw(
#             ary2dcv_1,
#             true,
#             channel_nums_1,
#             db_conn_2,
#             calib_info_2,
#             well_nums_2,
#             well_nums_2,
#             dye_in,
#             dyes_2bfild;
#             aw_out_format = :array)
#     return CalibCalibOutput(
#         ary2dcv_1,
#         mw_ary3_1,
#         k4dcv_2,
#         dcvd_ary3_1,
#         wva_data_2,
#         dcv_aw_ary3_1)
# end ## calib_calib


## deprecated to remove MySql dependency
#
## get all the data from a calibration experiment, including data from all the channels for all the steps
# function get_full_calib_data(
#    db_conn::MySQL.MySQLHandle,
#    calib_info::OrderedDict,
#    well_nums::AbstractVector=[]
#    )
#
#    calib_info = ensure_ci(db_conn, calib_info)
#
#    calib_key_vec = get_ordered_keys(calib_info)
#    cd_key_vec = calib_key_vec[2:end] ## cd = channel of dye. "water" is index 1 per original order.
#    channel_nums = map(cd_key_vec) do cd_key
#        parse(Int, split(cd_key, "_")[2])
#    end
#    num_channels = length(channel_nums)
#
#    calib_dict = OrderedDict(map(calib_key_vec) do calib_key
#        exp_id = calib_info[calib_key]["calibration_id"]
#        step_id = calib_info[calib_key]["step_id"]
#        k_qry_2b = "
#            SELECT fluorescence_value, well_num, channel
#                FROM fluorescence_data
#                WHERE
#                    experiment_id = $exp_id AND
#                    step_id = $step_id AND
#                    cycle_num = 1 AND
#                    step_id is not NULL
#                    well_constraint
#                ORDER BY well_num, channel
#        "
#        calib_data_1key, calib_well_nums = get_mysql_data_well(
#            well_nums, k_qry_2b, db_conn, false
#        )
#        if length(well_nums) > 0 && Set(calib_well_nums) != Set(well_nums)
#            error(logger, "experiment $exp_id, step $step_id: calibration data is not found for all the wells requested")
#        end ## if
#        calib_data_1key_chwl = vcat(map(channel_nums) do channel
#            transpose(calib_data_1key[:fluorescence_value][calib_data_1key[:channel] .== channel])
#        end...) ## do channel. return an array where rows indexed by channels and columns indexed by wells
#
#        return calib_key => (calib_data_1key_chwl, calib_well_nums)
#    end)
#
#    return calib_dict ## share the same keys as `calib_info`
#
# end ## get_full_calib_data