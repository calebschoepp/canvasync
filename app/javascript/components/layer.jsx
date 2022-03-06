import { useEffect, useRef, useState } from 'react'
import Paper from 'paper';
import { CanvasTools } from './notebook';
import consumer from '../channels/consumer';

export function Layer({ scope, layer, isOwner, layerId, activeTool, activeColor }) {
  const pathRef = useRef(null);
  const [pathState, setPathState] = useState([]);
  const [layerChannel, setLayerChannel] = useState(null);

  const setupSubscription = (newLayer) => {
    return consumer.subscriptions.create({ channel: 'LayerChannel', layer_id: layerId }, {
      connected() {
        // Called when the subscription is ready for use on the server
        console.log(`Connected to layer_channel_${layerId}...`);
      },

      disconnected() {
        // Called when the subscription has been terminated by the server
      },

      received(data) {
        // Called when there's incoming data on the websocket for this channel
        // TODO: Generalize to receive diff and add the proper type of element to the layer
        // TODO: Check to see if this diff has already been applied on this client
        newLayer.addChild(new Paper.PointText({
          point: [50, 50],
          content: data,
          fillColor: (isOwner) ? 'red' : 'blue',
          fontSize: 25
        }));
      }
    });
  }

  // Should be called after a user creates a diff
  const transmitDiff = (diff) => {
    // TODO: This isn't running the first time through. Why is it null the first time?
    if (layerChannel !== null) {
      layerChannel.send({ sent_by: "Caleb", body: "This is a cool app."});
    }
  }

  useEffect(() => {
    // Set up action cable subscriber once layer is created
    if (!!layer) {
      setLayerChannel(setupSubscription(layer));
    }
  }, [layer]);

  useEffect(() => {
    paperHandler();
  }, [scope]);

  useEffect(() => {
    if (pathRef.current) {
      setPathState(oldPaths => [...oldPaths, pathRef.current]);
    }
  }, [activeTool, activeColor]);

  useEffect(() => {
    pathRef.current = null;
    paperHandler();
  }, [pathState.length, activeTool, activeColor]);

  const paperHandler = () => {
    let path = null;

    let rect = null;
    let p1 = null;
    let p2 = null;

    if (scope) {
      scope.view.onMouseDown = (event) => {
        scope.activate();
        if (activeTool === 'Pen') {
          scope.project.deselectAll();
          pathRef.current = new Paper.Path();
        } else if (activeTool === 'Eraser') {
          scope.project.deselectAll();
          path = new Paper.Path();
        }
        else if (activeTool === 'Select') {
          p1 = new Paper.Point(event.point.x, event.point.y);
          if (rect && p1.isInside(rect) && scope.project.selectedItems.length > 0) {
            rect = null;
            path = null;
          } else {
            scope.project.deselectAll();
            rect = new Paper.Rectangle();
            path = new Paper.Path.Rectangle(rect);
          }
        } else if (activeTool === 'Text') {
          scope.project.deselectAll();
          const point = new Paper.Point(event.point.x, event.point.y);
          pathRef.current = new Paper.PointText({
            point: point,
            fontFamily: 'serif',
            fontSize: 25,
          });
          pathRef.current.fullySelected = true;
        }
        if (activeTool !== 'Pen' && activeTool !== 'Text' && scope.project.selectedItems.length === 0) {
          path.strokeColor = 'black';
          path.strokeWidth = 3;
          path.dashArray = [10, 12];
        } else if (scope.project.selectedItems.length === 0 || (activeTool === 'Text')) {
          pathRef.current.strokeColor = activeColor;
          pathRef.current.strokeWidth = activeTool === 'Pen' ? 3 : 1;
        }
      };

      scope.view.onMouseDrag = (event) => {
        if (activeTool === 'Pen') {
          pathRef.current.add(event.point);
        } else if (activeTool === 'Eraser') {
          path.add(event.point);
        } else if (activeTool === 'Select') {
          p2 = new Paper.Point(event.point.x, event.point.y);
          if (scope.project.selectedItems.length === 0) {
            rect.set(p1, p2);
            path.segments = [
              new Paper.Segment(new Paper.Point(rect.x, rect.y)),
              new Paper.Segment(new Paper.Point(rect.x + rect.width, rect.y)),
              new Paper.Segment(new Paper.Point(rect.x + rect.width, rect.y + rect.height)),
              new Paper.Segment(new Paper.Point(rect.x, rect.y + rect.height)),
            ];
          }
        }
      };

      scope.view.onMouseUp = () => {
        if (activeTool === 'Pen') {
          pathRef.current.simplify(10);
          setPathState(oldPaths => [...oldPaths, pathRef.current]);
          transmitDiff(pathRef.current);
          pathRef.current = null;
        } else if (activeTool === 'Eraser') {
          const newPathState = [];
          for (p of pathState) {
            if (path.intersects(p)) {
              p.remove();
            } else {
              newPathState.push(p);
            }
            setPathState(newPathState);
          }
          path.remove();
          path = null;
        } else if (activeTool === 'Select') {
          if (scope.project.selectedItems.length === 0) {
            for (p of pathState) {
              // check for path
              if (p.segments && p.segments.every((segment) => path.contains(segment.point))) {
                p.fullySelected = true;
              } else if (p.content && p.isInside(rect)) { // check for text
                p.fullySelected = true;
              }
            }
            path.remove();
            path = null;
          } else {
            const newPathState = [];
            for (p of pathState) {
              if (scope.project.selectedItems.find((selectedItem) => selectedItem.id === p.id)) {
                p.translate(p2.subtract(p1));
                p.fullySelected = false;
              }
              newPathState.push(p);
            }
            setPathState(newPathState);
          }
        }
      };

      scope.view.onKeyDown = (event) => {
        if (activeTool !== 'Text' && activeTool !== 'Select') {
          return;
        }
        scope.project.selectedItems.length
        if (activeTool === 'Select' && event.key === 'delete' && scope.project.selectedItems.length) {
          const newPathState = [];
          for (p of pathState) {
            if (scope.project.selectedItems.find((selectedItem) => selectedItem.id === p.id)) {
              p.remove();
            } else {
              newPathState.push(p);
            }
          }
          setPathState(newPathState);
        } else if (event.key === 'escape' || event.key === 'enter') {
          setPathState(oldPaths => [...oldPaths, pathRef.current]);
          pathRef.current.fullySelected = false;
          pathRef.current = null;
        } else if (event.key === 'backspace') {
          path.content = pathRef.current.content.slice(0, -1);
        }
        if (activeTool === 'Text' && pathRef.current && event.character !== '') {
          pathRef.current.content += event.character;
        }
      };

      scope.view.draw();
    }
  };

  return null;
};
