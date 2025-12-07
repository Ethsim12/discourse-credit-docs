import { withPluginApi } from "discourse/lib/plugin-api";
import User from "discourse/models/user";

export default {
  name: "credit-docs-ui",

  initialize() {
    withPluginApi("1.8.0", (api) => {
      const currentUser = api.getCurrentUser();
      const currentUser = User.current();

      if (!currentUser) {
        return;
      }

      if (typeof currentUser.credit_balance === "undefined") {
        return;
      }

      currentUser.set("credit_balance", currentUser.credit_balance);
    });
  },
};
