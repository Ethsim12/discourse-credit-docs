// assets/javascripts/discourse/initializers/credit-docs-composer.js

import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "credit-docs-composer",

  initialize() {
    withPluginApi("1.8.0", () => {
      // NOTE:
      // The old composer upload UI for gating documents used the
      // deprecated widgets API:
      //
      //   api.decorateWidget("composer-upload:after", …)
      //
      // That code has been removed to avoid the
      // "discourse.widgets-decommissioned" admin warning.
      //
      // Composer UI is now provided via a Glimmer component mounted
      // in a plugin outlet (see:
      // - components/credit-docs-gate-upload.js
      // - templates/connectors/XXX/credit-docs-gate-upload.hbs)
    });
  },
};

