import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";

export default {
  name: "credit-docs-composer",

  initialize() {
    withPluginApi("1.8.0", (api) => {
      api.decorateUploadMarkdown(async (composerModel, upload) => {
        // Add UI after upload appears
        upload.creditGatingEnabled = false;
        upload.creditCost = 1;
      });

      api.addComposerUploadHandler("credit-docs-gate", {
        id: "credit-docs-gate",
        title: "Gate with credits",

        async perform(file, opts) {
          // Not used here - UI handled separately
        },
      });

      api.decorateWidget("upload", (helper, attrs) => {
        const upload = attrs.upload;
        if (!upload) return;

        return helper.h("div.credit-gate-controls", [
          helper.h("label", "Gate (credits):"),
          helper.h("input.credit-cost", {
            value: upload.creditCost || 1,
            type: "number",
            min: 0,
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
                }).then(() => {
                  upload.creditGatingEnabled = true;
                  alert("Upload gated with cost " + upload.creditCost);
                });
              },
            },
            "Apply"
          ),
        ]);
      });
    });
  },
};
