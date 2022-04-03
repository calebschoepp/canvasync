import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="join"
export default class extends Controller {
  static targets = ["id"];

  connect() {}

  preview() {
    const id = this.id;
    if (id && /^\d+$/.test(id)) {
        const url = `/notebooks/${this.id}/preview`;
        fetch(url)
            .then(response => response.status)
            .then(status => {
                if (status === 404) {
                    alert("Notebook does not exist");
                } else if (status === 200) {
                    window.location.href = url;
                } else {
                    alert("Something went wrong");
                }
            });
    } else {
        alert("Invalid notebook id");
    }
  }

  get id() {
    return this.idTarget.value;
  }
}
