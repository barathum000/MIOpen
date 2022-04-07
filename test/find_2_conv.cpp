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

#include "test.hpp"
#include "driver.hpp"
#include "get_handle.hpp"

#include <miopen/miopen.h>

#include <miopen/convolution.hpp>

#include <vector>

namespace miopen {
struct Find2Test : test_driver
{
    tensor<float> x;
    tensor<float> w;
    tensor<float> y;
    Allocator::ManageDataPtr x_dev;
    Allocator::ManageDataPtr w_dev;
    Allocator::ManageDataPtr y_dev;

    miopenProblemDirection_t direction;
    // --input 16,192,28,28 --weights 32,192,5,5 --filter 2,2,1,1,1,1,
    miopen::ConvolutionDescriptor filter = {
        2, miopenConvolution, miopenPaddingDefault, {1, 1}, {1, 1}, {1, 1}};

    Find2Test()
    {
        add(direction,
            "direction",
            generate_data({
                miopenProblemDirectionForward,
                miopenProblemDirectionBackward,
                miopenProblemDirectionBackwardWeight,
            }));
    }

    void run() { TestConv(); }

private:
    void TestConv()
    {
        auto& handle_deref = get_handle();

        x = tensor<float>{16, 192, 28, 28}.generate(tensor_elem_gen_integer{17});
        w = tensor<float>{32, 192, 5, 5}.generate(tensor_elem_gen_integer{17});
        y = tensor<float>{filter.GetForwardOutputTensor(x.desc, w.desc)};

        x_dev = handle_deref.Write(x.data);
        w_dev = handle_deref.Write(w.data);
        y_dev = handle_deref.Write(y.data);

        miopenHandle_t handle;
        miopenProblem_t problem;

        deref(&handle) = &handle_deref;
        EXPECT_EQUAL(miopenCreateProblem(&problem), miopenStatusSuccess);

        AddConvDescriptor(problem);
        AddConvTensorDescriptors(problem);

        std::ignore    = TestFindSolutions(handle, problem);
        auto solutions = TestFindSolutionsWithOptions(handle, problem);

        TestSolutionAttributes(solutions);
        TestRunSolutions(handle, solutions);

        EXPECT_EQUAL(miopenDestroyProblem(problem), miopenStatusSuccess);
    }

    void AddConvDescriptor(miopenProblem_t problem)
    {
        miopenConvolutionDescriptor_t conv;
        miopen::deref(&conv) = new ConvolutionDescriptor{filter};
        EXPECT_EQUAL(miopenSetProblemOperatorDescriptor(problem, conv, direction),
                     miopenStatusSuccess);
        EXPECT_EQUAL(miopenDestroyConvolutionDescriptor(conv), miopenStatusSuccess);
    }

    void AddConvTensorDescriptors(miopenProblem_t problem)
    {
        auto test_set_tensor_descriptor = [problem](miopenTensorName_t name,
                                                    const TensorDescriptor& desc) {
            miopenTensorDescriptor_t api_desc;
            miopen::deref(&api_desc) = new TensorDescriptor{desc};
            EXPECT_EQUAL(miopenSetProblemTensorDescriptor(problem, name, api_desc),
                         miopenStatusSuccess);
            EXPECT_EQUAL(miopenDestroyTensorDescriptor(api_desc), miopenStatusSuccess);
        };

        test_set_tensor_descriptor(miopenTensorConvolutionX, x.desc);
        test_set_tensor_descriptor(miopenTensorConvolutionW, w.desc);
        test_set_tensor_descriptor(miopenTensorConvolutionY, y.desc);
    }

    std::vector<miopenSolution_t> TestFindSolutions(miopenHandle_t handle, miopenProblem_t problem)
    {
        auto solutions = std::vector<miopenSolution_t>{};
        std::size_t found;

        solutions.resize(100);

        EXPECT_EQUAL(miopenFindSolutions(
                         handle, problem, nullptr, solutions.data(), &found, solutions.size()),
                     miopenStatusSuccess);
        EXPECT_OP(found, >=, 0);

        solutions.resize(found);
        return solutions;
    }

    std::vector<miopenSolution_t> TestFindSolutionsWithOptions(miopenHandle_t handle,
                                                               miopenProblem_t problem)
    {
        auto solutions    = std::vector<miopenSolution_t>{};
        std::size_t found = 0;

        solutions.resize(100);

        const auto search_values = std::vector<int>({0, 1});
        const auto workspace_limit_values =
            std::vector<std::size_t>({std::numeric_limits<std::size_t>::max(), 0});

        for(const auto search : search_values)
            for(const auto workspace_limit : workspace_limit_values)
            {
                miopenSearchOptions_t options;

                const auto checked_set_options = [&](auto option, auto value) {
                    using Type = decltype(value);
                    EXPECT_EQUAL(miopenSetSearchOption(options, option, sizeof(Type), &value),
                                 miopenStatusSuccess);
                };

                EXPECT_EQUAL(miopenCreateSearchOptions(&options), miopenStatusSuccess);
                checked_set_options(miopenSearchOptionExhaustiveSearch, search);
                checked_set_options(miopenSearchOptionResultsOrder, miopenSearchResultsOrderByTime);
                checked_set_options(miopenSearchOptionWorkspaceLimit, workspace_limit);

                EXPECT_EQUAL(
                    miopenFindSolutions(
                        handle, problem, options, solutions.data(), &found, solutions.size()),
                    miopenStatusSuccess);

                EXPECT_EQUAL(miopenDestroySearchOptions(options), miopenStatusSuccess);
            }

        EXPECT_OP(found, >=, 0);
        solutions.resize(found);
        return solutions;
    }

