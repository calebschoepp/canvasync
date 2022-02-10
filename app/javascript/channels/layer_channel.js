import consumer from "./consumer"

export default () => {
    consumer.subscriptions.create({channel: "LayerChannel", layer_id: window.layerIds[0]}, {
        connected() {
            // Called when the subscription is ready for use on the server
            console.log(`Connected to layer_channel_${window.layerIds[0]}...`);
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
