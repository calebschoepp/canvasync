// Entrypoint for React app
import React from "react";
import { render } from "react-dom";
import App from "./components/App";

document.addEventListener("DOMContentLoaded", () => {
    console.log("hello")
    render(
        <App />,
        document.getElementById("root")
    );
});