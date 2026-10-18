// Draws the whole conversation tree into the sidebar: every line, nested under
// the line it answers. Clicking a line shows its branch, through `onPick(node)`.
// Learner lines carry their status as a colour; tutor lines that end the scene
// get a tick.
import { el } from "./dom.js";
import { ConversationTree } from "./tree.js";

export function createTreeView(pane, toggle, { onPick }) {
  toggle.addEventListener("click", () => {
    pane.hidden = !pane.hidden;
    toggle.setAttribute("aria-pressed", String(!pane.hidden));
  });

  function list(tree, parentId, onPath) {
    const children = tree.childrenOf(parentId);
    if (!children.length) return null;
    const ul = el("ul");
    for (const node of children) {
      const button = el("button", `node ${node.role}`, node.text);
      button.type = "button";
      button.title = node.text;
      button.classList.toggle("done", Boolean(node.done));
      button.classList.toggle("on-path", onPath.has(node.id));
      button.classList.toggle("active", node.id === tree.active.id);
      const status = ConversationTree.statusOf(node);
      if (status) button.classList.add(status);
      button.addEventListener("click", () => onPick(node));
      const item = el("li");
      item.append(button);
      const below = list(tree, node.id, onPath);
      if (below) item.append(below);
      ul.append(item);
    }
    return ul;
  }

  return {
    render(tree) {
      const onPath = new Set(tree.activePath.map((node) => node.id));
      pane.replaceChildren(list(tree, null, onPath));
      pane.querySelector(".active")?.scrollIntoView({ block: "nearest" });
    },
  };
}
