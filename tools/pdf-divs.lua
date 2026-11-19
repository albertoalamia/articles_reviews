-- PDF rendering of the review's tagged divs. HTML gets them through theme.scss; LaTeX has no CSS,
-- so the evidence tag becomes a bold label and the verdict box an indented block. No effect on HTML.
local labels = {
  ["evidence-confirmed"]  = "Confirmed.",
  ["evidence-inferred"]   = "Inferred.",
  ["evidence-needs-data"] = "Needs data.",
}

function Div(el)
  if not FORMAT:match("latex") then return nil end
  for cls, lab in pairs(labels) do
    if el.classes:includes(cls) then
      local label = pandoc.Strong({ pandoc.Str(lab) })
      local first = el.content[1]
      if first and first.t == "Para" then
        first.content:insert(1, pandoc.Space())
        first.content:insert(1, label)
      else
        el.content:insert(1, pandoc.Para({ label }))
      end
      el.classes = pandoc.List({})
      return { pandoc.RawBlock("latex", "\\begin{quote}\\small"), el, pandoc.RawBlock("latex", "\\end{quote}") }
    end
  end
  if el.classes:includes("verdict") then
    el.classes = pandoc.List({})
    return { pandoc.RawBlock("latex", "\\begin{quote}"), el, pandoc.RawBlock("latex", "\\end{quote}") }
  end
  return nil
end
