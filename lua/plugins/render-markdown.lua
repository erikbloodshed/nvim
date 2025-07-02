return {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    config = function()
        require('render-markdown').setup({
            anti_conceal = { enabled = false },
        })
    end
}
