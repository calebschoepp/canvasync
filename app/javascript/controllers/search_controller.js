import { Controller } from "@hotwired/stimulus"

// Mandated by FR-5: Search.Notebooks
export default class extends Controller {
  // Connects to data-controller="search"
  static targets = ["query"];

  connect() {
  }

  update() {
    // Call search endpoint with search query and render links
    fetch(`/search?query=${this.query}`)
        .then(response => response.text())
        .then(html => this.element.querySelector("#results").innerHTML = html)
  }

  get query() {
    return this.queryTarget.value;
  }
}
