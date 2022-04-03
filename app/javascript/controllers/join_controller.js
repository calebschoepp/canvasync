import { Controller } from "@hotwired/stimulus";

// Mandated by FR-7: Add.Notebook
export default class extends Controller {
  // Connects to data-controller="join"
  static targets = ["id"];

  connect() {}

  preview() {
    const id = this.id;
    if (id && /^\d+$/.test(id)) {
      window.location.href = `/notebooks/${this.id}/preview`;
    }
  }

  get id() {
    return this.idTarget.value;
  }
}
