import React, { useEffect, useRef, useState } from 'react'
import Paper from 'paper';
import consumer from '../channels/consumer';

export function Layer(props) {
  const fontSize = 50;

  const pathRef = useRef(null);
  const [penState, setPenState] = useState('pen');
  const [pathState, setPathState] = useState([]);

  const sub = (layer, layerId) => {
    consumer.subscriptions.create({ channel: 'LayerChannel', layer_id: layerId }, {
      connected() {
        // Called when the subscription is ready for use on the server
        console.log(`Connected to layer_channel_${layerId}...`);
      },

      disconnected() {
        // Called when the subscription has been terminated by the server
      },

      received(data) {
        // Called when there's incoming data on the websocket for this channel

        // TODO: generalize to receive diff and add the proper type of element to the layer
        layer.addChild(new Paper.PointText({
          point: [50, 50],
          content: data,
          fillColor: (layerId == '0') ? 'red' : 'blue',
          fontSize: fontSize
        }));
      }
    });
  }

  // Should be called after a user creates a diff
  const transmitDiff = (diff) => {
    // TODO: implement logic to send diff back to server over `layer_channel_${layerId}`
  }

  useEffect(() => {
    // Set up action cable subscriber once layer is created
    if (!!props.layer) {
      sub(props.layer, props.layerId);
    }
  }, [props.layer, props.layerId]);

  useEffect(() => {
    paperHandler();
  }, []);

  /* Nayan's code */
  // useEffect(() => {
  //   pathRef.current = null;
  //   paperHandler();
  // }, [pathState.length, penState, colorState]);

  const paperHandler = () => {
    // let path = null;

    // let rect = null;
    // let p1 = null;
    // let p2 = null;

    // props.layer.view.onMouseDown = (event) => {
    //   if (penState === 'pen') {
    //     props.layer.deselectAll();
    //     pathRef.current = new props.layer.Path();
    //   } else if (penState === 'eraser') {
    //     props.layer.deselectAll();
    //     path = new props.layer.Path();
    //   }
    //   else if (penState === 'select') {
    //     p1 = new props.layer.Point(event.point.x, event.point.y);
    //     if (rect && p1.isInside(rect) && props.layer.selectedItems.length > 0) {
    //       rect = null;
    //       path = null;
    //     } else {
    //       props.layer.deselectAll();
    //       rect = new props.layer.Rectangle();
    //       path = new props.layer.Path.Rectangle(rect);
    //     }
    //   } else if (penState === 'text') {
    //     props.layer.deselectAll();
    //     const point = new props.layer.Point(event.point.x, event.point.y);
    //     pathRef.current = new props.layer.PointText({
    //       point: point,
    //       fontFamily: 'serif',
    //       fontSize: 25,
    //     });
    //     pathRef.current.fullySelected = true;
    //   }
    //   if (penState !== 'pen' && penState !== 'text' && props.layer.project.selectedItems.length === 0) {
    //     path.strokeColor = 'black';
    //     path.strokeWidth = 3;
    //     path.dashArray = [10, 12];
    //   } else if (props.layer.project.selectedItems.length === 0 || (penState === 'text')) {
    //     pathRef.current.strokeColor = colorState;
    //     pathRef.current.strokeWidth = penState === 'pen' ? 3 : 1;
    //   }
    // };

    // props.layer.onMouseDrag = (event) => {
    //   if (penState === 'pen') {
    //     pathRef.current.add(event.point);
    //   } else if (penState === 'eraser') {
    //     path.add(event.point);
    //   } else if (penState === 'select') {
    //     p2 = new props.layer.Point(event.point.x, event.point.y);
    //     if (props.layer.selectedItems.length === 0) {
    //       rect.set(p1, p2);
    //       path.segments = [
    //         new props.layer.Segment(new props.layer.Point(rect.x, rect.y)),
    //         new props.layer.Segment(new props.layer.Point(rect.x + rect.width, rect.y)),
    //         new props.layer.Segment(new props.layer.Point(rect.x + rect.width, rect.y + rect.height)),
    //         new props.layer.Segment(new props.layer.Point(rect.x, rect.y + rect.height)),
    //       ];
    //     }
    //   }
    // };

    // props.layer.view.onMouseUp = () => {
    //   if (penState === 'pen') {
    //     pathRef.current.simplify(10);
    //     setPathState(oldPaths => [...oldPaths, pathRef.current]);
    //     pathRef.current = null;
    //   } else if (penState === 'eraser') {
    //     const newPathState = [];
    //     for (p of pathState) {
    //       if (path.intersects(p)) {
    //         p.remove();
    //       } else {
    //         newPathState.push(p);
    //       }
    //       setPathState(newPathState);
    //     }
    //     path.remove();
    //     path = null;
    //   } else if (penState === 'select') {
    //     if (props.layer.project.selectedItems.length === 0) {
    //       for (p of pathState) {
    //         // check for path
    //         if (p.segments && p.segments.every((segment) => path.contains(segment.point))) {
    //           p.fullySelected = true;
    //         } else if (p.content && p.isInside(rect)) { // check for text
    //           p.fullySelected = true;
    //         }
    //       }
    //       path.remove();
    //       path = null;
    //     } else {
    //       const newPathState = [];
    //       for (p of pathState) {
    //         if (props.layer.project.selectedItems.find((selectedItem) => selectedItem.id === p.id)) {
    //           p.translate(p2.subtract(p1));
    //           p.fullySelected = false;
    //         }
    //         newPathState.push(p);
    //       }
    //       setPathState(newPathState);
    //     }
    //   }
    // };

    // props.layer.onKeyDown = (event) => {
    //   if (penState !== 'text' && penState !== 'select') {
    //     return;
    //   }
    //   props.layer.project.selectedItems.length
    //   if (penState === 'select' && event.key === 'delete' && props.layer.project.selectedItems.length) {
    //     const newPathState = [];
    //     for (p of pathState) {
    //       if (props.layer.project.selectedItems.find((selectedItem) => selectedItem.id === p.id)) {
    //         p.remove();
    //       } else {
    //         newPathState.push(p);
    //       }
    //     }
    //     setPathState(newPathState);
    //   } else if (event.key === 'escape' || event.key === 'enter') {
    //     setPathState(oldPaths => [...oldPaths, pathRef.current]);
    //     pathRef.current.fullySelected = false;
    //     pathRef.current = null;
    //   } else if (event.key === 'backspace') {
    //     path.content = pathRef.current.content.slice(0, -1);
    //   }
    //   if (penState === 'text' && pathRef.current && event.character !== '') {
    //     pathRef.current.content += event.character;
    //   }
    // };

    // props.layer.draw();
  };

  return null;
};
