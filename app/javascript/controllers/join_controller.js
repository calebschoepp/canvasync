import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="join"
export default class extends Controller {
  static targets = ["id"];

  connect() {}

  // TODO: Display an error if id is invalid
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
