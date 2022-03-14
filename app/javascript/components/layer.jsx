import { useEffect, useRef, useState } from 'react'
import Paper from 'paper';
import { CanvasTools } from './notebook';
import consumer from '../channels/consumer';

// TODO: build in error handling with lost diffs

export function Layer({ scope, layer, isOwner, layerId, activeTool, activeColor }) {
  let seq = 0;

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
        if (Array.isArray(data)) {
          // Load existing diffs
          for (let diff of data) {
            if (diff.seq !== seq) {
              // TODO: handle diff out of order
              console.log(`Invalid diff ordering... ${diff}`);
            } else if (diff.visible) {
              console.log(`Loading diff... ${diff}`)
              newLayer.importJSON(diff.data);
              seq += 1;
            }
          }
        } else if (data.seq === seq) {
          console.log(`Loading diff... ${data}`)
          newLayer.importJSON(data.data);
          seq += 1;
        } else {
          console.log(`Invalid diff ordering... ${data}`);
        }
      }
    });
  }

  const transmitDiff = (diff) => {
    // TODO: handle based on activeTool
    if (layerChannel !== null) {
      if (activeTool === CanvasTools.pen || activeTool === CanvasTools.text) {
        console.log(diff.exportJSON())
        layerChannel.send({type: activeTool, seq: seq, data: diff.exportJSON(), rebroadcast: window.isOwner});
        seq += 1;
      }
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
  }, [layerChannel]);

  useEffect(() => {
    paperHandler();
  }, [scope]);

  useEffect(() => {
    console.log(scope.project.layers[0]);
    if (pathRef.current !== null) {
      transmitDiff(pathRef.current);
      pathRef.current = null;
      // setPathState(oldPaths => [...oldPaths, pathRef.current]);
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

    if (!scope) {
      return;
    }

    scope.view.onMouseDown = (event) => {
      scope.activate();
      if (activeTool === CanvasTools.pen) {
        scope.project.deselectAll();
        pathRef.current = new Paper.Path();
      } else if (activeTool === CanvasTools.eraser) {
        scope.project.deselectAll();
        path = new Paper.Path();
      }
      else if (activeTool === CanvasTools.select) {
        p1 = new Paper.Point(event.point.x, event.point.y);
        if (rect && p1.isInside(rect) && scope.project.selectedItems.length > 0) {
          rect = null;
          path = null;
        } else {
          scope.project.deselectAll();
          rect = new Paper.Rectangle();
          path = new Paper.Path.Rectangle(rect);
        }
      } else if (activeTool === CanvasTools.text) {
        console.log(scope.project.layers);
        scope.project.deselectAll();
        const point = new Paper.Point(event.point.x, event.point.y);
        pathRef.current = new Paper.PointText({
          point: point,
          fontFamily: 'serif',
          fontSize: 25,
        });
        pathRef.current.fullySelected = true;
      }

      if (activeTool !== CanvasTools.pen && activeTool !== CanvasTools.text &&
          scope.project.selectedItems.length === 0) {
        path.strokeColor = 'black';
        path.strokeWidth = 3;
        path.dashArray = [10, 12];
      } else if (scope.project.selectedItems.length === 0 || (activeTool === CanvasTools.text)) {
        pathRef.current.strokeColor = activeColor;
        pathRef.current.strokeWidth = activeTool === CanvasTools.pen ? 3 : 1;
      }
    };

    scope.view.onMouseDrag = (event) => {
      if (activeTool === CanvasTools.pen) {
        pathRef.current.add(event.point);
      } else if (activeTool === CanvasTools.eraser) {
        path.add(event.point);
      } else if (activeTool === CanvasTools.select) {
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
      if (activeTool === CanvasTools.pen) {
        pathRef.current.simplify(10);
        setPathState(oldPaths => [...oldPaths, pathRef.current]);
        transmitDiff(pathRef.current);
        pathRef.current = null;
      } else if (activeTool === CanvasTools.eraser) {
        const newPathState = [];
        for (let p of pathState) {
          if (path.intersects(p)) {
            p.remove();
          } else {
            newPathState.push(p);
          }
          setPathState(newPathState);
        }
        path.remove();
        path = null;
      } else if (activeTool === CanvasTools.select) {
        if (scope.project.selectedItems.length === 0) {
          for (let p of pathState) {
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
          for (let p of pathState) {
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
      if (activeTool !== CanvasTools.text && activeTool !== CanvasTools.select) {
        return;
      }
      scope.project.selectedItems.length
      if (activeTool === CanvasTools.select && event.key === 'delete' && scope.project.selectedItems.length) {
        const newPathState = [];
        for (let p of pathState) {
          if (scope.project.selectedItems.find((selectedItem) => selectedItem.id === p.id)) {
            p.remove();
          } else {
            newPathState.push(p);
          }
        }
        setPathState(newPathState);
      } else if (event.key === 'escape' || event.key === 'enter') {
        setPathState(oldPaths => [...oldPaths, pathRef.current]);
        transmitDiff(pathRef.current);
        pathRef.current.fullySelected = false;
        pathRef.current = null;
      } else if (event.key === 'backspace') {
        path.content = pathRef.current.content.slice(0, -1);
      }
      if (activeTool === CanvasTools.text && pathRef.current && event.character !== '') {
        pathRef.current.content += event.character;
      }
    };

    scope.view.draw();
  };

  return null;
}
