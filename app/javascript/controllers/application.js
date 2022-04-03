// Mandated by FR-5: Search.Notebooks and FR-7: Add.Notebook

import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
