import consumer from "./consumer"

export default () => {
    consumer.subscriptions.create("LayerChannel", {
        connected() {
            // Called when the subscription is ready for use on the server
            console.log("Connected to layer channel...")
        },

        disconnected() {
            // Called when the subscription has been terminated by the server
        },

        received(data) {
            // Called when there's incoming data on the websocket for this channel
            console.log(data)
        }
    })
}
