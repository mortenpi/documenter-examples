import Documenter, MarkdownAST, TOML

# This digs deeper into Documenter internals, by defining a new at-block that gets evaluated
# during the Documenter "expansion" step. The expansion of CollapsedExample re-uses the
# standard runner for @example blocks, but creates a custom MarkdownAST block, which then
# is dispatched on in the HTMLWriter (domify).
abstract type CustomExpander <: Documenter.Expanders.ExpanderPipeline end
Documenter.Selectors.matcher(::Type{CustomExpander}, node, page, doc) = Documenter.iscode(node, r"^@custom")
Documenter.Selectors.order(::Type{CustomExpander}) = 7.9
function Documenter.Selectors.runner(::Type{CustomExpander}, node, page, doc)
    m = match(r"^@custom(\s+(\w+))?", node.element.info)
    isnothing(m) && error("Invalid @custom block: $(node.element.info)")
    node.element = CustomBlock(m[2], TOML.parse(node.element.code))
    return
end
# This is the MarkdownAST element that replaces Documenter.MultiOutput so that we could
# dispatch on it in the writer.
struct CustomBlock <: Documenter.AbstractDocumenterBlock
    type :: String
    settings :: Dict
end
function Documenter.HTMLWriter.domify(dctx::Documenter.HTMLWriter.DCtx, node::MarkdownAST.Node, block::CustomBlock)
    Documenter.DOM.@tags img
    if block.type == "img"
        # In this case, we interpret the at-custom to contain the values for the
        # style attribute of the Julia logo image.
        style = join(("$k: $v" for (k, v) in pairs(block.settings)), "; ")
        return img[
            :class => "custom",
            :style => style,
            :src=>"https://docs.julialang.org/en/v1/assets/logo.svg"
        ]()
    else
        error("Invalid type: $(block.type)")
    end
end

Documenter.MDFlatten.mdflatten(io, node::MarkdownAST.Node, e::CustomBlock) = nothing
