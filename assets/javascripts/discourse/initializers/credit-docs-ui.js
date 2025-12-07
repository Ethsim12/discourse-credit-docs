import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "credit-docs-ui",

  initialize() {
    withPluginApi("1.8.0", (api) => {
      const currentUser = api.getCurrentUser();
      if (!currentUser) {
        return;
      }

      // Ensure serializer field exists
      if (typeof currentUser.credit_balance === "undefined") {
        return;
      }

      // Make it reactive for templates / connectors
      currentUser.set("credit_balance", currentUser.credit_balance);
    });
  },
};
