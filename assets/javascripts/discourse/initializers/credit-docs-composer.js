import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";

export default {
  name: "credit-docs-composer",

  initialize() {
    withPluginApi("1.8.0", (api) => {

      api.decorateWidget("composer-upload:after", (helper, attrs) => {
        const upload = attrs && attrs.upload;
        if (!upload) return;

        return helper.h("div.credit-gate-controls", [
          helper.h("label", "Gate (credits):"),
          helper.h("input.credit-cost", {
            type: "number",
            min: 0,
            value: upload.creditCost || 1,
            onchange(e) {
              upload.creditCost = parseInt(e.target.value, 10);
            },
          }),

          helper.h(
            "button.credit-gate-btn",
            {
              onclick() {
                ajax("/credit-docs/gate", {
                  method: "PUT",
                  data: {
                    upload_id: upload.id,
                    cost: upload.creditCost,
                  },
                }).then(() => alert("Updated credit cost"));
              },
            },
            "Apply"
          ),
        ]);
      });
    });
  },
};
