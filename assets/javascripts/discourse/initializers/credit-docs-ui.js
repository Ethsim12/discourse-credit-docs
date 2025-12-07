import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "credit-docs-ui",

  initialize() {
    withPluginApi("1.8.0", (api) => {
      const currentUser = api.getCurrentUser();
      if (!currentUser) {
        return;
      }

      // Make sure the serializer field exists
      if (typeof currentUser.credit_balance === "undefined") {
        return;
      }

      // Ensure it's an Ember property so templates can react to it
      currentUser.set("credit_balance", currentUser.credit_balance);
    });
  },
};
