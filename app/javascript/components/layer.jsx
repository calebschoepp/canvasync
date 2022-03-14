import { useEffect, useRef, useState } from 'react'
import Paper from 'paper';
import { CanvasTools } from './notebook';
import consumer from '../channels/consumer';

// TODO: build in error handling with lost diffs
// TODO: make font size, line width, etc. variables

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
        const processDiff = (diff) => {
          let [diffSeq, diffVisible, diffData] = diff;
          // Process an incoming diff
          if (diffSeq < seq) {
            // TODO: handle diff out of order
            console.log(`Diff seq number too small... ${diff}`);
          } else if (diffSeq > seq) {
            // TODO: handle diff out of order
            console.log(`Diff seq number too large... ${diff}`);
          } else {
            if (diffVisible) {
              console.log(`Loading diff... ${diff}`)
              newLayer.importJSON(diffData);
            }
            seq += 1;
          }
        };

        if (Array.isArray(data)) {
          // Process array of incoming diffs
          data.forEach(diff => processDiff(diff));
        } else {
          // Process single incoming diff
          processDiff(data);
        }
      }
    });
  }

  const transmitDiff = (tool, diff) => {
    if (!layerChannel) {
      return;
    }

    console.log(diff.exportJSON());

    // TODO: Refactor to handle select
    if (tool === CanvasTools.pen || tool === CanvasTools.text) {
      layerChannel.send({type: tool, seq: seq++, data: diff.exportJSON()});
    } else if (tool === CanvasTools.eraser) {
      layerChannel.send({type: tool, seq: seq++, data: diff});
    }
  }

  useEffect(() => {
    // Set up action cable subscriber once layer is created
    if (!layer) {
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
    if (!!pathRef.current) {
      return;
    }

    // Update pathState
    setPathState(oldPaths => [...oldPaths, {seq: seq, data: pathRef.current}]);

    // Transmit text diff
    if (pathRef.current instanceof Paper.PointText) {
      transmitDiff(CanvasTools.text, activeTool.current);
      pathRef.current.fullySelected = false;
    }
  }, [activeTool, activeColor]);

  useEffect(() => {
    pathRef.current = null;
    paperHandler();
  }, [pathState.length]);

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

      // Transmit text diff
      if (!!pathRef && pathRef.current instanceof Paper.PointText) {
        transmitDiff(CanvasTools.text, activeTool.current);
        pathRef.current.fullySelected = false;
      }

      if (activeTool === CanvasTools.pen) {
        scope.project.deselectAll();
        pathRef.current = new Paper.Path();
      } else if (activeTool === CanvasTools.eraser) {
        scope.project.deselectAll();
        path = new Paper.Path();
      } else if (activeTool === CanvasTools.select) {
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

      if (scope.project.selectedItems.length === 0) {
        if (activeTool === CanvasTools.eraser || activeTool === CanvasTools.select) {
          path.strokeColor = 'black';
          path.strokeWidth = 3;
          path.dashArray = [10, 12];
        } else {
          pathRef.current.strokeColor = activeColor;
          pathRef.current.strokeWidth = (activeTool === CanvasTools.pen) ? 3 : 1;
        }
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
        setPathState(oldPaths => [...oldPaths, {seq: seq, data: pathRef.current}]);
        transmitDiff(CanvasTools.pen, pathRef.current);
        pathRef.current = null;
      } else if (activeTool === CanvasTools.eraser) {
        const newPathState = [...pathState];
        const erasedDiffs = [];
        // TODO
        newPathState.forEach((diff) => {
          if (path.intersects(diff)) {
            diff.data.visible = false;
            erasedDiffs.push(diff.seq);
          }
        });
        if (erasedDiffs.length) {
          // Only create an erase diff if state changed
          setPathState(newPathState);
          transmitDiff(CanvasTools.eraser, erasedDiffs);
        }
        path.remove();
        path = null;
      } else if (activeTool === CanvasTools.select) {
        if (scope.project.selectedItems.length === 0) {
          for (let p of pathState) {
            if (p.segments && p.segments.every((segment) => path.contains(segment.point))) {
              // Check for path
              p.fullySelected = true;
            } else if (p.content && p.isInside(rect)) {
              // Check for text
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
          // TODO
          setPathState(newPathState);
        }
      }
    };

    scope.view.onKeyDown = (event) => {
      if (activeTool !== CanvasTools.text && activeTool !== CanvasTools.select) {
        return;
      }

      if (activeTool === CanvasTools.select && event.key === 'delete' && scope.project.selectedItems.length) {
        const newPathState = [];
        for (let p of pathState) {
          if (scope.project.selectedItems.find((selectedItem) => selectedItem.id === p.id)) {
            p.remove();
          } else {
            newPathState.push(p);
          }
        }
        // TODO
        setPathState(newPathState);
      } else if (event.key === 'escape' || event.key === 'enter') {
        setPathState(oldPaths => [...oldPaths, {seq: seq, data: pathRef.current}]);
        transmitDiff(CanvasTools.text, pathRef.current);
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
