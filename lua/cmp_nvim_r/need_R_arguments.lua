local M = function(request)
    local resp = {
        pkg = nil,
        fnm = nil,
        firstobj = nil,
        listdf = nil
    }

    local ts = vim.treesitter
    local ts_utils = require"nvim-treesitter.ts_utils"
    local queries = require"cmp_nvim_r.queries"
    local helpers = require"cmp_nvim_r.helpers"

    -- Setup syntax tree
    local req_node = ts.get_node_at_pos(request.context.bufnr, request.context.cursor.line, request.context.cursor.character - 1, {}) -- node to left of cursor in insert mode
    -- local language_tree = ts.get_parser(request.context.bufnr, "r")
    -- local syntax_tree = language_tree:parse()
    -- local root = syntax_tree[1]:root()

    -- To avoid searching whole file
    local branch = helpers.get_branch(req_node)

    -- Move to helper?
    local text = function(node)
        if node then
            return ts.query.get_node_text(node, request.context.bufnr)
        else return nil end
    end

    -- Business logic
    if
        helpers.is_in_pipeline(req_node, branch, request.context.bufnr) and
        helpers.is_in_function(req_node)
    then
        local parent_call = helpers.get_parent_function(req_node)
        local pipelines = helpers.get_pipelines(req_node, branch, request.context.bufnr)
        local pipe_source = helpers.get_pipeline_source(pipelines.outermost)
        resp = {
            pkg  = text(parent_call.pkg),
            fnm  = text(parent_call.fun),
            firstobj = text(pipe_source),
            listdf = true
        }
    elseif helpers.is_in_function(req_node) then
        local parent_call = helpers.get_parent_function(req_node)
        local data_arg = helpers.get_data_args(parent_call.call, request.context.bufnr)
        resp = {
            pkg  = text(parent_call.pkg),
            fnm  = text(parent_call.fun),
            firstobj = text(data_arg[1]),
            listdf = true,
            test = data_arg,
        }
    end

    -- for debugging, remove
    Resp = resp
    return resp
end

return M
