local M = {
    data_arg = vim.treesitter.parse_query('r', [[
        (call
            arguments: [
                (arguments
                    (default_argument
                        name: (identifier) @name (#any-of? @name "data" ".data")
                        value: (identifier) @data
                    )
                )
                (arguments .
                    (_ !name) @data
                )
            ]
        ) @call
    ]]),
    pipeline = vim.treesitter.parse_query('r', [[
        [
            (binary
                operator: (special) @_special (#eq? @_special "%>%")
            )
            (pipe)
        ] @pipeline
    ]])
}
return M