    void TestSolutionAttributes(const std::vector<miopenSolution_t>& solutions)
    {
        for(const auto& solution : solutions)
        {
            const auto checked_get_attr = [&](auto name, auto& value) {
                using Type = std::remove_reference_t<decltype(value)>;
                EXPECT_EQUAL(
                    miopenGetSolutionAttribute(solution, name, sizeof(Type), &value, nullptr),
                    miopenStatusSuccess);
            };

            float time;
            std::size_t workspace_size;
            checked_get_attr(miopenSolutionAttributeTime, time);
            checked_get_attr(miopenSolutionAttributeWorkspaceSize, workspace_size);
        }
    }

    void TestRunSolutions(miopenHandle_t handle, std::vector<miopenSolution_t>& solutions)
    {
        miopenTensorName_t names[3] = {
            miopenTensorConvolutionX, miopenTensorConvolutionW, miopenTensorConvolutionY};
        void* buffers[3] = {x_dev.get(), w_dev.get(), y_dev.get()};

        miopenTensorDescriptor_t x_desc, w_desc, y_desc;
        miopen::deref(&x_desc)                  = new TensorDescriptor{x.desc};
        miopen::deref(&w_desc)                  = new TensorDescriptor{w.desc};
        miopen::deref(&y_desc)                  = new TensorDescriptor{y.desc};
        miopenTensorDescriptor_t descriptors[3] = {x_desc, w_desc, y_desc};

        for(const auto& solution : solutions)
        {
            TestRunSolution(handle, solution, names, descriptors, buffers);

            // Save-load cycle
            std::size_t solution_size;
            EXPECT_EQUAL(miopenGetSolutionSize(solution, &solution_size), miopenStatusSuccess);

            auto solution_binary = std::vector<char>{};
            solution_binary.resize(solution_size);

            EXPECT_EQUAL(miopenSaveSolution(solution, solution_binary.data()), miopenStatusSuccess);
            EXPECT_EQUAL(miopenDestroySolution(solution), miopenStatusSuccess);

            miopenSolution_t read_solution;
            EXPECT_EQUAL(
                miopenLoadSolution(&read_solution, solution_binary.data(), solution_binary.size()),
                miopenStatusSuccess);

            TestRunSolution(handle, read_solution, names, descriptors, buffers);
            EXPECT_EQUAL(miopenDestroySolution(read_solution), miopenStatusSuccess);
        }

        EXPECT_EQUAL(miopenDestroyTensorDescriptor(x_desc), miopenStatusSuccess);
        EXPECT_EQUAL(miopenDestroyTensorDescriptor(w_desc), miopenStatusSuccess);
        EXPECT_EQUAL(miopenDestroyTensorDescriptor(y_desc), miopenStatusSuccess);
    }

    void TestRunSolution(miopenHandle_t handle,
                         miopenSolution_t solution,
                         miopenTensorName_t* names,
                         miopenTensorDescriptor_t* descriptors,
                         void** buffers)
    {
        auto& handle_deref = get_handle();

        const auto checked_get_attr = [&](auto name, auto& value) {
            using Type = std::remove_reference_t<decltype(value)>;
            EXPECT_EQUAL(miopenGetSolutionAttribute(solution, name, sizeof(Type), &value, nullptr),
                         miopenStatusSuccess);
        };

        std::size_t workspace_size;
        checked_get_attr(miopenSolutionAttributeWorkspaceSize, workspace_size);

        auto workspace     = std::vector<char>(workspace_size);
        auto workspace_dev = workspace_size != 0 ? handle_deref.Write(workspace) : nullptr;

        const auto checked_run_solution = [&](auto&& descriptors_) {
            EXPECT_EQUAL(miopenRunSolution(handle,
                                           solution,
                                           3,
                                           names,
                                           descriptors_,
                                           buffers,
                                           workspace_dev.get(),
                                           workspace_size),
                         miopenStatusSuccess);
        };

        // Without descriptors
        checked_run_solution(nullptr);
        // With descriptors
        checked_run_solution(descriptors);
    }
};
} // namespace miopen

int main(int argc, const char* argv[]) { test_drive<miopen::Find2Test>(argc, argv); }
