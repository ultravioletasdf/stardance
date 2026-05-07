import { Controller } from "@hotwired/stimulus";
import { readStack, writeStack } from "./nav_history_controller";

// Pops the top of the nav-history stack (the current page) and navigates to
// the new top. Uses Turbo.visit so the navigation flows through Turbo Drive
// — this preserves `data-turbo-permanent` elements (the sidebar) and uses
// the Turbo cache where available, so the navbar doesn't flash/rebuild.
//
// Falls back to the link's `fallbackValue` (or its own href) when the stack
// only has the current page or is empty.
export default class extends Controller {
  static values = { fallback: String };

  go(event) {
    event.preventDefault();
    const stack = readStack();

    if (stack.length > 1) {
      stack.pop(); // current page
      const target = stack[stack.length - 1];
      writeStack(stack);
      this._navigate(target);
      return;
    }

    const fallback =
      this.fallbackValue || this.element.getAttribute("href") || "/";
    this._navigate(fallback);
  }

  _navigate(url) {
    if (window.Turbo?.visit) {
      window.Turbo.visit(url);
    } else {
      window.location.href = url;
    }
  }
}
