// assets/javascripts/discourse/initializers/credit-docs-composer.js

import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "credit-docs-composer",

  initialize() {
    withPluginApi("1.8.0", () => {
      // NOTE:
      // The old composer upload UI for gating documents used the
      // deprecated widgets API (api.decorateWidget("composer-upload:after", …)).
      //
      // That code has been removed to avoid the "widgets decommissioned"
      // admin warning. The backend (credits, gating on download, etc.)
      // still works, but there is currently no composer UI to set
      // per-upload costs.
      //
      // A future version can replace this with a Glimmer component
      // mounted via a modern plugin outlet.
    });
  },
};
