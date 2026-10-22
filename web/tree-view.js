// Draws the whole conversation tree into the sidebar: every line, nested under
// the line it answers. Clicking a line rewinds the conversation to it, through
// `onPick(node)`.
// Learner lines carry their status as a colour; tutor lines that end the scene
// get a tick.
import { el } from "./dom.js";
import { ConversationTree } from "./tree.js";

export function createTreeView(pane, toggle, { onPick }) {
  toggle.addEventListener("click", () => {
    pane.hidden = !pane.hidden;
    toggle.setAttribute("aria-pressed", String(!pane.hidden));
  });

  // alternatives shown as their first line only; node ids repeat across
  // conversations, so they are forgotten when another one is shown
  const folded = new Set();
  let shownId = null;

  // Folds or unfolds the alternative `node`; hidden when there is nothing below it.
  function foldButton(tree, node) {
    const open = !folded.has(node.id);
    const button = el("button", "fold", open ? "▾" : "▸");
    button.type = "button";
    button.title = open ? "Fold this branch" : "Unfold this branch";
    button.setAttribute("aria-expanded", String(open));
    button.disabled = !tree.childrenOf(node.id).length;
    button.addEventListener("click", () => {
      if (open) folded.add(node.id);
      else folded.delete(node.id);
      render(tree);
    });
    return button;
  }

  function line(tree, node, onPath) {
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
    return item;
  }

  // The lines below `parentId` into `ul`: a single answer goes on in the same
  // column, only where there are several does each start an indented branch.
  function addLines(ul, tree, parentId, onPath) {
    const children = tree.childrenOf(parentId);
    const fork = children.length > 1;
    for (const node of children) {
      let column = ul;
      if (fork) {
        column = el("ul");
        const branch = el("li", "branch");
        branch.append(column);
        ul.append(branch);
      }
      const item = line(tree, node, onPath);
      if (fork) item.prepend(foldButton(tree, node));
      column.append(item);
      if (!fork || !folded.has(node.id)) addLines(column, tree, node.id, onPath);
    }
    return ul;
  }

  function render(tree) {
    if (tree.id !== shownId) folded.clear();
    shownId = tree.id;
    const onPath = new Set(tree.activePath.map((node) => node.id));
    pane.replaceChildren(addLines(el("ul"), tree, null, onPath));
    pane.querySelector(".active")?.scrollIntoView({ block: "nearest" });
  }

  return { render };
}
