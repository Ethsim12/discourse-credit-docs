// assets/javascripts/discourse/components/credit-docs-gate-upload.js

import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";

export default class CreditDocsGateUpload extends Component {
  @service currentUser;
  @service siteSettings;
  @service dialog;

  @tracked cost = null;
  @tracked saving = false;
  @tracked saved = false;
  @tracked errorMessage = null;

  constructor(owner, args) {
    super(owner, args);

    // If the outlet passes an existing doc cost, initialise from it
    if (this.args.initialCost != null) {
      this.cost = this.args.initialCost;
    } else {
      // fall back to site setting default if present
      const defaultCost =
        this.siteSettings?.credit_docs_default_cost ?? null;
      this.cost = defaultCost;
    }
  }

  get upload() {
    return this.args.upload;
  }

  get disabled() {
    return this.saving || !this.upload;
  }

  @action
  updateCost(event) {
    const value = event.target.value;
    const intVal = parseInt(value, 10);
    if (Number.isNaN(intVal) || intVal < 0) {
      this.cost = 0;
    } else {
      this.cost = intVal;
    }
    this.saved = false;
    this.errorMessage = null;
  }

  @action
  async applyGate() {
    if (!this.upload) {
      return;
    }

    this.saving = true;
    this.saved = false;
    this.errorMessage = null;

    try {
      // Adjust URL / payload to match your CreditDocs::GatingController
      await ajax("/credit-docs/gate", {
        type: "PUT",
        data: {
          upload_id: this.upload.id,
          cost: this.cost,
        },
      });

      this.saved = true;
    } catch (e) {
      // crude error handling; you can improve this
      // based on how your controller responds
      this.errorMessage = e?.jqXHR?.responseText || "Failed to save gate settings.";
    } finally {
      this.saving = false;
    }
  }
}
