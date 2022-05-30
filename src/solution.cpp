/*******************************************************************************
 *
 * MIT License
 *
 * Copyright (c) 2022 Advanced Micro Devices, Inc.
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

#include <miopen/solution.hpp>

#include <miopen/check_numerics.hpp>
#include <miopen/conv/data_invoke_params.hpp>
#include <miopen/conv/wrw_invoke_params.hpp>
#include <miopen/any_solver.hpp>

#include <nlohmann/json.hpp>

#include <boost/hof/match.hpp>

namespace miopen {

void Solution::Run(Handle& handle,
                   const std::unordered_map<miopenTensorName_t, RunInput>& inputs,
                   Data_t workspace,
                   std::size_t workspace_size)
{
    if(workspace_size < workspace_required)
        MIOPEN_THROW(miopenStatusBadParm,
                     GetSolver().ToString() + " requires at least " +
                         std::to_string(workspace_required) + " workspace, while " +
                         std::to_string(workspace_size) + " was provided");

    const auto run = boost::hof::match([&](const ConvolutionDescriptor& op_desc) {
        RunImpl(handle, inputs, workspace, workspace_size, op_desc);
    });

    boost::apply_visitor(run, problem.GetOperatorDescriptor());
}

void Solution::RunImpl(Handle& handle,
                       const std::unordered_map<miopenTensorName_t, RunInput>& inputs,
                       Data_t workspace,
                       std::size_t workspace_size,
                       const ConvolutionDescriptor& conv_desc)
{
    auto problem_ = GetProblem();

    const auto get_input_checked = [&](auto name, const std::string& name_str) {
        const auto& found = inputs.find(name);
        if(found == inputs.end())
            MIOPEN_THROW(miopenStatusInvalidValue,
                         "Problem is missing " + name_str + " tensor descriptor.");
        auto ret = found->second;
        if(!ret.descriptor.has_value())
            ret.descriptor = GetProblem().GetTensorDescriptorChecked(name, name_str);
        return ret;
    };

    auto x       = get_input_checked(miopenTensorConvolutionX, "miopenTensorConvolutionX");
    const auto w = get_input_checked(miopenTensorConvolutionW, "miopenTensorConvolutionW");
    auto y       = get_input_checked(miopenTensorConvolutionY, "miopenTensorConvolutionY");

    {
        if(conv_desc.mode == miopenTranspose)
        {
            problem_ = {};
            problem_.SetOperatorDescriptor(conv_desc);

            switch(GetProblem().GetDirection())
            {
            case miopenProblemDirectionForward:
                problem_.SetDirection(miopenProblemDirectionBackward);
                break;
            case miopenProblemDirectionBackward:
                problem_.SetDirection(miopenProblemDirectionForward);
                break;
            case miopenProblemDirectionBackwardWeight:
                problem_.SetDirection(miopenProblemDirectionBackwardWeight);
                break;
            }

            std::swap(x, y);

            problem_.RegisterTensorDescriptor(miopenTensorConvolutionX, *x.descriptor);
            problem_.RegisterTensorDescriptor(miopenTensorConvolutionW, *w.descriptor);
            problem_.RegisterTensorDescriptor(miopenTensorConvolutionY, *y.descriptor);
        }
    }

    if(miopen::CheckNumericsEnabled())
    {
        if(problem_.GetDirection() != miopenProblemDirectionBackward)
            miopen::checkNumericsInput(handle, *x.descriptor, x.buffer);
        if(problem_.GetDirection() != miopenProblemDirectionBackwardWeight)
            miopen::checkNumericsInput(handle, *w.descriptor, w.buffer);
        if(problem_.GetDirection() != miopenProblemDirectionForward)
            miopen::checkNumericsInput(handle, *y.descriptor, y.buffer);
    }

    const auto conv_problem = problem_.AsConvolution();

    Problem::ValidateGroupCount(*x.descriptor, *w.descriptor, conv_problem.GetConv());

    const auto invoke_ctx = [&]() -> AnyInvokeParams {
        switch(problem_.GetDirection())
        {
        case miopenProblemDirectionForward:
            return conv::DataInvokeParams(
                {*x.descriptor, x.buffer, *w.descriptor, w.buffer, *y.descriptor, y.buffer},
                workspace,
                workspace_size,
                conv_problem.GetConv().attribute.gfx90aFp16alt.GetFwd());
        case miopenProblemDirectionBackward:
            return conv::DataInvokeParams(
                {*y.descriptor, y.buffer, *w.descriptor, w.buffer, *x.descriptor, x.buffer},
                workspace,
                workspace_size,
                conv_problem.GetConv().attribute.gfx90aFp16alt.GetBwd());
        case miopenProblemDirectionBackwardWeight:
            return conv::WrWInvokeParams{
                {*y.descriptor, y.buffer, *x.descriptor, x.buffer, *w.descriptor, w.buffer},
                workspace,
                workspace_size,
                conv_problem.GetConv().attribute.gfx90aFp16alt.GetWrW()};
        default: MIOPEN_THROW(miopenStatusNotImplemented);
        }
    }();

    const auto net_cfg       = conv_problem.BuildConfKey();
    const auto found_invoker = handle.GetInvoker(net_cfg, GetSolver());

    const auto checkNumericsOutput_ = [&]() {
        if(miopen::CheckNumericsEnabled())
        {
            if(problem_.GetDirection() == miopenProblemDirectionBackward)
                miopen::checkNumericsOutput(handle, *x.descriptor, x.buffer);
            if(problem_.GetDirection() == miopenProblemDirectionBackwardWeight)
                miopen::checkNumericsOutput(handle, *w.descriptor, w.buffer);
            if(problem_.GetDirection() == miopenProblemDirectionForward)
                miopen::checkNumericsOutput(handle, *y.descriptor, y.buffer);
        }
    };

    if(found_invoker)
    {
        (*found_invoker)(handle, invoke_ctx);
        checkNumericsOutput_();
        return;
    }

    auto conv_ctx = ConvolutionContext{conv_problem, {&handle}};
    conv_ctx.DetectRocm();

    decltype(auto) db        = GetDb(conv_ctx);
    const auto conv_solution = GetSolver().GetSolver().FindSolution(conv_ctx, db, invoke_ctx);
    decltype(auto) invoker =
        handle.PrepareInvoker(*conv_solution.invoker_factory, conv_solution.construction_params);
    handle.RegisterInvoker(invoker, net_cfg, GetSolver().ToString());
    invoker(handle, invoke_ctx);
    checkNumericsOutput_();
}

void to_json(nlohmann::json& json, const Solution::SerializationMetadata& metadata)
{
    json = nlohmann::json{
        {"validation", metadata.validation_number},
        {"version", metadata.version},
    };
}
void from_json(const nlohmann::json& json, Solution::SerializationMetadata& metadata)
{
    json.at("validation").get_to(metadata.validation_number);
    json.at("version").get_to(metadata.version);
}

void to_json(nlohmann::json& json, const Solution& solution)
{
    json = nlohmann::json{
        {"header", Solution::SerializationMetadata::Current()},
        {"time", solution.time},
        {"workspace", solution.workspace_required},
        {"solver", solution.solver.ToString()},
        {"problem", solution.problem},
    };
}

void from_json(const nlohmann::json& json, Solution& solution)
{
    {
        const auto header = json.at("header").get<Solution::SerializationMetadata>();
        constexpr const auto check_header = Solution::SerializationMetadata::Current();

        if(header.validation_number != check_header.validation_number)
            MIOPEN_THROW(miopenStatusInvalidValue,
                         "Invalid buffer has been passed to the solution deserialization.");
        if(header.version != check_header.version)
            MIOPEN_THROW(
                miopenStatusInvalidValue,
                "Data from wrong version has been passed to the solution deserialization.");
    }

    json.at("time").get_to(solution.time);
    json.at("workspace").get_to(solution.workspace_required);
    solution.solver = json.at("solver").get<std::string>();
    json.at("problem").get_to(solution.problem);
}
} // namespace miopen