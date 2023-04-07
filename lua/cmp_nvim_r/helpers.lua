local ts = vim.treesitter
local ts_utils = require"nvim-treesitter.ts_utils"
local queries = require"cmp_nvim_r.queries"

P = function(v)
    print(vim.inspect(v))
end

Pm = function(v)
    print(vim.inspect(getmetatable(v)))
end

Pt = function(node, bufnr)
    P(ts.query.get_node_text(node, 1))
end

-- Tree navigation and general {{{

-- Get parent of node with root as parent
local get_branch
get_branch = function(node)
    if node:type() == "program" then
        return node
    end
    if node:parent():type() == "program" then
        return node
    else
      return get_branch(node:parent())
    end
end

--}}}

-- Pipelines {{{

-- Check if node is in pipeline
local is_in_pipeline
is_in_pipeline = function(node, parent, bufnr)
    for _, captures, _ in queries.pipeline:iter_matches(parent, bufnr) do
        if ts_utils.is_parent(captures[2], node) then return true end
    end
    return false
end

-- Find all pipelines containing node
-- Identify outermost and innermost pipelines
local get_pipelines
get_pipelines = function(node, parent, bufnr)
    local pipes = {}
    local parents = {}
    local innermost = nil
    local outermost = nil

    -- get pipelines in parent
    for _, captures, _ in queries.pipeline:iter_matches(parent, bufnr) do
        table.insert(pipes, captures[2])
    end

    -- get top-level (parents) in parent
    for i = 1, #pipes do
        local is_parent = ts_utils.is_parent(pipes[i], node)
        local is_top_level = true
        for j = 1, #pipes do
            if pipes[i]:parent() == pipes[j] then
                is_top_level = false
            end
        end
        if is_top_level and is_parent then
            table.insert(parents, pipes[i])
        end
    end

    -- find innermost and outermost pipeline
    for i = #parents, 1, -1 do
        local is_innermost = true
        local is_outermost = true
        for j = 1, #parents do
            if i == j then goto continue
            elseif ts_utils.is_parent(parents[i], parents[j]) then
                is_innermost = false
            elseif ts_utils.is_parent(parents[j], parents[i]) then
                is_outermost = false
            end
            ::continue::
        end
        if is_innermost then innermost = parents[i] end
        if is_outermost then outermost = parents[i] end
    end

    return {raw = pipes, parents = parents, innermost = innermost, outermost = outermost}
end

-- Get leftmost object in a pipeline
local get_pipeline_source
get_pipeline_source = function(node)
    local left = node:field("left")
    if #left > 1 then return nil, "Multiple children named left:"
    elseif left[1] then return get_pipeline_source(left[1])
    else return node
    end
end

--- }}}

-- Functions and arguments {{{

local get_parent_calls -- only care about functions with data arguments
get_parent_calls = function(node, parent, bufnr)
    local calls = {}
    local parents = {}
    local outermost = nil
    local innermost = nil

    -- get functions with possible data arguments in parents
    for _, captures, _ in queries.data_arg:iter_matches(parent, bufnr) do
        table.insert(calls, captures[3])
    end

    -- get parents
    for i = 1, #calls do
        local is_parent = ts_utils.is_parent(calls[i], node)
        if is_parent then
            table.insert(parents, calls[i])
        end
    end

    -- remove duplicate
    for i = #parents, 1, -1 do
        for j = 1, #parents do
            if i ~= j and parents[i] == parents[j] then
                table.remove(parents, i)
            end
        end
    end

    -- find innermost and outermost calls
    for i = #parents, 1, -1 do
        local is_innermost = true
        local is_outermost = true
        for j = 1, #parents do
            if i == j then goto continue
            elseif ts_utils.is_parent(parents[i], parents[j]) then
                is_innermost = false
            elseif ts_utils.is_parent(parents[j], parents[i]) then
                is_outermost = false
            end
            ::continue::
        end
        if is_innermost then innermost = parents[i] end
        if is_outermost then outermost = parents[i] end
    end

    return {raw = calls, parents = parents, innermost = innermost, outermost = outermost}
end

local get_call_fields
get_call_fields = function(node)
    local ret = {}
    local func_node = node:field("function")[1]

    if func_node:type() == "identifier" then
        ret = {call = node, fun = func_node}
    elseif func_node:type() == "namespace_get" then
        ret = {
            call = node,
            fun = func_node:field("function")[1],
            pkg = func_node:field("namespace")[1]
        }
    end

    return ret
end

local get_parent_function
get_parent_function = function(node)
    if node:type() == "call" then
        local ret = {}
        local func_node = node:field("function")[1]

        if func_node:type() == "identifier" then
            ret = {call = node, fun = func_node}
        elseif func_node:type() == "namespace_get" then
            ret = {
                call = node,
                fun = func_node:field("function")[1],
                pkg = func_node:field("namespace")[1]
            }
        end

        return ret

    elseif node:parent() then return get_parent_function(node:parent())
    end
end

local is_in_function
is_in_function = function(node)
    if not node:parent() then return false
    elseif node:type() == "call" then return true
    else return is_in_function(node:parent())
    end
end

local get_data_args
get_data_args = function(node, bufnr)
    local ret = {}
    for _, captures, _ in queries.data_arg:iter_matches(node, bufnr) do
        if captures[3] == node then table.insert(ret, captures[2]) end
    end
    return ret
end

--- }}}

local M = {
    get_branch = get_branch,
    is_in_pipeline = is_in_pipeline,
    get_pipelines = get_pipelines,
    get_pipeline_source = get_pipeline_source,
    get_call_fields = get_call_fields,
    is_in_function = is_in_function,
    get_data_args = get_data_args,
    get_parent_calls = get_parent_calls,
    get_parent_function = get_parent_function
}

return M
