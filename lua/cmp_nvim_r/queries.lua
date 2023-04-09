local M = {
    data_arg = vim.treesitter.query.parse('r', [[
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
    pipeline = vim.treesitter.query.parse('r', [[
        [
            (binary
                operator: (special) @_special (#eq? @_special "%>%")
            )
            (pipe)
        ] @pipeline
    ]])
}
return M
